import XCTest
@testable import GymChecklist

final class ExpandedFeatureTests: XCTestCase {
    func testProfileCalculatesBMIOnlyWhenHeightAndWeightExist() {
        let profile = UserProfile(heightCentimeters: 180)
        XCTAssertNil(profile.bmi(weightInKilograms: nil))
        XCTAssertEqual(profile.bmi(weightInKilograms: 81) ?? 0, 25, accuracy: 0.000_1)
    }

    @MainActor
    func testBodyWeightHistoryIsOwnerBoundAndSortedByMostRecentMeasurement() throws {
        let owner = UserID(rawValue: "owner")
        let repository = InMemoryBodyWeightRepository(userID: owner)
        let earlier = BodyWeightMeasurement(
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 1),
            weightInKilograms: 81, measuredAt: .distantPast, updatedAt: .distantPast
        )
        let later = BodyWeightMeasurement(
            userID: owner, localDate: LocalDate(year: 2026, month: 9, day: 2),
            weightInKilograms: 80, measuredAt: .distantFuture, updatedAt: .distantFuture
        )
        try repository.save(earlier)
        try repository.save(later)
        XCTAssertEqual(repository.measurements.map(\.id), [later.id, earlier.id])
        XCTAssertThrowsError(try repository.save(BodyWeightMeasurement(
            userID: UserID(rawValue: "other"), localDate: earlier.localDate,
            weightInKilograms: 80, measuredAt: Date(), updatedAt: Date()
        )))
    }

    func testSetTypesHideIrrelevantMetricsAndFormatterUsesOnlyTheChosenType() {
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
    }
}
