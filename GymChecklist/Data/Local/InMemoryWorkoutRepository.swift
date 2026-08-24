import Foundation

@MainActor
final class InMemoryWorkoutRepository: WorkoutRepository {
    let userID: UserID
    private var observers: [UUID: @MainActor ([Workout]) -> Void] = [:]
    private var storage: [WorkoutDateKey: Workout] = [:]
    private let makeWorkoutID: () -> WorkoutID
#if DEBUG
    private var failNextSaveForTesting = false
    private var successfulSavesBeforeFailureForTesting: Int?
#endif

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

    func observeWorkouts(_ observer: @escaping @MainActor ([Workout]) -> Void) -> WorkoutObservation {
        let id = UUID()
        observers[id] = observer
        observer(workouts)
        return InMemoryWorkoutObservation { [weak self] in
            self?.observers.removeValue(forKey: id)
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
        publishSnapshot()
        return .created(workout)
    }

    func save(_ workout: Workout) throws {
#if DEBUG
        if failNextSaveForTesting {
            failNextSaveForTesting = false
            throw InMemoryWorkoutRepositoryError.simulatedSaveFailure
        }
        if let remainingSaves = successfulSavesBeforeFailureForTesting {
            guard remainingSaves > 0 else {
                successfulSavesBeforeFailureForTesting = nil
                throw InMemoryWorkoutRepositoryError.simulatedSaveFailure
            }
            successfulSavesBeforeFailureForTesting = remainingSaves - 1
        }
#endif
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
        publishSnapshot()
    }

#if DEBUG
    func armNextSaveFailureForTesting() {
        failNextSaveForTesting = true
    }

    func armSaveFailureForTesting(afterSuccessfulSaves count: Int) {
        precondition(count >= 0, "Save failure delay must not be negative")
        successfulSavesBeforeFailureForTesting = count
    }
#endif

    func deleteWorkout(on date: LocalDate) throws {
        let key = WorkoutDateKey(userID: userID, localDate: date)
        guard storage.removeValue(forKey: key) != nil else { throw InMemoryWorkoutRepositoryError.workoutNotFound(key) }
        publishSnapshot()
    }

    private func publishSnapshot() {
        let snapshot = workouts
        observers.values.forEach { $0(snapshot) }
    }
}

@MainActor
private final class InMemoryWorkoutObservation: WorkoutObservation {
    private var cancelHandler: (() -> Void)?

    init(cancelHandler: @escaping () -> Void) {
        self.cancelHandler = cancelHandler
    }

    func cancel() {
        cancelHandler?()
        cancelHandler = nil
    }

    deinit {
        MainActor.assumeIsolated {
            cancel()
        }
    }
}

enum InMemoryWorkoutRepositoryError: Error, Equatable {
    case workoutNotFound(WorkoutDateKey)
#if DEBUG
    case simulatedSaveFailure
#endif
}
