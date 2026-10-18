import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreBodyWeightRepository: BodyWeightRepository {
    let userID: UserID
    private let store: Firestore
    private var listener: ListenerRegistration?
    private var observers: [UUID: @MainActor ([BodyWeightMeasurement]) -> Void] = [:]
    private let failures = PersistenceFailureBroadcaster<BodyWeightPersistenceFailure>()
    private(set) var measurements: [BodyWeightMeasurement] = []
    private var mutations = ScopedDocumentMutationTracker<BodyWeightMeasurementID, BodyWeightMeasurement>()
    private var pendingJournal: DurablePendingMutationJournal<BodyWeightMeasurementID, BodyWeightMeasurement>?

    init?(store: Firestore = .firestore(), currentUserID: (() -> UserID?)? = nil) {
        let user = currentUserID?() ?? Auth.auth().currentUser.map { UserID(rawValue: $0.uid) }
        guard let user, !user.rawValue.isEmpty, !user.rawValue.contains("/") else { return nil }
        userID = user
        self.store = store
        pendingJournal = DurablePendingMutationJournal(
            storageKey: PendingMutationJournalStorage.key(scope: "bodyWeight", userID: user)
        )
        listener = collection.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, _ in
            guard let snapshot else { return }
            let decoded = FirestoreBodyWeightSnapshotDecoder.decode(
                snapshot.documents.map { document in
                    FirestoreBodyWeightSnapshotEntry(
                        documentID: document.documentID,
                        payload: try? document.data(as: FirestoreBodyWeightMeasurementDocument.self)
                    )
                },
                userID: user
            )
            Task { @MainActor in
                guard let self else { return }
                self.measurements = decoded.measurementsPreservingCachedEntries(self.measurements)
                self.publish()
                self.reconcileRestartedWrites(snapshot: snapshot, decoded: decoded)
            }
        }
    }

    deinit { MainActor.assumeIsolated { listener?.remove() } }

    func observeMeasurements(_ observer: @escaping @MainActor ([BodyWeightMeasurement]) -> Void) -> BodyWeightObservation {
        let id = UUID()
        observers[id] = observer
        observer(measurements)
        return FirestoreBodyWeightObservation { [weak self] in self?.observers.removeValue(forKey: id) }
    }

    func observePersistenceFailures(
        _ observer: @escaping @MainActor (BodyWeightPersistenceFailure) -> Void
    ) -> PersistenceFailureObservation {
        failures.observe(observer)
    }

    func save(_ measurement: BodyWeightMeasurement) throws {
        guard measurement.userID == userID else { throw BodyWeightRepositoryError.ownerMismatch }
        guard measurement.weightInKilograms.isFinite, measurement.weightInKilograms > 0 else {
            throw BodyWeightRepositoryError.invalidMeasurement
        }
        let payload = FirestoreBodyWeightMeasurementDocument(measurement: measurement)
        let baseline = measurements.first(where: { $0.id == measurement.id }).map { PersistedDocument.value($0) } ?? .missing
        let ticket = mutations.begin(key: measurement.id, baseline: baseline, attempted: .value(measurement))
        pendingJournal?.record(ticket, attempted: .value(measurement))
        measurements.removeAll { $0.id == measurement.id }
        measurements.append(measurement)
        measurements = sorted(measurements)
        publish()
        do {
            try store.document(FirestoreDocumentPath.bodyWeightMeasurement(userID: userID, measurementID: measurement.id))
                .setData(from: payload) { [weak self] error in
                    Task { @MainActor in self?.recordWriteCompletion(error, ticket: ticket) }
                }
        } catch {
            recordWriteCompletion(error, ticket: ticket, publishesFailure: false)
            throw error
        }
    }

    func deleteMeasurement(
        id: BodyWeightMeasurementID,
        onFailure: @escaping @MainActor () -> Void
    ) throws {
        guard let removedMeasurement = measurements.first(where: { $0.id == id }) else {
            throw BodyWeightRepositoryError.measurementNotFound(id)
        }
        let ticket = mutations.begin(key: id, baseline: .value(removedMeasurement), attempted: .missing)
        pendingJournal?.record(ticket, attempted: .missing)
        measurements.removeAll { $0.id == id }
        publish()
        store.document(FirestoreDocumentPath.bodyWeightMeasurement(userID: userID, measurementID: id)).delete { [weak self] error in
            Task { @MainActor [weak self] in
                self?.recordWriteCompletion(error, ticket: ticket, onDeleteFailure: onFailure)
            }
        }
    }

    private var collection: CollectionReference {
        store.collection("users").document(userID.rawValue).collection("bodyWeightMeasurements")
    }

    private func sorted(_ values: [BodyWeightMeasurement]) -> [BodyWeightMeasurement] {
        values.sorted {
            BodyWeightMeasurement.isMoreRecent($0, than: $1)
        }
    }

    private func recordWriteCompletion(
        _ error: Swift.Error?,
        ticket: ScopedDocumentMutationTicket<BodyWeightMeasurementID>,
        onDeleteFailure: (@MainActor () -> Void)? = nil,
        publishesFailure: Bool = true
    ) {
        let result: ScopedDocumentMutationResult = error == nil ? .accepted : .rejected
        pendingJournal?.complete(ticket, result: result)
        let completion = mutations.complete(ticket, result: result)
        guard case let .rejected(rollbackSnapshot, attempted) = completion else { return }
        restore(rollbackSnapshot, id: ticket.key)
        switch (rollbackSnapshot, attempted) {
        case let (_, .value(measurement)):
            if publishesFailure { publishFailure(.saveRejected(measurement)) }
        case let (.value(measurement), .missing):
            onDeleteFailure?()
            if publishesFailure { publishFailure(.deleteRejected(measurement)) }
        default:
            break
        }
    }

    private func restore(
        _ snapshot: PersistedDocument<BodyWeightMeasurement>,
        id: BodyWeightMeasurementID
    ) {
        measurements.removeAll { $0.id == id }
        if case let .value(measurement) = snapshot { measurements.append(measurement) }
        measurements = sorted(measurements)
        publish()
    }

    private func reconcileRestartedWrites(
        snapshot: QuerySnapshot,
        decoded: DecodedFirestoreBodyWeightSnapshot
    ) {
        let decodedByID = Dictionary(uniqueKeysWithValues: decoded.measurements.map { ($0.id, $0) })
        guard !snapshot.metadata.isFromCache, !snapshot.metadata.hasPendingWrites else { return }
        for unconfirmed in pendingJournal?.reconcileRestarted(stableValues: decodedByID) ?? [] {
            switch (unconfirmed.attempted, unconfirmed.stable) {
            case let (.value(measurement), _):
                publishFailure(.saveUnconfirmedAfterRestart(measurement))
            case let (.missing, .value(measurement)):
                publishFailure(.deleteUnconfirmedAfterRestart(measurement))
            default:
                break
            }
        }
    }

    private func publish() { observers.values.forEach { $0(measurements) } }
    private func publishFailure(_ failure: BodyWeightPersistenceFailure) {
        failures.publish(failure)
    }
}

@MainActor private final class FirestoreBodyWeightObservation: BodyWeightObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}
