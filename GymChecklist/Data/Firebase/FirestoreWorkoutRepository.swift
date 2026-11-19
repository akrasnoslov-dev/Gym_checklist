import FirebaseAuth
import FirebaseFirestore
import Foundation
import UIKit

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
    private lazy var restarter = FirestoreListenerRestarter { [weak self] in self?.startListening() }
    private var observers: [UUID: @MainActor ([Workout], WorkoutLoadState) -> Void] = [:]
    private let failures = PersistenceFailureBroadcaster<WorkoutPersistenceFailure>()
    private(set) var workouts: [Workout] = []
    private var loadState: WorkoutLoadState = .loading
    private var hasUsableSnapshot = false
    private lazy var documents = OptimisticDocumentStore<LocalDate, Workout>(
        collection: "workouts",
        journalScope: "workouts",
        userID: self.boundUserID,
        restore: { [weak self] date, snapshot in self?.restore(snapshot, on: date) },
        report: { [weak self] failure in self?.publishFailure(failure) }
    )

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
        _ = documents // Loads the pending-write journal before the first snapshot.
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
        let ticket = documents.begin(key: date, baseline: .missing, attempted: .value(workout))
        workouts.append(workout)
        markLocalSnapshotAvailable()
        publish()
        do {
            try persist(workout, ticket: ticket)
        } catch {
            failures.publish(.saveRejected(workout))
        }
        return .created(workout)
    }

    func save(_ workout: Workout) throws {
        let userID = try authenticatedUserID()
        guard workout.userID == userID else { throw Error.ownerMismatch }
        if let existing = self.workout(on: workout.localDate), existing.id != workout.id { throw Error.duplicateDate }
        let baseline = self.workout(on: workout.localDate).map { PersistedDocument.value($0) } ?? .missing
        let ticket = documents.begin(key: workout.localDate, baseline: baseline, attempted: .value(workout))
        workouts.removeAll { $0.localDate == workout.localDate }
        workouts.append(workout)
        markLocalSnapshotAvailable()
        publish()
        try persist(workout, ticket: ticket)
    }

    func deleteWorkout(on date: LocalDate) throws {
        _ = try authenticatedUserID()
        guard let removedWorkout = workout(on: date) else { throw Error.workoutNotFound }
        let ticket = documents.begin(key: date, baseline: .value(removedWorkout), attempted: .missing)
        workouts.removeAll { $0.localDate == date }
        markLocalSnapshotAvailable()
        publish()
        let reference = self.document(for: date)
        documents.delete(ticket, documentID: date.description) { completion in
            reference.delete(completion: completion)
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
        let reference = self.document(for: workout.localDate)
        try documents.write(ticket, documentID: workout.localDate.description) { completion in
            try reference.setData(from: FirestoreWorkoutPayload(workout: workout), completion: completion)
        }
    }

    private func startListening() {
        guard let userID = boundUserID else { return }
        listener = store.collection("users").document(userID.rawValue).collection("workouts").addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            guard error == nil, let snapshot else {
                if let error {
                    FirestoreDiagnostics.shared.record(FirestoreDiagnosticEvent(
                        operation: .listen, collection: "workouts", documentID: nil, error: error
                    ))
                }
                Task { @MainActor in
                    guard let self, self.boundUserID == userID else { return }
                    self.recordUnavailable()
                    // GYM-37: the listener is dead after an error; attach a new one later.
                    self.listener?.remove()
                    self.listener = nil
                    guard Auth.auth().currentUser?.uid == userID.rawValue else { return }
                    self.restarter.listenerFailed()
                }
                return
            }
            let entries = snapshot.documents.map { document in
                FirestoreWorkoutSnapshotEntry(
                    documentDate: FirestoreWorkoutDocument.localDate(document.documentID),
                    payload: FirestoreDiagnostics.shared.decodeLogging(
                        FirestoreWorkoutPayload.self, from: document, collection: "workouts"
                    )
                )
            }
            let decoded = FirestoreWorkoutSnapshotDecoder.decode(entries, userID: userID)
            FirestoreDiagnostics.shared.recordDomainRejections(
                documentIDs: zip(snapshot.documents, entries).compactMap { document, entry in
                    guard entry.payload != nil else { return nil }
                    guard let date = entry.documentDate else { return document.documentID }
                    // A repaired workout is shown, but its dropped records are still logged (GYM-39).
                    let isRejected = decoded.discardedDocumentDates.contains(date)
                        || decoded.repairedDocumentDates.contains(date)
                    return isRejected ? document.documentID : nil
                },
                collection: "workouts"
            )
            Task { @MainActor in
                guard let self, self.boundUserID == userID else { return }
                self.restarter.listenerDelivered(isFromCache: snapshot.metadata.isFromCache)
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
                self.documents.reconcileRestarted(
                    isFromCache: snapshot.metadata.isFromCache,
                    hasPendingWrites: snapshot.metadata.hasPendingWrites,
                    stableValues: Dictionary(uniqueKeysWithValues: decoded.workouts.map { ($0.localDate, $0) })
                )
            }
        }
    }

    private func markLocalSnapshotAvailable() {
        hasUsableSnapshot = true
        loadState = .available
    }

    private func restore(_ snapshot: PersistedDocument<Workout>, on date: LocalDate) {
        workouts.removeAll { $0.localDate == date }
        if case let .value(workout) = snapshot { workouts.append(workout) }
        workouts.sort { $0.localDate < $1.localDate }
        markLocalSnapshotAvailable()
        publish()
    }

    private func recordUnavailable() {
        loadState = .unavailable(hasUsableSnapshot: hasUsableSnapshot)
        publish()
    }

    private func publish() { observers.values.forEach { $0(workouts, loadState) } }
    private func publishFailure(_ failure: OptimisticDocumentFailure<LocalDate, Workout>) {
        switch failure {
        case let .saveRejected(workout):
            failures.publish(.saveRejected(workout))
        case let .deleteRejected(workout):
            failures.publish(.deleteRejected(workout))
        case let .saveUnconfirmedAfterRestart(workout):
            failures.publish(.saveUnconfirmedAfterRestart(workout))
        case let .deleteUnconfirmedAfterRestart(workout):
            failures.publish(.deleteUnconfirmedAfterRestart(workout))
        case .deleteRejectedWithoutLocalCopy:
            break // Deleting a workout that is not listed throws before any write.
        }
    }

    private func validatedCurrentUserID() -> UserID? {
        guard let userID = currentUserID(), !userID.rawValue.isEmpty, !userID.rawValue.contains("/") else { return nil }
        return userID
    }

}

