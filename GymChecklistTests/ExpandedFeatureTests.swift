import XCTest
@testable import GymChecklist

final class ExpandedFeatureTests: XCTestCase {
    func testClearedProfileEncodesNullsThatReplacePreviouslySavedValues() throws {
        let owner = UserID(rawValue: "owner")
        let original = UserSettings(
            userID: owner, appearance: .dark, weightUnit: .pounds,
            profile: UserProfile(
                sex: .female, dateOfBirth: LocalDate(year: 1990, month: 1, day: 2), heightCentimeters: 180
            )
        )
        let cleared = UserSettings(userID: owner, appearance: .dark, weightUnit: .pounds)
        let encoder = JSONEncoder()
        var stored = try XCTUnwrap(try JSONSerialization.jsonObject(
            with: encoder.encode(FirestoreUserSettingsDocument(settings: original))
        ) as? [String: Any])
        let update = try XCTUnwrap(try JSONSerialization.jsonObject(
            with: encoder.encode(FirestoreUserSettingsDocument(settings: cleared))
        ) as? [String: Any])
        for key in ["sex", "dateOfBirth", "heightCentimeters"] {
            XCTAssertTrue(update[key] is NSNull, "Cleared \(key) must be present in a merged write")
        }
        stored.merge(update) { _, newValue in newValue }
        let reread = try JSONDecoder().decode(
            FirestoreUserSettingsDocument.self, from: JSONSerialization.data(withJSONObject: stored)
        )
        XCTAssertEqual(reread.settings(userID: owner), cleared)
    }

    @MainActor
    func testTodayPlanEditsRetainExplicitTypesAtZeroAndAfterCompletion() throws {
        let date = LocalDate(year: 2026, month: 9, day: 4)
        let repository = InMemoryWorkoutRepository(userID: UserID(rawValue: "owner"))
        var workout = repository.createEmptyWorkout(on: date, at: .distantPast).workout
        let exerciseID = WorkoutExerciseID()
        let weighted = WorkoutSet(order: 0, reps: 8, weight: 0, type: .weighted)
        let timed = WorkoutSet(order: 1, timeSeconds: 45, type: .timed)
        workout.exercises = [WorkoutExercise(
            id: exerciseID, exerciseID: SystemExerciseCatalog.all[0].id,
            customName: nil, order: 0, isSkipped: false, sets: [weighted, timed]
        )]
        try repository.save(workout)
        let model = WorkoutViewModel(repository: repository, initialDate: date, currentDate: date)

        try model.editTodaySet(weighted.id, in: exerciseID, on: date, reps: 8, weight: 0, timeSeconds: 0)
        try model.editTodaySet(timed.id, in: exerciseID, on: date, reps: 0, weight: 0, timeSeconds: 0)
        let atZero = try XCTUnwrap(repository.workout(on: date)?.exercises.first?.sets)
        XCTAssertEqual(atZero.map(\.type), [.weighted, .timed])
        try model.editTodaySet(weighted.id, in: exerciseID, on: date, reps: 8, weight: 60, timeSeconds: 0)
        try model.editTodaySet(timed.id, in: exerciseID, on: date, reps: 0, weight: 0, timeSeconds: 30)
        try model.toggleCompletion(of: timed.id, in: exerciseID, on: date)
        try model.editTodaySet(timed.id, in: exerciseID, on: date, reps: 0, weight: 0, timeSeconds: 0)
        let updated = try XCTUnwrap(repository.workout(on: date)?.exercises.first?.sets)
        XCTAssertEqual(updated[0].weight, 60)
        XCTAssertEqual(updated[0].type, .weighted)
        XCTAssertEqual(updated[1].type, .timed)
        XCTAssertEqual(updated[1].actualType, .timed)
        XCTAssertEqual(updated[1].timeSeconds, 30)
        XCTAssertEqual(updated[1].actualTimeSeconds, 0)
        XCTAssertTrue(updated[1].isCompleted)
    }

