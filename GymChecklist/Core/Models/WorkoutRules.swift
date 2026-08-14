import Foundation

extension Workout {
    var completionStatus: WorkoutStatus {
        let activeSets = exercises.filter { !$0.isSkipped }.flatMap(\.sets)
        let completedCount = activeSets.filter(\.isCompleted).count
        if !exercises.isEmpty && exercises.allSatisfy(\.isSkipped) { return .completed }
        if !activeSets.isEmpty && activeSets.allSatisfy(\.isCompleted) { return .completed }
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

enum WorkoutScheduleRules {
    static func validateUniqueDates(in workouts: [Workout]) throws {
        var dates = Set<WorkoutDateKey>()
        for workout in workouts where !dates.insert(workout.dateKey).inserted {
            throw WorkoutScheduleError.duplicateDate(workout.dateKey)
        }
    }
}
