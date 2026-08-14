import XCTest

final class GymChecklistUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesOnTodayAndNavigatesAllTabs() {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launch()

        XCTAssertTrue(app.staticTexts["todayPlaceholder"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Program"].tap()
        XCTAssertTrue(app.staticTexts["programWeekHeader"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["programDate-2026-08-14"].exists)
        XCTAssertTrue(app.staticTexts["programEmptyState"].exists)
        XCTAssertTrue(app.buttons["programCreateWorkout"].exists)

        app.buttons["programNextWeek"].tap()
        XCTAssertTrue(app.buttons["programDate-2026-08-21"].waitForExistence(timeout: 2))
        app.buttons["programPreviousWeek"].tap()
        XCTAssertTrue(app.buttons["programDate-2026-08-14"].waitForExistence(timeout: 2))

        app.buttons["programCreateWorkout"].tap()
        XCTAssertTrue(app.staticTexts["programWorkoutState"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["programEmptyWorkout"].exists)
        XCTAssertFalse(app.buttons["programCreateWorkout"].exists)

        app.buttons["programDate-2026-08-13"].tap()
        XCTAssertTrue(app.staticTexts["programEmptyState"].waitForExistence(timeout: 2))
        app.buttons["programDate-2026-08-14"].tap()
        XCTAssertTrue(app.staticTexts["programWorkoutState"].waitForExistence(timeout: 2))

        app.buttons["programAddExercise"].tap()
        let search = app.searchFields["Search exercises"]
        XCTAssertTrue(search.waitForExistence(timeout: 2))
        search.tap()
        search.typeText("bench")
        let bench = app.buttons["exercisePickerResult-00000000-0000-4000-8000-000000000001"]
        XCTAssertTrue(bench.waitForExistence(timeout: 2))
        bench.tap()
        XCTAssertTrue(app.staticTexts["programExercise-Bench Press"].waitForExistence(timeout: 2))

        app.buttons["programAddExercise"].tap()
        let customSearch = app.searchFields["Search exercises"]
        XCTAssertTrue(customSearch.waitForExistence(timeout: 2))
        customSearch.tap()
        customSearch.typeText("Nordic Hop")
        XCTAssertTrue(app.buttons["exercisePickerAddCustom"].waitForExistence(timeout: 2))
        app.buttons["exercisePickerAddCustom"].tap()
        XCTAssertTrue(app.textFields["customExerciseName"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.textFields["customExerciseName"].value as? String, "Nordic Hop")
        app.buttons["customExerciseSave"].tap()
        XCTAssertTrue(app.staticTexts["programExercise-Nordic Hop"].waitForExistence(timeout: 2))

        let benchName = app.staticTexts["programExercise-Bench Press"]
        let nordicName = app.staticTexts["programExercise-Nordic Hop"]
        XCTAssertLessThan(benchName.frame.minY, nordicName.frame.minY)
        app.buttons["Actions for Nordic Hop, exercise 2 of 2"].tap()
        app.buttons["Move up"].tap()
        let reordered = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in nordicName.frame.minY < benchName.frame.minY },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [reordered], timeout: 2), .completed)

        app.buttons["Actions for Bench Press, exercise 2 of 2"].tap()
        app.buttons["Delete"].tap()
        XCTAssertFalse(benchName.waitForExistence(timeout: 1))
        app.buttons["programDate-2026-08-13"].tap()
        XCTAssertTrue(app.staticTexts["programEmptyState"].waitForExistence(timeout: 2))
        app.buttons["programDate-2026-08-14"].tap()
        XCTAssertTrue(nordicName.waitForExistence(timeout: 2))
        XCTAssertFalse(benchName.exists)

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["settingsPlaceholder"].waitForExistence(timeout: 2))

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["settingsPlaceholder"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["todayPlaceholder"].waitForExistence(timeout: 2))
    }
}
