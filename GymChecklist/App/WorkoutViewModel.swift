import Combine
import Foundation

enum ProgramPlanningError: Error, Equatable {
    case workoutNotFound(LocalDate)
    case copySourceHasNoSets(LocalDate)
    case copyDestinationMatchesSource(LocalDate)
    case copyDestinationOccupied(LocalDate)
    case repeatEndDateMustFollowSource(LocalDate)
    case exerciseUnavailable(ExerciseID)
    case workoutExerciseNotFound(WorkoutExerciseID)
    case workoutExerciseSkipped(WorkoutExerciseID)
    case todayActionRequiresCurrentDate(LocalDate)
    case historicalActualEditRequiresPastDate(LocalDate)
    case workoutSetNotFound(WorkoutSetID)
    case workoutSetNotCompleted(WorkoutSetID)
    case invalidExerciseOrder
    case invalidSetOrder
    case invalidSetValues
    case inconsistentSetType
}

enum WorkoutCopyStrategy: Equatable {
    case addExercises
    case replaceExercises
}

enum WorkoutCopyDestinationState: Equatable {
    case missing
    case empty
    case populated(exerciseCount: Int, setCount: Int)
}

struct WorkoutRepeatResult: Equatable {
    let createdDates: [LocalDate]
    let skippedOccupiedDates: [LocalDate]
}

