import Foundation
import SwiftUI

enum TodayContentState: Equatable {
    case activeWorkout
    case noProgram
    case restDay
    case loading
    case unavailable

    static func resolve(
        workouts: [Workout],
        currentDate: LocalDate,
        loadState: WorkoutLoadState = .available
    ) -> TodayContentState {
        if loadState == .loading { return .loading }
        if loadState == .unavailable(hasUsableSnapshot: false) { return .unavailable }
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
    let weightUnit: WeightUnit
    let onOpenProgram: () -> Void
    @State private var editorRoute: TodaySetEditorRoute?
    @State private var showsCompletionPopup = false
    @State private var completionContent: WorkoutCompletionContent = .crushed
    @State private var mutationError: TodayMutationError?
    @AccessibilityFocusState private var accessibilityFocus: AccessibilityFocusTarget?
    @State private var completionRestoreFocus: AccessibilityFocusTarget?

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: GymTheme.spacing24) {
                    header

                    if viewModel.workoutLoadState == .unavailable(hasUsableSnapshot: true) {
                        syncUnavailableMessage
                    }

                    switch TodayContentState.resolve(
                        workouts: viewModel.workouts,
                        currentDate: currentDate,
                        loadState: viewModel.workoutLoadState
                    ) {
                    case .activeWorkout:
                        if let workout = viewModel.workout(on: currentDate) {
                            if workout.exercises.isEmpty {
                                emptyWorkoutState
                            } else {
                                let exercises = orderedExercises(in: workout)
                                ForEach(exercises.filter { !$0.isSkipped }) { exercise in
                                    exerciseSection(exercise)
                                }
                                restoreSkippedExercisesMenu(exercises.filter(\.isSkipped))
                            }
                        }
                    case .noProgram:
                        noProgramState
                    case .restDay:
                        restDayState
                    case .loading:
                        loadingState
                    case .unavailable:
                        unavailableState
                    }
                }
                .padding(.horizontal, GymTheme.spacing16)
                .padding(.vertical, GymTheme.spacing20)
                .accessibilityHidden(showsCompletionPopup)
            }
            .allowsHitTesting(!showsCompletionPopup)
            if showsCompletionPopup {
                TodayCompletionOverlay(content: completionContent) {
                    showsCompletionPopup = false
                    accessibilityFocus = completionRestoreFocus ?? .header
                    completionRestoreFocus = nil
                }
                .accessibilityFocused($accessibilityFocus, equals: .completionOverlay)
            }
        }
        .gymPageBackground()
        .accessibilityIdentifier("todayScreen")
        .onChange(of: currentDate) { _, _ in
            editorRoute = nil
            showsCompletionPopup = false
            mutationError = nil
            accessibilityFocus = nil
            completionRestoreFocus = nil
        }
        .sheet(item: $editorRoute) { route in
            TodaySetEditorSheet(route: route, weightUnit: weightUnit) { reps, weight, timeSeconds in
                try viewModel.editTodaySet(
                    route.workoutSet.id,
                    in: route.exercise.id,
                    on: currentDate,
                    reps: reps,
                    weight: weight,
                    timeSeconds: timeSeconds
                )
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
                .accessibilityIdentifier("todayDate")
        }
        .accessibilityIdentifier("todayHeader")
        .accessibilityFocused($accessibilityFocus, equals: .header)
    }

    private var noProgramState: some View {
        TodayEmptyHero(
            systemImage: "list.clipboard",
            title: "No workout planned yet.",
            message: "Create your first workout to get started.",
            actionTitle: "Create workout",
            actionIdentifier: "todayCreateWorkout",
            action: onOpenProgram
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todayNoProgramState")
    }

    private var loadingState: some View {
        ProgressView("Loading workout")
            .frame(maxWidth: .infinity, minHeight: 220)
            .foregroundStyle(GymTheme.textSecondary)
            .accessibilityIdentifier("todayLoadingState")
    }

    private var unavailableState: some View {
        TodayEmptyHero(
            systemImage: "wifi.exclamationmark",
            title: "Workout unavailable.",
            message: "Check your connection. The app will retry automatically.",
            actionTitle: nil,
            actionIdentifier: nil,
            action: nil
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todayUnavailableState")
    }

    private var syncUnavailableMessage: some View {
        Label("Saved workout data is available. Changes will sync when possible.", systemImage: "icloud.slash")
            .font(.footnote)
            .foregroundStyle(GymTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gymCard()
            .accessibilityIdentifier("todaySyncUnavailableMessage")
    }

    private var restDayState: some View {
        TodayEmptyHero(
            systemImage: "sun.max.fill",
            title: "Rest day.",
            message: "Your program exists; no workout is scheduled today. See you tomorrow.",
            actionTitle: "View program",
            actionIdentifier: "todayViewProgram",
            action: onOpenProgram
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todayRestDayState")
    }

    private var emptyWorkoutState: some View {
        TodayEmptyHero(
            systemImage: "figure.strengthtraining.traditional",
            title: "Workout is empty.",
            message: "Add exercises in Program before you start.",
            actionTitle: "View program",
            actionIdentifier: "todayEmptyWorkoutViewProgram",
            action: onOpenProgram
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todayEmptyWorkoutState")
    }

    private func exerciseSection(_ exercise: WorkoutExercise) -> some View {
        let sets = orderedSets(in: exercise)
        let exerciseName = viewModel.exerciseName(for: exercise)

        return VStack(spacing: 0) {
            HStack(spacing: GymTheme.spacing12) {
                Text(exerciseName)
                    .font(.headline)
                    .accessibilityLabel("\(exerciseName), \(sets.count) \(sets.count == 1 ? "set" : "sets")")
                    .accessibilityHint("Actions available to skip this exercise.")
                    .accessibilityIdentifier("todayExercise-\(exercise.id.rawValue.uuidString)")
                    .accessibilityAction(named: Text("Skip exercise")) {
                        skip(exercise)
                    }
                Spacer(minLength: 0)
                Menu {
                    Button("Skip exercise") {
                        skip(exercise)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Exercise actions")
            }
            .padding(.leading, GymTheme.spacing16)
            .padding(.trailing, GymTheme.spacing8)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
            .contextMenu {
                Button("Skip exercise") {
                    skip(exercise)
                }
            }

            Divider().overlay(GymTheme.separator)

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
                .accessibilityFocused($accessibilityFocus, equals: .set(set.id))
                .highPriorityGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                    editorRoute = TodaySetEditorRoute(exercise: exercise, workoutSet: set)
                })
                .accessibilityAction(named: Text(set.isCompleted ? "Edit actual" : "Edit set")) {
                    editorRoute = TodaySetEditorRoute(exercise: exercise, workoutSet: set)
                }
                if set.id != sets.last?.id {
                    Divider().overlay(GymTheme.separator)
                }
            }
        }
        .background(
            GymTheme.surfaceElevated,
            in: RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: GymTheme.groupRadius, style: .continuous)
                .stroke(GymTheme.borderSubtle, lineWidth: 1)
        }
    }

    private func setRow(_ set: WorkoutSet) -> some View {
        HStack(spacing: GymTheme.spacing12) {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(set.isCompleted ? GymTheme.accentForeground : GymTheme.textSecondary)
            Text(setDescription(for: set))
                .font(.body)
                .foregroundStyle(GymTheme.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, GymTheme.spacing16)
        .padding(.vertical, GymTheme.spacing8)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
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
            .frame(minHeight: 44)
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
        SetDisplayFormatter(unit: weightUnit).string(
            reps: set.displayedReps,
            weightInKilograms: set.displayedWeight,
            timeSeconds: set.displayedTimeSeconds,
            type: set.displayedType
        )
    }

    private var dateLabel: String {
        guard let date = currentDate.date(in: calendar) else { return currentDate.description }
        return date.formatted(.dateTime.weekday(.wide).month(.wide).day().locale(Locale(identifier: "en")))
    }

    private func toggleCompletion(for set: WorkoutSet, in exercise: WorkoutExercise) {
        let statusBeforeMutation = viewModel.workout(on: currentDate)?.completionStatus ?? .planned
        do {
            try viewModel.toggleCompletion(of: set.id, in: exercise.id, on: currentDate)
            presentCompletionIfNeeded(after: statusBeforeMutation, restoreFocus: .set(set.id))
        } catch {
            showMutationError()
        }
    }

    private func skip(_ exercise: WorkoutExercise) {
        let statusBeforeMutation = viewModel.workout(on: currentDate)?.completionStatus ?? .planned
        do {
            try viewModel.skipTodayExercise(exercise.id, on: currentDate)
            presentCompletionIfNeeded(after: statusBeforeMutation, restoreFocus: .header)
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

    private func presentCompletionIfNeeded(
        after statusBeforeMutation: WorkoutStatus,
        restoreFocus: AccessibilityFocusTarget
    ) {
        let statusAfterMutation = viewModel.workout(on: currentDate)?.completionStatus ?? .planned
        showsCompletionPopup = WorkoutCompletionTrigger.shouldPresent(
            before: statusBeforeMutation,
            after: statusAfterMutation
        )
        guard showsCompletionPopup else { return }
        if let workoutID = viewModel.workout(on: currentDate)?.id {
            completionContent = WorkoutCompletionContent.selected(for: workoutID)
        }
        completionRestoreFocus = restoreFocus
        DispatchQueue.main.async {
            accessibilityFocus = .completionOverlay
        }
    }
}

private struct TodayEmptyHero: View {
    let systemImage: String
    let title: String
    let message: String
    let actionTitle: String?
    let actionIdentifier: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: GymTheme.spacing16) {
            Spacer(minLength: 48)
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(GymTheme.accentForeground)
                .frame(width: 78, height: 78)
                .background(GymTheme.accentSoft, in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: GymTheme.spacing8) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(GymTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.body)
                    .foregroundStyle(GymTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(GymPrimaryButtonStyle())
                    .frame(maxWidth: 230)
                    .accessibilityIdentifier(actionIdentifier ?? "todayHeroAction")
            }
            Spacer(minLength: 48)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }
}

private enum AccessibilityFocusTarget: Hashable {
    case header
    case set(WorkoutSetID)
    case completionOverlay
}

enum TodayMutationError: Identifiable {
    case saveFailed

    var id: String { "saveFailed" }
    var title: String { "Couldn't confirm this change" }
    var message: String { "Check your workout before trying again." }
}

/// The approved completion artwork is packaged with the app. Selection is
/// deterministic per workout so presentation is stable for UI tests and does
/// not depend on a network call or the process-randomized Swift hash seed.
enum WorkoutCompletionContent: CaseIterable {
    case crushed
    case barely
    case another

    var assetName: String {
        switch self {
        case .crushed: "CompletionCrushed"
        case .barely: "CompletionBarely"
        case .another: "CompletionAnother"
        }
    }

    var title: String {
        switch self {
        case .crushed: "You crushed it!"
        case .barely: "Gym survived. Barely."
        case .another: "Another one done."
        }
    }

    var message: String {
        switch self {
        case .crushed: "That bar had no chance."
        case .barely: "See you at the next set."
        case .another: "Consistency looks good on you."
        }
    }

    static func selected(for workoutID: WorkoutID) -> Self {
        let index = workoutID.rawValue.uuidString.utf8.reduce(0) { $0 + Int($1) } % allCases.count
        return allCases[index]
    }
}

private struct TodayCompletionOverlay: View {
    let content: WorkoutCompletionContent
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            GymTheme.scrim
                .ignoresSafeArea()
            VStack(spacing: GymTheme.spacing16) {
                Image(content.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 112)
                    .accessibilityHidden(true)
                Text(content.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(GymTheme.textPrimary)
                Text(content.message)
                    .font(.subheadline)
                    .foregroundStyle(GymTheme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Done", action: onDismiss)
                    .buttonStyle(GymPrimaryButtonStyle())
                    .accessibilityIdentifier("todayCompletionDismiss")
            }
            .padding(28)
            .background(
                GymTheme.surfaceGrouped,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(GymTheme.borderSubtle, lineWidth: 1)
            }
            .padding(32)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("todayCompletionPopup")
            .accessibilityAddTraits(.isModal)
        }
    }
}

private struct TodaySetEditorRoute: Identifiable {
    let exercise: WorkoutExercise
    let workoutSet: WorkoutSet

    var id: WorkoutSetID { workoutSet.id }
}

private struct TodaySetEditorSheet: View {
    let route: TodaySetEditorRoute
    let weightUnit: WeightUnit
    let onSave: (Int, Double, Int) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reps: Int
    @State private var weight: Double
    @State private var timeSeconds: Int
    @State private var showsValidationError = false
    @State private var showsSaveError = false

    init(
        route: TodaySetEditorRoute,
        weightUnit: WeightUnit,
        onSave: @escaping (Int, Double, Int) throws -> Void
    ) {
        self.route = route
        self.weightUnit = weightUnit
        self.onSave = onSave
        _reps = State(initialValue: route.workoutSet.displayedReps)
        _weight = State(initialValue: weightUnit.displayWeight(fromCanonicalKilograms: route.workoutSet.displayedWeight))
        _timeSeconds = State(initialValue: route.workoutSet.displayedTimeSeconds)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(route.workoutSet.isCompleted ? "Actual results" : "Planned set") {
                    Text(route.workoutSet.displayedType.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if route.workoutSet.displayedType != .timed {
                        TextField("Reps", value: $reps, format: .number)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("todaySetEditorReps")
                    }
                    if route.workoutSet.displayedType == .weighted || route.workoutSet.displayedType == .legacyMixed {
                        TextField("Weight", value: $weight, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("todaySetEditorWeight")
                        LabeledContent("Unit", value: weightUnit.rawValue)
                            .accessibilityIdentifier("todaySetEditorWeightUnit")
                    }
                    if route.workoutSet.displayedType == .timed || route.workoutSet.displayedType == .legacyMixed {
                        TextField("Time (seconds)", value: $timeSeconds, format: .number)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("todaySetEditorTime")
                    }
                }
            }
            .navigationTitle(route.workoutSet.isCompleted ? "Edit actual" : "Edit set")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("todaySetEditorCancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try onSave(reps, weightUnit.canonicalKilograms(fromDisplayWeight: weight), timeSeconds)
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
