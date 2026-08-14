import Combine
import Foundation

enum ProgramPlanningError: Error, Equatable {
    case workoutNotFound(LocalDate)
    case exerciseUnavailable(ExerciseID)
    case workoutExerciseNotFound(WorkoutExerciseID)
    case invalidExerciseOrder
}

@MainActor
final class ProgramViewModel: ObservableObject {
    @Published private(set) var selectedDate: LocalDate
    @Published private(set) var workouts: [Workout]
    @Published private(set) var exerciseLibrary: LocalExerciseLibrary

    let currentDate: LocalDate
    let calendar: Calendar
    private let repository: WorkoutRepository
    private let now: () -> Date
    private let makeWorkoutExerciseID: () -> WorkoutExerciseID

    init(
        repository: WorkoutRepository,
        initialDate: LocalDate,
        currentDate: LocalDate,
        calendar: Calendar = .autoupdatingCurrent,
        exerciseLibrary: LocalExerciseLibrary? = nil,
        now: @escaping () -> Date = Date.init,
        makeWorkoutExerciseID: @escaping () -> WorkoutExerciseID = { WorkoutExerciseID() }
    ) {
        let library = exerciseLibrary ?? LocalExerciseLibrary(userID: repository.userID)
        precondition(
            repository.workouts.allSatisfy { $0.userID == repository.userID },
            "Workout repository returned another user's data"
        )
        precondition(library.userID == repository.userID, "Exercise library owner must match workout owner")
        self.repository = repository
        self.selectedDate = initialDate
        self.currentDate = currentDate
        self.calendar = calendar
        self.exerciseLibrary = library
        self.now = now
        self.makeWorkoutExerciseID = makeWorkoutExerciseID
        self.workouts = repository.workouts
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

    func moveWeek(by offset: Int) {
        guard let date = selectedDate.adding(weeks: offset, calendar: calendar) else { return }
        selectedDate = date
    }

    func createSelectedWorkout() {
        _ = repository.createEmptyWorkout(on: selectedDate, at: now())
        workouts = repository.workouts
    }

    func searchExercises(_ query: String) -> [Exercise] {
        exerciseLibrary.search(query)
    }

    func createCustomExercise(name: String) throws -> Exercise {
        var library = exerciseLibrary
        let result = try library.createCustomExercise(name: name)
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
            return normalized
        }
    }
}
