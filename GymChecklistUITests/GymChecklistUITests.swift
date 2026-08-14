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
        app.buttons["programDate-2026-08-12"].tap()
        XCTAssertTrue(app.staticTexts["programSelectedDate"].label.contains("August 12, 2026"))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["settingsPlaceholder"].waitForExistence(timeout: 2))

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["settingsPlaceholder"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["todayPlaceholder"].waitForExistence(timeout: 2))
    }
}
