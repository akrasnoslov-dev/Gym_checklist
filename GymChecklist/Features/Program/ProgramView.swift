import Foundation
import SwiftUI

struct ProgramView: View {
    @ObservedObject var viewModel: ProgramViewModel
    @State private var exercisePickerRoute: ExercisePickerRoute?
    @State private var pendingDeletion: PendingExerciseDeletion?
    @State private var showsMutationError = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    weekHeader
                    dateSelector
                }
                selectedDateSections
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Program")
            .accessibilityIdentifier("programScreen")
            .toolbar {
                if !orderedExercises.isEmpty {
                    EditButton()
                        .accessibilityIdentifier("programEditExercises")
                }
            }
            .sheet(item: $exercisePickerRoute) { route in
                ExercisePickerView(
                    search: viewModel.searchExercises,
                    createCustom: viewModel.createCustomExercise,
                    onSelect: { exercise in
                        try viewModel.addExercise(exercise, to: route.workoutDate)
                    }
                )
            }
            .alert("Workout could not be updated", isPresented: $showsMutationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Try again.")
            }
            .confirmationDialog(
                "Delete \(pendingDeletion?.name ?? "exercise")?",
                isPresented: deleteConfirmationBinding,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let pendingDeletion { deleteExercise(pendingDeletion.id) }
                    pendingDeletion = nil
                }
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: {
                Text("Its configured sets will be removed. You can re-add the exercise later.")
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
    }

    private var dateSelector: some View {
        HStack(spacing: 2) {
            ForEach(calendarState.weekDates, id: \.self) { date in
                dateButton(date)
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 2, bottom: 8, trailing: 2))
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
    private var selectedDateSections: some View {
        Section {
            Text(fullDateLabel(for: calendarState.selectedDate))
                .font(.title2.weight(.semibold))
                .accessibilityIdentifier("programSelectedDate")
        }

        switch calendarState.selectedDayState {
        case .empty:
            Section {
                Text("No workout planned for this date.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("programEmptyState")
                Button("Create workout") {
                    viewModel.createSelectedWorkout()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("programCreateWorkout")
            }
        case let .workout(status):
            Section {
                Label(statusLabel(status), systemImage: ProgramDayState.workout(status).systemImage ?? "circle")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("programWorkoutState")
            }

            Section("Exercises") {
                if orderedExercises.isEmpty {
                    Text("No exercises added yet.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("programEmptyWorkout")
                }
                ForEach(orderedExercises) { exercise in
                    exerciseRow(
                        exercise,
                        index: orderedExercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
                    )
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)

                Button {
                    exercisePickerRoute = ExercisePickerRoute(workoutDate: calendarState.selectedDate)
                } label: {
                    Label("Add exercise", systemImage: "plus")
                }
                .accessibilityIdentifier("programAddExercise")
            }
        }
    }

    private func exerciseRow(_ exercise: WorkoutExercise, index: Int) -> some View {
        let name = viewModel.exerciseName(for: exercise)
        return HStack(alignment: .center) {
            Text(name)
                .accessibilityIdentifier("programExercise-\(name)")
            Spacer()
            Menu {
                if index > 0 {
                    Button("Move up") { moveExercise(exercise.id, by: -1) }
                        .accessibilityIdentifier("programExerciseMoveUp-\(exercise.id.rawValue.uuidString)")
                }
                if index < orderedExercises.count - 1 {
                    Button("Move down") { moveExercise(exercise.id, by: 1) }
                        .accessibilityIdentifier("programExerciseMoveDown-\(exercise.id.rawValue.uuidString)")
                }
                Button("Delete", role: .destructive) { requestDeletion(of: exercise) }
                    .accessibilityIdentifier("programExerciseDelete-\(exercise.id.rawValue.uuidString)")
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Actions for \(name), exercise \(index + 1) of \(orderedExercises.count)")
        }
        .accessibilityIdentifier("programExerciseRow-\(exercise.id.rawValue.uuidString)")
        .accessibilityHint("Exercise \(index + 1) of \(orderedExercises.count)")
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
    private var orderedExercises: [WorkoutExercise] {
        viewModel.orderedExercises(on: calendarState.selectedDate)
    }

    private func deleteExercises(at offsets: IndexSet) {
        let exercises = offsets.compactMap {
            orderedExercises.indices.contains($0) ? orderedExercises[$0] : nil
        }
        for exercise in exercises { requestDeletion(of: exercise) }
    }

    private func moveExercises(from offsets: IndexSet, to destination: Int) {
        var reordered = orderedExercises
        reordered.move(fromOffsets: offsets, toOffset: destination)
        persistOrder(reordered.map(\.id))
    }

    private func moveExercise(_ id: WorkoutExerciseID, by offset: Int) {
        var reordered = orderedExercises
        guard let source = reordered.firstIndex(where: { $0.id == id }) else { return }
        let destination = source + offset
        guard reordered.indices.contains(destination) else { return }
        reordered.swapAt(source, destination)
        persistOrder(reordered.map(\.id))
    }

    private func persistOrder(_ ids: [WorkoutExerciseID]) {
        do {
            try viewModel.reorderExercises(ids, on: calendarState.selectedDate)
        } catch {
            showsMutationError = true
        }
    }

    private func deleteExercise(_ id: WorkoutExerciseID) {
        do {
            try viewModel.deleteExercise(id, from: calendarState.selectedDate)
        } catch {
            showsMutationError = true
        }
    }

    private func requestDeletion(of exercise: WorkoutExercise) {
        if exercise.sets.isEmpty {
            deleteExercise(exercise.id)
        } else {
            pendingDeletion = PendingExerciseDeletion(
                id: exercise.id,
                name: viewModel.exerciseName(for: exercise)
            )
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )
    }
}

private struct ExercisePickerRoute: Identifiable {
    let workoutDate: LocalDate
    var id: LocalDate { workoutDate }
}

private struct PendingExerciseDeletion {
    let id: WorkoutExerciseID
    let name: String
}
