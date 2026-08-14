import XCTest
@testable import GymChecklist

final class DomainModelsTests: XCTestCase {
    func testModelsRoundTripWithExplicitOrderAndSkippedState() throws {
        let userID = UserID(rawValue: "user")
        let exerciseID = ExerciseID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        let set = WorkoutSet(id: WorkoutSetID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!), order: 3, reps: 8, weight: 60, timeSeconds: 0)
        let workoutExercise = WorkoutExercise(id: WorkoutExerciseID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!), exerciseID: exerciseID, customName: nil, order: 2, isSkipped: true, sets: [set])
        let workout = Workout(id: WorkoutID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!), userID: userID, localDate: LocalDate(year: 2026, month: 8, day: 14), exercises: [workoutExercise], createdAt: Date(timeIntervalSince1970: 1), updatedAt: Date(timeIntervalSince1970: 2))
        let exercise = Exercise(id: exerciseID, name: "Squat", category: "Legs", isSystem: true, createdByUserID: nil)
        let settings = UserSettings(userID: userID, appearance: .dark, weightUnit: .pounds)

        XCTAssertEqual(try roundTrip(workout), workout)
        XCTAssertEqual(try roundTrip(exercise), exercise)
        XCTAssertEqual(try roundTrip(settings), settings)
        XCTAssertEqual(workout.exercises.first?.order, 2)
        XCTAssertEqual(workout.exercises.first?.sets.first?.order, 3)
        XCTAssertEqual(workout.dateKey, WorkoutDateKey(userID: userID, localDate: workout.localDate))
    }

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
    }
}

final class LocalDateTests: XCTestCase {
    func testInstantResolvesAcrossDayBoundaryInTwoTimeZones() {
        let instant = ISO8601DateFormatter().date(from: "2026-08-14T00:30:00Z")!
        XCTAssertEqual(LocalDate(date: instant, calendar: calendar("Europe/Copenhagen")), LocalDate(year: 2026, month: 8, day: 14))
        XCTAssertEqual(LocalDate(date: instant, calendar: calendar("America/Los_Angeles")), LocalDate(year: 2026, month: 8, day: 13))
    }

    func testStoredFridayIsTimezoneIndependentAndNavigatesWeeks() throws {
        let friday = LocalDate(year: 2026, month: 8, day: 14)
        let decoded = try JSONDecoder().decode(LocalDate.self, from: JSONEncoder().encode(friday))
        XCTAssertEqual(decoded, friday)
        XCTAssertEqual(decoded.description, "2026-08-14")
        XCTAssertEqual(friday.adding(weeks: 1, calendar: calendar("Europe/Copenhagen")), LocalDate(year: 2026, month: 8, day: 21))
        XCTAssertEqual(LocalDate(year: 2026, month: 12, day: 28).adding(weeks: 1, calendar: calendar("America/Los_Angeles")), LocalDate(year: 2027, month: 1, day: 4))
    }

    func testInvalidEncodedDateIsRejected() {
        let invalid = Data(#"{"year":2026,"month":2,"day":30}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(LocalDate.self, from: invalid))
    }

    private func calendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }
}

final class SetDisplayFormatterTests: XCTestCase {
    func testCompactDisplayRules() {
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(reps: 8, weight: 60, timeSeconds: 0), "8 reps × 60 kg")
        XCTAssertEqual(SetDisplayFormatter(unit: .pounds).string(reps: 8, weight: 132.5, timeSeconds: 0), "8 reps × 132.5 lb")
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(reps: 12, weight: 0, timeSeconds: 0), "12 reps")
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(reps: 1, weight: 0, timeSeconds: 45), "45 sec")
        XCTAssertEqual(SetDisplayFormatter(unit: .kilograms).string(reps: 8, weight: 60, timeSeconds: 45), "8 reps × 60 kg × 45 sec")
        XCTAssertFalse(SetDisplayFormatter(unit: .kilograms).string(reps: 12, weight: 0, timeSeconds: 0).contains("0 kg"))
    }
}

final class WorkoutSetSemanticsTests: XCTestCase {
    func testCompleteEditUndoAndRecompleteTransitions() {
        let firstCompletion = Date(timeIntervalSince1970: 100)
        var set = WorkoutSet(order: 0, reps: 8, weight: 60, timeSeconds: 0)
        set.complete(at: firstCompletion)
        XCTAssertTrue(set.isCompleted)
        XCTAssertEqual(set.actualReps, 8)
        XCTAssertEqual(set.actualWeight, 60)
        XCTAssertEqual(set.actualTimeSeconds, 0)
        XCTAssertEqual(set.completedAt, firstCompletion)

        set.editPlan(reps: 10, weight: 62.5, timeSeconds: 0)
        XCTAssertEqual(set.displayedReps, 8, "Plan edits must not overwrite completed actuals")
        set.editActual(reps: 9, weight: 61, timeSeconds: 0)
        XCTAssertTrue(set.isCompleted)
        XCTAssertEqual(set.displayedReps, 9)
        XCTAssertEqual(set.reps, 10)

        set.undoCompletion()
        XCTAssertFalse(set.isCompleted)
        XCTAssertNil(set.actualReps)
        XCTAssertNil(set.actualWeight)
        XCTAssertNil(set.actualTimeSeconds)
        XCTAssertNil(set.completedAt)
        XCTAssertEqual(set.displayedReps, 10)

        set.complete(at: Date(timeIntervalSince1970: 200))
        XCTAssertEqual(set.actualReps, 10)
        XCTAssertEqual(set.actualWeight, 62.5)
    }

