import SwiftUI

struct TodayView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let currentDate: LocalDate
    let calendar: Calendar
    @State private var editorRoute: TodaySetEditorRoute?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header

                if let workout = viewModel.workout(on: currentDate), !workout.exercises.isEmpty {
                    ForEach(orderedExercises(in: workout).filter { !$0.isSkipped }) { exercise in
                        exerciseSection(exercise)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
        .accessibilityIdentifier("todayScreen")
        .sheet(item: $editorRoute) { route in
            TodaySetEditorSheet(route: route) { reps, weight, timeSeconds in
                try viewModel.editTodaySet(
                    route.set.id,
                    in: route.exercise.id,
                    on: currentDate,
                    reps: reps,
                    weight: weight,
                    timeSeconds: timeSeconds
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today")
                .font(.largeTitle.weight(.bold))
            Text(dateLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func exerciseSection(_ exercise: WorkoutExercise) -> some View {
        let sets = orderedSets(in: exercise)

        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.exerciseName(for: exercise))
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(sets) { set in
                    Button {
                        toggleCompletion(for: set, in: exercise)
                    } label: {
                        setRow(set)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("todaySet-\(set.id.rawValue.uuidString)")
                    .accessibilityValue(set.isCompleted ? "Completed" : "Incomplete")
                    .highPriorityGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                        editorRoute = TodaySetEditorRoute(exercise: exercise, set: set)
                    })
                    if set.id != sets.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func setRow(_ set: WorkoutSet) -> some View {
        HStack(spacing: 12) {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(set.isCompleted ? Color.accentColor : Color.secondary)
            Text(setDescription(for: set))
                .font(.body)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func orderedExercises(in workout: Workout) -> [WorkoutExercise] {
        workout.exercises.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }
    }

    private func orderedSets(in exercise: WorkoutExercise) -> [WorkoutSet] {
        exercise.sets.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }
    }

    private func setDescription(for set: WorkoutSet) -> String {
        SetDisplayFormatter(unit: .kilograms).string(
            reps: set.displayedReps,
            weight: set.displayedWeight,
            timeSeconds: set.displayedTimeSeconds
        )
    }

    private var dateLabel: String {
        guard let date = currentDate.date(in: calendar) else { return currentDate.description }
        return date.formatted(.dateTime.weekday(.wide).month(.wide).day().year().locale(Locale(identifier: "en")))
    }

    private func toggleCompletion(for set: WorkoutSet, in exercise: WorkoutExercise) {
        do {
            try viewModel.toggleCompletion(of: set.id, in: exercise.id, on: currentDate)
        } catch {
            assertionFailure("Today set completion failed: \(error)")
        }
    }
}

private struct TodaySetEditorRoute: Identifiable {
    let exercise: WorkoutExercise
    let set: WorkoutSet

    var id: WorkoutSetID { set.id }
}

private struct TodaySetEditorSheet: View {
    let route: TodaySetEditorRoute
    let onSave: (Int, Double, Int) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reps: Int
    @State private var weight: Double
    @State private var timeSeconds: Int
    @State private var showsValidationError = false

    init(
        route: TodaySetEditorRoute,
        onSave: @escaping (Int, Double, Int) throws -> Void
    ) {
        self.route = route
        self.onSave = onSave
        _reps = State(initialValue: route.set.displayedReps)
        _weight = State(initialValue: route.set.displayedWeight)
        _timeSeconds = State(initialValue: route.set.displayedTimeSeconds)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(route.set.isCompleted ? "Actual results" : "Planned set") {
                    TextField("Reps", value: $reps, format: .number)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("todaySetEditorReps")
                    TextField("Weight", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("todaySetEditorWeight")
                    TextField("Time (seconds)", value: $timeSeconds, format: .number)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("todaySetEditorTime")
                }
            }
            .navigationTitle(route.set.isCompleted ? "Edit actual" : "Edit set")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("todaySetEditorCancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try onSave(reps, weight, timeSeconds)
                            dismiss()
                        } catch {
                            showsValidationError = true
                        }
                    }
                    .accessibilityIdentifier("todaySetEditorSave")
                }
            }
            .alert("Set values must be non-negative", isPresented: $showsValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enter valid reps, weight, and time values.")
            }
        }
    }
}
