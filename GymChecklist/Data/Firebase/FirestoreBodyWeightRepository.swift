import FirebaseAuth
import FirebaseFirestore
import Foundation

private let bodyWeightCollectionName = "bodyWeightMeasurements"

@MainActor
final class FirestoreBodyWeightRepository: BodyWeightRepository {
    let userID: UserID
    private let store: Firestore
    private var listener: ListenerRegistration?
    private lazy var restarter = FirestoreListenerRestarter { [weak self] in self?.startListening() }
    private var observers: [UUID: @MainActor ([BodyWeightMeasurement]) -> Void] = [:]
    private let failures = PersistenceFailureBroadcaster<BodyWeightPersistenceFailure>()
    private(set) var measurements: [BodyWeightMeasurement] = []
    private lazy var documents = OptimisticDocumentStore<BodyWeightMeasurementID, BodyWeightMeasurement>(
        collection: bodyWeightCollectionName,
        journalScope: "bodyWeight",
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
        guard PersistedValueLimits.isValidBodyWeight(measurement.weightInKilograms) else {
            throw BodyWeightRepositoryError.invalidMeasurement
        }
        let payload = FirestoreBodyWeightMeasurementDocument(measurement: measurement)
        let baseline = measurements.first(where: { $0.id == measurement.id }).map { PersistedDocument.value($0) } ?? .missing
        let ticket = documents.begin(key: measurement.id, baseline: baseline, attempted: .value(measurement))
        measurements.removeAll { $0.id == measurement.id }
        measurements.append(measurement)
        measurements = sorted(measurements)
        publish()
        let document = store.document(FirestoreDocumentPath.bodyWeightMeasurement(userID: userID, measurementID: measurement.id))
        try documents.write(ticket, documentID: payload.id) { completion in
            try document.setData(from: payload, completion: completion)
        }
    }

    func deleteMeasurement(id: BodyWeightMeasurementID) throws {
        guard let removedMeasurement = measurements.first(where: { $0.id == id }) else {
            throw BodyWeightRepositoryError.measurementNotFound(id)
        }
        let ticket = documents.begin(key: id, baseline: .value(removedMeasurement), attempted: .missing)
        measurements.removeAll { $0.id == id }
        publish()
        let document = store.document(FirestoreDocumentPath.bodyWeightMeasurement(userID: userID, measurementID: id))
        documents.delete(ticket, documentID: id.rawValue.uuidString) { completion in
            document.delete(completion: completion)
        }
    }

    /// Firestore ends a listener after it reports an error, so a retry has to
    /// attach a new one. Measurements already shown stay visible meanwhile.
    func restartListening() {
        guard listener == nil else { return }
        restarter.cancel()
        startListening()
    }

    private var collection: CollectionReference {
        store.collection("users").document(userID.rawValue).collection(bodyWeightCollectionName)
    }

    private func startListening() {
        let user = userID
        listener = collection.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            guard error == nil, let snapshot else {
                if let error {
                    FirestoreDiagnostics.shared.record(FirestoreDiagnosticEvent(
                        operation: .listen, collection: bodyWeightCollectionName, documentID: nil, error: error
                    ))
                }
                Task { @MainActor in self?.recordListenerFailure() }
                return
            }
            let entries = snapshot.documents.map { document in
                FirestoreBodyWeightSnapshotEntry(
                    documentID: document.documentID,
                    payload: FirestoreDiagnostics.shared.decodeLogging(
                        FirestoreBodyWeightMeasurementDocument.self, from: document, collection: bodyWeightCollectionName
                    )
                )
            }
            let decoded = FirestoreBodyWeightSnapshotDecoder.decode(entries, userID: user)
            let decodedIDs = Set(decoded.measurements.map { $0.id.rawValue.uuidString })
            FirestoreDiagnostics.shared.recordDomainRejections(
                documentIDs: entries.filter { $0.payload != nil && !decodedIDs.contains($0.documentID) }.map(\.documentID),
                collection: bodyWeightCollectionName
            )
            Task { @MainActor in
                guard let self else { return }
                self.restarter.listenerDelivered(isFromCache: snapshot.metadata.isFromCache)
                self.measurements = decoded.measurementsPreservingCachedEntries(self.measurements)
                self.publish()
                self.documents.reconcileRestarted(
                    isFromCache: snapshot.metadata.isFromCache,
                    hasPendingWrites: snapshot.metadata.hasPendingWrites,
                    stableValues: Dictionary(uniqueKeysWithValues: decoded.measurements.map { ($0.id, $0) })
                )
            }
        }
    }

    /// GYM-12: a failed listener is reported instead of silently freezing the list.
    private func recordListenerFailure() {
        listener?.remove()
        listener = nil
        // A listener torn down by sign-out is expected, not a user-facing failure.
        guard Auth.auth().currentUser?.uid == userID.rawValue else { return }
        // GYM-37: retry automatically too; the banner's Retry just goes sooner.
        restarter.listenerFailed()
        failures.publish(.historyUnavailable)
    }

    private func sorted(_ values: [BodyWeightMeasurement]) -> [BodyWeightMeasurement] {
        values.sorted {
            BodyWeightMeasurement.isMoreRecent($0, than: $1)
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

    private func publish() { observers.values.forEach { $0(measurements) } }

    private func publishFailure(_ failure: OptimisticDocumentFailure<BodyWeightMeasurementID, BodyWeightMeasurement>) {
        switch failure {
        case let .saveRejected(measurement):
            failures.publish(.saveRejected(measurement))
        case let .deleteRejected(measurement):
            failures.publish(.deleteRejected(measurement))
        case let .saveUnconfirmedAfterRestart(measurement):
            failures.publish(.saveUnconfirmedAfterRestart(measurement))
        case let .deleteUnconfirmedAfterRestart(measurement):
            failures.publish(.deleteUnconfirmedAfterRestart(measurement))
        case .deleteRejectedWithoutLocalCopy:
            break // Deleting a measurement that is not listed throws before any write.
        }
    }
}

@MainActor private final class FirestoreBodyWeightObservation: BodyWeightObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}
