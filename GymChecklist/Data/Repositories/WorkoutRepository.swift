import Foundation

enum WorkoutRepositoryError: Error, Equatable {
    case ownerMismatch
    case duplicateDate(WorkoutDateKey)
    case identityConflict
}

enum WorkoutCreationResult {
    case created(Workout)
    case existing(Workout)

    var workout: Workout {
        switch self {
        case let .created(workout), let .existing(workout): workout
        }
    }

    var wasCreated: Bool {
        if case .created = self { return true }
        return false
    }
}

protocol WorkoutRepository: AnyObject {
    var userID: UserID { get }
    var workouts: [Workout] { get }

    func workout(on date: LocalDate) -> Workout?
    @discardableResult func createEmptyWorkout(on date: LocalDate, at timestamp: Date) -> WorkoutCreationResult
    func save(_ workout: Workout) throws
}
