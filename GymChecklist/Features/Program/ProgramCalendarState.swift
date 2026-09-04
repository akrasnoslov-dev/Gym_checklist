import Foundation

enum ProgramDayState: Equatable {
    case empty
    case workout(WorkoutStatus)

    var label: String {
        switch self {
        case .empty: "Empty"
        case .workout(.planned): "Planned"
        case .workout(.partial): "Partial"
        case .workout(.completed): "Completed"
        case .workout(.incomplete): "Incomplete"
        }
    }

    var systemImage: String? {
        switch self {
        case .empty: nil
        case .workout(.planned): "circle"
        case .workout(.partial): "circle.lefthalf.filled"
        case .workout(.completed): "checkmark.circle.fill"
        case .workout(.incomplete): "exclamationmark.circle"
        }
    }
}

struct ProgramCalendarState {
    private(set) var selectedDate: LocalDate
    let currentDate: LocalDate
    let calendar: Calendar
    private let workoutsByDate: [LocalDate: Workout]

    init(
        selectedDate: LocalDate,
        currentDate: LocalDate? = nil,
        calendar: Calendar = .autoupdatingCurrent,
        workouts: [Workout] = []
    ) {
        self.selectedDate = selectedDate
        self.currentDate = currentDate ?? selectedDate
        self.calendar = calendar
        self.workoutsByDate = workouts.reduce(into: [:]) { result, workout in
            result[workout.localDate] = workout
        }
    }

    var weekDates: [LocalDate] {
        guard
            let selected = selectedDate.date(in: calendar),
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: selected)?.start
        else { return [] }

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStart).map {
                LocalDate(date: $0, calendar: calendar)
            }
        }
    }

    var selectedWorkout: Workout? { workoutsByDate[selectedDate] }
    var selectedDayState: ProgramDayState { dayState(for: selectedDate) }

    mutating func select(_ date: LocalDate) {
        selectedDate = date
    }

    mutating func moveWeek(by offset: Int) {
        guard let date = selectedDate.adding(weeks: offset, calendar: calendar) else { return }
        selectedDate = date
    }

    func dayState(for date: LocalDate) -> ProgramDayState {
        guard let workout = workoutsByDate[date] else { return .empty }
        return .workout(workout.calendarStatus(asOf: currentDate))
    }

    /// A fixed six-row grid avoids layout jumps and keeps every date in the
    /// local calendar. Dates outside the visible month remain selectable.
    func monthDates(containing anchor: LocalDate) -> [LocalDate] {
        guard let date = anchor.date(in: calendar),
              let monthStart = calendar.dateInterval(of: .month, for: date)?.start,
              let gridStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start
        else { return [] }
        return (0..<42).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: gridStart)
                .map { LocalDate(date: $0, calendar: calendar) }
        }
    }
}
