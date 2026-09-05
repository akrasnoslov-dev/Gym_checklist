import Foundation
import SwiftUI

struct ProgramView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let weightUnit: WeightUnit
    // SwiftUI's static List rows do not reliably redraw this calendar from an
    // observed-object mutation. This is a rendering mirror of the view-model
    // selection; mutations in either direction are synchronized below.
    @State private var displayedSelectedDate: LocalDate
    @State private var displayedMonth: LocalDate
    @State private var calendarMode: CalendarMode = .week
    @State private var exercisePickerRoute: ExercisePickerRoute?
    @State private var setEditorRoute: SetEditorRoute?
    @State private var historicalActualEditorRoute: HistoricalActualEditorRoute?
    @State private var copyWorkoutRoute: CopyWorkoutRoute?
    @State private var repeatWorkoutRoute: RepeatWorkoutRoute?
    @State private var pendingDeletion: PendingExerciseDeletion?
    @State private var pendingWorkoutDeletion: LocalDate?
    @State private var showsMutationError = false

    init(viewModel: WorkoutViewModel, weightUnit: WeightUnit) {
        self.viewModel = viewModel
        self.weightUnit = weightUnit
        _displayedSelectedDate = State(initialValue: viewModel.selectedDate)
        _displayedMonth = State(initialValue: viewModel.selectedDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 8) {
                        Picker("Program view", selection: $calendarMode) {
                            ForEach(CalendarMode.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .accessibilityIdentifier("programViewMode")
                        calendarHeader
                        dateSelector
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // Program navigation must update both the date controls
                    // and the selected day's content. A List keeps its static
                    // rows alive across these state changes (and obscures
                    // sibling controls from accessibility), so this screen
                    // intentionally uses one dynamic scroll hierarchy.
                    ForEach([displayedSelectedDate], id: \.self) { _ in
                        selectedDateSections
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Program")
            .accessibilityIdentifier("programScreen")
            .onAppear {
                displayedSelectedDate = viewModel.selectedDate
                displayedMonth = viewModel.selectedDate
            }
            .onChange(of: displayedSelectedDate) { _, selectedDate in
                viewModel.select(selectedDate)
                displayedMonth = selectedDate
            }
            .onChange(of: viewModel.selectedDate) { _, selectedDate in
                if displayedSelectedDate != selectedDate {
                    displayedSelectedDate = selectedDate
                }
            }
            .toolbar {
                if !isHistorical, let workout = calendarState.selectedWorkout {
                    Menu {
                        Button {
                            copyWorkoutRoute = CopyWorkoutRoute(
                                sourceDate: workout.localDate,
                                exerciseCount: workout.exercises.count,
                                setCount: workout.exercises.flatMap(\.sets).count
                            )
                        } label: { Label("Copy workout", systemImage: "doc.on.doc") }
                        .accessibilityIdentifier("programCopyWorkout")
                        Button {
                            repeatWorkoutRoute = RepeatWorkoutRoute(sourceDate: workout.localDate)
                        } label: { Label("Repeat workout", systemImage: "arrow.triangle.2.circlepath") }
                        .accessibilityIdentifier("programRepeatWorkout")
                        Divider()
                        Button("Delete workout", systemImage: "trash", role: .destructive) {
                            pendingWorkoutDeletion = calendarState.selectedDate
                        }
                        .accessibilityIdentifier("programDeleteWorkout")
                    } label: {
                        Label("Workout actions", systemImage: "ellipsis.circle")
                    }
                    .accessibilityIdentifier("programWorkoutActions")
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
            .sheet(item: $setEditorRoute) { route in
                ProgramSetEditorSheet(
                    set: route.set,
                    exerciseName: viewModel.exerciseName(for: route.exercise),
                    weightUnit: weightUnit,
                    onSave: { reps, weight, timeSeconds, type in
                        guard let set = route.set else { return }
                        try viewModel.editSet(
                            set.id,
                            in: route.exercise.id,
                            on: route.workoutDate,
                            reps: reps,
                            weight: weight,
                            timeSeconds: timeSeconds,
                            type: type
                        )
                    },
                    onDelete: {
                        guard let set = route.set else { return }
                        try viewModel.deleteSet(
                            set.id,
                            from: route.exercise.id,
                            on: route.workoutDate
                        )
                    }
                )
            }
            .sheet(item: $historicalActualEditorRoute) { route in
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
            }
            .sheet(item: $copyWorkoutRoute) { route in
                CopyWorkoutSheet(
                    sourceDate: route.sourceDate,
                    exerciseCount: route.exerciseCount,
                    setCount: route.setCount,
                    calendar: calendarState.calendar,
                    isDestinationOccupied: { viewModel.hasWorkout(on: $0) },
                    onCopy: { destinationDate in
                        try viewModel.copyWorkout(from: route.sourceDate, to: destinationDate)
                    }
                )
            }
            .sheet(item: $repeatWorkoutRoute) { route in
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
            .confirmationDialog(
                "Delete this workout?",
                isPresented: deleteWorkoutConfirmationBinding,
                titleVisibility: .visible
            ) {
                Button("Delete workout", role: .destructive) {
                    if let pendingWorkoutDeletion { deleteWorkout(on: pendingWorkoutDeletion) }
                    pendingWorkoutDeletion = nil
                }
                .accessibilityIdentifier("programConfirmDeleteWorkout")
                Button("Cancel", role: .cancel) { pendingWorkoutDeletion = nil }
            } message: {
                Text("All exercises, sets, and recorded results for this date will be removed.")
            }
        }
    }

    private var calendarHeader: some View {
        Group {
            if calendarMode == .week { weekHeader } else { monthHeader }
        }
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
        let isSelected = date == displayedSelectedDate
        let isCurrentMonth = date.month == displayedMonth.month && date.year == displayedMonth.year
        let isToday = date == calendarState.currentDate
        return Button { displayedSelectedDate = date } label: {
            VStack(spacing: 3) {
                Text("\(date.day)").font(.subheadline.weight(isSelected ? .bold : .regular))
                Image(systemName: state.systemImage ?? "circle")
                    .font(.caption2)
                    .foregroundStyle(state.systemImage == nil ? Color.secondary.opacity(0.45) : GymTheme.accentForeground)
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
            displayedSelectedDate = date
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
        Section {
            Text(fullDateLabel(for: calendarState.selectedDate))
                .font(.title2.weight(.semibold))
                .padding(.horizontal)
                .accessibilityIdentifier("programSelectedDate")
        }

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
            Section {
                Text(isHistorical ? "No recorded workout for this date." : "No workout planned for this date.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("programEmptyState")
                if !isHistorical {
                    Button("Create workout") {
                        viewModel.createSelectedWorkout()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GymTheme.accent)
                    .accessibilityIdentifier("programCreateWorkout")
                }
            }
        case let .workout(status):
            Section {
                Label(statusLabel(status), systemImage: ProgramDayState.workout(status).systemImage ?? "circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(status == .completed ? GymTheme.accentForeground : Color.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(GymTheme.surface, in: Capsule())
                    .accessibilityIdentifier("programWorkoutState")
            }

            Section("Exercises") {
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
                        exercisePickerRoute = ExercisePickerRoute(workoutDate: calendarState.selectedDate)
                    } label: {
                        Label("Add exercise", systemImage: "plus")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("programAddExercise")
                }
            }
        }
        }
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
                historicalActualEditorRoute = HistoricalActualEditorRoute(
                    workoutDate: calendarState.selectedDate,
                    exercise: exercise,
                    workoutSet: set
                )
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
        let sets = viewModel.orderedSets(for: exercise.id, on: calendarState.selectedDate)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
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
            ForEach(Array(sets.enumerated()), id: \.element.id) { setIndex, set in
                HStack(spacing: 4) {
                    Button {
                        setEditorRoute = SetEditorRoute(
                            workoutDate: calendarState.selectedDate,
                            exercise: exercise,
                            set: set
                        )
                    } label: {
                        HStack {
                            Text("Set \(setIndex + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(SetDisplayFormatter(unit: weightUnit).string(
                                reps: set.displayedReps,
                                weightInKilograms: set.displayedWeight,
                                timeSeconds: set.displayedTimeSeconds,
                                type: set.displayedType
                            ))
                        }
                        .frame(minHeight: 44)
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

                    if sets.count > 1 {
                        Menu {
                            if setIndex > 0 {
                                Button("Move up") { moveSet(set.id, in: exercise.id, by: -1) }
                            }
                            if setIndex < sets.count - 1 {
                                Button("Move down") { moveSet(set.id, in: exercise.id, by: 1) }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Actions for set \(setIndex + 1) for \(name)")
                    }
                }
            }
            Button {
                addSet(to: exercise.id)
            } label: {
                Label("Add set", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Add set to \(name)")
            .accessibilityIdentifier("programAddSet-\(exercise.id.rawValue.uuidString)")
        }
        .accessibilityElement(children: .contain)
        .gymCard()
        .accessibilityIdentifier("programExerciseRow-\(exercise.id.rawValue.uuidString)")
        .accessibilityHint("Exercise \(index + 1) of \(orderedExercises.count)")
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
            selectedDate: displayedSelectedDate,
            currentDate: viewModel.currentDate,
            calendar: viewModel.calendar,
            workouts: viewModel.workouts
        )
    }
    private var orderedExercises: [WorkoutExercise] {
        viewModel.orderedExercises(on: calendarState.selectedDate)
    }
    private var isHistorical: Bool { calendarState.selectedDate < viewModel.currentDate }

    private func moveWeek(by offset: Int) {
        guard let date = displayedSelectedDate.adding(weeks: offset, calendar: viewModel.calendar) else { return }
        displayedSelectedDate = date
    }

    private func moveMonth(by offset: Int) {
        guard let date = displayedMonth.adding(months: offset, calendar: viewModel.calendar) else { return }
        displayedMonth = date
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

    private func addSet(to exerciseID: WorkoutExerciseID) {
        do {
            try viewModel.addSet(to: exerciseID, on: calendarState.selectedDate)
        } catch {
            showsMutationError = true
        }
    }

    private func deleteWorkout(on date: LocalDate) {
        do {
            try viewModel.deleteWorkout(on: date)
        } catch {
            showsMutationError = true
        }
    }

    private func moveSet(_ id: WorkoutSetID, in exerciseID: WorkoutExerciseID, by offset: Int) {
        var reordered = viewModel.orderedSets(for: exerciseID, on: calendarState.selectedDate)
        guard let source = reordered.firstIndex(where: { $0.id == id }) else { return }
        let destination = source + offset
        guard reordered.indices.contains(destination) else { return }
        reordered.swapAt(source, destination)
        do {
            try viewModel.reorderSets(reordered.map(\.id), in: exerciseID, on: calendarState.selectedDate)
        } catch {
            showsMutationError = true
        }
    }

    private func requestDeletion(of exercise: WorkoutExercise) {
        pendingDeletion = PendingExerciseDeletion(
            id: exercise.id,
            name: viewModel.exerciseName(for: exercise)
        )
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )
    }

    private var deleteWorkoutConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingWorkoutDeletion != nil },
            set: { if !$0 { pendingWorkoutDeletion = nil } }
        )
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
    let id: WorkoutExerciseID
    let name: String
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
    let sourceDate: LocalDate
    let exerciseCount: Int
    let setCount: Int

    var id: LocalDate { sourceDate }
}

private struct RepeatWorkoutRoute: Identifiable {
    let sourceDate: LocalDate
    var id: LocalDate { sourceDate }
}

private struct CopyWorkoutSheet: View {
    let sourceDate: LocalDate
    let exerciseCount: Int
    let setCount: Int
    let calendar: Calendar
    let isDestinationOccupied: (LocalDate) -> Bool
    let onCopy: (LocalDate) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var destination: Date
    @State private var showsCopyError = false

    init(
        sourceDate: LocalDate,
        exerciseCount: Int,
        setCount: Int,
        calendar: Calendar,
        isDestinationOccupied: @escaping (LocalDate) -> Bool,
        onCopy: @escaping (LocalDate) throws -> Void
    ) {
        self.sourceDate = sourceDate
        self.exerciseCount = exerciseCount
        self.setCount = setCount
        self.calendar = calendar
        self.isDestinationOccupied = isDestinationOccupied
        self.onCopy = onCopy
        _destination = State(initialValue: sourceDate.date(in: calendar) ?? Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GymSectionHeader(title: "Source")
                    HStack(spacing: 12) {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                            .frame(width: 38, height: 38)
                            .foregroundStyle(GymTheme.accentForeground)
                            .background(GymTheme.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(fullDateLabel(for: sourceDate))
                                .font(.headline)
                        .accessibilityIdentifier("copyWorkoutSourceDate")
                            Text("\(exerciseCount) \(exerciseCount == 1 ? "exercise" : "exercises") · \(setCount) \(setCount == 1 ? "set" : "sets")")
                                .foregroundStyle(.secondary)
                        .accessibilityIdentifier("copyWorkoutSummary")
                        }
                        Spacer()
                    }
                    .gymCard()

                    GymSectionHeader(title: "Destination")
                    VStack(alignment: .leading, spacing: 12) {
                        DatePicker("Destination date", selection: $destination, displayedComponents: .date)
                            .accessibilityIdentifier("copyWorkoutDestination")
                        Divider()
                        Text(fullDateLabel(for: destinationDate))
                            .font(.headline)
                        if let destinationMessage {
                            Text(destinationMessage)
                                .font(.subheadline)
                                .foregroundStyle(GymTheme.destructive)
                                .accessibilityIdentifier("copyWorkoutDestinationMessage")
                        } else {
                            Text("Creates an independent planned workout.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .gymCard()

                    Button {
                        do {
                            try onCopy(destinationDate)
                            dismiss()
                        } catch {
                            showsCopyError = true
                        }
                    } label: {
                        Text("Copy")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GymTheme.accent)
                    .disabled(destinationMessage != nil)
                    .accessibilityIdentifier("copyWorkoutAction")
                }
                .padding()
            }
            .navigationTitle("Copy workout")
            .accessibilityIdentifier("copyWorkoutSheet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("copyWorkoutCancel")
                }
            }
            .alert("Workout could not be copied", isPresented: $showsCopyError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Choose another date and try again.")
            }
        }
    }

    private var destinationDate: LocalDate {
        LocalDate(date: destination, calendar: calendar)
    }

    private var destinationMessage: String? {
        if destinationDate == sourceDate {
            return "Choose a different date."
        }
        if isDestinationOccupied(destinationDate) {
            return "A workout already exists on this date. Choose another date."
        }
        return nil
    }

    private func fullDateLabel(for date: LocalDate) -> String {
        guard let value = date.date(in: calendar) else { return date.description }
        return value.formatted(.dateTime.weekday(.wide).month(.wide).day().year().locale(Locale(identifier: "en")))
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
                    .buttonStyle(.borderedProminent)
                    .tint(GymTheme.accent)
                    .disabled(candidateDates.isEmpty || availableDates.isEmpty)
                    .accessibilityIdentifier("repeatWorkoutAction")
                }
                .padding()
            }
            .navigationTitle("Repeat workout")
            .accessibilityIdentifier("repeatWorkoutSheet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
    let onSave: (Int, Double, Int, WorkoutSetType) throws -> Void
    let onDelete: () throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reps: Int
    @State private var weight: Double
    @State private var timeSeconds: Int
    @State private var type: WorkoutSetType
    @State private var showsValidationError = false
    @State private var isDeleteConfirmationPresented = false

    init(
        set: WorkoutSet?,
        exerciseName: String,
        weightUnit: WeightUnit,
        onSave: @escaping (Int, Double, Int, WorkoutSetType) throws -> Void,
        onDelete: @escaping () throws -> Void
    ) {
        self.set = set
        self.exerciseName = exerciseName
        self.weightUnit = weightUnit
        self.onSave = onSave
        self.onDelete = onDelete
        _reps = State(initialValue: set?.reps ?? 0)
        _weight = State(initialValue: weightUnit.displayWeight(fromCanonicalKilograms: set?.weight ?? 0))
        _timeSeconds = State(initialValue: set?.timeSeconds ?? 0)
        _type = State(initialValue: set?.type ?? .repsOnly)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(set?.isCompleted == true ? "\(exerciseName) plan" : exerciseName) {
                    if set?.isCompleted == true {
                        Text("Actual results are unchanged.")
                            .foregroundStyle(.secondary)
                    }
                    if set?.type == .legacyMixed {
                        Text("This legacy set keeps its recorded values until you choose a new set type.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("programSetEditorLegacyNotice")
                    }
                    Picker("Set type", selection: $type) {
                        ForEach(WorkoutSetType.editableCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("programSetEditorType")
                    if type != .timed {
                        TextField("Reps", value: $reps, format: .number)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("programSetEditorReps")
                    }
                    if type == .weighted || type == .legacyMixed {
                        TextField("Weight (\(weightUnit.rawValue))", value: $weight, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("programSetEditorWeight")
                    }
                    if type == .timed || type == .legacyMixed {
                        TextField("Time (seconds)", value: $timeSeconds, format: .number)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("programSetEditorTime")
                    }
                }

                if set != nil {
                    Section {
                        Button("Delete set", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                        .accessibilityIdentifier("programSetEditorDelete")
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
                        do {
                            try onSave(reps, weightUnit.canonicalKilograms(fromDisplayWeight: weight), timeSeconds, type)
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
            .confirmationDialog(
                "Delete this set?",
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Delete set", role: .destructive) {
                    do {
                        try onDelete()
                        dismiss()
                    } catch {
                        showsValidationError = true
                    }
                }
                .accessibilityIdentifier("programConfirmDeleteSet")
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This set will be removed from the workout.")
            }
        }
    }
}

private struct HistoricalActualEditorSheet: View {
    let route: HistoricalActualEditorRoute
    let weightUnit: WeightUnit
    let onSave: (Int, Double, Int) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reps: Int
    @State private var weight: Double
    @State private var timeSeconds: Int
    @State private var showsValidationError = false
    @State private var showsSaveError = false

    init(
        route: HistoricalActualEditorRoute,
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
                Section("Actual results") {
                    Text(route.workoutSet.displayedType.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if route.workoutSet.displayedType != .timed {
                        TextField("Reps", value: $reps, format: .number)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("programHistoryActualEditorReps")
                    }
                    if route.workoutSet.displayedType == .weighted || route.workoutSet.displayedType == .legacyMixed {
                        TextField("Weight (\(weightUnit.rawValue))", value: $weight, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("programHistoryActualEditorWeight")
                    }
                    if route.workoutSet.displayedType == .timed || route.workoutSet.displayedType == .legacyMixed {
                        TextField("Time (seconds)", value: $timeSeconds, format: .number)
                            .keyboardType(.numberPad)
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
        }
    }
}
