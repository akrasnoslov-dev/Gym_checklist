import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreWorkoutRepository: WorkoutRepository {
    enum Error: Swift.Error, Equatable {
        case unauthenticated
        case ownerMismatch
        case duplicateDate
        case workoutNotFound
    }

    private let store: Firestore
    private let currentUserID: () -> UserID?
    private var boundUserID: UserID?
    private var listener: ListenerRegistration?
    private var observers: [UUID: @MainActor ([Workout], WorkoutLoadState) -> Void] = [:]
    private let failures = PersistenceFailureBroadcaster<WorkoutPersistenceFailure>()
    private(set) var workouts: [Workout] = []
    private var loadState: WorkoutLoadState = .loading
    private var hasUsableSnapshot = false
    private var mutations = ScopedDocumentMutationTracker<LocalDate, Workout>()
    private var pendingJournal: DurablePendingMutationJournal<LocalDate, Workout>?

    var userID: UserID {
        guard let boundUserID else { preconditionFailure("Firestore repository requires an authenticated user") }
        return boundUserID
    }

    init(
        store: Firestore = .firestore(),
        currentUserID: @escaping () -> UserID? = {
            Auth.auth().currentUser.map { UserID(rawValue: $0.uid) }
        }
    ) {
        self.store = store
        self.currentUserID = currentUserID
        self.boundUserID = validatedCurrentUserID()
        if let userID = boundUserID {
            pendingJournal = DurablePendingMutationJournal(
                storageKey: PendingMutationJournalStorage.key(scope: "workouts", userID: userID)
            )
        }
        startListening()
    }

    deinit { MainActor.assumeIsolated { listener?.remove() } }

    func observeWorkouts(_ observer: @escaping @MainActor ([Workout], WorkoutLoadState) -> Void) -> WorkoutObservation {
        let id = UUID()
        observers[id] = observer
        observer(workouts, loadState)
        return FirestoreWorkoutObservation { [weak self] in self?.observers.removeValue(forKey: id) }
    }

    func observePersistenceFailures(
        _ observer: @escaping @MainActor (WorkoutPersistenceFailure) -> Void
    ) -> PersistenceFailureObservation {
        failures.observe(observer)
    }

    func workout(on date: LocalDate) -> Workout? {
        workouts.first { $0.localDate == date }
    }

    @discardableResult
    func createEmptyWorkout(on date: LocalDate, at timestamp: Date) -> WorkoutCreationResult {
        guard let userID = boundUserID else { preconditionFailure("Firestore repository requires an authenticated user") }
        if let existing = workout(on: date) { return .existing(existing) }
        let workout = Workout(id: WorkoutID(), userID: userID, localDate: date, exercises: [], createdAt: timestamp, updatedAt: timestamp)
        let ticket = mutations.begin(key: date, baseline: .missing, attempted: .value(workout))
        pendingJournal?.record(ticket, attempted: .value(workout))
        workouts.append(workout)
        markLocalSnapshotAvailable()
        publish()
        do {
            try persist(workout, ticket: ticket)
        } catch {
            publishFailure(.saveRejected(workout))
        }
        return .created(workout)
    }

    func save(_ workout: Workout) throws {
        let userID = try authenticatedUserID()
        guard workout.userID == userID else { throw Error.ownerMismatch }
        if let existing = self.workout(on: workout.localDate), existing.id != workout.id { throw Error.duplicateDate }
        let baseline = self.workout(on: workout.localDate).map { PersistedDocument.value($0) } ?? .missing
        let ticket = mutations.begin(key: workout.localDate, baseline: baseline, attempted: .value(workout))
        pendingJournal?.record(ticket, attempted: .value(workout))
        workouts.removeAll { $0.localDate == workout.localDate }
        workouts.append(workout)
        markLocalSnapshotAvailable()
        publish()
        try persist(workout, ticket: ticket)
    }

    func deleteWorkout(on date: LocalDate) throws {
        _ = try authenticatedUserID()
        guard let removedWorkout = workout(on: date) else { throw Error.workoutNotFound }
        let ticket = mutations.begin(key: date, baseline: .value(removedWorkout), attempted: .missing)
        pendingJournal?.record(ticket, attempted: .missing)
        workouts.removeAll { $0.localDate == date }
        markLocalSnapshotAvailable()
        publish()
        document(for: date).delete { [weak self] error in
            Task { @MainActor in
                self?.recordWriteCompletion(error, ticket: ticket)
            }
        }
    }

    private func authenticatedUserID() throws -> UserID {
        guard let userID = boundUserID else { throw Error.unauthenticated }
        return userID
    }

    private func document(for date: LocalDate) -> DocumentReference {
        store.collection("users").document(userID.rawValue).collection("workouts").document(date.description)
    }

    private func persist(_ workout: Workout, ticket: ScopedDocumentMutationTicket<LocalDate>) throws {
        do {
            try document(for: workout.localDate).setData(from: FirestoreWorkoutPayload(workout: workout)) { [weak self] error in
                Task { @MainActor in
                    self?.recordWriteCompletion(error, ticket: ticket)
                }
            }
        } catch {
            recordWriteCompletion(error, ticket: ticket, publishesFailure: false)
            throw error
        }
    }

    private func startListening() {
        guard let userID = boundUserID else { return }
        listener = store.collection("users").document(userID.rawValue).collection("workouts").addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            guard error == nil, let snapshot else {
                Task { @MainActor in
                    guard let self, self.boundUserID == userID else { return }
                    self.recordUnavailable()
                }
                return
            }
            let entries = snapshot.documents.map { document in
                FirestoreWorkoutSnapshotEntry(
                    documentDate: FirestoreWorkoutDocument.localDate(document.documentID),
                    payload: try? document.data(as: FirestoreWorkoutPayload.self)
                )
            }
            let decoded = FirestoreWorkoutSnapshotDecoder.decode(entries, userID: userID)
            Task { @MainActor in
                guard let self, self.boundUserID == userID else { return }
                guard entries.isEmpty || decoded.discardedEntryCount < entries.count else {
                    if self.hasUsableSnapshot {
                        self.recordUnavailable()
                    } else {
                        self.loadState = .unavailable(hasUsableSnapshot: false)
                        self.publish()
                    }
                    return
                }
                self.workouts = decoded.workoutsPreservingCachedEntries(self.workouts)
                let availability = FirestoreWorkoutSnapshotAvailability.successfulSnapshot(
                    discardedEntryCount: decoded.discardedEntryCount
                )
                self.hasUsableSnapshot = availability.hasUsableSnapshot
                self.loadState = availability.loadState
                self.publish()
                self.reconcileRestartedWrites(snapshot: snapshot, decoded: decoded)
            }
        }
    }

    private func markLocalSnapshotAvailable() {
        hasUsableSnapshot = true
        loadState = .available
    }

    private func recordWriteCompletion(
        _ error: Swift.Error?,
        ticket: ScopedDocumentMutationTicket<LocalDate>,
        publishesFailure: Bool = true
    ) {
        let result: ScopedDocumentMutationResult = error == nil ? .accepted : .rejected
        pendingJournal?.complete(ticket, result: result)
        let completion = mutations.complete(ticket, result: result)
        guard case let .rejected(rollbackSnapshot, attempted) = completion else { return }
        restore(rollbackSnapshot, on: ticket.key)
        switch (rollbackSnapshot, attempted) {
        case let (_, .value(workout)):
            if publishesFailure { publishFailure(.saveRejected(workout)) }
        case let (.value(workout), .missing):
            if publishesFailure { publishFailure(.deleteRejected(workout)) }
        default:
            break
        }
    }

    private func restore(_ snapshot: PersistedDocument<Workout>, on date: LocalDate) {
        workouts.removeAll { $0.localDate == date }
        if case let .value(workout) = snapshot { workouts.append(workout) }
        workouts.sort { $0.localDate < $1.localDate }
        markLocalSnapshotAvailable()
        publish()
    }

    private func reconcileRestartedWrites(
        snapshot: QuerySnapshot,
        decoded: DecodedFirestoreWorkoutSnapshot
    ) {
        let decodedByDate = Dictionary(uniqueKeysWithValues: decoded.workouts.map { ($0.localDate, $0) })
        guard !snapshot.metadata.isFromCache, !snapshot.metadata.hasPendingWrites else { return }
        for unconfirmed in pendingJournal?.reconcileRestarted(stableValues: decodedByDate) ?? [] {
            switch (unconfirmed.attempted, unconfirmed.stable) {
            case let (.value(workout), _):
                publishFailure(.saveUnconfirmedAfterRestart(workout))
            case let (.missing, .value(workout)):
                publishFailure(.deleteUnconfirmedAfterRestart(workout))
            default:
                break
            }
        }
    }

    private func recordUnavailable() {
        loadState = .unavailable(hasUsableSnapshot: hasUsableSnapshot)
        publish()
    }

    private func publish() { observers.values.forEach { $0(workouts, loadState) } }
    private func publishFailure(_ failure: WorkoutPersistenceFailure) {
        failures.publish(failure)
    }

    private func validatedCurrentUserID() -> UserID? {
        guard let userID = currentUserID(), !userID.rawValue.isEmpty, !userID.rawValue.contains("/") else { return nil }
        return userID
    }

}

@MainActor private final class FirestoreWorkoutObservation: WorkoutObservation {
    private var handler: (() -> Void)?; init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}
