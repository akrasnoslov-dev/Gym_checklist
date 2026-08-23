import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreCustomExerciseRepository: CustomExerciseRepository {
    let userID: UserID
    private let store: Firestore
    private var listener: ListenerRegistration?
    private var observers: [UUID: @MainActor ([Exercise]) -> Void] = [:]
    private(set) var customExercises: [Exercise] = []

    init?(store: Firestore = .firestore(), currentUserID: (() -> UserID?)? = nil) {
        let user = currentUserID?() ?? Auth.auth().currentUser.map { UserID(rawValue: $0.uid) }
        guard let user, !user.rawValue.isEmpty, !user.rawValue.contains("/") else { return nil }
        userID = user
        self.store = store
        listener = collection.addSnapshotListener { [weak self] snapshot, _ in
            let exercises = snapshot?.documents.compactMap { document -> Exercise? in
                guard let payload = try? document.data(as: FirestoreCustomExerciseDocument.self),
                      document.documentID == payload.id else { return nil }
                return try? payload.exercise(userID: user)
            } ?? []
            Task { @MainActor in
                guard let self else { return }
                self.customExercises = self.sorted(exercises)
                self.publish()
            }
        }
    }

    deinit { listener?.remove() }

    func observeCustomExercises(_ observer: @escaping @MainActor ([Exercise]) -> Void) -> CustomExerciseObservation {
        let id = UUID()
        observers[id] = observer
        observer(customExercises)
        return FirestoreCustomExerciseObservation { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    func save(_ exercise: Exercise) throws {
        guard exercise.createdByUserID == userID else { throw CustomExerciseRepositoryError.ownerMismatch }
        guard !exercise.isSystem else { throw CustomExerciseRepositoryError.systemExerciseCannotBePersisted }
        let payload = try FirestoreCustomExerciseDocument(exercise: exercise)
        customExercises.removeAll { $0.id == exercise.id }
        customExercises.append(exercise)
        customExercises = sorted(customExercises)
        publish()
        try collection.document(payload.id).setData(from: payload)
    }

    func deleteCustomExercise(id: ExerciseID) throws {
        customExercises.removeAll { $0.id == id }
        publish()
        collection.document(id.rawValue.uuidString).delete()
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

    private func publish() { observers.values.forEach { $0(customExercises) } }
}

@MainActor private final class FirestoreCustomExerciseObservation: CustomExerciseObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { cancel() }
}
