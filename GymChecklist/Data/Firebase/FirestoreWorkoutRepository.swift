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
    private(set) var workouts: [Workout] = []
    private var loadState: WorkoutLoadState = .loading
    private var hasUsableSnapshot = false
    private var latestWriteGeneration = 0

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

    func observeWorkouts(_ observer: @escaping @MainActor ([Workout], WorkoutLoadState) -> Void) -> WorkoutObservation {
        let id = UUID()
        observers[id] = observer
        observer(workouts, loadState)
        return FirestoreWorkoutObservation { [weak self] in self?.observers.removeValue(forKey: id) }
    }

    func workout(on date: LocalDate) -> Workout? {
        workouts.first { $0.localDate == date }
    }

    @discardableResult
    func createEmptyWorkout(on date: LocalDate, at timestamp: Date) -> WorkoutCreationResult {
        guard let userID = boundUserID else { preconditionFailure("Firestore repository requires an authenticated user") }
        if let existing = workout(on: date) { return .existing(existing) }
        let workout = Workout(id: WorkoutID(), userID: userID, localDate: date, exercises: [], createdAt: timestamp, updatedAt: timestamp)
        workouts.append(workout)
        markLocalSnapshotAvailable()
        publish()
        persist(workout)
        return .created(workout)
    }

    func save(_ workout: Workout) throws {
        let userID = try authenticatedUserID()
        guard workout.userID == userID else { throw Error.ownerMismatch }
        if let existing = self.workout(on: workout.localDate), existing.id != workout.id { throw Error.duplicateDate }
        workouts.removeAll { $0.localDate == workout.localDate }
        workouts.append(workout)
        markLocalSnapshotAvailable()
        publish()
        persist(workout)
    }

    func deleteWorkout(on date: LocalDate) throws {
        _ = try authenticatedUserID()
        guard workout(on: date) != nil else { throw Error.workoutNotFound }
        workouts.removeAll { $0.localDate == date }
        markLocalSnapshotAvailable()
        publish()
        let writeGeneration = nextWriteGeneration()
        document(for: date).delete { [weak self] error in
            Task { @MainActor in
                self?.recordWriteCompletion(error, generation: writeGeneration)
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

    private func persist(_ workout: Workout) {
        let writeGeneration = nextWriteGeneration()
        do {
            try document(for: workout.localDate).setData(from: FirestoreWorkoutPayload(workout: workout)) { [weak self] error in
                Task { @MainActor in
                    self?.recordWriteCompletion(error, generation: writeGeneration)
                }
            }
        } catch {
            recordWriteCompletion(error, generation: writeGeneration)
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
            }
        }
    }

    private func markLocalSnapshotAvailable() {
        hasUsableSnapshot = true
        loadState = .available
    }

    private func nextWriteGeneration() -> Int {
        latestWriteGeneration += 1
        return latestWriteGeneration
    }

    private func recordWriteCompletion(_ error: Swift.Error?, generation: Int) {
        guard generation == latestWriteGeneration else { return }
        if error == nil {
            if hasUsableSnapshot { loadState = .available }
        } else {
            recordUnavailable()
            return
        }
        publish()
    }

    private func recordUnavailable() {
        loadState = .unavailable(hasUsableSnapshot: hasUsableSnapshot)
        publish()
    }

    private func publish() { observers.values.forEach { $0(workouts, loadState) } }

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
