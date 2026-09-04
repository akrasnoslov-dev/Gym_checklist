import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreBodyWeightRepository: BodyWeightRepository {
    let userID: UserID
    private let store: Firestore
    private var listener: ListenerRegistration?
    private var observers: [UUID: @MainActor ([BodyWeightMeasurement]) -> Void] = [:]
    private(set) var measurements: [BodyWeightMeasurement] = []

    init?(store: Firestore = .firestore(), currentUserID: (() -> UserID?)? = nil) {
        let user = currentUserID?() ?? Auth.auth().currentUser.map { UserID(rawValue: $0.uid) }
        guard let user, !user.rawValue.isEmpty, !user.rawValue.contains("/") else { return nil }
        userID = user
        self.store = store
        listener = collection.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, _ in
            guard let snapshot else { return }
            let decoded = snapshot.documents.compactMap { document -> BodyWeightMeasurement? in
                guard let payload = try? document.data(as: FirestoreBodyWeightMeasurementDocument.self),
                      document.documentID == payload.id else { return nil }
                return try? payload.measurement(userID: user)
            }
            Task { @MainActor in
                guard let self else { return }
                self.measurements = self.sorted(decoded)
                self.publish()
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

    func save(_ measurement: BodyWeightMeasurement) throws {
        guard measurement.userID == userID else { throw BodyWeightRepositoryError.ownerMismatch }
        guard measurement.weightInKilograms.isFinite, measurement.weightInKilograms > 0 else {
            throw BodyWeightRepositoryError.invalidMeasurement
        }
        let payload = FirestoreBodyWeightMeasurementDocument(measurement: measurement)
        measurements.removeAll { $0.id == measurement.id }
        measurements.append(measurement)
        measurements = sorted(measurements)
        publish()
        try store.document(FirestoreDocumentPath.bodyWeightMeasurement(userID: userID, measurementID: measurement.id))
            .setData(from: payload)
    }

    func deleteMeasurement(id: BodyWeightMeasurementID) throws {
        measurements.removeAll { $0.id == id }
        publish()
        store.document(FirestoreDocumentPath.bodyWeightMeasurement(userID: userID, measurementID: id)).delete()
    }

    private var collection: CollectionReference {
        store.collection("users").document(userID.rawValue).collection("bodyWeightMeasurements")
    }

    private func sorted(_ values: [BodyWeightMeasurement]) -> [BodyWeightMeasurement] {
        values.sorted {
            if $0.measuredAt != $1.measuredAt { return $0.measuredAt > $1.measuredAt }
            return $0.id.rawValue.uuidString > $1.id.rawValue.uuidString
        }
    }

    private func publish() { observers.values.forEach { $0(measurements) } }
}

@MainActor private final class FirestoreBodyWeightObservation: BodyWeightObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}
