import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreCustomExerciseRepository: CustomExerciseRepository {
    let userID: UserID
    private let store: Firestore
    private var listener: ListenerRegistration?
    private lazy var restarter = FirestoreListenerRestarter { [weak self] in self?.startListening() }
    private var observers: [UUID: @MainActor ([Exercise]) -> Void] = [:]
    private let failures = PersistenceFailureBroadcaster<CustomExercisePersistenceFailure>()
    private(set) var customExercises: [Exercise] = []
    private lazy var documents = OptimisticDocumentStore<ExerciseID, Exercise>(
        collection: "customExercises",
        journalScope: "customExercises",
        userID: self.userID,
        restore: { [weak self] id, snapshot in self?.restore(snapshot, id: id) },
        report: { [weak self] failure in self?.publishFailure(failure) }
    )

    init?(store: Firestore = .firestore(), currentUserID: (() -> UserID?)? = nil) {
        let user = currentUserID?() ?? Auth.auth().currentUser.map { UserID(rawValue: $0.uid) }
        guard let user, !user.rawValue.isEmpty, !user.rawValue.contains("/") else { return nil }
        userID = user
        self.store = store
        _ = documents // Loads the pending-write journal before the first snapshot.
        startListening()
    }

    private func startListening() {
        let user = userID
        listener = collection.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            guard let snapshot else {
                // The list keeps its last value while the listener reconnects (GYM-37).
                if let error {
                    FirestoreDiagnostics.shared.record(FirestoreDiagnosticEvent(
                        operation: .listen, collection: "customExercises", documentID: nil, error: error
                    ))
                }
                Task { @MainActor in self?.recordListenerFailure() }
                return
            }
            let entries = snapshot.documents.map { document in
                FirestoreCustomExerciseSnapshotEntry(
                    documentID: document.documentID,
                    payload: FirestoreDiagnostics.shared.decodeLogging(
                        FirestoreCustomExerciseDocument.self, from: document, collection: "customExercises"
                    )
                )
            }
            let decoded = FirestoreCustomExerciseSnapshotDecoder.decode(entries, userID: user)
            let decodedIDs = Set(decoded.exercises.map { $0.id.rawValue.uuidString })
            FirestoreDiagnostics.shared.recordDomainRejections(
                documentIDs: entries.filter { $0.payload != nil && !decodedIDs.contains($0.documentID) }.map(\.documentID),
                collection: "customExercises"
            )
            Task { @MainActor in
                guard let self else { return }
                self.restarter.listenerDelivered(isFromCache: snapshot.metadata.isFromCache)
                self.customExercises = self.sorted(
                    decoded.exercisesPreservingCachedEntries(self.customExercises)
                )
                self.publish()
                self.documents.reconcileRestarted(
                    isFromCache: snapshot.metadata.isFromCache,
                    hasPendingWrites: snapshot.metadata.hasPendingWrites,
                    stableValues: Dictionary(uniqueKeysWithValues: decoded.exercises.map { ($0.id, $0) })
                )
            }
        }
    }

    deinit { MainActor.assumeIsolated { listener?.remove() } }

    /// GYM-37: the listener is dead after an error; attach a new one after a
    /// back-off, unless the user signed out.
    private func recordListenerFailure() {
        listener?.remove()
        listener = nil
        guard Auth.auth().currentUser?.uid == userID.rawValue else { return }
        restarter.listenerFailed()
    }

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
        let ticket = documents.begin(key: exercise.id, baseline: baseline, attempted: .value(exercise))
        customExercises.removeAll { $0.id == exercise.id }
        customExercises.append(exercise)
        customExercises = sorted(customExercises)
        publish()
        let document = collection.document(payload.id)
        try documents.write(ticket, documentID: payload.id) { completion in
            try document.setData(from: payload, completion: completion)
        }
    }

    func deleteCustomExercise(id: ExerciseID) throws {
        let removedExercise = customExercises.first(where: { $0.id == id })
        let ticket = documents.begin(
            key: id,
            baseline: removedExercise.map { PersistedDocument.value($0) } ?? .missing,
            attempted: .missing
        )
        if removedExercise != nil {
            customExercises.removeAll { $0.id == id }
            publish()
        }
        let documentID = id.rawValue.uuidString
        let document = collection.document(documentID)
        documents.delete(ticket, documentID: documentID) { completion in
            document.delete(completion: completion)
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

    private func restore(_ snapshot: PersistedDocument<Exercise>, id: ExerciseID) {
        customExercises.removeAll { $0.id == id }
        if case let .value(exercise) = snapshot { customExercises.append(exercise) }
        customExercises = sorted(customExercises)
        publish()
    }

    private func publish() { observers.values.forEach { $0(customExercises) } }

    private func publishFailure(_ failure: OptimisticDocumentFailure<ExerciseID, Exercise>) {
        switch failure {
        case let .saveRejected(exercise):
            failures.publish(.saveRejected(exercise))
        case let .deleteRejected(exercise):
            failures.publish(.deleteRejected(exercise))
        case let .deleteRejectedWithoutLocalCopy(id):
            failures.publish(.deleteRejectedWithoutLocalCopy(id))
        case let .saveUnconfirmedAfterRestart(exercise):
            failures.publish(.saveUnconfirmedAfterRestart(exercise))
        case let .deleteUnconfirmedAfterRestart(exercise):
            failures.publish(.deleteUnconfirmedAfterRestart(exercise))
        }
    }
}

@MainActor private final class FirestoreCustomExerciseObservation: CustomExerciseObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}
