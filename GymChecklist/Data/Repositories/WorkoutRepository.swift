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

/// A provider-neutral indication of whether the workout snapshot can be used.
/// It deliberately carries no provider error details so UI can give concise,
/// safe feedback while Firestore reconnects in the background.
enum WorkoutLoadState: Equatable {
    case loading
    case available
    case unavailable(hasUsableSnapshot: Bool)
}

@MainActor
protocol WorkoutObservation: AnyObject {
    func cancel()
}

@MainActor
protocol WorkoutRepository: AnyObject {
    var userID: UserID { get }
    var workouts: [Workout] { get }
    /// Registers a main-actor consumer for locally available snapshots and
    /// their availability state. The returned observation owns cancellation.
    func observeWorkouts(_ observer: @escaping @MainActor ([Workout], WorkoutLoadState) -> Void) -> WorkoutObservation

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

@MainActor
protocol CustomExerciseObservation: AnyObject {
    func cancel()
}

@MainActor
protocol CustomExerciseRepository: AnyObject {
    var userID: UserID { get }
    var customExercises: [Exercise] { get }

    /// Registers a main-actor consumer for cached and subsequently synced
    /// custom exercises. The returned observation owns its cancellation.
    func observeCustomExercises(_ observer: @escaping @MainActor ([Exercise]) -> Void) -> CustomExerciseObservation
    func save(_ exercise: Exercise) throws
    func deleteCustomExercise(id: ExerciseID) throws
}

enum UserSettingsRepositoryError: Error, Equatable {
    case ownerMismatch
}

@MainActor
protocol UserSettingsObservation: AnyObject {
    func cancel()
}

@MainActor
protocol UserSettingsRepository: AnyObject {
    var userID: UserID { get }
    var settings: UserSettings { get }

    /// Registers a main-actor consumer for cached and subsequently synced
    /// settings. The returned observation owns its cancellation lifecycle.
    func observeSettings(_ observer: @escaping @MainActor (UserSettings) -> Void) -> UserSettingsObservation
    func save(_ settings: UserSettings) throws
    func saveAppearance(_ appearance: Appearance) throws
    func saveWeightUnit(_ weightUnit: WeightUnit) throws
}
