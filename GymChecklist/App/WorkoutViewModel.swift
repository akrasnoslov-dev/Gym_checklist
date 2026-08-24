import Combine
import Foundation

enum ProgramPlanningError: Error, Equatable {
    case workoutNotFound(LocalDate)
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
}

struct WorkoutRepeatResult: Equatable {
    let createdDates: [LocalDate]
    let skippedOccupiedDates: [LocalDate]
}

@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published private(set) var selectedDate: LocalDate
    @Published private(set) var workouts: [Workout]
    @Published private(set) var exerciseLibrary: LocalExerciseLibrary

    @Published private(set) var currentDate: LocalDate
    let calendar: Calendar
    private let repository: WorkoutRepository
    private let customExerciseRepository: CustomExerciseRepository?
    private let now: () -> Date
    private let currentDateProvider: () -> LocalDate
    private let makeWorkoutExerciseID: () -> WorkoutExerciseID
    private let makeWorkoutSetID: () -> WorkoutSetID
    private var workoutObservation: WorkoutObservation?
    private var customExerciseObservation: CustomExerciseObservation?

    init(
        repository: WorkoutRepository,
        initialDate: LocalDate,
        currentDate: LocalDate,
        calendar: Calendar = .autoupdatingCurrent,
        exerciseLibrary: LocalExerciseLibrary? = nil,
        customExerciseRepository: CustomExerciseRepository? = nil,
        now: @escaping () -> Date = Date.init,
        currentDateProvider: (() -> LocalDate)? = nil,
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
        self.selectedDate = initialDate
        self.currentDate = currentDate
        self.calendar = calendar
        self.exerciseLibrary = library
        self.now = now
        self.currentDateProvider = currentDateProvider ?? { currentDate }
        self.makeWorkoutExerciseID = makeWorkoutExerciseID
        self.makeWorkoutSetID = makeWorkoutSetID
        self.workouts = repository.workouts
        self.workoutObservation = repository.observeWorkouts { [weak self] workouts in
            self?.workouts = workouts
        }
        if let customExerciseRepository {
            self.customExerciseObservation = customExerciseRepository.observeCustomExercises { [weak self] exercises in
                guard let self else { return }
                var library = self.exerciseLibrary
                library.replaceCustomExercises(exercises)
                self.exerciseLibrary = library
            }
        }
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
        _ = repository.createEmptyWorkout(on: selectedDate, at: now())
        workouts = repository.workouts
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

    func copyWorkout(from sourceDate: LocalDate, to destinationDate: LocalDate) throws {
        guard let source = repository.workout(on: sourceDate) else {
            throw ProgramPlanningError.workoutNotFound(sourceDate)
        }
        guard sourceDate != destinationDate else {
            throw ProgramPlanningError.copyDestinationMatchesSource(destinationDate)
        }
        guard repository.workout(on: destinationDate) == nil else {
            throw ProgramPlanningError.copyDestinationOccupied(destinationDate)
        }

        try createPlannedCopy(of: source, on: destinationDate)
        workouts = repository.workouts
        selectedDate = destinationDate
    }

    func repeatWorkout(from sourceDate: LocalDate, through endDate: LocalDate) throws -> WorkoutRepeatResult {
        guard let source = repository.workout(on: sourceDate) else {
            throw ProgramPlanningError.workoutNotFound(sourceDate)
        }
        guard endDate > sourceDate else {
            throw ProgramPlanningError.repeatEndDateMustFollowSource(endDate)
        }

        let candidateDates = weeklyDates(after: sourceDate, through: endDate)
        let skippedOccupiedDates = candidateDates.filter { repository.workout(on: $0) != nil }
        let destinations = candidateDates.filter { repository.workout(on: $0) == nil }
        var createdDates: [LocalDate] = []

        do {
            for destinationDate in destinations {
                try createPlannedCopy(of: source, on: destinationDate)
                createdDates.append(destinationDate)
            }
        } catch {
            for destinationDate in createdDates {
                try? repository.deleteWorkout(on: destinationDate)
            }
            throw error
        }

        workouts = repository.workouts
        return WorkoutRepeatResult(
            createdDates: createdDates,
            skippedOccupiedDates: skippedOccupiedDates
        )
    }

    private func createPlannedCopy(of source: Workout, on destinationDate: LocalDate) throws {
        guard repository.workout(on: destinationDate) == nil else {
            throw ProgramPlanningError.copyDestinationOccupied(destinationDate)
        }

        let timestamp = now()
        let result = repository.createEmptyWorkout(on: destinationDate, at: timestamp)
        guard result.wasCreated else {
            throw ProgramPlanningError.copyDestinationOccupied(destinationDate)
        }

        var copied = result.workout
        copied.exercises = normalizedExercises(source.exercises).enumerated().map { exerciseIndex, sourceExercise in
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
                        timeSeconds: sourceSet.timeSeconds
                    )
                }
            )
        }
        copied.updatedAt = timestamp
        do {
            try repository.save(copied)
        } catch {
            try? repository.deleteWorkout(on: destinationDate)
            throw error
        }
    }

    private func weeklyDates(after sourceDate: LocalDate, through endDate: LocalDate) -> [LocalDate] {
        var dates: [LocalDate] = []
        var date = sourceDate
        while let nextDate = date.adding(weeks: 1, calendar: calendar), nextDate <= endDate {
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
        return result.exercise
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

        let timestamp = now()
        workout.exercises[exerciseIndex].sets[setIndex].toggleCompletion(at: timestamp)
        workout.updatedAt = timestamp
        try saveTodayWorkout(workout)
    }

    func editTodaySet(
        _ setID: WorkoutSetID,
        in exerciseID: WorkoutExerciseID,
        on workoutDate: LocalDate,
        reps: Int,
        weight: Double,
        timeSeconds: Int
    ) throws {
        try requireCurrentTodayDate(workoutDate)
        guard Self.areValidSetValues(reps: reps, weight: weight, timeSeconds: timeSeconds) else {
            throw ProgramPlanningError.invalidSetValues
        }
        try mutateExercise(exerciseID, on: workoutDate) { exercise in
            guard !exercise.isSkipped else { throw ProgramPlanningError.workoutExerciseSkipped(exerciseID) }
            guard let setIndex = exercise.sets.firstIndex(where: { $0.id == setID }) else {
                throw ProgramPlanningError.workoutSetNotFound(setID)
            }
            if exercise.sets[setIndex].isCompleted {
                exercise.sets[setIndex].editActual(reps: reps, weight: weight, timeSeconds: timeSeconds)
            } else {
                exercise.sets[setIndex].editPlan(reps: reps, weight: weight, timeSeconds: timeSeconds)
            }
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
        try mutateExercise(exerciseID, on: workoutDate) { exercise in
            guard let setIndex = exercise.sets.firstIndex(where: { $0.id == setID }) else {
                throw ProgramPlanningError.workoutSetNotFound(setID)
            }
            guard exercise.sets[setIndex].isCompleted else {
                throw ProgramPlanningError.workoutSetNotCompleted(setID)
            }
            exercise.sets[setIndex].editActual(reps: reps, weight: weight, timeSeconds: timeSeconds)
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

        workout.exercises[exerciseIndex].isSkipped = true
        workout.updatedAt = now()
        try saveTodayWorkout(workout)
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
            let copiedValues = sets.last.map { (reps: $0.reps, weight: $0.weight, timeSeconds: $0.timeSeconds) }
            guard copiedValues.map({ Self.areValidSetValues(reps: $0.reps, weight: $0.weight, timeSeconds: $0.timeSeconds) }) ?? true else {
                throw ProgramPlanningError.invalidSetValues
            }
            exercise.sets = sets + [WorkoutSet(
                id: makeWorkoutSetID(),
                order: sets.count,
                reps: copiedValues?.reps ?? 0,
                weight: copiedValues?.weight ?? 0,
                timeSeconds: copiedValues?.timeSeconds ?? 0
            )]
        }
    }

    func editSet(
        _ setID: WorkoutSetID,
        in exerciseID: WorkoutExerciseID,
        on workoutDate: LocalDate,
        reps: Int,
        weight: Double,
        timeSeconds: Int
    ) throws {
        guard Self.areValidSetValues(reps: reps, weight: weight, timeSeconds: timeSeconds) else {
            throw ProgramPlanningError.invalidSetValues
        }
        try mutateExercise(exerciseID, on: workoutDate) { exercise in
            guard let setIndex = exercise.sets.firstIndex(where: { $0.id == setID }) else {
                throw ProgramPlanningError.workoutSetNotFound(setID)
            }
            exercise.sets[setIndex].editPlan(reps: reps, weight: weight, timeSeconds: timeSeconds)
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
}