extension FirestoreDiagnostics {
    /// Decodes a snapshot document, logging the decoding error instead of
    /// discarding it silently. Returns nil when the document is unreadable.
    func decodeLogging<T: Decodable>(_ type: T.Type, from document: DocumentSnapshot, collection: String) -> T? {
        do {
            return try document.data(as: type)
        } catch {
            record(FirestoreDiagnosticEvent(
                operation: .decode, collection: collection, documentID: document.documentID, error: error
            ))
            return nil
        }
    }

    /// Logs documents that decoded but failed domain validation.
    func recordDomainRejections(documentIDs: [String], collection: String) {
        for documentID in documentIDs {
            record(FirestoreDiagnosticEvent(
                operation: .decode, collection: collection, documentID: documentID,
                error: FirestoreMappingError.domainValidationFailed
            ))
        }
    }
}

@MainActor private final class FirestoreWorkoutObservation: WorkoutObservation {
    private var handler: (() -> Void)?; init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}

/// Re-attaches a Firestore listener after it fails (GYM-37). Firestore ends a
/// listener on error, so without this a repository stays stale until restart.
/// Retries back off (2, 4, 8 … 60 s) and also run when the app returns to the
/// foreground.
@MainActor
final class FirestoreListenerRestarter {
    private let restart: @MainActor () -> Void
    private var attempt = 0
    private var scheduled: Task<Void, Never>?
    private var foregroundObserver: NSObjectProtocol?

    init(restart: @escaping @MainActor () -> Void) {
        self.restart = restart
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.restartNowIfWaiting() }
        }
    }

    deinit {
        MainActor.assumeIsolated {
            scheduled?.cancel()
            if let foregroundObserver { NotificationCenter.default.removeObserver(foregroundObserver) }
        }
    }

    nonisolated static func delay(forAttempt attempt: Int) -> TimeInterval {
        min(60, pow(2, Double(min(attempt, 6) + 1)))
    }

    /// Call when the listener reported an error and has been removed.
    func listenerFailed() {
        guard scheduled == nil else { return }
        let delay = Self.delay(forAttempt: attempt)
        attempt += 1
        scheduled = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.fire()
        }
    }

    /// Call for every snapshot. Only a server snapshot proves the listener
    /// recovered; a cached one arrives first even when the server keeps
    /// rejecting the listener, so it must not reset the back-off.
    func listenerDelivered(isFromCache: Bool) {
        guard !isFromCache else { return }
        attempt = 0
    }

    func cancel() {
        scheduled?.cancel()
        scheduled = nil
    }

    private func restartNowIfWaiting() {
        guard scheduled != nil else { return }
        scheduled?.cancel()
        fire()
    }

    private func fire() {
        scheduled = nil
        restart()
    }
}
