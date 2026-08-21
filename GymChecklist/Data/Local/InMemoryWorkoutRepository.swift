import Foundation

final class InMemoryWorkoutRepository: WorkoutRepository {
    let userID: UserID
    private var storage: [WorkoutDateKey: Workout] = [:]
    private let makeWorkoutID: () -> WorkoutID

    init(userID: UserID, makeWorkoutID: @escaping () -> WorkoutID = { WorkoutID() }) {
        precondition(!userID.rawValue.isEmpty, "Workout repository requires a user ID")
        self.userID = userID
        self.makeWorkoutID = makeWorkoutID
    }

    var workouts: [Workout] {
        storage.values.sorted {
            if $0.localDate != $1.localDate { return $0.localDate < $1.localDate }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }
    }

    func workout(on date: LocalDate) -> Workout? {
        storage[WorkoutDateKey(userID: userID, localDate: date)]
    }

    @discardableResult
    func createEmptyWorkout(on date: LocalDate, at timestamp: Date) -> WorkoutCreationResult {
        let key = WorkoutDateKey(userID: userID, localDate: date)
        if let existing = storage[key] { return .existing(existing) }

        let workout = Workout(
            id: makeWorkoutID(),
            userID: userID,
            localDate: date,
            exercises: [],
            createdAt: timestamp,
            updatedAt: timestamp
        )
        storage[key] = workout
        return .created(workout)
    }

    func save(_ workout: Workout) throws {
        guard workout.userID == userID else { throw WorkoutRepositoryError.ownerMismatch }

        let key = workout.dateKey
        if let occupied = storage[key], occupied.id != workout.id {
            throw WorkoutRepositoryError.duplicateDate(key)
        }
        if storage.contains(where: { storedKey, storedWorkout in
            storedWorkout.id == workout.id && storedKey != key
        }) {
            throw WorkoutRepositoryError.identityConflict
        }

        var persisted = workout
        if let existing = storage[key] { persisted.createdAt = existing.createdAt }
        storage[key] = persisted
    }

    func deleteWorkout(on date: LocalDate) throws {
        let key = WorkoutDateKey(userID: userID, localDate: date)
        guard storage.removeValue(forKey: key) != nil else { throw InMemoryWorkoutRepositoryError.workoutNotFound(key) }
    }
}

enum InMemoryWorkoutRepositoryError: Error, Equatable {
    case workoutNotFound(WorkoutDateKey)
}
