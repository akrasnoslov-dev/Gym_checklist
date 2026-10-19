import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreCustomExerciseRepository: CustomExerciseRepository {
    let userID: UserID
    private let store: Firestore
    private var listener: ListenerRegistration?
    private var observers: [UUID: @MainActor ([Exercise]) -> Void] = [:]
    private let failures = PersistenceFailureBroadcaster<CustomExercisePersistenceFailure>()
    private(set) var customExercises: [Exercise] = []
    private var mutations = ScopedDocumentMutationTracker<ExerciseID, Exercise>()
    private var pendingJournal: DurablePendingMutationJournal<ExerciseID, Exercise>?

    init?(store: Firestore = .firestore(), currentUserID: (() -> UserID?)? = nil) {
        let user = currentUserID?() ?? Auth.auth().currentUser.map { UserID(rawValue: $0.uid) }
        guard let user, !user.rawValue.isEmpty, !user.rawValue.contains("/") else { return nil }
        userID = user
        self.store = store
        pendingJournal = DurablePendingMutationJournal(
            storageKey: PendingMutationJournalStorage.key(scope: "customExercises", userID: user)
        )
        listener = collection.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, _ in
            guard let snapshot else { return }
            let decoded = FirestoreCustomExerciseSnapshotDecoder.decode(
                snapshot.documents.map { document in
                    FirestoreCustomExerciseSnapshotEntry(
                        documentID: document.documentID,
                        payload: try? document.data(as: FirestoreCustomExerciseDocument.self)
                    )
                },
                userID: user
            )
            Task { @MainActor in
                guard let self else { return }
                self.customExercises = self.sorted(
                    decoded.exercisesPreservingCachedEntries(self.customExercises)
                )
                self.publish()
                self.reconcileRestartedWrites(snapshot: snapshot, decoded: decoded)
            }
        }
    }

    deinit { MainActor.assumeIsolated { listener?.remove() } }

    func observeCustomExercises(_ observer: @escaping @MainActor ([Exercise]) -> Void) -> CustomExerciseObservation {
        let id = UUID()
        observers[id] = observer
        observer(customExercises)
        return FirestoreCustomExerciseObservation { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    func observePersistenceFailures(
        _ observer: @escaping @MainActor (CustomExercisePersistenceFailure) -> Void
    ) -> PersistenceFailureObservation {
        failures.observe(observer)
    }

    func save(_ exercise: Exercise) throws {
        guard exercise.createdByUserID == userID else { throw CustomExerciseRepositoryError.ownerMismatch }
        guard !exercise.isSystem else { throw CustomExerciseRepositoryError.systemExerciseCannotBePersisted }
        let payload = try FirestoreCustomExerciseDocument(exercise: exercise)
        let baseline = customExercises.first(where: { $0.id == exercise.id }).map { PersistedDocument.value($0) } ?? .missing
        let ticket = mutations.begin(key: exercise.id, baseline: baseline, attempted: .value(exercise))
        pendingJournal?.record(ticket, attempted: .value(exercise))
        customExercises.removeAll { $0.id == exercise.id }
        customExercises.append(exercise)
        customExercises = sorted(customExercises)
        publish()
        do {
            try collection.document(payload.id).setData(from: payload) { [weak self] error in
                Task { @MainActor in self?.recordWriteCompletion(error, ticket: ticket) }
            }
        } catch {
            recordWriteCompletion(error, ticket: ticket, publishesFailure: false)
            throw error
        }
    }

    func deleteCustomExercise(id: ExerciseID) throws {
        guard let removedExercise = customExercises.first(where: { $0.id == id }) else {
            let ticket = mutations.begin(key: id, baseline: .missing, attempted: .missing)
            pendingJournal?.record(ticket, attempted: .missing)
            collection.document(id.rawValue.uuidString).delete { [weak self] error in
                Task { @MainActor in self?.recordWriteCompletion(error, ticket: ticket) }
            }
            return
        }
        let ticket = mutations.begin(key: id, baseline: .value(removedExercise), attempted: .missing)
        pendingJournal?.record(ticket, attempted: .missing)
        customExercises.removeAll { $0.id == id }
        publish()
        collection.document(id.rawValue.uuidString).delete { [weak self] error in
            Task { @MainActor in self?.recordWriteCompletion(error, ticket: ticket) }
        }
    }

    private var collection: CollectionReference {
        store.collection("users").document(userID.rawValue).collection("customExercises")
    }

    private func sorted(_ exercises: [Exercise]) -> [Exercise] {
        exercises.sorted {
            if $0.name != $1.name { return $0.name < $1.name }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }
    }

    private func recordWriteCompletion(
        _ error: Swift.Error?,
        ticket: ScopedDocumentMutationTicket<ExerciseID>,
        publishesFailure: Bool = true
    ) {
        let result: ScopedDocumentMutationResult = error == nil ? .accepted : .rejected
        pendingJournal?.complete(ticket, result: result)
        let completion = mutations.complete(ticket, result: result)
        guard case let .rejected(rollbackSnapshot, attempted) = completion else { return }
        restore(rollbackSnapshot, id: ticket.key)
        switch (rollbackSnapshot, attempted) {
        case let (_, .value(exercise)):
            if publishesFailure { publishFailure(.saveRejected(exercise)) }
        case let (.value(exercise), .missing):
            if publishesFailure { publishFailure(.deleteRejected(exercise)) }
        case (.missing, .missing):
            if publishesFailure { publishFailure(.deleteRejectedWithoutLocalCopy(ticket.key)) }
        default:
            break
        }
    }

    private func restore(_ snapshot: PersistedDocument<Exercise>, id: ExerciseID) {
        customExercises.removeAll { $0.id == id }
        if case let .value(exercise) = snapshot { customExercises.append(exercise) }
        customExercises = sorted(customExercises)
        publish()
    }

    private func reconcileRestartedWrites(
        snapshot: QuerySnapshot,
        decoded: DecodedFirestoreCustomExerciseSnapshot
    ) {
        let decodedByID = Dictionary(uniqueKeysWithValues: decoded.exercises.map { ($0.id, $0) })
        guard !snapshot.metadata.isFromCache, !snapshot.metadata.hasPendingWrites else { return }
        for unconfirmed in pendingJournal?.reconcileRestarted(stableValues: decodedByID) ?? [] {
            switch (unconfirmed.attempted, unconfirmed.stable) {
            case let (.value(exercise), _):
                publishFailure(.saveUnconfirmedAfterRestart(exercise))
            case let (.missing, .value(exercise)):
                publishFailure(.deleteUnconfirmedAfterRestart(exercise))
            default:
                break
            }
        }
    }

    private func publish() { observers.values.forEach { $0(customExercises) } }
    private func publishFailure(_ failure: CustomExercisePersistenceFailure) {
        failures.publish(failure)
    }
}

@MainActor private final class FirestoreCustomExerciseObservation: CustomExerciseObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}
