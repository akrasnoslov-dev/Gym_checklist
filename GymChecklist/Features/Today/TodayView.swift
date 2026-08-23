import SwiftUI

enum TodayContentState: Equatable {
    case activeWorkout
    case noProgram
    case restDay

    static func resolve(workouts: [Workout], currentDate: LocalDate) -> TodayContentState {
        guard !workouts.contains(where: { $0.localDate == currentDate }) else { return .activeWorkout }
        return workouts.isEmpty ? .noProgram : .restDay
    }
}

enum WorkoutCompletionTrigger {
    static func shouldPresent(before: WorkoutStatus, after: WorkoutStatus) -> Bool {
        before != .completed && after == .completed
    }
}

struct TodayView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let currentDate: LocalDate
    let calendar: Calendar
    let onOpenProgram: () -> Void
    @State private var editorRoute: TodaySetEditorRoute?
    @State private var showsCompletionPopup = false
    @State private var mutationError: TodayMutationError?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header

                switch TodayContentState.resolve(workouts: viewModel.workouts, currentDate: currentDate) {
                case .activeWorkout:
                    if let workout = viewModel.workout(on: currentDate), !workout.exercises.isEmpty {
                        let exercises = orderedExercises(in: workout)
                        ForEach(exercises.filter { !$0.isSkipped }) { exercise in
                            exerciseSection(exercise)
                        }
                        restoreSkippedExercisesMenu(exercises.filter(\.isSkipped))
                    }
                case .noProgram:
                    noProgramState
                case .restDay:
                    restDayState
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
            .accessibilityHidden(showsCompletionPopup)
        }
        .accessibilityIdentifier("todayScreen")
        .onChange(of: currentDate) { _, _ in
            editorRoute = nil
            showsCompletionPopup = false
            mutationError = nil
        }
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
        .overlay {
            if showsCompletionPopup {
                TodayCompletionOverlay {
                    showsCompletionPopup = false
                }
            }
        }
        .alert(item: $mutationError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
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
        .accessibilityIdentifier("todayHeader")
    }

    private var noProgramState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No workout planned yet.")
                .foregroundStyle(.secondary)
            Button("Create workout", action: onOpenProgram)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("todayCreateWorkout")
        }
        .accessibilityIdentifier("todayNoProgramState")
    }

    private var restDayState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rest day.")
                .font(.title3.weight(.semibold))
            Text("See you tomorrow.")
                .foregroundStyle(.secondary)
            Button("View program", action: onOpenProgram)
                .buttonStyle(.bordered)
                .accessibilityIdentifier("todayViewProgram")
        }
        .accessibilityIdentifier("todayRestDayState")
    }

    private func exerciseSection(_ exercise: WorkoutExercise) -> some View {
        let sets = orderedSets(in: exercise)
        let exerciseName = viewModel.exerciseName(for: exercise)

        VStack(alignment: .leading, spacing: 8) {
            Text(exerciseName)
                .font(.headline)
                .contextMenu {
                    Button("Skip exercise", role: .destructive) {
                        skip(exercise)
                    }
                }
                .accessibilityLabel("\(exerciseName), \(sets.count) \(sets.count == 1 ? \"set\" : \"sets\")")
                .accessibilityHint("Actions available to skip this exercise.")
                .accessibilityIdentifier("todayExercise-\(exercise.id.rawValue.uuidString)")
                .accessibilityAction(named: Text("Skip exercise")) {
                    skip(exercise)
                }

            VStack(spacing: 0) {
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                    Button {
                        toggleCompletion(for: set, in: exercise)
                    } label: {
                        setRow(set)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("todaySet-\(set.id.rawValue.uuidString)")
                    .accessibilityLabel("\(exerciseName), set \(index + 1): \(setDescription(for: set))")
                    .accessibilityValue(set.isCompleted ? "Completed" : "Incomplete")
                    .accessibilityHint("Double tap to toggle completion. Actions available to edit this set.")
                    .accessibilityAddTraits(set.isCompleted ? .isSelected : [])
                    .highPriorityGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                        editorRoute = TodaySetEditorRoute(exercise: exercise, set: set)
                    })
                    .accessibilityAction(named: Text(set.isCompleted ? "Edit actual" : "Edit set")) {
                        editorRoute = TodaySetEditorRoute(exercise: exercise, set: set)
                    }
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
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func restoreSkippedExercisesMenu(_ exercises: [WorkoutExercise]) -> some View {
        if !exercises.isEmpty {
            Menu {
                ForEach(exercises) { exercise in
                    Button("Restore \(viewModel.exerciseName(for: exercise))") {
                        restore(exercise)
                    }
                    .accessibilityIdentifier("todayRestore-\(exercise.id.rawValue.uuidString)")
                }
            } label: {
                Label("Skipped exercises", systemImage: "arrow.uturn.backward")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("todayRestoreSkippedExercises")
        }
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
        let statusBeforeMutation = viewModel.workout(on: currentDate)?.completionStatus ?? .planned
        do {
            try viewModel.toggleCompletion(of: set.id, in: exercise.id, on: currentDate)
            presentCompletionIfNeeded(after: statusBeforeMutation)
        } catch {
            showMutationError()
        }
    }

    private func skip(_ exercise: WorkoutExercise) {
        let statusBeforeMutation = viewModel.workout(on: currentDate)?.completionStatus ?? .planned
        do {
            try viewModel.skipTodayExercise(exercise.id, on: currentDate)
            presentCompletionIfNeeded(after: statusBeforeMutation)
        } catch {
            showMutationError()
        }
    }

    private func restore(_ exercise: WorkoutExercise) {
        do {
            try viewModel.restoreTodayExercise(exercise.id, on: currentDate)
        } catch {
            showMutationError()
        }
    }

    private func showMutationError() {
        mutationError = .saveFailed
    }

    private func presentCompletionIfNeeded(after statusBeforeMutation: WorkoutStatus) {
        let statusAfterMutation = viewModel.workout(on: currentDate)?.completionStatus ?? .planned
        showsCompletionPopup = WorkoutCompletionTrigger.shouldPresent(
            before: statusBeforeMutation,
            after: statusAfterMutation
        )
    }
}

enum TodayMutationError: Identifiable {
    case saveFailed

    var id: String { "saveFailed" }
    var title: String { "Couldn't confirm this change" }
    var message: String { "Check your workout before trying again." }
}

private struct TodayCompletionOverlay: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                Text("Another one done.")
                    .font(.title3.weight(.semibold))
                Button("Done", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("todayCompletionDismiss")
            }
            .padding(28)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 20))
            .padding(32)
            .accessibilityIdentifier("todayCompletionPopup")
            .accessibilityAddTraits(.isModal)
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
    @State private var showsSaveError = false

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
                            if let planningError = error as? ProgramPlanningError,
                               planningError == .invalidSetValues {
                                showsValidationError = true
                            } else {
                                showsSaveError = true
                            }
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
            .alert("Couldn't confirm this change", isPresented: $showsSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Check your workout before trying again.")
            }
        }
    }
}
