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

enum WorkoutPersistenceFailure: Equatable {
    case saveRejected(Workout)
    case deleteRejected(Workout)
    case saveUnconfirmedAfterRestart(Workout)
    case deleteUnconfirmedAfterRestart(Workout)
}

enum UserSettingsPersistenceFailure: Equatable {
    case saveRejected(UserSettings)
    case saveUnconfirmedAfterRestart(UserSettings)
}

enum CustomExercisePersistenceFailure: Equatable {
    case saveRejected(Exercise)
    case deleteRejected(Exercise)
    case deleteRejectedWithoutLocalCopy(ExerciseID)
    case saveUnconfirmedAfterRestart(Exercise)
    case deleteUnconfirmedAfterRestart(Exercise)
}

enum BodyWeightPersistenceFailure: Equatable {
    case saveRejected(BodyWeightMeasurement)
    case deleteRejected(BodyWeightMeasurement)
    case saveUnconfirmedAfterRestart(BodyWeightMeasurement)
    case deleteUnconfirmedAfterRestart(BodyWeightMeasurement)
}

struct PersistenceIssue: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let retryTitle: String
    let secondaryTitle: String

    init(
        title: String,
        message: String,
        retryTitle: String,
        secondaryTitle: String = "Keep Current Version"
    ) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.secondaryTitle = secondaryTitle
    }
}

@MainActor
protocol PersistenceFailureObservation: AnyObject {
    func cancel()
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
    func observePersistenceFailures(
        _ observer: @escaping @MainActor (WorkoutPersistenceFailure) -> Void
    ) -> PersistenceFailureObservation

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
    func observePersistenceFailures(
        _ observer: @escaping @MainActor (CustomExercisePersistenceFailure) -> Void
    ) -> PersistenceFailureObservation
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
    func observePersistenceFailures(
        _ observer: @escaping @MainActor (UserSettingsPersistenceFailure) -> Void
    ) -> PersistenceFailureObservation
    func save(_ settings: UserSettings) throws
    func saveAppearance(_ appearance: Appearance) throws
    func saveWeightUnit(_ weightUnit: WeightUnit) throws
}

enum BodyWeightRepositoryError: Error, Equatable {
    case ownerMismatch
    case invalidMeasurement
    case measurementNotFound(BodyWeightMeasurementID)
}

@MainActor
protocol BodyWeightObservation: AnyObject {
    func cancel()
}

/// A small owner-bound history. Repositories publish local mutations before a
/// provider acknowledges them so Settings stays useful while offline.
@MainActor
protocol BodyWeightRepository: AnyObject {
    var userID: UserID { get }
    var measurements: [BodyWeightMeasurement] { get }
    func observeMeasurements(_ observer: @escaping @MainActor ([BodyWeightMeasurement]) -> Void) -> BodyWeightObservation
    func observePersistenceFailures(
        _ observer: @escaping @MainActor (BodyWeightPersistenceFailure) -> Void
    ) -> PersistenceFailureObservation
    func save(_ measurement: BodyWeightMeasurement) throws
    /// Deletes optimistically so an offline user can continue immediately.
    /// `onFailure` is invoked if the provider later rejects the pending delete.
    func deleteMeasurement(
        id: BodyWeightMeasurementID,
        onFailure: @escaping @MainActor () -> Void
    ) throws
}

extension WorkoutRepository {
    func observePersistenceFailures(
        _ observer: @escaping @MainActor (WorkoutPersistenceFailure) -> Void
    ) -> PersistenceFailureObservation {
        NoOpPersistenceFailureObservation()
    }
}

extension CustomExerciseRepository {
    func observePersistenceFailures(
        _ observer: @escaping @MainActor (CustomExercisePersistenceFailure) -> Void
    ) -> PersistenceFailureObservation {
        NoOpPersistenceFailureObservation()
    }
}

extension UserSettingsRepository {
    func observePersistenceFailures(
        _ observer: @escaping @MainActor (UserSettingsPersistenceFailure) -> Void
    ) -> PersistenceFailureObservation {
        NoOpPersistenceFailureObservation()
    }
}

extension BodyWeightRepository {
    func observePersistenceFailures(
        _ observer: @escaping @MainActor (BodyWeightPersistenceFailure) -> Void
    ) -> PersistenceFailureObservation {
        NoOpPersistenceFailureObservation()
    }
}

@MainActor
private final class NoOpPersistenceFailureObservation: PersistenceFailureObservation {
    func cancel() {}
}

@MainActor
final class ClosurePersistenceFailureObservation: PersistenceFailureObservation {
    private var handler: (() -> Void)?

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    func cancel() {
        handler?()
        handler = nil
    }

    deinit { MainActor.assumeIsolated { cancel() } }
}

@MainActor
final class PersistenceFailureBroadcaster<Failure> {
    private var observers: [UUID: @MainActor (Failure) -> Void] = [:]
    private var pending: [Failure] = []

    func observe(
        _ observer: @escaping @MainActor (Failure) -> Void
    ) -> PersistenceFailureObservation {
        let id = UUID()
        observers[id] = observer
        let replay = pending
        pending.removeAll()
        replay.forEach(observer)
        return ClosurePersistenceFailureObservation { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    func publish(_ failure: Failure) {
        guard !observers.isEmpty else {
            pending.append(failure)
            return
        }
        observers.values.forEach { $0(failure) }
    }
}
