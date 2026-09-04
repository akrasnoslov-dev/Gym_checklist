import XCTest
@testable import GymChecklist

final class ExpandedFeatureTests: XCTestCase {
    func testProfileCalculatesBMIOnlyWhenHeightAndWeightExist() {
        let profile = UserProfile(heightCentimeters: 180)
        XCTAssertNil(profile.bmi(weightInKilograms: nil))
        XCTAssertEqual(profile.bmi(weightInKilograms: 81) ?? 0, 25, accuracy: 0.000_1)
    }

    @MainActor
    func testBodyWeightHistoryUsesLocalDateForCurrentWeightAndKeepsFutureEntriesOutOfBMI() throws {
        let owner = UserID(rawValue: "owner")
        let repository = InMemoryBodyWeightRepository(userID: owner)
        let backfilledOlderDate = BodyWeightMeasurement(
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 1),
            weightInKilograms: 81, measuredAt: .distantFuture, updatedAt: .distantFuture
        )
        let newerMeasurementDate = BodyWeightMeasurement(
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 2),
            weightInKilograms: 80, measuredAt: .distantPast, updatedAt: .distantPast
        )
        try repository.save(backfilledOlderDate)
        try repository.save(newerMeasurementDate)
        XCTAssertEqual(repository.measurements.map(\.id), [newerMeasurementDate.id, backfilledOlderDate.id])

        let settingsRepository = InMemoryUserSettingsRepository(
            userID: owner,
            settings: UserSettings(userID: owner, profile: UserProfile(heightCentimeters: 180))
        )
        let viewModel = SettingsViewModel(
            repository: settingsRepository,
            bodyWeightRepository: repository,
            currentDate: LocalDate(year: 2026, month: 9, day: 2)
        )
        XCTAssertEqual(viewModel.currentWeightInKilograms, 80)
        XCTAssertEqual(viewModel.bmi ?? 0, 24.691_358, accuracy: 0.000_001)

        let sameDateLaterMeasurement = BodyWeightMeasurement(
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 2),
            weightInKilograms: 79.5, measuredAt: .distantFuture, updatedAt: .distantFuture
        )
        try repository.save(sameDateLaterMeasurement)
        XCTAssertEqual(repository.measurements.first?.id, sameDateLaterMeasurement.id)
        XCTAssertEqual(viewModel.currentWeightInKilograms, 79.5)
        try repository.deleteMeasurement(id: sameDateLaterMeasurement.id)
        XCTAssertEqual(viewModel.currentWeightInKilograms, 80)

        let future = BodyWeightMeasurement(
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 3),
            weightInKilograms: 79, measuredAt: .distantPast, updatedAt: .distantPast
        )
        try repository.save(future)
        XCTAssertEqual(repository.measurements.first?.id, future.id)
        XCTAssertEqual(viewModel.currentWeightInKilograms, 80)
        XCTAssertThrowsError(try repository.save(BodyWeightMeasurement(
            userID: UserID(rawValue: "other"), localDate: backfilledOlderDate.localDate,
            weightInKilograms: 80, measuredAt: Date(), updatedAt: Date()
        )))
    }

    func testLegacyMixedSetRoundTripsWithoutDiscardingPlanOrActualValues() throws {
        let document = FirestoreWorkoutSetDocument(
            id: "00000000-0000-4000-8000-000000000001", order: 0,
            reps: 8, weight: 60, timeSeconds: 45, type: nil,
            isCompleted: true, actualReps: 7, actualWeight: 65, actualTimeSeconds: 50,
            actualType: nil, completedAt: .distantPast
        )

        let legacy = try document.workoutSet()
        XCTAssertEqual(legacy.type, .legacyMixed)
        XCTAssertEqual(legacy.reps, 8)
        XCTAssertEqual(legacy.weight, 60)
        XCTAssertEqual(legacy.timeSeconds, 45)
        XCTAssertEqual(legacy.actualType, .legacyMixed)
        XCTAssertEqual(legacy.actualReps, 7)
        XCTAssertEqual(legacy.actualWeight, 65)
        XCTAssertEqual(legacy.actualTimeSeconds, 50)
        XCTAssertEqual(legacy.displayedType, .legacyMixed)

        let persisted = FirestoreWorkoutSetDocument(set: legacy)
        XCTAssertEqual(persisted.type, .legacyMixed)
        XCTAssertEqual(persisted.actualType, .legacyMixed)
        let reread = try persisted.workoutSet()
        XCTAssertEqual(reread.reps, 8)
        XCTAssertEqual(reread.weight, 60)
        XCTAssertEqual(reread.timeSeconds, 45)
        XCTAssertEqual(reread.actualReps, 7)
        XCTAssertEqual(reread.actualWeight, 65)
        XCTAssertEqual(reread.actualTimeSeconds, 50)
    }

    func testLegacyMixedCodableCopyRepeatAndAddSetKeepRawValuesUntilAnExplicitTypeIsChosen() throws {
        let legacyID = WorkoutSetID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000011")!)
        let legacy = WorkoutSet(
            id: legacyID, order: 0, reps: 8, weight: 60, timeSeconds: 45, type: .legacyMixed
        )
        let encoded = try JSONEncoder().encode(legacy)
        var payload = try XCTUnwrap(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        payload.removeValue(forKey: "type")
        let legacyJSON = try JSONSerialization.data(withJSONObject: payload)
        let decoded = try JSONDecoder().decode(WorkoutSet.self, from: legacyJSON)
        XCTAssertEqual(decoded.type, .legacyMixed)
        XCTAssertEqual(decoded.reps, 8)
        XCTAssertEqual(decoded.weight, 60)
        XCTAssertEqual(decoded.timeSeconds, 45)

        let owner = UserID(rawValue: "owner")
        let sourceDate = LocalDate(year: 2026, month: 9, day: 4)
        let copyDate = LocalDate(year: 2026, month: 9, day: 5)
        let repository = InMemoryWorkoutRepository(userID: owner)
        var source = repository.createEmptyWorkout(on: sourceDate, at: .distantPast).workout
        let exerciseID = WorkoutExerciseID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000012")!)
        source.exercises = [WorkoutExercise(
            id: exerciseID, exerciseID: SystemExerciseCatalog.all[0].id, customName: nil,
            order: 0, isSkipped: false, sets: [decoded]
        )]
        try repository.save(source)
        let viewModel = WorkoutViewModel(
            repository: repository, initialDate: sourceDate, currentDate: sourceDate,
            calendar: mondayCalendar()
        )

        try viewModel.copyWorkout(from: sourceDate, to: copyDate)
        let copiedExercise = try XCTUnwrap(repository.workout(on: copyDate)?.exercises.first)
        let copied = try XCTUnwrap(copiedExercise.sets.first)
        XCTAssertEqual(copied.type, .legacyMixed)
        XCTAssertEqual(copied.reps, 8)
        XCTAssertEqual(copied.weight, 60)
        XCTAssertEqual(copied.timeSeconds, 45)

        let repeated = try viewModel.repeatWorkout(
            from: sourceDate,
            through: LocalDate(year: 2026, month: 9, day: 11),
            cadence: WorkoutRepeatCadence(intervalWeeks: 1)
        )
        let repeatedDate = try XCTUnwrap(repeated.createdDates.first)
        let repeatedSet = try XCTUnwrap(repository.workout(on: repeatedDate)?.exercises.first?.sets.first)
        XCTAssertEqual(repeatedSet.type, .legacyMixed)
        XCTAssertEqual(repeatedSet.reps, 8)
        XCTAssertEqual(repeatedSet.weight, 60)
        XCTAssertEqual(repeatedSet.timeSeconds, 45)

        try viewModel.addSet(to: copiedExercise.id, on: copyDate)
        let added = try XCTUnwrap(repository.workout(on: copyDate)?.exercises.first?.sets.last)
        XCTAssertEqual(added.type, .legacyMixed)
        XCTAssertEqual(added.reps, 8)
        XCTAssertEqual(added.weight, 60)
        XCTAssertEqual(added.timeSeconds, 45)

        try viewModel.editSet(
            added.id, in: copiedExercise.id, on: copyDate,
            reps: 10, weight: 70, timeSeconds: 30, type: .weighted
        )
        let explicitlyTyped = try XCTUnwrap(repository.workout(on: copyDate)?.exercises.first?.sets.last)
        XCTAssertEqual(explicitlyTyped.type, .weighted)
        XCTAssertEqual(explicitlyTyped.reps, 10)
        XCTAssertEqual(explicitlyTyped.weight, 70)
        XCTAssertEqual(explicitlyTyped.timeSeconds, 0)
    }

    func testSetTypesHideIrrelevantMetricsAndFormatterUsesOnlyTheChosenType() {
        XCTAssertEqual(WorkoutSetType.editableCases, [.weighted, .repsOnly, .timed])
        let timed = WorkoutSet(order: 0, reps: 10, weight: 30, timeSeconds: 45, type: .timed)
        XCTAssertEqual(timed.reps, 0)
        XCTAssertEqual(timed.weight, 0)
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(
            reps: timed.reps, weightInKilograms: timed.weight, timeSeconds: timed.timeSeconds, type: timed.type
        ), "45 sec")

        let repsOnly = WorkoutSet(order: 0, reps: 12, weight: 50, timeSeconds: 20, type: .repsOnly)
        XCTAssertEqual(repsOnly.weight, 0)
        XCTAssertEqual(repsOnly.timeSeconds, 0)
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(
            reps: repsOnly.reps, weightInKilograms: repsOnly.weight, timeSeconds: repsOnly.timeSeconds, type: repsOnly.type
        ), "12 reps")
    }

    @MainActor
    func testRepeatCadenceUsesTheRequestedWeekInterval() throws {
        let owner = UserID(rawValue: "owner")
        let source = LocalDate(year: 2026, month: 9, day: 4)
        let repository = InMemoryWorkoutRepository(userID: owner)
        _ = repository.createEmptyWorkout(on: source, at: .distantPast)
        let model = WorkoutViewModel(repository: repository, initialDate: source, currentDate: source)
        let result = try model.repeatWorkout(
            from: source,
            through: LocalDate(year: 2026, month: 10, day: 2),
            cadence: WorkoutRepeatCadence(intervalWeeks: 2)
        )
        XCTAssertEqual(result.createdDates, [
            LocalDate(year: 2026, month: 9, day: 18),
            LocalDate(year: 2026, month: 10, day: 2)
        ])
    }

    func testMonthGridUsesLocalDatesAndContainsSixFullWeeks() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Copenhagen")!
        let selected = LocalDate(year: 2026, month: 9, day: 4)
        let state = ProgramCalendarState(selectedDate: selected, currentDate: selected, calendar: calendar)
        let dates = state.monthDates(containing: selected)
        XCTAssertEqual(dates.count, 42)
        XCTAssertTrue(dates.contains(selected))
        XCTAssertEqual(dates.first?.day, 31)
        XCTAssertEqual(state.weekDates.first, LocalDate(year: 2026, month: 8, day: 31))
        XCTAssertEqual(state.weekDates.map(\.day), [31, 1, 2, 3, 4, 5, 6])
    }

    func testWeekAndMonthUseTheSameMondayFirstLocalDateSelection() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        var state = ProgramCalendarState(
            selectedDate: LocalDate(year: 2026, month: 9, day: 4),
            currentDate: LocalDate(year: 2026, month: 9, day: 4), calendar: calendar
        )
        let outsideMonth = LocalDate(year: 2026, month: 8, day: 31)
        XCTAssertTrue(state.monthDates(containing: state.selectedDate).contains(outsideMonth))
        state.select(outsideMonth)
        XCTAssertEqual(state.selectedDate, outsideMonth)
        XCTAssertEqual(state.weekDates.first, outsideMonth)
        state.moveWeek(by: 1)
        XCTAssertEqual(state.selectedDate, LocalDate(year: 2026, month: 9, day: 7))
        XCTAssertEqual(state.weekDates.first, LocalDate(year: 2026, month: 9, day: 7))
    }

    private func mondayCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Copenhagen")!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }
}
