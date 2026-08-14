import XCTest

final class GymChecklistUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesOnTodayAndNavigatesAllTabs() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["todayPlaceholder"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Program"].tap()
        XCTAssertTrue(app.staticTexts["programPlaceholder"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["settingsPlaceholder"].waitForExistence(timeout: 2))

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["settingsPlaceholder"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["todayPlaceholder"].waitForExistence(timeout: 2))
    }
}
