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
    private var observers: [UUID: @MainActor ([Workout]) -> Void] = [:]
    private(set) var workouts: [Workout] = []

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
        startListening()
    }

    deinit { MainActor.assumeIsolated { listener?.remove() } }

    func refreshAuthentication() {
        listener?.remove()
        listener = nil
        boundUserID = validatedCurrentUserID()
        workouts = []
        publish()
        startListening()
    }

    func observeWorkouts(_ observer: @escaping @MainActor ([Workout]) -> Void) -> WorkoutObservation {
        let id = UUID()
        observers[id] = observer
        observer(workouts)
        return FirestoreWorkoutObservation { [weak self] in self?.observers.removeValue(forKey: id) }
    }

    func workout(on date: LocalDate) -> Workout? {
        workouts.first { $0.localDate == date }
    }

    @discardableResult
    func createEmptyWorkout(on date: LocalDate, at timestamp: Date) -> WorkoutCreationResult {
        guard let userID = boundUserID else { preconditionFailure("Firestore repository requires an authenticated user") }
        if let existing = workout(on: date) { return .existing(existing) }
        let workout = Workout(userID: userID, localDate: date, exercises: [], createdAt: timestamp, updatedAt: timestamp)
        workouts.append(workout)
        publish()
        persist(workout)
        return .created(workout)
    }

    func save(_ workout: Workout) throws {
        let userID = try authenticatedUserID()
        guard workout.userID == userID else { throw Error.ownerMismatch }
        if let existing = workout(on: workout.localDate), existing.id != workout.id { throw Error.duplicateDate }
        workouts.removeAll { $0.localDate == workout.localDate }
        workouts.append(workout)
        publish()
        persist(workout)
    }

    func deleteWorkout(on date: LocalDate) throws {
        _ = try authenticatedUserID()
        guard workout(on: date) != nil else { throw Error.workoutNotFound }
        workouts.removeAll { $0.localDate == date }
        publish()
        document(for: date).delete()
    }

    private func authenticatedUserID() throws -> UserID {
        guard let userID = boundUserID else { throw Error.unauthenticated }
        return userID
    }

    private func document(for date: LocalDate) -> DocumentReference {
        store.collection("users").document(userID.rawValue).collection("workouts").document(date.description)
    }

    private func persist(_ workout: Workout) {
        try? document(for: workout.localDate).setData(from: FirestoreWorkoutPayload(workout: workout))
    }

    private func startListening() {
        guard let userID = boundUserID else { return }
        listener = store.collection("users").document(userID.rawValue).collection("workouts").addSnapshotListener { [weak self] snapshot, _ in
            guard let snapshot else { return }
            let decoded = snapshot.documents.compactMap { document in
                guard let date = FirestoreWorkoutDocument.localDate(document.documentID),
                      let payload = try? document.data(as: FirestoreWorkoutPayload.self),
                      let workout = try? payload.domainWorkout(userID: userID, documentDate: date)
                else { return nil }
                return workout
            } ?? []
            Task { @MainActor in
                guard let self, self.boundUserID == userID else { return }
                self.workouts = decoded.sorted { $0.localDate < $1.localDate }
                self.publish()
            }
        }
    }

    private func publish() { observers.values.forEach { $0(workouts) } }

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
