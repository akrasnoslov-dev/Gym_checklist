import Foundation

extension Workout {
    var completionStatus: WorkoutStatus {
        let activeExercises = exercises.filter { !$0.isSkipped }
        let activeSets = activeExercises.flatMap(\.sets)
        let completedCount = activeSets.filter(\.isCompleted).count
        if !exercises.isEmpty && exercises.allSatisfy(\.isSkipped) { return .completed }
        if !activeExercises.isEmpty && activeExercises.allSatisfy({ !$0.sets.isEmpty && $0.sets.allSatisfy(\.isCompleted) }) { return .completed }
        if completedCount > 0 { return .partial }
        return .planned
    }

    func calendarStatus(asOf currentDate: LocalDate) -> WorkoutStatus {
        completionStatus == .planned && localDate < currentDate ? .incomplete : completionStatus
    }
}

enum WorkoutScheduleError: Error, Equatable {
    case duplicateDate(WorkoutDateKey)
}

struct WorkoutRepeatCadence: Equatable, Hashable, Sendable {
    let intervalWeeks: Int

    init(intervalWeeks: Int) {
        precondition(intervalWeeks > 0, "Repeat cadence must be positive")
        self.intervalWeeks = intervalWeeks
    }

    static let weekly = WorkoutRepeatCadence(intervalWeeks: 1)

    var title: String { intervalWeeks == 1 ? "Every week" : "Every \(intervalWeeks) weeks" }
}

enum WorkoutScheduleRules {
    static func validateUniqueDates(in workouts: [Workout]) throws {
        var dates = Set<WorkoutDateKey>()
        for workout in workouts where !dates.insert(workout.dateKey).inserted {
            throw WorkoutScheduleError.duplicateDate(workout.dateKey)
        }
    }
}