    func testActualEditDoesNothingWhileIncomplete() {
        var set = WorkoutSet(order: 0, reps: 5)
        set.editActual(reps: 9, weight: 10, timeSeconds: 20)
        XCTAssertNil(set.actualReps)
    }

    func testInvalidCompletedEncodingIsRejected() throws {
        let set = WorkoutSet(order: 0, reps: 5)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(set)) as? [String: Any])
        object["isCompleted"] = true
        XCTAssertThrowsError(try JSONDecoder().decode(WorkoutSet.self, from: JSONSerialization.data(withJSONObject: object)))
    }
}

final class WorkoutStatusTests: XCTestCase {
    func testStatusTruthTable() {
        XCTAssertEqual(workout(exercises: []).completionStatus, .planned)
        XCTAssertEqual(workout(exercises: [exercise(completed: [])]).completionStatus, .planned)
        XCTAssertEqual(workout(exercises: [exercise(completed: [false, false])]).completionStatus, .planned)
        XCTAssertEqual(workout(exercises: [exercise(completed: [true, false])]).completionStatus, .partial)
        XCTAssertEqual(workout(exercises: [exercise(completed: [true, true])]).completionStatus, .completed)
        XCTAssertEqual(workout(exercises: [exercise(completed: [false], skipped: true)]).completionStatus, .completed)
        XCTAssertEqual(workout(exercises: [exercise(completed: [false], skipped: true), exercise(completed: [false])]).completionStatus, .planned)
    }

    func testPastPlannedWorkoutIsIncomplete() {
        let past = workout(exercises: [exercise(completed: [false])], date: LocalDate(year: 2026, month: 8, day: 13))
        XCTAssertEqual(past.calendarStatus(asOf: LocalDate(year: 2026, month: 8, day: 14)), .incomplete)
    }

    func testWorkoutDatesAreUniquePerUser() throws {
        let first = workout(exercises: [])
        var duplicate = first
        duplicate.id = WorkoutID()
        XCTAssertThrowsError(try WorkoutScheduleRules.validateUniqueDates(in: [first, duplicate]))

        duplicate.userID = UserID(rawValue: "another-user")
        XCTAssertNoThrow(try WorkoutScheduleRules.validateUniqueDates(in: [first, duplicate]))
    }

    private func workout(exercises: [WorkoutExercise], date: LocalDate = LocalDate(year: 2026, month: 8, day: 14)) -> Workout {
        Workout(id: WorkoutID(), userID: UserID(rawValue: "user"), localDate: date, exercises: exercises, createdAt: .distantPast, updatedAt: .distantPast)
    }

    private func exercise(completed: [Bool], skipped: Bool = false) -> WorkoutExercise {
        var sets = completed.enumerated().map { WorkoutSet(order: $0.offset, reps: 8) }
        for index in sets.indices where completed[index] { sets[index].complete(at: .distantPast) }
        return WorkoutExercise(id: WorkoutExerciseID(), exerciseID: ExerciseID(), customName: nil, order: 0, isSkipped: skipped, sets: sets)
    }
}

final class SystemExerciseCatalogTests: XCTestCase {
    func testCatalogCoversApprovedCategoriesWithStableSystemExercises() throws {
        let exercises = SystemExerciseCatalog.all
        let expectedCategories: Set<String> = [
            "Chest", "Back", "Legs", "Shoulders", "Biceps", "Triceps", "Core", "Cardio/Other"
        ]

        XCTAssertFalse(exercises.isEmpty)
        XCTAssertEqual(exercises.count, 34)
        XCTAssertEqual(Set(exercises.compactMap(\.category)), expectedCategories)
        XCTAssertTrue(exercises.allSatisfy(\.isSystem))
        XCTAssertTrue(exercises.allSatisfy { $0.createdByUserID == nil })
        XCTAssertTrue(exercises.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        XCTAssertEqual(Set(exercises.map(\.id)).count, exercises.count)
        XCTAssertEqual(Set(exercises.map { $0.name.lowercased() }).count, exercises.count)

        let expectedIDs = Set((1...34).map { ordinal in
            let suffix = String(format: "%012d", ordinal)
            return ExerciseID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-\(suffix)")!)
        })
        XCTAssertEqual(Set(exercises.map(\.id)), expectedIDs)

        let benchPress = try XCTUnwrap(exercises.first { $0.name == "Bench Press" })
        XCTAssertEqual(benchPress.id, ExerciseID(rawValue: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!))
    }

    func testSearchIsTrimmedCaseInsensitiveAndDeterministic() {
        let lowercaseIDs = SystemExerciseCatalog.search("bench").map(\.id)
        let mixedCaseIDs = SystemExerciseCatalog.search("  bEnCh  ").map(\.id)

        XCTAssertEqual(mixedCaseIDs, lowercaseIDs)
        XCTAssertEqual(SystemExerciseCatalog.search("BENCH").map(\.name), ["Bench Press", "Close-Grip Bench Press"])
        XCTAssertEqual(SystemExerciseCatalog.search("cable row").map(\.name), ["Seated Cable Row"])
    }

    func testEmptyQueryReturnsAllAndUnknownQueryReturnsNothing() {
        XCTAssertEqual(SystemExerciseCatalog.search(""), SystemExerciseCatalog.all)
        XCTAssertEqual(SystemExerciseCatalog.search("   \n"), SystemExerciseCatalog.all)
        XCTAssertTrue(SystemExerciseCatalog.search("not a bundled exercise").isEmpty)
    }
}