    func testWeightedDisplayOmitsZeroAndFormatsValuesBeyondIntegerRange() {
        for unit in [WeightUnit.kilograms, .pounds] {
            XCTAssertEqual(SetDisplayFormatter(unit: unit).string(
                reps: 8, weightInKilograms: 0, timeSeconds: 0, type: .weighted
            ), "8 reps")
        }
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(
            reps: 8, weightInKilograms: 1e20, timeSeconds: 0, type: .weighted
        ), "8 reps × 100000000000000000000 kg")
        XCTAssertTrue(SetDisplayFormatter(unit: .pounds).string(
            reps: 8, weightInKilograms: 1e20, timeSeconds: 0, type: .weighted
        ).hasSuffix(" lb"))
    }

    func testProfileCalculatesBMIOnlyWhenHeightAndWeightExist() {
        let profile = UserProfile(heightCentimeters: 180)
        XCTAssertNil(profile.bmi(weightInKilograms: nil))
        XCTAssertEqual(profile.bmi(weightInKilograms: 81) ?? 0, 25, accuracy: 0.000_1)
        XCTAssertNil(UserProfile(heightCentimeters: .leastNonzeroMagnitude).bmi(weightInKilograms: 81))
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
        try repository.deleteMeasurement(id: sameDateLaterMeasurement.id, onFailure: {})
        XCTAssertEqual(viewModel.currentWeightInKilograms, 80)

        let future = BodyWeightMeasurement(
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 3),
            weightInKilograms: 79, measuredAt: .distantPast, updatedAt: .distantPast
        )
        try repository.save(future)
        XCTAssertEqual(repository.measurements.first?.id, future.id)
        XCTAssertEqual(viewModel.currentWeightInKilograms, 80)
        viewModel.refreshCurrentDate(LocalDate(year: 2026, month: 9, day: 3))
        XCTAssertEqual(viewModel.currentWeightInKilograms, 79)
        XCTAssertEqual(viewModel.bmi ?? 0, 24.382_716, accuracy: 0.000_001)
        XCTAssertThrowsError(try repository.save(BodyWeightMeasurement(
            userID: UserID(rawValue: "other"), localDate: backfilledOlderDate.localDate,
            weightInKilograms: 80, measuredAt: Date(), updatedAt: Date()
        )))
    }

    func testBodyWeightSnapshotPreservesCachedMeasurementWhenItsDocumentIsUnreadable() {
        let owner = UserID(rawValue: "owner")
        let cached = BodyWeightMeasurement(
            id: BodyWeightMeasurementID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000010")!),
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 2),
            weightInKilograms: 80, measuredAt: .distantPast, updatedAt: .distantPast
        )
        let fresh = BodyWeightMeasurement(
            id: BodyWeightMeasurementID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000011")!),
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 3),
            weightInKilograms: 79, measuredAt: .distantFuture, updatedAt: .distantFuture
        )
        let snapshot = FirestoreBodyWeightSnapshotDecoder.decode([
            FirestoreBodyWeightSnapshotEntry(documentID: cached.id.rawValue.uuidString, payload: nil),
            FirestoreBodyWeightSnapshotEntry(
                documentID: fresh.id.rawValue.uuidString,
                payload: FirestoreBodyWeightMeasurementDocument(measurement: fresh)
            )
        ], userID: owner)

        XCTAssertEqual(snapshot.measurementsPreservingCachedEntries([cached]), [fresh, cached])
    }

    func testBodyWeightDeleteFailureRestoresTheOptimisticallyRemovedRowOnce() {
        let owner = UserID(rawValue: "owner")
        let removed = BodyWeightMeasurement(
            id: BodyWeightMeasurementID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000012")!),
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 2),
            weightInKilograms: 80, measuredAt: .distantPast, updatedAt: .distantPast
        )
        let newer = BodyWeightMeasurement(
            id: BodyWeightMeasurementID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000013")!),
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 3),
            weightInKilograms: 79, measuredAt: .distantFuture, updatedAt: .distantFuture
        )

        let restored = BodyWeightDeletionFailureRecovery.measurementsRestoring(removed, to: [newer])
        XCTAssertEqual(restored, [newer, removed])
        XCTAssertEqual(
            BodyWeightDeletionFailureRecovery.measurementsRestoring(removed, to: restored),
            restored
        )
    }

    func testCustomExerciseSnapshotPreservesCachedExerciseWhenItsDocumentIsUnreadable() throws {
        let owner = UserID(rawValue: "owner")
        let cached = Exercise(
            id: ExerciseID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000014")!),
            name: "Cached custom", category: nil, isSystem: false, createdByUserID: owner
        )
        let fresh = Exercise(
            id: ExerciseID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000015")!),
            name: "Fresh custom", category: nil, isSystem: false, createdByUserID: owner
        )
        let snapshot = FirestoreCustomExerciseSnapshotDecoder.decode([
            FirestoreCustomExerciseSnapshotEntry(documentID: cached.id.rawValue.uuidString, payload: nil),
            FirestoreCustomExerciseSnapshotEntry(
                documentID: fresh.id.rawValue.uuidString,
                payload: try FirestoreCustomExerciseDocument(exercise: fresh)
            )
        ], userID: owner)

        XCTAssertEqual(snapshot.discardedExerciseIDs, Set([cached.id]))
        XCTAssertEqual(snapshot.exercisesPreservingCachedEntries([cached]), [fresh, cached])
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
        XCTAssertEqual(reread.type, .legacyMixed)
        XCTAssertEqual(reread.actualType, .legacyMixed)
    }

    func testLegacyTimedPlaceholdersInferTimedWhileMeaningfulRepTimeValuesRemainMixed() throws {
        let legacyPlaceholder = FirestoreWorkoutSetDocument(
            id: "00000000-0000-4000-8000-000000000002", order: 0,
            reps: 1, weight: 0, timeSeconds: 45, type: nil,
            isCompleted: true, actualReps: 1, actualWeight: 0, actualTimeSeconds: 50,
            actualType: nil, completedAt: .distantPast
        )

        let decodedPlaceholder = try legacyPlaceholder.workoutSet()
        XCTAssertEqual(decodedPlaceholder.type, .timed)
        XCTAssertEqual(decodedPlaceholder.actualType, .timed)
        XCTAssertEqual(decodedPlaceholder.reps, 1)
        XCTAssertEqual(decodedPlaceholder.actualReps, 1)
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(
            reps: decodedPlaceholder.displayedReps,
            weightInKilograms: decodedPlaceholder.displayedWeight,
            timeSeconds: decodedPlaceholder.displayedTimeSeconds,
            type: decodedPlaceholder.displayedType
        ), "50 sec")
        XCTAssertEqual(FirestoreWorkoutSetDocument(set: decodedPlaceholder).type, .timed)

        XCTAssertEqual(WorkoutSet(order: 0, reps: 0, weight: 0, timeSeconds: 45).type, .timed)
        let repAndTime = WorkoutSet(order: 0, reps: 8, weight: 0, timeSeconds: 45)
        XCTAssertEqual(repAndTime.type, .legacyMixed)
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(
            reps: repAndTime.reps, weightInKilograms: repAndTime.weight,
            timeSeconds: repAndTime.timeSeconds, type: repAndTime.type
        ), "8 reps × 45 sec")

        let encoded = try JSONEncoder().encode(WorkoutSet(
            id: WorkoutSetID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000003")!),
            order: 0, reps: 0, weight: 0, timeSeconds: 45, type: .timed
        ))
        var payload = try XCTUnwrap(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        payload.removeValue(forKey: "type")
        payload["reps"] = 1
        let codablePlaceholder = try JSONDecoder().decode(
            WorkoutSet.self, from: JSONSerialization.data(withJSONObject: payload)
        )
        XCTAssertEqual(codablePlaceholder.type, .timed)
        XCTAssertEqual(codablePlaceholder.reps, 1)
    }

    @MainActor
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
