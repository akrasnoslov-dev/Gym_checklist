import Combine
import Foundation

@MainActor
final class ProgramViewModel: ObservableObject {
    @Published private(set) var selectedDate: LocalDate
    @Published private(set) var workouts: [Workout]

    let currentDate: LocalDate
    let calendar: Calendar
    private let repository: WorkoutRepository
    private let now: () -> Date

    init(
        repository: WorkoutRepository,
        initialDate: LocalDate,
        currentDate: LocalDate,
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping () -> Date = Date.init
    ) {
        precondition(
            repository.workouts.allSatisfy { $0.userID == repository.userID },
            "Workout repository returned another user's data"
        )
        self.repository = repository
        self.selectedDate = initialDate
        self.currentDate = currentDate
        self.calendar = calendar
        self.now = now
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
}
