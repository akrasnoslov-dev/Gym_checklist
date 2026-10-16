import Foundation
import SwiftUI

struct ProgramView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let weightUnit: WeightUnit
    @State private var displayedMonth: LocalDate
    @State private var calendarMode: CalendarMode = .week
    @State private var activeSheet: ProgramSheetRoute?
    @State private var confirmation: ProgramConfirmation?
    @State private var reorderSession: ProgramSetReorderSession?
    @State private var setRowFrames: [WorkoutSetID: CGRect] = [:]
    @GestureState private var isReorderGestureActive = false
    @State private var showsMutationError = false

    init(viewModel: WorkoutViewModel, weightUnit: WeightUnit) {
        self.viewModel = viewModel
        self.weightUnit = weightUnit
        _displayedMonth = State(initialValue: viewModel.selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: GymTheme.spacing12) {
                programHeader
                Picker("Program view", selection: $calendarMode) {
                    ForEach(CalendarMode.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("programViewMode")
                calendarHeader
                dateSelector
                programLegend
            }
            .padding(.horizontal, GymTheme.spacing16)
            .padding(.top, GymTheme.spacing12)
            .padding(.bottom, GymTheme.spacing8)
            .background(GymTheme.surfaceBase)

            Divider().overlay(GymTheme.separator)

            selectedDateSections
        }
        .coordinateSpace(name: ProgramSetListCoordinateSpace.name)
        .onPreferenceChange(ProgramSetRowFramePreferenceKey.self) { setRowFrames = $0 }
        .gymPageBackground()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("programScreen")
        .onAppear {
            displayedMonth = viewModel.selectedDate
        }
        .onChange(of: viewModel.selectedDate) { _, selectedDate in
            displayedMonth = selectedDate
            cancelSetReorder()
        }
        .onChange(of: isReorderGestureActive) { _, isActive in
            if !isActive, reorderSession != nil {
                cancelSetReorder()
            }
        }
        .onDisappear(perform: cancelSetReorder)
        .alert(
            confirmationTitle,
            isPresented: confirmationBinding,
            presenting: confirmation
        ) {
            confirmationActions($0)
        } message: { Text(confirmationMessage($0)) }
        .sheet(item: $activeSheet) { route in
            sheetContent(route)
        }
        .alert("Workout could not be updated", isPresented: $showsMutationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Try again.")
        }
    }

    private var programHeader: some View {
        HStack(alignment: .center, spacing: GymTheme.spacing12) {
            Text("Program")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(GymTheme.textPrimary)
            Spacer(minLength: 0)
            if let workout = calendarState.selectedWorkout {
                Menu {
                    Button {
                        activeSheet = .copy(CopyWorkoutRoute(destinationDate: workout.localDate))
                    } label: {
                        Label("Copy workout", systemImage: "doc.on.doc")
                    }
                    .accessibilityIdentifier("programCopyWorkout")

                    if !isHistorical {
                        Button {
                            activeSheet = .repeatWorkout(RepeatWorkoutRoute(sourceDate: workout.localDate))
                        } label: {
                            Label("Repeat workout", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .accessibilityIdentifier("programRepeatWorkout")
                    }

                    Divider()
                    Button("Delete workout", systemImage: "trash", role: .destructive) {
                        confirmation = .workout(workout.localDate)
                    }
                    .accessibilityIdentifier("programDeleteWorkout")
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Workout actions")
                .accessibilityIdentifier("programWorkoutActions")
            }
        }
        .frame(minHeight: 44)
    }

    @ViewBuilder
    private func sheetContent(_ route: ProgramSheetRoute) -> some View {
        switch route {
        case let .exercisePicker(route):
            ExercisePickerView(
                search: viewModel.searchExercises,
                createCustom: viewModel.createCustomExercise,
                renameCustom: { try viewModel.renameCustomExercise($0, to: $1) },
                deleteCustom: viewModel.deleteCustomExercise,
                onSelect: { exercise in
                    try viewModel.addExercise(exercise, to: route.workoutDate)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        case let .setEditor(route):
            ProgramSetEditorSheet(
                set: route.set,
                exerciseName: viewModel.exerciseName(for: route.exercise),
                weightUnit: weightUnit,
                onSave: { reps, weight, timeSeconds in
                    guard let set = route.set else { return }
                    try viewModel.editSet(
                        set.id,
                        in: route.exercise.id,
                        on: route.workoutDate,
                        reps: reps,
                        weight: weight,
                        timeSeconds: timeSeconds,
                        type: set.type
                    )
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        case let .historicalActual(route):
            HistoricalActualEditorSheet(
                route: route,
                weightUnit: weightUnit,
                onSave: { reps, weight, timeSeconds in
                    try viewModel.editHistoricalActual(
                        route.workoutSet.id,
                        in: route.exercise.id,
                        on: route.workoutDate,
                        reps: reps,
                        weight: weight,
                        timeSeconds: timeSeconds
                    )
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        case let .copy(route):
            CopyWorkoutSheet(
                destinationDate: route.destinationDate,
                currentDate: viewModel.currentDate,
                calendar: calendarState.calendar,
                availableWorkouts: viewModel.workouts,
                destinationState: viewModel.copyDestinationState(on:),
                onCopy: { sourceDate, destinationDate, strategy in
                    try viewModel.copyWorkout(from: sourceDate, to: destinationDate, strategy: strategy)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true)
        case let .repeatWorkout(route):
            RepeatWorkoutSheet(
                sourceDate: route.sourceDate,
                exerciseCount: calendarState.selectedWorkout?.exercises.count ?? 0,
                setCount: calendarState.selectedWorkout?.exercises.flatMap(\.sets).count ?? 0,
                calendar: calendarState.calendar,
                isDestinationOccupied: { viewModel.hasWorkout(on: $0) },
                onRepeat: { endDate, cadence in
                    try viewModel.repeatWorkout(from: route.sourceDate, through: endDate, cadence: cadence)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        case .reorderExercises:
            ExerciseReorderSheet(
                exercises: orderedExercises,
                exerciseName: viewModel.exerciseName(for:),
                onReorder: persistOrder
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func confirmationActions(_ route: ProgramConfirmation) -> some View {
        Button(route.destructiveActionTitle, role: .destructive) {
            confirmation = nil
            performConfirmedDeletion(route)
        }
        .accessibilityIdentifier(route.accessibilityIdentifier)
        Button("Cancel", role: .cancel) { confirmation = nil }
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { confirmation != nil },
            set: { if !$0 { confirmation = nil } }
        )
    }

    private var confirmationTitle: String {
        confirmation?.title ?? "Confirm deletion"
    }

    private func confirmationMessage(_ route: ProgramConfirmation) -> String {
        route.message
    }

    private func performConfirmedDeletion(_ route: ProgramConfirmation) {
        do {
            switch route {
            case let .workout(date):
                try viewModel.deleteWorkout(on: date)
            case let .exercise(deletion):
                try viewModel.deleteExercise(deletion.id, from: deletion.workoutDate)
            case let .set(deletion):
                try viewModel.deleteSet(deletion.setID, from: deletion.exerciseID, on: deletion.workoutDate)
            }
        } catch {
            showsMutationError = true
        }
    }

    private var calendarHeader: some View {
        Group {
            if calendarMode == .week { weekHeader } else { monthHeader }
        }
    }

    private var programLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GymTheme.spacing12) {
                legendItem("Empty", symbol: "circle", color: GymTheme.textSecondary)
                legendItem("Planned", symbol: "circle", color: GymTheme.accentForeground)
                legendItem("Partial", symbol: "circle.lefthalf.filled", color: .orange)
                legendItem("Completed", symbol: "checkmark.circle.fill", color: GymTheme.accentForeground)
                legendItem("Incomplete", symbol: "exclamationmark.circle", color: GymTheme.destructive)
            }
            .font(.caption2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Workout status legend")
    }

    private func legendItem(_ title: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text(title)
                .foregroundStyle(GymTheme.textSecondary)
        }
        .fixedSize()
    }

    private var weekHeader: some View {
        HStack {
            Button {
                moveWeek(by: -1)
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
                moveWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next week")
            .accessibilityIdentifier("programNextWeek")
        }
    }

    private var dateSelector: some View {
        Group {
            if calendarMode == .week {
                HStack(spacing: 2) {
                    ForEach(calendarState.weekDates, id: \.self) { date in
                        dateButton(date)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 2, bottom: 8, trailing: 2))
            } else {
                monthGrid
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { moveMonth(by: -1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                .accessibilityLabel("Previous month")
                .accessibilityIdentifier("programPreviousMonth")
            Spacer()
            Text(monthRangeLabel).font(.headline).accessibilityIdentifier("programMonthHeader")
            Spacer()
            Button { moveMonth(by: 1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                .accessibilityLabel("Next month")
                .accessibilityIdentifier("programNextMonth")
        }
    }

    private var monthGrid: some View {
        let dates = calendarState.monthDates(containing: displayedMonth)
        return VStack(spacing: 6) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 36)), count: 7), spacing: 6) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"].indices, id: \.self) { index in
                    Text(["M", "T", "W", "T", "F", "S", "S"][index])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("programMonthWeekday-\(index)")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Weekdays Monday through Sunday")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 36)), count: 7), spacing: 6) {
                ForEach(dates, id: \.self) { date in monthDateButton(date) }
            }
        }
        .padding(.horizontal, 4)
        .accessibilityIdentifier("programMonthGrid")
    }

    private func monthDateButton(_ date: LocalDate) -> some View {
        let state = calendarState.dayState(for: date)
        let isSelected = date == viewModel.selectedDate
        let isCurrentMonth = date.month == displayedMonth.month && date.year == displayedMonth.year
        let isToday = date == calendarState.currentDate
        return Button { viewModel.select(date) } label: {
            VStack(spacing: 3) {
                Text("\(date.day)").font(.subheadline.weight(isSelected ? .bold : .regular))
                Image(systemName: state.systemImage ?? "circle")
                    .font(.caption2)
                    .foregroundStyle(dayStateColor(state))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isCurrentMonth ? Color.primary : Color.secondary)
            .background(isSelected ? GymTheme.accentSoft : Color.clear, in: RoundedRectangle(cornerRadius: 9))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isSelected ? GymTheme.accentForeground : (isToday ? Color.primary.opacity(0.65) : .clear), lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fullDateLabel(for: date))
        .accessibilityValue("\(state.label)\(isSelected ? ", selected" : "")\(isToday ? ", today" : "")\(isCurrentMonth ? "" : ", outside current month")")
        .accessibilityIdentifier("programMonthDate-\(date.description)")
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
                Image(systemName: state.systemImage ?? "circle")
                .frame(width: 16, height: 16)
                .font(.caption)
                .foregroundStyle(dayStateColor(state))
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .padding(.vertical, 4)
            .background(isSelected ? GymTheme.accentSoft : Color.clear)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? GymTheme.accentForeground : Color.clear, lineWidth: 2)
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
        List {
            VStack(alignment: .leading, spacing: GymTheme.spacing8) {
                HStack(spacing: GymTheme.spacing8) {
                    Text(calendarState.selectedWorkout == nil ? "Plan workout" : "Workout")
                        .font(.headline)
                        .foregroundStyle(GymTheme.textPrimary)
                        .accessibilityLabel(fullDateLabel(for: calendarState.selectedDate))
                        .accessibilityIdentifier("programSelectedDate")
                    Spacer(minLength: 0)
                    if case let .workout(status) = calendarState.selectedDayState {
                        Label(statusLabel(status), systemImage: ProgramDayState.workout(status).systemImage ?? "circle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(dayStateColor(.workout(status)))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(GymTheme.surface, in: Capsule())
                            .accessibilityIdentifier("programWorkoutState")
                    }
                }
                if !isHistorical && calendarState.selectedWorkout != nil {
                    Label("Saved on device", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GymTheme.accentForeground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(GymTheme.accentSoft, in: Capsule())
                        .accessibilityIdentifier("programSavedStatus")
                }
            }
            .listRowBackground(GymTheme.surfaceBase)
            .listRowSeparator(.hidden)
            .frame(maxWidth: .infinity, alignment: .leading)

        if viewModel.workoutLoadState == .loading {
            Section {
                ProgressView("Loading workout")
                    .accessibilityIdentifier("programLoadingState")
            }
        } else if viewModel.workoutLoadState == .unavailable(hasUsableSnapshot: false) {
            Section {
                Text("Workout unavailable right now.")
                    .font(.headline)
                Text("Check your connection. The app will retry automatically.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("programUnavailableState")
            }
        } else {
            if viewModel.workoutLoadState == .unavailable(hasUsableSnapshot: true) {
                Section {
                    Label("Saved workout data is available. Changes will sync when possible.", systemImage: "icloud.slash")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("programSyncUnavailableMessage")
                }
            }

            switch calendarState.selectedDayState {
            case .empty:
                VStack(spacing: GymTheme.spacing16) {
                Image(systemName: isHistorical ? "clock.arrow.circlepath" : "list.clipboard")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(GymTheme.accentForeground)
                    .frame(width: 72, height: 72)
                    .background(GymTheme.accentSoft, in: Circle())
                    .accessibilityHidden(true)
                Text(isHistorical ? "No recorded workout." : "No workout planned yet.")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(GymTheme.textPrimary)
                    .accessibilityIdentifier("programEmptyState")
                Text(isHistorical ? "There is no workout history for this date." : "Create your first workout to get started.")
                    .font(.subheadline)
                    .foregroundStyle(GymTheme.textSecondary)
                    .multilineTextAlignment(.center)
                if !isHistorical {
                    Button("Create workout") {
                        viewModel.createSelectedWorkout()
                    }
                    .buttonStyle(GymPrimaryButtonStyle())
                    .frame(maxWidth: 240)
                    .accessibilityIdentifier("programCreateWorkout")
                }
            }
                .frame(maxWidth: .infinity, minHeight: 280)
            case .workout:
                Group {
                    if orderedExercises.isEmpty {
                        Text("No exercises added yet.")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("programEmptyWorkout")
                    }
                    if isHistorical {
                        ForEach(orderedExercises) { exercise in
                            historyExerciseRow(exercise)
                        }
                    } else {
                        ForEach(orderedExercises) { exercise in
                            exerciseRow(
                                exercise,
                                index: orderedExercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
                            )
                        }

                        Button {
                            activeSheet = .exercisePicker(ExercisePickerRoute(workoutDate: calendarState.selectedDate))
                        } label: {
                            Label("Add exercise", systemImage: "plus")
                        }
                        .buttonStyle(GymPrimaryButtonStyle())
                        .accessibilityIdentifier("programAddExercise")
                    }
                }
            }
        }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(GymTheme.surfaceBase)
    }

    private func historyExerciseRow(_ exercise: WorkoutExercise) -> some View {
        let name = viewModel.exerciseName(for: exercise)
        let sets = viewModel.orderedSets(for: exercise.id, on: calendarState.selectedDate)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                Spacer()
                if exercise.isSkipped {
                    Text("Skipped")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("programHistoryExerciseSkipped-\(exercise.id.rawValue.uuidString)")
                }
            }
            ForEach(Array(sets.enumerated()), id: \.element.id) { setIndex, set in
                historySetRow(
                    set,
                    setIndex: setIndex,
                    exercise: exercise,
                    exerciseName: name
                )
                .id("\(set.id.rawValue.uuidString)-\(set.displayedReps)-\(set.displayedWeight)-\(set.displayedTimeSeconds)-\(set.isCompleted)")
            }
        }
        .accessibilityElement(children: .contain)
        .gymCard()
        .accessibilityIdentifier("programHistoryExercise-\(exercise.id.rawValue.uuidString)")
    }

    @ViewBuilder
    private func historySetRow(
        _ set: WorkoutSet,
        setIndex: Int,
        exercise: WorkoutExercise,
        exerciseName: String
    ) -> some View {
        let value = SetDisplayFormatter(unit: weightUnit).string(
            reps: set.displayedReps,
            weightInKilograms: set.displayedWeight,
            timeSeconds: set.displayedTimeSeconds,
            type: set.displayedType
        )
        let state = exercise.isSkipped
            ? (set.isCompleted ? "Skipped · Completed" : "Skipped")
            : (set.isCompleted ? "Completed" : "Incomplete")
        let valueKind = set.isCompleted ? "Actual" : "Planned"
        let row = HStack(spacing: 8) {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(set.isCompleted ? GymTheme.accentForeground : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Set \(setIndex + 1)")
                Text("\(state) · \(valueKind): \(value)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(minHeight: 44)

        if set.isCompleted {
            Button {
                activeSheet = .historicalActual(HistoricalActualEditorRoute(
                    workoutDate: calendarState.selectedDate,
                    exercise: exercise,
                    workoutSet: set
                ))
            } label: {
                row
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Set \(setIndex + 1) for \(exerciseName)")
            .accessibilityValue("\(state), \(valueKind.lowercased()) \(value)")
            .accessibilityHint("Edit actual results")
            .accessibilityIdentifier("programHistorySet-\(set.id.rawValue.uuidString)")
        } else {
            row
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Set \(setIndex + 1) for \(exerciseName)")
                .accessibilityValue("\(state), \(valueKind.lowercased()) \(value)")
                .accessibilityIdentifier("programHistorySet-\(set.id.rawValue.uuidString)")
        }
    }

    private func exerciseRow(_ exercise: WorkoutExercise, index: Int) -> some View {
        let name = viewModel.exerciseName(for: exercise)
        let sets = visibleSets(for: exercise.id)

        return Section {
            ForEach(Array(sets.enumerated()), id: \.element.id) { setIndex, set in
                HStack(spacing: GymTheme.spacing8) {
                    Button {
                        activeSheet = .setEditor(SetEditorRoute(
                            workoutDate: calendarState.selectedDate,
                            exercise: exercise,
                            set: set
                        ))
                    } label: {
                        HStack(spacing: GymTheme.spacing12) {
                            Text("\(setIndex + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(GymTheme.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(GymTheme.surfaceBase, in: Circle())
                            Text(SetDisplayFormatter(unit: weightUnit).string(
                                reps: set.displayedReps,
                                weightInKilograms: set.displayedWeight,
                                timeSeconds: set.displayedTimeSeconds,
                                type: set.displayedType
                            ))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(GymTheme.textPrimary)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit set \(setIndex + 1) for \(name)")
                    .accessibilityValue(SetDisplayFormatter(unit: weightUnit).string(
                        reps: set.displayedReps,
                        weightInKilograms: set.displayedWeight,
                        timeSeconds: set.displayedTimeSeconds,
                        type: set.displayedType
                    ))
                    .accessibilityIdentifier("programSet-\(exercise.id.rawValue.uuidString)-\(set.id.rawValue.uuidString)")

                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(GymTheme.accentForeground)
                        .frame(width: 44, height: 44)
                        .background(GymTheme.accentSoft, in: RoundedRectangle(cornerRadius: 9))
                        .contentShape(Rectangle())
                        .accessibilityLabel("Drag set \(setIndex + 1) to reorder")
                        .accessibilityHint("Drag up or down")
                        .accessibilityIdentifier("programSetDragHandle-\(set.id.rawValue.uuidString)")
                        .gesture(reorderGesture(for: set.id, in: exercise.id, sets: sets))
                }
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ProgramSetRowFramePreferenceKey.self,
                            value: [set.id: geometry.frame(in: .named(ProgramSetListCoordinateSpace.name))]
                        )
                    }
                }
                .listRowBackground(GymTheme.surfaceGrouped)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        confirmation = .set(PendingSetDeletion(
                            workoutDate: calendarState.selectedDate,
                            exerciseID: exercise.id,
                            setID: set.id,
                            setNumber: setIndex + 1
                        ))
                    }
                    .accessibilityLabel("Delete set \(setIndex + 1)")
                }
            }

            Button {
                addSet(to: exercise.id)
            } label: {
                Label("Add set", systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(GymTheme.accentForeground)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add set to \(name)")
            .accessibilityIdentifier("programAddSet-\(exercise.id.rawValue.uuidString)")
        } header: {
            HStack(spacing: GymTheme.spacing8) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(GymTheme.textPrimary)
                    .textCase(nil)
                    .accessibilityIdentifier("programExercise-\(name)")
                Spacer()
                Text(exerciseSetType(exercise).title)
                    .font(.caption)
                    .foregroundStyle(GymTheme.textSecondary)
                    .textCase(nil)
                Menu {
                    Menu("Set type", systemImage: "slider.horizontal.3") {
                        ForEach(WorkoutSetType.editableCases, id: \.self) { type in
                            Button {
                                setExerciseType(type, for: exercise.id)
                            } label: {
                                if exerciseSetType(exercise) == type {
                                    Label(type.title, systemImage: "checkmark")
                                } else {
                                    Text(type.title)
                                }
                            }
                        }
                    }
                    if orderedExercises.count > 1 {
                        Button("Reorder exercises", systemImage: "arrow.up.arrow.down") {
                            activeSheet = .reorderExercises
                        }
                        .accessibilityIdentifier("programReorderExercises")
                    }
                    Button("Delete", role: .destructive) {
                        confirmation = .exercise(PendingExerciseDeletion(
                            workoutDate: calendarState.selectedDate,
                            id: exercise.id,
                            name: name
                        ))
                    }
                    .accessibilityIdentifier("programExerciseDelete-\(exercise.id.rawValue.uuidString)")
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Actions for \(name), exercise \(index + 1) of \(orderedExercises.count)")
            }
            .accessibilityIdentifier("programExerciseRow-\(exercise.id.rawValue.uuidString)")
        }
    }

    private var weekRangeLabel: String {
        guard let first = calendarState.weekDates.first, let last = calendarState.weekDates.last else { return "Week" }
        return "\(shortDateLabel(for: first)) - \(shortDateLabel(for: last))"
    }

    private var monthRangeLabel: String {
        guard let date = displayedMonth.date(in: calendarState.calendar) else { return "Month" }
        return date.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "en")))
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

    private var calendarState: ProgramCalendarState {
        ProgramCalendarState(
            selectedDate: viewModel.selectedDate,
            currentDate: viewModel.currentDate,
            calendar: viewModel.calendar,
            workouts: viewModel.workouts
        )
    }
    private var orderedExercises: [WorkoutExercise] {
        viewModel.orderedExercises(on: calendarState.selectedDate)
    }

    private func visibleSets(for exerciseID: WorkoutExerciseID) -> [WorkoutSet] {
        let actual = viewModel.orderedSets(for: exerciseID, on: calendarState.selectedDate)
        guard let session = reorderSession, session.exerciseID == exerciseID else { return actual }
        let ids = session.provisionalOrder
        guard
              ids.count == actual.count,
              Set(ids) == Set(actual.map(\.id)) else { return actual }
        let byID = Dictionary(uniqueKeysWithValues: actual.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }
    private var isHistorical: Bool { calendarState.selectedDate < viewModel.currentDate }

    private func dayStateColor(_ state: ProgramDayState) -> Color {
        switch state {
        case .empty: GymTheme.textSecondary.opacity(0.45)
        case .workout(.planned), .workout(.completed): GymTheme.accentForeground
        case .workout(.partial): .orange
        case .workout(.incomplete): GymTheme.destructive
        }
    }

    private func moveWeek(by offset: Int) {
        viewModel.moveWeek(by: offset)
    }

    private func moveMonth(by offset: Int) {
        guard let date = displayedMonth.adding(months: offset, calendar: viewModel.calendar) else { return }
        displayedMonth = date
    }

    private func persistOrder(_ ids: [WorkoutExerciseID]) {
        do {
            try viewModel.reorderExercises(ids, on: calendarState.selectedDate)
        } catch {
            showsMutationError = true
        }
    }

    private func persistSetOrder(_ ids: [WorkoutSetID], in exerciseID: WorkoutExerciseID) {
        do {
            try viewModel.reorderSets(ids, in: exerciseID, on: calendarState.selectedDate)
        } catch {
            showsMutationError = true
        }
    }

    private func addSet(to exerciseID: WorkoutExerciseID) {
        do {
            try viewModel.addSet(to: exerciseID, on: calendarState.selectedDate)
        } catch {
            showsMutationError = true
        }
    }

    private func exerciseSetType(_ exercise: WorkoutExercise) -> WorkoutSetType {
        let configured = visibleSets(for: exercise.id).first {
            $0.reps > 0 || $0.weight > 0 || $0.timeSeconds > 0
        }
        return configured?.type ?? visibleSets(for: exercise.id).first?.type ?? .repsOnly
    }

    private func setExerciseType(_ type: WorkoutSetType, for exerciseID: WorkoutExerciseID) {
        do {
            try viewModel.setExerciseType(type, for: exerciseID, on: calendarState.selectedDate)
        } catch {
            showsMutationError = true
        }
    }

    private func reorderGesture(
        for setID: WorkoutSetID,
        in exerciseID: WorkoutExerciseID,
        sets: [WorkoutSet]
    ) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named(ProgramSetListCoordinateSpace.name))
            .updating($isReorderGestureActive) { _, isActive, _ in
                isActive = true
            }
            .onChanged { value in
                if reorderSession == nil {
                    reorderSession = ProgramSetReorderSession(
                        exerciseID: exerciseID,
                        setID: setID,
                        originalOrder: sets.map(\.id)
                    )
                }
                guard var session = reorderSession,
                      session.exerciseID == exerciseID,
                      session.setID == setID else { return }
                session.update(dragLocationY: value.location.y, rowFrames: setRowFrames)
                withAnimation(.easeInOut(duration: 0.16)) {
                    reorderSession = session
                }
            }
            .onEnded { _ in
                guard let session = reorderSession,
                      session.exerciseID == exerciseID,
                      session.setID == setID else { return }
                if session.hasChanged {
                    persistSetOrder(session.provisionalOrder, in: exerciseID)
                }
                cancelSetReorder()
            }
    }

    private func cancelSetReorder() {
        withAnimation(.easeOut(duration: 0.14)) {
            reorderSession = nil
        }
    }
}

struct ProgramSetReorderSession: Equatable {
    let exerciseID: WorkoutExerciseID
    let setID: WorkoutSetID
    let originalOrder: [WorkoutSetID]
    private(set) var provisionalOrder: [WorkoutSetID]

    init(exerciseID: WorkoutExerciseID, setID: WorkoutSetID, originalOrder: [WorkoutSetID]) {
        self.exerciseID = exerciseID
        self.setID = setID
        self.originalOrder = originalOrder
        self.provisionalOrder = originalOrder
    }

    var hasChanged: Bool { provisionalOrder != originalOrder }

    mutating func update(dragLocationY: CGFloat, rowFrames: [WorkoutSetID: CGRect]) {
        guard let targetSetID = provisionalOrder.min(by: {
            abs((rowFrames[$0]?.midY ?? .greatestFiniteMagnitude) - dragLocationY)
                < abs((rowFrames[$1]?.midY ?? .greatestFiniteMagnitude) - dragLocationY)
        }), rowFrames[targetSetID] != nil else { return }
        update(targetSetID: targetSetID)
    }

    mutating func update(targetSetID: WorkoutSetID) {
        guard targetSetID != setID,
              let sourceIndex = provisionalOrder.firstIndex(of: setID),
              let targetIndex = provisionalOrder.firstIndex(of: targetSetID) else { return }
        provisionalOrder.remove(at: sourceIndex)
        provisionalOrder.insert(setID, at: min(targetIndex, provisionalOrder.count))
    }

    mutating func cancel() {
        provisionalOrder = originalOrder
    }
}

private enum ProgramSetListCoordinateSpace {
    static let name = "program-set-list"
}

private struct ProgramSetRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [WorkoutSetID: CGRect] = [:]

    static func reduce(value: inout [WorkoutSetID: CGRect], nextValue: () -> [WorkoutSetID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

private struct ExerciseReorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exercises: [WorkoutExercise]
    let exerciseName: (WorkoutExercise) -> String
    let onReorder: ([WorkoutExerciseID]) -> Void

    init(
        exercises: [WorkoutExercise],
        exerciseName: @escaping (WorkoutExercise) -> String,
        onReorder: @escaping ([WorkoutExerciseID]) -> Void
    ) {
        _exercises = State(initialValue: exercises)
        self.exerciseName = exerciseName
        self.onReorder = onReorder
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(exercises) { exercise in
                    Text(exerciseName(exercise))
                        .accessibilityLabel("Reorder \(exerciseName(exercise))")
                        .accessibilityIdentifier("programReorderExercise-\(exerciseName(exercise))")
                }
                .onMove { source, destination in
                    exercises.move(fromOffsets: source, toOffset: destination)
                    onReorder(exercises.map(\.id))
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Reorder exercises")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done", action: dismiss.callAsFunction) } }
        }
    }
}

private enum CalendarMode: CaseIterable, Hashable {
    case week, month

    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        }
    }
}

private struct ExercisePickerRoute: Identifiable {
    let workoutDate: LocalDate
    var id: LocalDate { workoutDate }
}

private struct HistoricalActualEditorRoute: Identifiable {
    let workoutDate: LocalDate
    let exercise: WorkoutExercise
    let workoutSet: WorkoutSet

    var id: WorkoutSetID { workoutSet.id }
}

private struct PendingExerciseDeletion {
    let workoutDate: LocalDate
    let id: WorkoutExerciseID
    let name: String
}

private struct PendingSetDeletion {
    let workoutDate: LocalDate
    let exerciseID: WorkoutExerciseID
    let setID: WorkoutSetID
    let setNumber: Int
}

private struct SetEditorRoute: Identifiable {
    let workoutDate: LocalDate
    let exercise: WorkoutExercise
    let set: WorkoutSet?

    var id: String {
        "\(workoutDate.description)-\(exercise.id.rawValue.uuidString)-\(set?.id.rawValue.uuidString ?? "new")"
    }
}

private struct CopyWorkoutRoute: Identifiable {
    let destinationDate: LocalDate

    var id: LocalDate { destinationDate }
}

private struct RepeatWorkoutRoute: Identifiable {
    let sourceDate: LocalDate
    var id: LocalDate { sourceDate }
}

private enum ProgramSheetRoute: Identifiable {
    case exercisePicker(ExercisePickerRoute)
    case setEditor(SetEditorRoute)
    case historicalActual(HistoricalActualEditorRoute)
    case copy(CopyWorkoutRoute)
    case repeatWorkout(RepeatWorkoutRoute)
    case reorderExercises

    var id: String {
        switch self {
        case let .exercisePicker(route): "exercise-picker-\(route.id)"
        case let .setEditor(route): "set-editor-\(route.id)"
        case let .historicalActual(route): "actual-editor-\(route.id.rawValue.uuidString)"
        case let .copy(route): "copy-\(route.id)"
        case let .repeatWorkout(route): "repeat-\(route.id)"
        case .reorderExercises: "reorder-exercises"
        }
    }
}

private enum ProgramConfirmation {
    case workout(LocalDate)
    case exercise(PendingExerciseDeletion)
    case set(PendingSetDeletion)

    var title: String {
        switch self {
        case .workout: "Delete this workout?"
        case let .exercise(deletion): "Delete \(deletion.name)?"
        case .set: "Delete this set?"
        }
    }

    var message: String {
        switch self {
        case .workout:
            "All exercises, sets, and recorded results for this date will be removed."
        case .exercise:
            "Its configured sets will be removed. You can re-add the exercise later."
        case .set:
            "This set will be removed from the workout."
        }
    }

    var destructiveActionTitle: String {
        switch self {
        case .workout: "Delete workout"
        case .exercise: "Delete"
        case .set: "Delete set"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .workout: "programConfirmDeleteWorkout"
        case .exercise: "programConfirmDeleteExercise"
        case .set: "programConfirmDeleteSet"
        }
    }
}

private struct CopyWorkoutSheet: View {
    private enum DestinationChoice: String, CaseIterable, Identifiable {
        case add = "Add exercises"
        case replace = "Replace exercises"

        var id: Self { self }
        var strategy: WorkoutCopyStrategy {
            self == .add ? .addExercises : .replaceExercises
        }
    }

    let destinationDate: LocalDate
    let currentDate: LocalDate
    let calendar: Calendar
    let availableWorkouts: [Workout]
    let destinationState: (LocalDate) -> WorkoutCopyDestinationState
    let onCopy: (LocalDate, LocalDate, WorkoutCopyStrategy) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSourceDateValue: Date
    @State private var sourceMonth: LocalDate
    @State private var destination: Date
    @State private var destinationChoice: DestinationChoice = .add
    @State private var showsReplaceConfirmation = false
    @State private var showsCopyError = false

    init(
        destinationDate: LocalDate,
        currentDate: LocalDate,
        calendar: Calendar,
        availableWorkouts: [Workout],
        destinationState: @escaping (LocalDate) -> WorkoutCopyDestinationState,
        onCopy: @escaping (LocalDate, LocalDate, WorkoutCopyStrategy) throws -> Void
    ) {
        self.destinationDate = destinationDate
        self.currentDate = currentDate
        self.calendar = calendar
        self.availableWorkouts = availableWorkouts
        self.destinationState = destinationState
        self.onCopy = onCopy
        let initialSource = availableWorkouts
            .filter { $0.localDate != destinationDate }
            .sorted { $0.localDate > $1.localDate }
            .first?.localDate ?? destinationDate
        _selectedSourceDateValue = State(initialValue: initialSource.date(in: calendar) ?? Date())
        _sourceMonth = State(initialValue: initialSource)
        _destination = State(initialValue: destinationDate.date(in: calendar) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Button { moveSourceMonth(by: -1) } label: {
                            Image(systemName: "chevron.left").frame(width: 36, height: 36)
                        }
                        .accessibilityLabel("Previous source month")
                        Spacer()
                        Text(sourceMonthLabel)
                            .font(.headline)
                        Spacer()
                        Button { moveSourceMonth(by: 1) } label: {
                            Image(systemName: "chevron.right").frame(width: 36, height: 36)
                        }
                        .accessibilityLabel("Next source month")
                    }

                    sourceCalendar

                    HStack(spacing: 12) {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                            .frame(width: 38, height: 38)
                            .foregroundStyle(GymTheme.accentForeground)
                            .background(GymTheme.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(fullDateLabel(for: selectedSourceDate))
                                .font(.headline)
                                .accessibilityIdentifier("copyWorkoutSourceDate")
                            Text(sourceSummary)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("copyWorkoutSummary")
                        }
                    }
                } header: {
                    GymSectionHeader(title: "Source")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("copyWorkoutSourcePicker")

                if availableSourceWorkouts.isEmpty {
                    if !sourceExists {
                        Text("No other workout is available to copy.")
                            .font(.subheadline)
                            .foregroundStyle(GymTheme.destructive)
                            .accessibilityIdentifier("copyWorkoutSourceMessage")
                    }
                }

                Section {
                    DatePicker("Destination date", selection: $destination, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .accessibilityIdentifier("copyWorkoutDestination")

                    Text(destinationSummary)
                        .font(.subheadline)
                        .foregroundStyle(destinationMessage == nil ? GymTheme.textSecondary : GymTheme.destructive)
                        .accessibilityIdentifier("copyWorkoutDestinationMessage")

                    if case .populated = currentDestinationState, destinationMessage == nil {
                        Picker("Existing workout", selection: $destinationChoice) {
                            ForEach(DestinationChoice.allCases) { choice in
                                Text(choice.rawValue).tag(choice)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("copyWorkoutDestinationChoice")
                    }
                } header: {
                    GymSectionHeader(title: "Destination")
                }

            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button {
                    requestCopy()
                } label: {
                    Text(copyActionTitle)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(GymPrimaryButtonStyle())
                .disabled(destinationMessage != nil)
                .opacity(destinationMessage != nil ? 0.55 : 1)
                .accessibilityIdentifier("copyWorkoutAction")
                .padding(.horizontal, GymTheme.spacing16)
                .padding(.vertical, GymTheme.spacing12)
                .frame(maxWidth: .infinity)
                .background(GymTheme.surfaceBase)
            }
            .gymPageBackground()
            .navigationTitle("Copy workout")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("copyWorkoutSheet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(GymTheme.accentForeground)
                        .accessibilityIdentifier("copyWorkoutCancel")
                }
            }
            .alert("Workout could not be copied", isPresented: $showsCopyError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Review the source and destination, then try again.")
            }
            .alert("Replace exercises?", isPresented: $showsReplaceConfirmation) {
                Button("Replace exercises", role: .destructive) {
                    performCopy(strategy: .replaceExercises)
                }
                .accessibilityIdentifier("copyWorkoutConfirmReplace")
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Existing exercises and their recorded results on \(fullDateLabel(for: selectedDestinationDate)) will be removed.")
            }
        }
    }

    private var selectedSourceDate: LocalDate {
        LocalDate(date: selectedSourceDateValue, calendar: calendar)
    }

    private var selectedDestinationDate: LocalDate {
        LocalDate(date: destination, calendar: calendar)
    }

    private var availableSourceWorkouts: [Workout] {
        availableWorkouts.filter { $0.localDate != selectedDestinationDate }
    }

    private var sourceExists: Bool {
        availableWorkouts.contains(where: { $0.localDate == selectedSourceDate })
    }

    private var currentDestinationState: WorkoutCopyDestinationState {
        destinationState(selectedDestinationDate)
    }

    private var sourceSummary: String {
        guard let source = availableWorkouts.first(where: { $0.localDate == selectedSourceDate }) else {
            return "No workout on this date"
        }
        let exercises = source.exercises.count
        let sets = source.exercises.flatMap(\.sets).count
        return "\(exercises) \(exercises == 1 ? "exercise" : "exercises") · \(sets) \(sets == 1 ? "set" : "sets")"
    }

    private var destinationMessage: String? {
        if !sourceExists {
            return "Choose a source date that has a workout."
        }
        if selectedDestinationDate == selectedSourceDate {
            return "Choose a different date."
        }
        return nil
    }

    private var destinationSummary: String {
        if let destinationMessage { return destinationMessage }
        switch currentDestinationState {
        case .missing:
            return "A new independent planned workout will be created."
        case .empty:
            return "The empty workout will receive an independent plan copy."
        case let .populated(exerciseCount, setCount):
            return "Existing: \(exerciseCount) \(exerciseCount == 1 ? "exercise" : "exercises") · \(setCount) \(setCount == 1 ? "set" : "sets")."
        }
    }

    private var copyActionTitle: String {
        if case .populated = currentDestinationState {
            return destinationChoice.rawValue
        }
        return "Copy exercises"
    }

    private var sourceMonthLabel: String {
        guard let date = sourceMonth.date(in: calendar) else { return "Source month" }
        return date.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "en")))
    }

    private var sourceCalendar: some View {
        let state = ProgramCalendarState(
            selectedDate: selectedSourceDate,
            currentDate: currentDate,
            calendar: calendar,
            workouts: availableWorkouts
        )
        let dates = state.monthDates(containing: sourceMonth)
        return VStack(spacing: 6) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 32)), count: 7), spacing: 4) {
                ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(GymTheme.textSecondary)
                }
                ForEach(dates, id: \.self) { date in
                    sourceDateButton(date, state: state.dayState(for: date))
                }
            }
        }
    }

    private func sourceDateButton(_ date: LocalDate, state: ProgramDayState) -> some View {
        let workout = availableWorkouts.first(where: { $0.localDate == date })
        let isAvailable = workout != nil && date != selectedDestinationDate
        let isSelected = date == selectedSourceDate
        let isCurrentMonth = date.month == sourceMonth.month && date.year == sourceMonth.year
        return Button {
            selectedSourceDateValue = date.date(in: calendar) ?? selectedSourceDateValue
        } label: {
            VStack(spacing: 2) {
                Text("\(date.day)")
                    .font(.caption.weight(isSelected ? .bold : .regular))
                Image(systemName: workout == nil ? "circle" : (state.systemImage ?? "circle"))
                    .font(.caption2)
                    .opacity(workout == nil ? 0 : 1)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .foregroundStyle(isAvailable ? sourceStateColor(state) : GymTheme.textSecondary.opacity(0.45))
            .background(isSelected ? GymTheme.accentSoft : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .opacity(isCurrentMonth ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .accessibilityLabel(fullDateLabel(for: date))
        .accessibilityValue(workout.map { "\(state.label), \($0.exercises.count) exercises, \($0.exercises.flatMap(\.sets).count) sets" } ?? "No workout")
        .accessibilityIdentifier("copyWorkoutSourceDate-\(date.description)")
    }

    private func moveSourceMonth(by offset: Int) {
        guard let next = sourceMonth.adding(months: offset, calendar: calendar) else { return }
        sourceMonth = next
    }

    private func sourceStateColor(_ state: ProgramDayState) -> Color {
        switch state {
        case .empty: GymTheme.textSecondary.opacity(0.45)
        case .workout(.planned), .workout(.completed): GymTheme.accentForeground
        case .workout(.partial): .orange
        case .workout(.incomplete): GymTheme.destructive
        }
    }

    private func requestCopy() {
        guard destinationMessage == nil else { return }
        if case .populated = currentDestinationState, destinationChoice == .replace {
            showsReplaceConfirmation = true
        } else {
            performCopy(strategy: currentDestinationState.isPopulated ? destinationChoice.strategy : .replaceExercises)
        }
    }

    private func performCopy(strategy: WorkoutCopyStrategy) {
        do {
            try onCopy(selectedSourceDate, selectedDestinationDate, strategy)
            dismiss()
        } catch {
            showsCopyError = true
        }
    }

    private func fullDateLabel(for date: LocalDate) -> String {
        guard let value = date.date(in: calendar) else { return date.description }
        return value.formatted(.dateTime.weekday(.wide).month(.wide).day().year().locale(Locale(identifier: "en")))
    }
}

private extension WorkoutCopyDestinationState {
    var isPopulated: Bool {
        if case .populated = self { return true }
        return false
    }
}

private struct RepeatWorkoutSheet: View {
    private enum Duration: String, CaseIterable, Identifiable {
        case fourWeeks = "4 weeks"
        case eightWeeks = "8 weeks"
        case untilDate = "Until date"

        var id: Self { self }
        var weeks: Int? {
            switch self {
            case .fourWeeks: 4
            case .eightWeeks: 8
            case .untilDate: nil
            }
        }
    }

    let sourceDate: LocalDate
    let exerciseCount: Int
    let setCount: Int
    let calendar: Calendar
    let isDestinationOccupied: (LocalDate) -> Bool
    let onRepeat: (LocalDate, WorkoutRepeatCadence) throws -> WorkoutRepeatResult

    @Environment(\.dismiss) private var dismiss
    @State private var duration: Duration = .fourWeeks
    @State private var cadenceWeeks = 1
    @State private var untilDate: Date
    @State private var showsRepeatError = false

    init(
        sourceDate: LocalDate,
        exerciseCount: Int,
        setCount: Int,
        calendar: Calendar,
        isDestinationOccupied: @escaping (LocalDate) -> Bool,
        onRepeat: @escaping (LocalDate, WorkoutRepeatCadence) throws -> WorkoutRepeatResult
    ) {
        self.sourceDate = sourceDate
        self.exerciseCount = exerciseCount
        self.setCount = setCount
        self.calendar = calendar
        self.isDestinationOccupied = isDestinationOccupied
        self.onRepeat = onRepeat
        _untilDate = State(initialValue: sourceDate.adding(weeks: 4, calendar: calendar)?.date(in: calendar) ?? Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GymSectionHeader(title: "Source workout")
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3)
                            .frame(width: 38, height: 38)
                            .foregroundStyle(GymTheme.accentForeground)
                            .background(GymTheme.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                    Text(fullDateLabel(for: sourceDate))
                                .font(.headline)
                        .accessibilityIdentifier("repeatWorkoutSourceDate")
                    Text("\(exerciseCount) \(exerciseCount == 1 ? "exercise" : "exercises") · \(setCount) \(setCount == 1 ? "set" : "sets")")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("repeatWorkoutSourceSummary")
                        }
                        Spacer()
                    }
                    .gymCard()

                    GymSectionHeader(title: "Schedule")
                    VStack(alignment: .leading, spacing: 14) {
                    Text("Cadence").font(.subheadline.weight(.medium))
                    Picker("Cadence", selection: $cadenceWeeks) {
                        ForEach(1...4, id: \.self) { weeks in
                            Text(weeks == 1 ? "Every week" : "Every \(weeks) weeks").tag(weeks)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("repeatWorkoutCadence")
                    Divider()
                    Text("Duration").font(.subheadline.weight(.medium))
                    Picker("Duration", selection: $duration) {
                        ForEach(Duration.allCases) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("repeatWorkoutDuration")
                    if duration == .untilDate {
                        DatePicker("Repeat until", selection: $untilDate, displayedComponents: .date)
                            .accessibilityIdentifier("repeatWorkoutUntilDate")
                    }
                    }
                    .gymCard()

                    GymSectionHeader(title: "Result")
                    VStack(alignment: .leading, spacing: 8) {
                    Text(scheduleSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("repeatWorkoutSummary")
                    ForEach(occupiedDates, id: \.self) { date in
                        Text("Skip existing workout: \(fullDateLabel(for: date))")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("repeatWorkoutSkip-\(date.description)")
                    }
                    }
                    .gymCard()

                    Button {
                        do {
                            _ = try onRepeat(endDate, WorkoutRepeatCadence(intervalWeeks: cadenceWeeks))
                            dismiss()
                        } catch {
                            showsRepeatError = true
                        }
                    } label: {
                        Text("Create")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(GymPrimaryButtonStyle())
                    .disabled(candidateDates.isEmpty || availableDates.isEmpty)
                    .opacity(candidateDates.isEmpty || availableDates.isEmpty ? 0.55 : 1)
                    .accessibilityIdentifier("repeatWorkoutAction")
                }
                .padding(GymTheme.spacing16)
            }
            .gymPageBackground()
            .navigationTitle("Repeat workout")
            .navigationBarTitleDisplayMode(.large)
            .accessibilityIdentifier("repeatWorkoutSheet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(GymTheme.accentForeground)
                        .accessibilityIdentifier("repeatWorkoutCancel")
                }
            }
            .alert("Workout could not be repeated", isPresented: $showsRepeatError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Choose another duration and try again.")
            }
        }
    }

    private var endDate: LocalDate {
        if let weeks = duration.weeks {
            return sourceDate.adding(weeks: weeks, calendar: calendar) ?? sourceDate
        }
        return LocalDate(date: untilDate, calendar: calendar)
    }

    private var candidateDates: [LocalDate] {
        guard endDate > sourceDate else { return [] }
        var dates: [LocalDate] = []
        var date = sourceDate
        while let nextDate = date.adding(weeks: cadenceWeeks, calendar: calendar), nextDate <= endDate {
            dates.append(nextDate)
            date = nextDate
        }
        return dates
    }

    private var availableDates: [LocalDate] {
        candidateDates.filter { !isDestinationOccupied($0) }
    }

    private var occupiedDates: [LocalDate] {
        candidateDates.filter { isDestinationOccupied($0) }
    }

    private var scheduleSummary: String {
        guard !candidateDates.isEmpty else {
            return "Choose an end date that includes at least one repetition."
        }
        let occupiedCount = occupiedDates.count
        guard !availableDates.isEmpty else {
            return "Every selected week already has a workout. Nothing will be replaced."
        }
        if occupiedCount > 0 {
            return "\(availableDates.count) \(availableDates.count == 1 ? "workout" : "workouts") will be created. \(occupiedCount) occupied \(occupiedCount == 1 ? "week" : "weeks") will be skipped."
        }
        return "\(availableDates.count) independent \(availableDates.count == 1 ? "workout" : "workouts") will be created."
    }

    private func fullDateLabel(for date: LocalDate) -> String {
        guard let value = date.date(in: calendar) else { return date.description }
        return value.formatted(.dateTime.weekday(.wide).month(.wide).day().year().locale(Locale(identifier: "en")))
    }
}

private struct ProgramSetEditorSheet: View {
    let set: WorkoutSet?
    let exerciseName: String
    let weightUnit: WeightUnit
    let onSave: (Int, Double, Int) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var repsText: String
    @State private var weightText: String
    @State private var timeText: String
    @State private var showsValidationError = false
    private let initialRepsText: String
    private let initialWeightText: String
    private let initialTimeText: String

    init(
        set: WorkoutSet?,
        exerciseName: String,
        weightUnit: WeightUnit,
        onSave: @escaping (Int, Double, Int) throws -> Void
    ) {
        self.set = set
        self.exerciseName = exerciseName
        self.weightUnit = weightUnit
        self.onSave = onSave
        let repsText = String(set?.reps ?? 0) == "0" ? "" : String(set?.reps ?? 0)
        let displayWeight = weightUnit.displayWeight(fromCanonicalKilograms: set?.weight ?? 0)
        let weightText = displayWeight == 0 ? "" : displayWeight.formatted(.number.precision(.fractionLength(0...2)))
        let timeText = String(set?.timeSeconds ?? 0) == "0" ? "" : String(set?.timeSeconds ?? 0)
        initialRepsText = repsText
        initialWeightText = weightText
        initialTimeText = timeText
        _repsText = State(initialValue: repsText)
        _weightText = State(initialValue: weightText)
        _timeText = State(initialValue: timeText)
    }

    private var reps: Int { Int(repsText) ?? 0 }
    private var weight: Double { Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var timeSeconds: Int { Int(timeText) ?? 0 }
    private var inputsAreValid: Bool {
        (repsText.isEmpty || Int(repsText) != nil)
            && (timeText.isEmpty || Int(timeText) != nil)
            && (weightText.isEmpty || Double(weightText.replacingOccurrences(of: ",", with: ".")) != nil)
    }
    private var type: WorkoutSetType { self.set?.type ?? .repsOnly }
    private var supportsReps: Bool { type != .timed }
    private var supportsWeight: Bool { type == .weighted || type == .legacyMixed }
    private var supportsTime: Bool { type == .timed || type == .legacyMixed }
    private var hasUnsavedChanges: Bool {
        repsText != initialRepsText || weightText != initialWeightText || timeText != initialTimeText
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(set?.isCompleted == true ? "\(exerciseName) plan" : exerciseName) {
                    LabeledContent("Reps") {
                        TextField("0", text: $repsText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .disabled(!supportsReps)
                            .accessibilityIdentifier("programSetEditorReps")
                    }
                    LabeledContent("Weight (\(weightUnit.rawValue))") {
                        TextField("0", text: $weightText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .disabled(!supportsWeight)
                            .accessibilityIdentifier("programSetEditorWeight")
                    }
                    LabeledContent("Time") {
                        TextField("0", text: $timeText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .disabled(!supportsTime)
                            .accessibilityIdentifier("programSetEditorTime")
                    }
                }
            }
            .navigationTitle(set?.isCompleted == true ? "Edit plan" : "Edit set")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard inputsAreValid else { showsValidationError = true; return }
                        do {
                            try onSave(reps, weightUnit.canonicalKilograms(fromDisplayWeight: weight), timeSeconds)
                            dismiss()
                        } catch {
                            showsValidationError = true
                        }
                    }
                    .accessibilityIdentifier("programSetEditorSave")
                }
            }
            .alert("Set values must be non-negative", isPresented: $showsValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enter valid reps, weight, and time values.")
            }
            .interactiveDismissDisabled(hasUnsavedChanges)
        }
    }
}

private struct HistoricalActualEditorSheet: View {
    let route: HistoricalActualEditorRoute
    let weightUnit: WeightUnit
    let onSave: (Int, Double, Int) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var repsText: String
    @State private var weightText: String
    @State private var timeText: String
    @State private var showsValidationError = false
    @State private var showsSaveError = false
    private let initialRepsText: String
    private let initialWeightText: String
    private let initialTimeText: String

    init(
        route: HistoricalActualEditorRoute,
        weightUnit: WeightUnit,
        onSave: @escaping (Int, Double, Int) throws -> Void
    ) {
        self.route = route
        self.weightUnit = weightUnit
        self.onSave = onSave
        let repsText = String(route.workoutSet.displayedReps) == "0" ? "" : String(route.workoutSet.displayedReps)
        let displayWeight = weightUnit.displayWeight(fromCanonicalKilograms: route.workoutSet.displayedWeight)
        let weightText = displayWeight == 0 ? "" : displayWeight.formatted(.number.precision(.fractionLength(0...2)))
        let timeText = String(route.workoutSet.displayedTimeSeconds) == "0" ? "" : String(route.workoutSet.displayedTimeSeconds)
        initialRepsText = repsText
        initialWeightText = weightText
        initialTimeText = timeText
        _repsText = State(initialValue: repsText)
        _weightText = State(initialValue: weightText)
        _timeText = State(initialValue: timeText)
    }

    private var reps: Int { Int(repsText) ?? 0 }
    private var weight: Double { Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var timeSeconds: Int { Int(timeText) ?? 0 }
    private var inputsAreValid: Bool {
        (repsText.isEmpty || Int(repsText) != nil)
            && (timeText.isEmpty || Int(timeText) != nil)
            && (weightText.isEmpty || Double(weightText.replacingOccurrences(of: ",", with: ".")) != nil)
    }
    private var hasUnsavedChanges: Bool {
        repsText != initialRepsText || weightText != initialWeightText || timeText != initialTimeText
    }
    private var supportsReps: Bool { route.workoutSet.displayedType != .timed }
    private var supportsWeight: Bool {
        route.workoutSet.displayedType == .weighted || route.workoutSet.displayedType == .legacyMixed
    }
    private var supportsTime: Bool {
        route.workoutSet.displayedType == .timed || route.workoutSet.displayedType == .legacyMixed
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Actual results") {
                    Text(route.workoutSet.displayedType.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    LabeledContent("Reps") {
                        TextField("0", text: $repsText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .disabled(!supportsReps)
                            .accessibilityIdentifier("programHistoryActualEditorReps")
                    }
                    LabeledContent("Weight (\(weightUnit.rawValue))") {
                        TextField("0", text: $weightText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .disabled(!supportsWeight)
                            .accessibilityIdentifier("programHistoryActualEditorWeight")
                    }
                    LabeledContent("Time") {
                        TextField("0", text: $timeText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .disabled(!supportsTime)
                            .accessibilityIdentifier("programHistoryActualEditorTime")
                    }
                }
            }
            .navigationTitle("Edit actual")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("programHistoryActualEditorCancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard inputsAreValid else { showsValidationError = true; return }
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
                    .accessibilityIdentifier("programHistoryActualEditorSave")
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
            .interactiveDismissDisabled(hasUnsavedChanges)
        }
    }
}
