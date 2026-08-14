import Foundation
import SwiftUI

struct ProgramView: View {
    @ObservedObject var viewModel: ProgramViewModel
    @State private var exercisePickerRoute: ExercisePickerRoute?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    weekHeader
                    dateSelector
                    selectedDateContent
                }
                .padding(.vertical)
            }
            .navigationTitle("Program")
            .accessibilityIdentifier("programScreen")
            .sheet(item: $exercisePickerRoute) { route in
                ExercisePickerView(
                    search: viewModel.searchExercises,
                    createCustom: viewModel.createCustomExercise,
                    onSelect: { exercise in
                        try viewModel.addExercise(exercise, to: route.workoutDate)
                    }
                )
            }
        }
    }

    private var weekHeader: some View {
        HStack {
            Button {
                viewModel.moveWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Previous week")
            .accessibilityIdentifier("programPreviousWeek")

            Spacer()
            Text(weekRangeLabel)
                .font(.headline)
                .accessibilityIdentifier("programWeekHeader")
            Spacer()

            Button {
                viewModel.moveWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next week")
            .accessibilityIdentifier("programNextWeek")
        }
        .padding(.horizontal, 4)
    }

    private var dateSelector: some View {
        HStack(spacing: 2) {
            ForEach(calendarState.weekDates, id: \.self) { date in
                dateButton(date)
            }
        }
        .padding(.horizontal, 2)
    }

    private func dateButton(_ date: LocalDate) -> some View {
        let state = calendarState.dayState(for: date)
        let isSelected = date == calendarState.selectedDate

        return Button {
            viewModel.select(date)
        } label: {
            VStack(spacing: 5) {
                Text(shortWeekday(for: date))
                    .font(.caption)
                Text("\(date.day)")
                    .font(.headline)
                Group {
                    if let image = state.systemImage {
                        Image(systemName: image)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 16, height: 16)
                .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fullDateLabel(for: date))
        .accessibilityValue(state.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("programDate-\(date.description)")
    }

    @ViewBuilder
    private var selectedDateContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(fullDateLabel(for: calendarState.selectedDate))
                .font(.title2.weight(.semibold))
                .accessibilityIdentifier("programSelectedDate")

            switch calendarState.selectedDayState {
            case .empty:
                Text("No workout planned for this date.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("programEmptyState")
                Button("Create workout") {
                    viewModel.createSelectedWorkout()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("programCreateWorkout")
            case let .workout(status):
                VStack(alignment: .leading, spacing: 12) {
                    Label(statusLabel(status), systemImage: ProgramDayState.workout(status).systemImage ?? "circle")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("programWorkoutState")
                    if let workout = calendarState.selectedWorkout, workout.exercises.isEmpty {
                        Text("No exercises added yet.")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("programEmptyWorkout")
                    } else if let workout = calendarState.selectedWorkout {
                        ForEach(workout.exercises.sorted { $0.order < $1.order }) { exercise in
                            let name = viewModel.exerciseName(for: exercise)
                            Text(name)
                                .accessibilityIdentifier("programExercise-\(name)")
                        }
                    }
                    Button {
                        exercisePickerRoute = ExercisePickerRoute(workoutDate: calendarState.selectedDate)
                    } label: {
                        Label("Add exercise", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("programAddExercise")
                }
            }
        }
        .padding(.horizontal)
    }

    private var weekRangeLabel: String {
        guard let first = calendarState.weekDates.first, let last = calendarState.weekDates.last else { return "Week" }
        return "\(shortDateLabel(for: first)) - \(shortDateLabel(for: last))"
    }

    private func shortWeekday(for date: LocalDate) -> String {
        guard let value = date.date(in: calendarState.calendar) else { return "" }
        return value.formatted(.dateTime.weekday(.narrow).locale(Locale(identifier: "en")))
    }

    private func shortDateLabel(for date: LocalDate) -> String {
        guard let value = date.date(in: calendarState.calendar) else { return date.description }
        return value.formatted(.dateTime.month(.abbreviated).day().locale(Locale(identifier: "en")))
    }

    private func fullDateLabel(for date: LocalDate) -> String {
        guard let value = date.date(in: calendarState.calendar) else { return date.description }
        return value.formatted(.dateTime.weekday(.wide).month(.wide).day().year().locale(Locale(identifier: "en")))
    }

    private func statusLabel(_ status: WorkoutStatus) -> String {
        ProgramDayState.workout(status).label
    }

    private var calendarState: ProgramCalendarState { viewModel.calendarState }
}

private struct ExercisePickerRoute: Identifiable {
    let workoutDate: LocalDate
    var id: LocalDate { workoutDate }
}
