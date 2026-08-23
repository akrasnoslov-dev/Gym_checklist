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

@MainActor
protocol WorkoutObservation: AnyObject {
    func cancel()
}

@MainActor
protocol WorkoutRepository: AnyObject {
    var userID: UserID { get }
    var workouts: [Workout] { get }
    /// Registers a main-actor consumer for locally available snapshots. The
    /// returned observation owns its cancellation lifecycle.
    func observeWorkouts(_ observer: @escaping @MainActor ([Workout]) -> Void) -> WorkoutObservation

    func workout(on date: LocalDate) -> Workout?
    @discardableResult func createEmptyWorkout(on date: LocalDate, at timestamp: Date) -> WorkoutCreationResult
    /// Replaces the locally observable workout snapshot.
    /// A throw can follow a durable local change, so callers must refresh from
    /// `workouts` before treating the attempted mutation as unchanged.
    func save(_ workout: Workout) throws
    func deleteWorkout(on date: LocalDate) throws
}

enum CustomExerciseRepositoryError: Error, Equatable {
    case ownerMismatch
    case systemExerciseCannotBePersisted
    case identityConflict
}

protocol CustomExerciseRepository: AnyObject {
    var userID: UserID { get }
    var customExercises: [Exercise] { get }

    func save(_ exercise: Exercise) throws
    func deleteCustomExercise(id: ExerciseID) throws
}

enum UserSettingsRepositoryError: Error, Equatable {
    case ownerMismatch
}

protocol UserSettingsRepository: AnyObject {
    var userID: UserID { get }
    var settings: UserSettings { get }

    func save(_ settings: UserSettings) throws
}