@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published private(set) var selectedDate: LocalDate
    @Published private(set) var workouts: [Workout]
    @Published private(set) var workoutLoadState: WorkoutLoadState
    @Published private(set) var exerciseLibrary: LocalExerciseLibrary
    @Published private(set) var persistenceIssue: PersistenceIssue?

    @Published private(set) var currentDate: LocalDate
    let calendar: Calendar
    private let repository: WorkoutRepository
    private let customExerciseRepository: CustomExerciseRepository?
    private let analytics: AnalyticsTracking
    private let now: () -> Date
    private let currentDateProvider: () -> LocalDate
    private let makeWorkoutID: () -> WorkoutID
    private let makeWorkoutExerciseID: () -> WorkoutExerciseID
    private let makeWorkoutSetID: () -> WorkoutSetID
    private var workoutObservation: WorkoutObservation?
    private var customExerciseObservation: CustomExerciseObservation?
    private var workoutFailureObservation: PersistenceFailureObservation?
    private var customExerciseFailureObservation: PersistenceFailureObservation?
    private var retryPersistenceAction: (@MainActor () -> Void)?
    private var queuedPersistenceIssues: [(PersistenceIssue, @MainActor () -> Void)] = []

    init(
        repository: WorkoutRepository,
        initialDate: LocalDate,
        currentDate: LocalDate,
        calendar: Calendar = .autoupdatingCurrent,
        exerciseLibrary: LocalExerciseLibrary? = nil,
        customExerciseRepository: CustomExerciseRepository? = nil,
        analytics: AnalyticsTracking = NoOpAnalyticsTracker(),
        now: @escaping () -> Date = Date.init,
        currentDateProvider: (() -> LocalDate)? = nil,
        makeWorkoutID: @escaping () -> WorkoutID = { WorkoutID() },
        makeWorkoutExerciseID: @escaping () -> WorkoutExerciseID = { WorkoutExerciseID() },
        makeWorkoutSetID: @escaping () -> WorkoutSetID = { WorkoutSetID() }
    ) {
        var library = exerciseLibrary ?? LocalExerciseLibrary(userID: repository.userID)
        precondition(
            repository.workouts.allSatisfy { $0.userID == repository.userID },
            "Workout repository returned another user's data"
        )
        precondition(library.userID == repository.userID, "Exercise library owner must match workout owner")
        if let customExerciseRepository {
            precondition(customExerciseRepository.userID == repository.userID, "Custom exercise repository owner must match workout owner")
            library.replaceCustomExercises(customExerciseRepository.customExercises)
        }
        self.repository = repository
        self.customExerciseRepository = customExerciseRepository
        self.analytics = analytics
        self.selectedDate = initialDate
        self.currentDate = currentDate
        self.calendar = calendar
        self.exerciseLibrary = library
        self.now = now
        self.currentDateProvider = currentDateProvider ?? { currentDate }
        self.makeWorkoutID = makeWorkoutID
        self.makeWorkoutExerciseID = makeWorkoutExerciseID
        self.makeWorkoutSetID = makeWorkoutSetID
        self.workouts = repository.workouts
        self.workoutLoadState = .loading
        self.persistenceIssue = nil
        self.workoutObservation = repository.observeWorkouts { [weak self] workouts, loadState in
            self?.workouts = workouts
            self?.workoutLoadState = loadState
        }
        self.workoutFailureObservation = repository.observePersistenceFailures { [weak self] failure in
            self?.handleWorkoutPersistenceFailure(failure)
        }
        if let customExerciseRepository {
            self.customExerciseObservation = customExerciseRepository.observeCustomExercises { [weak self] exercises in
                guard let self else { return }
                var library = self.exerciseLibrary
                library.replaceCustomExercises(exercises)
                self.exerciseLibrary = library
            }
            self.customExerciseFailureObservation = customExerciseRepository.observePersistenceFailures { [weak self] failure in
                self?.handleCustomExercisePersistenceFailure(failure)
            }
        }
    }

    func retryPersistenceIssue() {
        let action = retryPersistenceAction
        advancePersistenceIssueQueue()
        action?()
    }

    func dismissPersistenceIssue() {
        advancePersistenceIssueQueue()
    }

    var calendarState: ProgramCalendarState {
        ProgramCalendarState(
            selectedDate: selectedDate,
            currentDate: currentDate,
            calendar: calendar,
            workouts: workouts
        )
    }

    func select(_ date: LocalDate) {
        selectedDate = date
    }

    func refreshCurrentDate() {
        let refreshedDate = currentDateProvider()
        guard refreshedDate != currentDate else { return }
        currentDate = refreshedDate
    }

    func moveWeek(by offset: Int) {
        guard let date = selectedDate.adding(weeks: offset, calendar: calendar) else { return }
        selectedDate = date
    }

    func createSelectedWorkout() {
        guard selectedDate >= currentDate else { return }
        let result = repository.createEmptyWorkout(on: selectedDate, at: now())
        workouts = repository.workouts
        if result.wasCreated {
            analytics.log(.workoutCreated)
        }
    }

    func deleteWorkout(on workoutDate: LocalDate) throws {
        guard repository.workout(on: workoutDate) != nil else {
            throw ProgramPlanningError.workoutNotFound(workoutDate)
        }
        try repository.deleteWorkout(on: workoutDate)
        workouts = repository.workouts
    }

    func hasWorkout(on date: LocalDate) -> Bool {
        repository.workout(on: date) != nil
    }

    func copyDestinationState(on date: LocalDate) -> WorkoutCopyDestinationState {
        guard let workout = repository.workout(on: date) else { return .missing }
        let setCount = workout.exercises.reduce(0) { $0 + $1.sets.count }
        guard !workout.exercises.isEmpty || setCount > 0 else { return .empty }
        return .populated(exerciseCount: workout.exercises.count, setCount: setCount)
    }

    var copySourceWorkouts: [Workout] {
        workouts.filter { workout in
            workout.exercises.contains { !$0.sets.isEmpty }
        }
    }

    func copyWorkout(
        from sourceDate: LocalDate,
        to destinationDate: LocalDate,
        strategy: WorkoutCopyStrategy? = nil
    ) throws {
        guard let source = repository.workout(on: sourceDate) else {
            throw ProgramPlanningError.workoutNotFound(sourceDate)
        }
        guard sourceDate != destinationDate else {
            throw ProgramPlanningError.copyDestinationMatchesSource(destinationDate)
        }
        guard source.exercises.contains(where: { !$0.sets.isEmpty }) else {
            throw ProgramPlanningError.copySourceHasNoSets(sourceDate)
        }

        let destinationState = copyDestinationState(on: destinationDate)
        if case .populated = destinationState, strategy == nil {
            throw ProgramPlanningError.copyDestinationOccupied(destinationDate)
        }

        try applyPlannedCopy(
            of: source,
            on: destinationDate,
            strategy: strategy ?? .replaceExercises
        )
        workouts = repository.workouts
        selectedDate = destinationDate
        analytics.log(.workoutCopied)
    }

    func repeatWorkout(
        from sourceDate: LocalDate,
        through endDate: LocalDate,
        cadence: WorkoutRepeatCadence = .weekly
    ) throws -> WorkoutRepeatResult {
        guard let source = repository.workout(on: sourceDate) else {
            throw ProgramPlanningError.workoutNotFound(sourceDate)
        }
        guard endDate > sourceDate else {
            throw ProgramPlanningError.repeatEndDateMustFollowSource(endDate)
        }

        let candidateDates = repeatDates(after: sourceDate, through: endDate, cadence: cadence)
        let skippedOccupiedDates = candidateDates.filter { repository.workout(on: $0) != nil }
        let destinations = candidateDates.filter { repository.workout(on: $0) == nil }
        var createdDates: [LocalDate] = []

        do {
            for destinationDate in destinations {
                try applyPlannedCopy(of: source, on: destinationDate, strategy: .replaceExercises)
                createdDates.append(destinationDate)
            }
        } catch {
            for destinationDate in createdDates {
                try? repository.deleteWorkout(on: destinationDate)
            }
            throw error
        }

        workouts = repository.workouts
        let result = WorkoutRepeatResult(
            createdDates: createdDates,
            skippedOccupiedDates: skippedOccupiedDates
        )
        if !result.createdDates.isEmpty {
            analytics.log(.workoutRepeatCreated)
        }
        return result
    }

    private func applyPlannedCopy(
        of source: Workout,
        on destinationDate: LocalDate,
        strategy: WorkoutCopyStrategy
    ) throws {
        let timestamp = now()
        var destination = repository.workout(on: destinationDate) ?? Workout(
            id: makeWorkoutID(),
            userID: repository.userID,
            localDate: destinationDate,
            exercises: [],
            createdAt: timestamp,
            updatedAt: timestamp
        )
        let copiedExercises = normalizedExercises(source.exercises).enumerated().map { exerciseIndex, sourceExercise in
            WorkoutExercise(
                id: makeWorkoutExerciseID(),
                exerciseID: sourceExercise.exerciseID,
                customName: sourceExercise.customName,
                order: exerciseIndex,
                isSkipped: false,
                sets: normalizedSets(sourceExercise.sets).enumerated().map { setIndex, sourceSet in
                    WorkoutSet(
                        id: makeWorkoutSetID(),
                        order: setIndex,
                        reps: sourceSet.reps,
                        weight: sourceSet.weight,
                        timeSeconds: sourceSet.timeSeconds,
                        type: sourceSet.type
                    )
                }
            )
        }

        switch strategy {
        case .addExercises:
            let existing = normalizedExercises(destination.exercises)
            destination.exercises = existing + copiedExercises.enumerated().map { offset, exercise in
                var appended = exercise
                appended.order = existing.count + offset
                return appended
            }
        case .replaceExercises:
            destination.exercises = copiedExercises
        }
        destination.updatedAt = timestamp
        do {
            try repository.save(destination)
        } catch {
            workouts = repository.workouts
            throw error
        }
    }

    func repeatDates(
        after sourceDate: LocalDate,
        through endDate: LocalDate,
        cadence: WorkoutRepeatCadence
    ) -> [LocalDate] {
        var dates: [LocalDate] = []
        var date = sourceDate
        while let nextDate = date.adding(weeks: cadence.intervalWeeks, calendar: calendar), nextDate <= endDate {
            dates.append(nextDate)
            date = nextDate
        }
        return dates
    }

    func searchExercises(_ query: String) -> [Exercise] {
        exerciseLibrary.search(query)
    }

    func createCustomExercise(name: String) throws -> Exercise {
        var library = exerciseLibrary
        let result = try library.createCustomExercise(name: name)
        if result.wasCreated {
            try customExerciseRepository?.save(result.exercise)
        }
        exerciseLibrary = library
        if result.wasCreated {
            analytics.log(.customExerciseCreated)
        }
        return result.exercise
    }

    func renameCustomExercise(_ id: ExerciseID, to name: String) throws {
        var library = exerciseLibrary
        let updated = try library.renameCustomExercise(id: id, to: name)
        try customExerciseRepository?.save(updated)
        exerciseLibrary = library
    }

    func deleteCustomExercise(_ id: ExerciseID) throws {
        var library = exerciseLibrary
        try library.removeCustomExercise(id: id)
        try customExerciseRepository?.deleteCustomExercise(id: id)
        // Existing workouts retain customName as a historical fallback.
        exerciseLibrary = library
    }

    func addExercise(_ exercise: Exercise, to workoutDate: LocalDate) throws {
        guard var workout = repository.workout(on: workoutDate) else {
            throw ProgramPlanningError.workoutNotFound(workoutDate)
        }
        guard let availableExercise = exerciseLibrary.allExercises.first(where: { $0.id == exercise.id }) else {
            throw ProgramPlanningError.exerciseUnavailable(exercise.id)
        }

        workout.exercises = normalizedExercises(workout.exercises)
        workout.exercises.append(WorkoutExercise(
            id: makeWorkoutExerciseID(),
            exerciseID: availableExercise.id,
            customName: availableExercise.isSystem ? nil : availableExercise.name,
            order: workout.exercises.count,
            isSkipped: false,
            sets: []
        ))
        workout.updatedAt = now()
        try repository.save(workout)
        workouts = repository.workouts
        analytics.log(.exerciseAdded)
    }

    func orderedExercises(on workoutDate: LocalDate) -> [WorkoutExercise] {
        repository.workout(on: workoutDate).map { normalizedExercises($0.exercises) } ?? []
    }

    func workout(on workoutDate: LocalDate) -> Workout? {
        workouts.first { $0.localDate == workoutDate }
    }

    // MARK: Today execution

    func toggleCompletion(
        of setID: WorkoutSetID,
        in exerciseID: WorkoutExerciseID,
        on workoutDate: LocalDate
    ) throws {
        try requireCurrentTodayDate(workoutDate)
        guard var workout = repository.workout(on: workoutDate) else {
            throw ProgramPlanningError.workoutNotFound(workoutDate)
        }
        guard let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseID }) else {
            throw ProgramPlanningError.workoutExerciseNotFound(exerciseID)
        }
        guard !workout.exercises[exerciseIndex].isSkipped else {
            throw ProgramPlanningError.workoutExerciseSkipped(exerciseID)
        }
        guard let setIndex = workout.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) else {
            throw ProgramPlanningError.workoutSetNotFound(setID)
        }

        let statusBeforeMutation = workout.completionStatus
        let timestamp = now()
        workout.exercises[exerciseIndex].sets[setIndex].toggleCompletion(at: timestamp)
        let isCompleted = workout.exercises[exerciseIndex].sets[setIndex].isCompleted
        workout.updatedAt = timestamp
        try saveTodayWorkout(workout)
        analytics.log(isCompleted ? .setCompleted : .setUncompleted)
        if statusBeforeMutation != .completed, workout.completionStatus == .completed {
            analytics.log(.workoutCompleted)
        }
    }

    func editTodaySet(
        _ setID: WorkoutSetID,
        in exerciseID: WorkoutExerciseID,
        on workoutDate: LocalDate,
        reps: Int,
        weight: Double,
        timeSeconds: Int,
        type: WorkoutSetType? = nil
    ) throws {
        try requireCurrentTodayDate(workoutDate)
        guard Self.areValidSetValues(reps: reps, weight: weight, timeSeconds: timeSeconds) else {
            throw ProgramPlanningError.invalidSetValues
        }
        var actualValuesChanged = false
        try mutateExercise(exerciseID, on: workoutDate) { exercise in
            guard !exercise.isSkipped else { throw ProgramPlanningError.workoutExerciseSkipped(exerciseID) }
            guard let setIndex = exercise.sets.firstIndex(where: { $0.id == setID }) else {
                throw ProgramPlanningError.workoutSetNotFound(setID)
            }
            if exercise.sets[setIndex].isCompleted {
                let current = exercise.sets[setIndex]
                actualValuesChanged = current.actualReps != reps
                    || current.actualWeight != weight
                    || current.actualTimeSeconds != timeSeconds
                if actualValuesChanged {
                    exercise.sets[setIndex].editActual(reps: reps, weight: weight, timeSeconds: timeSeconds)
                }
            } else {
                let retainedType = type ?? exercise.sets[setIndex].type
                exercise.sets[setIndex].editPlan(reps: reps, weight: weight, timeSeconds: timeSeconds, type: retainedType)
            }
        }
        if actualValuesChanged {
            analytics.log(.setActualEdited)
        }
    }

    func editHistoricalActual(
        _ setID: WorkoutSetID,
        in exerciseID: WorkoutExerciseID,
        on workoutDate: LocalDate,
        reps: Int,
        weight: Double,
        timeSeconds: Int
    ) throws {
        guard workoutDate < currentDate else {
            throw ProgramPlanningError.historicalActualEditRequiresPastDate(workoutDate)
        }
        guard Self.areValidSetValues(reps: reps, weight: weight, timeSeconds: timeSeconds) else {
            throw ProgramPlanningError.invalidSetValues
        }
        var actualValuesChanged = false
        try mutateExercise(exerciseID, on: workoutDate) { exercise in
            guard let setIndex = exercise.sets.firstIndex(where: { $0.id == setID }) else {
                throw ProgramPlanningError.workoutSetNotFound(setID)
            }
            guard exercise.sets[setIndex].isCompleted else {
                throw ProgramPlanningError.workoutSetNotCompleted(setID)
            }
            let current = exercise.sets[setIndex]
            actualValuesChanged = current.actualReps != reps
                || current.actualWeight != weight
                || current.actualTimeSeconds != timeSeconds
            if actualValuesChanged {
                exercise.sets[setIndex].editActual(reps: reps, weight: weight, timeSeconds: timeSeconds)
            }
        }
        if actualValuesChanged {
            analytics.log(.setActualEdited)
        }
    }

    func skipTodayExercise(_ exerciseID: WorkoutExerciseID, on workoutDate: LocalDate) throws {
        try requireCurrentTodayDate(workoutDate)
        guard var workout = repository.workout(on: workoutDate) else {
            throw ProgramPlanningError.workoutNotFound(workoutDate)
        }
        guard let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseID }) else {
            throw ProgramPlanningError.workoutExerciseNotFound(exerciseID)
        }
        guard !workout.exercises[exerciseIndex].isSkipped else { return }

        let statusBeforeMutation = workout.completionStatus
        workout.exercises[exerciseIndex].isSkipped = true
        workout.updatedAt = now()
        try saveTodayWorkout(workout)
        analytics.log(.exerciseSkipped)
        if statusBeforeMutation != .completed, workout.completionStatus == .completed {
            analytics.log(.workoutCompleted)
        }
    }

    func restoreTodayExercise(_ exerciseID: WorkoutExerciseID, on workoutDate: LocalDate) throws {
        try requireCurrentTodayDate(workoutDate)
        guard var workout = repository.workout(on: workoutDate) else {
            throw ProgramPlanningError.workoutNotFound(workoutDate)
        }
        guard let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseID }) else {
            throw ProgramPlanningError.workoutExerciseNotFound(exerciseID)
        }
        guard workout.exercises[exerciseIndex].isSkipped else { return }

        workout.exercises[exerciseIndex].isSkipped = false
        workout.updatedAt = now()
        try saveTodayWorkout(workout)
    }

    func orderedSets(for exerciseID: WorkoutExerciseID, on workoutDate: LocalDate) -> [WorkoutSet] {
        orderedExercises(on: workoutDate)
            .first(where: { $0.id == exerciseID })
            .map { normalizedSets($0.sets) } ?? []
    }

    func deleteExercise(_ id: WorkoutExerciseID, from workoutDate: LocalDate) throws {
        guard var workout = repository.workout(on: workoutDate) else {
            throw ProgramPlanningError.workoutNotFound(workoutDate)
        }
        guard workout.exercises.contains(where: { $0.id == id }) else {
            throw ProgramPlanningError.workoutExerciseNotFound(id)
        }

        workout.exercises.removeAll { $0.id == id }
        workout.exercises = normalizedExercises(workout.exercises)
        workout.updatedAt = now()
        try repository.save(workout)
        workouts = repository.workouts
    }

    func reorderExercises(_ orderedIDs: [WorkoutExerciseID], on workoutDate: LocalDate) throws {
        guard var workout = repository.workout(on: workoutDate) else {
            throw ProgramPlanningError.workoutNotFound(workoutDate)
        }
        let current = normalizedExercises(workout.exercises)
        guard
            orderedIDs.count == current.count,
            Set(orderedIDs).count == orderedIDs.count,
            Set(orderedIDs) == Set(current.map(\.id))
        else { throw ProgramPlanningError.invalidExerciseOrder }
        guard orderedIDs != current.map(\.id) else { return }

        let exercisesByID = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        workout.exercises = orderedIDs.enumerated().compactMap { index, id in
            exercisesByID[id].map { exercise in
                var reordered = exercise
                reordered.order = index
                return reordered
            }
        }
        workout.updatedAt = now()
        try repository.save(workout)
        workouts = repository.workouts
    }

    func addSet(to exerciseID: WorkoutExerciseID, on workoutDate: LocalDate) throws {
        try mutateExercise(exerciseID, on: workoutDate) { exercise in
            let sets = normalizedSets(exercise.sets)
            let copiedValues = sets.last.map { (reps: $0.reps, weight: $0.weight, timeSeconds: $0.timeSeconds, type: $0.type) }
            guard copiedValues.map({ Self.areValidSetValues(reps: $0.reps, weight: $0.weight, timeSeconds: $0.timeSeconds) }) ?? true else {
                throw ProgramPlanningError.invalidSetValues
            }
            exercise.sets = sets + [WorkoutSet(
                id: makeWorkoutSetID(),
                order: sets.count,
                reps: copiedValues?.reps ?? 0,
                weight: copiedValues?.weight ?? 0,
                timeSeconds: copiedValues?.timeSeconds ?? 0,
                type: copiedValues?.type
            )]
        }
    }

    func editSet(
        _ setID: WorkoutSetID,
        in exerciseID: WorkoutExerciseID,
        on workoutDate: LocalDate,
        reps: Int,
        weight: Double,
        timeSeconds: Int,
        type: WorkoutSetType? = nil
    ) throws {
        guard Self.areValidSetValues(reps: reps, weight: weight, timeSeconds: timeSeconds) else {
            throw ProgramPlanningError.invalidSetValues
        }
        try mutateExercise(exerciseID, on: workoutDate) { exercise in
            guard let setIndex = exercise.sets.firstIndex(where: { $0.id == setID }) else {
                throw ProgramPlanningError.workoutSetNotFound(setID)
            }
            let chosenType = type ?? exercise.sets[setIndex].type
            let configuredOther = exercise.sets.first {
                $0.id != setID && ($0.reps > 0 || $0.weight > 0 || $0.timeSeconds > 0)
            }
            // Preserve pre-existing mixed/legacy data. Do not allow a newly
            // configured set to introduce another type into this exercise.
            if let configuredOther, configuredOther.type != chosenType {
                let current = exercise.sets[setIndex]
                let preservesExistingLegacyValues =
                    (current.reps > 0 || current.weight > 0 || current.timeSeconds > 0)
                    && current.type == chosenType
                guard preservesExistingLegacyValues else {
                    throw ProgramPlanningError.inconsistentSetType
                }
            }
            exercise.sets[setIndex].editPlan(reps: reps, weight: weight, timeSeconds: timeSeconds, type: chosenType)
            if reps > 0 || weight > 0 || timeSeconds > 0 {
                for index in exercise.sets.indices where index != setIndex {
                    let sibling = exercise.sets[index]
                    if !sibling.isCompleted && sibling.reps == 0 && sibling.weight == 0 && sibling.timeSeconds == 0 {
                        exercise.sets[index].editPlan(reps: 0, weight: 0, timeSeconds: 0, type: chosenType)
                    }
                }
            }
        }
    }

    func setExerciseType(
        _ type: WorkoutSetType,
        for exerciseID: WorkoutExerciseID,
        on workoutDate: LocalDate
    ) throws {
        guard WorkoutSetType.editableCases.contains(type) else {
            throw ProgramPlanningError.invalidSetValues
        }
        try mutateExercise(exerciseID, on: workoutDate) { exercise in
            for index in exercise.sets.indices {
                let set = exercise.sets[index]
                exercise.sets[index].editPlan(
                    reps: set.reps,
                    weight: set.weight,
                    timeSeconds: set.timeSeconds,
                    type: type
                )
            }
        }
    }

    func deleteSet(_ setID: WorkoutSetID, from exerciseID: WorkoutExerciseID, on workoutDate: LocalDate) throws {
        try mutateExercise(exerciseID, on: workoutDate) { exercise in
            guard exercise.sets.contains(where: { $0.id == setID }) else {
                throw ProgramPlanningError.workoutSetNotFound(setID)
            }
            exercise.sets.removeAll { $0.id == setID }
        }
    }

    func reorderSets(
        _ orderedIDs: [WorkoutSetID],
        in exerciseID: WorkoutExerciseID,
        on workoutDate: LocalDate
    ) throws {
        try mutateExercise(exerciseID, on: workoutDate) { exercise in
            let current = normalizedSets(exercise.sets)
            guard
                orderedIDs.count == current.count,
                Set(orderedIDs).count == orderedIDs.count,
                Set(orderedIDs) == Set(current.map(\.id))
            else { throw ProgramPlanningError.invalidSetOrder }
            guard orderedIDs != current.map(\.id) else { return }

            let setsByID = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
            exercise.sets = orderedIDs.enumerated().compactMap { index, id in
                setsByID[id].map { set in
                    var reordered = set
                    reordered.order = index
                    return reordered
                }
            }
        }
    }

    func exerciseName(for workoutExercise: WorkoutExercise) -> String {
        exerciseLibrary.allExercises.first { $0.id == workoutExercise.exerciseID }?.name
            ?? workoutExercise.customName
            ?? "Exercise"
    }

    private func normalizedExercises(_ exercises: [WorkoutExercise]) -> [WorkoutExercise] {
        exercises.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }.enumerated().map { index, exercise in
            var normalized = exercise
            normalized.order = index
            normalized.sets = normalizedSets(exercise.sets)
            return normalized
        }
    }

    private func normalizedSets(_ sets: [WorkoutSet]) -> [WorkoutSet] {
        sets.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }.enumerated().map { index, set in
            var normalized = set
            normalized.order = index
            return normalized
        }
    }

    private func mutateExercise(
        _ exerciseID: WorkoutExerciseID,
        on workoutDate: LocalDate,
        mutation: (inout WorkoutExercise) throws -> Void
    ) throws {
        guard var workout = repository.workout(on: workoutDate) else {
            throw ProgramPlanningError.workoutNotFound(workoutDate)
        }
        workout.exercises = normalizedExercises(workout.exercises)
        guard let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseID }) else {
            throw ProgramPlanningError.workoutExerciseNotFound(exerciseID)
        }

        try mutation(&workout.exercises[exerciseIndex])
        workout.exercises[exerciseIndex].sets = normalizedSets(workout.exercises[exerciseIndex].sets)
        workout.updatedAt = now()
        do {
            try repository.save(workout)
        } catch {
            workouts = repository.workouts
            throw error
        }
        workouts = repository.workouts
    }

    private func requireCurrentTodayDate(_ workoutDate: LocalDate) throws {
        guard workoutDate == currentDate else {
            throw ProgramPlanningError.todayActionRequiresCurrentDate(workoutDate)
        }
    }

    private func saveTodayWorkout(_ workout: Workout) throws {
        do {
            try repository.save(workout)
        } catch {
            workouts = repository.workouts
            throw error
        }
        workouts = repository.workouts
    }

    private static func areValidSetValues(reps: Int, weight: Double, timeSeconds: Int) -> Bool {
        reps >= 0 && timeSeconds >= 0 && weight.isFinite && weight >= 0
    }

    private func handleWorkoutPersistenceFailure(_ failure: WorkoutPersistenceFailure) {
        switch failure {
        case let .saveRejected(workout):
            presentPersistenceIssue(
                title: "Workout change wasn’t saved",
                message: "The last confirmed workout is shown. Retry to save your change.",
                retryTitle: "Retry Save"
            ) { [weak self] in
                guard let self else { return }
                do { try self.repository.save(workout) }
                catch { self.handleWorkoutPersistenceFailure(.saveRejected(workout)) }
            }
        case let .deleteRejected(workout):
            presentPersistenceIssue(
                title: "Workout wasn’t deleted",
                message: "The workout was restored. Retry to delete it.",
                retryTitle: "Retry Delete"
            ) { [weak self] in
                guard let self else { return }
                do { try self.repository.deleteWorkout(on: workout.localDate) }
                catch { self.handleWorkoutPersistenceFailure(.deleteRejected(workout)) }
            }
        case let .saveUnconfirmedAfterRestart(workout):
            presentPersistenceIssue(
                title: "Offline change needs review",
                message: "The current cloud workout is shown. Save your offline change again only if you want to replace it.",
                retryTitle: "Save Offline Change",
                secondaryTitle: "Remind Me Later"
            ) { [weak self] in
                guard let self else { return }
                do { try self.repository.save(workout) }
                catch { self.handleWorkoutPersistenceFailure(.saveRejected(workout)) }
            }
        case let .deleteUnconfirmedAfterRestart(workout):
            presentPersistenceIssue(
                title: "Workout deletion needs review",
                message: "The workout is present in the cloud. Delete it again only if you still want it removed.",
                retryTitle: "Delete Again",
                secondaryTitle: "Remind Me Later"
            ) { [weak self] in
                guard let self else { return }
                do { try self.repository.deleteWorkout(on: workout.localDate) }
                catch { self.handleWorkoutPersistenceFailure(.deleteRejected(workout)) }
            }
        }
    }

    private func handleCustomExercisePersistenceFailure(_ failure: CustomExercisePersistenceFailure) {
        guard let customExerciseRepository else { return }
        switch failure {
        case let .saveRejected(exercise):
            presentPersistenceIssue(
                title: "Exercise wasn’t saved",
                message: "Your exercise change is ready to retry.",
                retryTitle: "Retry Save"
            ) { [weak self] in
                do { try customExerciseRepository.save(exercise) }
                catch { self?.handleCustomExercisePersistenceFailure(.saveRejected(exercise)) }
            }
        case let .deleteRejected(exercise):
            presentPersistenceIssue(
                title: "Exercise wasn’t deleted",
                message: "The exercise was restored. Retry to delete it.",
                retryTitle: "Retry Delete"
            ) { [weak self] in
                do { try customExerciseRepository.deleteCustomExercise(id: exercise.id) }
                catch { self?.handleCustomExercisePersistenceFailure(.deleteRejected(exercise)) }
            }
        case let .deleteRejectedWithoutLocalCopy(id):
            presentPersistenceIssue(
                title: "Exercise wasn’t deleted",
                message: "The delete wasn’t accepted. Retry to remove the exercise.",
                retryTitle: "Retry Delete"
            ) { [weak self] in
                do { try customExerciseRepository.deleteCustomExercise(id: id) }
                catch { self?.handleCustomExercisePersistenceFailure(.deleteRejectedWithoutLocalCopy(id)) }
            }
        case let .saveUnconfirmedAfterRestart(exercise):
            presentPersistenceIssue(
                title: "Offline exercise change needs review",
                message: "The current cloud exercise is shown. Save your offline change again only if you want to replace it.",
                retryTitle: "Save Offline Change",
                secondaryTitle: "Remind Me Later"
            ) { [weak self] in
                do { try customExerciseRepository.save(exercise) }
                catch { self?.handleCustomExercisePersistenceFailure(.saveRejected(exercise)) }
            }
        case let .deleteUnconfirmedAfterRestart(exercise):
            presentPersistenceIssue(
                title: "Exercise deletion needs review",
                message: "The exercise is present in the cloud. Delete it again only if you still want it removed.",
                retryTitle: "Delete Again",
                secondaryTitle: "Remind Me Later"
            ) { [weak self] in
                do { try customExerciseRepository.deleteCustomExercise(id: exercise.id) }
                catch { self?.handleCustomExercisePersistenceFailure(.deleteRejected(exercise)) }
            }
        }
    }

    private func presentPersistenceIssue(
        title: String,
        message: String,
        retryTitle: String,
        secondaryTitle: String = "Keep Current Version",
        retry: @escaping @MainActor () -> Void
    ) {
        let issue = PersistenceIssue(
            title: title,
            message: message,
            retryTitle: retryTitle,
            secondaryTitle: secondaryTitle
        )
        guard persistenceIssue == nil else {
            queuedPersistenceIssues.append((issue, retry))
            return
        }
        retryPersistenceAction = retry
        persistenceIssue = issue
    }

    private func advancePersistenceIssueQueue() {
        guard !queuedPersistenceIssues.isEmpty else {
            persistenceIssue = nil
            retryPersistenceAction = nil
            return
        }
        let next = queuedPersistenceIssues.removeFirst()
        persistenceIssue = next.0
        retryPersistenceAction = next.1
    }

    deinit {
        MainActor.assumeIsolated {
            workoutObservation?.cancel()
            customExerciseObservation?.cancel()
            workoutFailureObservation?.cancel()
            customExerciseFailureObservation?.cancel()
        }
    }
}
