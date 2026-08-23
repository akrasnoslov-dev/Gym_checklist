import XCTest

final class GymChecklistUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesOnTodayAndNavigatesAllTabs() {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launch()

        XCTAssertTrue(app.otherElements["todayScreen"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Program"].tap()
        let weekHeader = app.staticTexts["programWeekHeader"]
        XCTAssertTrue(weekHeader.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["programDate-2026-08-14"].exists)
        XCTAssertTrue(app.staticTexts["programEmptyState"].exists)
        XCTAssertTrue(app.buttons["programCreateWorkout"].exists)

        let nextWeek = app.buttons["programNextWeek"]
        let previousWeek = app.buttons["programPreviousWeek"]
        XCTAssertTrue(nextWeek.isHittable)
        XCTAssertTrue(previousWeek.isHittable)
        nextWeek.tap()
        XCTAssertTrue(previousWeek.isHittable)
        previousWeek.tap()
        XCTAssertTrue(nextWeek.isHittable)

        app.buttons["programCreateWorkout"].tap()
        XCTAssertTrue(app.staticTexts["programWorkoutState"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["programEmptyWorkout"].exists)
        XCTAssertFalse(app.buttons["programCreateWorkout"].exists)

        app.buttons["programCopyWorkout"].tap()
        XCTAssertTrue(app.navigationBars["Copy workout"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["copyWorkoutSourceDate"].exists)
        XCTAssertTrue(app.staticTexts["copyWorkoutSummary"].exists)
        XCTAssertTrue(app.datePickers["copyWorkoutDestination"].exists)
        XCTAssertTrue(app.buttons["copyWorkoutAction"].exists)
        XCTAssertFalse(app.buttons["copyWorkoutAction"].isEnabled)
        app.buttons["copyWorkoutCancel"].tap()

        app.buttons["programRepeatWorkout"].tap()
        XCTAssertTrue(app.navigationBars["Repeat workout"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["repeatWorkoutSourceDate"].exists)
        XCTAssertTrue(app.staticTexts["repeatWorkoutSourceSummary"].exists)
        XCTAssertTrue(app.buttons["repeatWorkoutDuration"].exists)
        XCTAssertTrue(app.staticTexts["repeatWorkoutSummary"].exists)
        XCTAssertTrue(app.buttons["repeatWorkoutAction"].isEnabled)
        app.buttons["repeatWorkoutCancel"].tap()

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

        let addBenchSet = app.buttons["Add set to Bench Press"]
        XCTAssertTrue(addBenchSet.waitForExistence(timeout: 2))
        addBenchSet.tap()
        let firstBenchSet = app.buttons["Edit set 1 for Bench Press"]
        XCTAssertTrue(firstBenchSet.waitForExistence(timeout: 2))

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Friday, August 14, 2026"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["todayExercise-90000000-0000-4000-8000-000000000001"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["0 reps"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Start Workout"].exists)

        app.tabBars.buttons["Program"].tap()
        firstBenchSet.tap()
        XCTAssertTrue(app.textFields["programSetEditorReps"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["programSetEditorWeight"].exists)
        XCTAssertTrue(app.textFields["programSetEditorTime"].exists)
        app.buttons["programSetEditorSave"].tap()
        XCTAssertTrue(firstBenchSet.waitForExistence(timeout: 2))

        addBenchSet.tap()
        let secondBenchSetActions = app.buttons["Actions for set 2 for Bench Press"]
        XCTAssertTrue(secondBenchSetActions.waitForExistence(timeout: 2))
        secondBenchSetActions.tap()
        XCTAssertTrue(app.buttons["Move up"].waitForExistence(timeout: 2))
        app.buttons["Move up"].tap()
        XCTAssertTrue(firstBenchSet.waitForExistence(timeout: 2))

        firstBenchSet.tap()
        XCTAssertTrue(app.buttons["programSetEditorDelete"].waitForExistence(timeout: 2))
        app.buttons["programSetEditorDelete"].tap()
        XCTAssertTrue(firstBenchSet.waitForExistence(timeout: 2))

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

        let reorderedBenchActions = app.buttons["Actions for Bench Press, exercise 2 of 2"]
        XCTAssertTrue(reorderedBenchActions.waitForExistence(timeout: 2))
        reorderedBenchActions.tap()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 2))
        app.buttons["Delete"].tap()
        XCTAssertFalse(benchName.waitForExistence(timeout: 1))
        app.buttons["programDate-2026-08-13"].tap()
        XCTAssertTrue(app.staticTexts["programEmptyState"].waitForExistence(timeout: 2))
        app.buttons["programDate-2026-08-14"].tap()
        XCTAssertTrue(nordicName.waitForExistence(timeout: 2))
        XCTAssertFalse(benchName.exists)

        app.buttons["programDeleteWorkout"].tap()
        let confirmWorkoutDeletion = app.buttons
            .matching(identifier: "programConfirmDeleteWorkout")
            .firstMatch
        XCTAssertTrue(confirmWorkoutDeletion.waitForExistence(timeout: 2))
        confirmWorkoutDeletion.tap()
        XCTAssertTrue(app.staticTexts["programEmptyState"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["settingsPlaceholder"].waitForExistence(timeout: 2))

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["settingsPlaceholder"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.otherElements["todayScreen"].waitForExistence(timeout: 2))
    }
}

final class TodayInteractionUITests: XCTestCase {
    private let benchPress = "todayExercise-90000000-0000-4000-8000-000000000001"
    private let barbellRow = "todayExercise-90000000-0000-4000-8000-000000000002"
    private let firstBenchSet = "todaySet-90000000-0000-4000-8000-000000000101"
    private let secondBenchSet = "todaySet-90000000-0000-4000-8000-000000000102"
    private let rowSet = "todaySet-90000000-0000-4000-8000-000000000201"
    private let lowerSetIdentifier = "todaySet-90000000-0000-4000-8000-000000000316"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTodayCompletesAndUndoesSetWithoutLeavingTheScreen() {
        let app = launchSeededToday()
        let set = app.buttons[firstBenchSet]

        XCTAssertTrue(set.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["8 reps × 60 kg"].exists)
        assert(set, hasValue: "Incomplete")

        set.tap()
        assert(set, hasValue: "Completed")
        XCTAssertTrue(app.otherElements["todayScreen"].exists)
        XCTAssertFalse(app.alerts.element.exists)

        set.tap()
        assert(set, hasValue: "Incomplete")
        XCTAssertTrue(app.otherElements["todayScreen"].exists)
    }

    func testTodaySetUsesStableIdentifierAndAccessibleCompletionState() {
        let app = launchSeededToday()
        let exercise = app.staticTexts[benchPress]
        let set = app.buttons[firstBenchSet]

        XCTAssertTrue(exercise.waitForExistence(timeout: 5))
        XCTAssertEqual(exercise.label, "Bench Press, 2 sets")
        XCTAssertTrue(set.waitForExistence(timeout: 2))
        XCTAssertEqual(set.label, "Bench Press, set 1: 8 reps × 60 kg")
        assert(set, hasValue: "Incomplete")
        XCTAssertGreaterThanOrEqual(set.frame.height, 44)

        set.tap()
        assert(set, hasValue: "Completed")
    }

    func testTodaySetRemainsUsableAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_TODAY_WORKOUT"] = "1"
        app.launch()

        let set = app.buttons[firstBenchSet]
        XCTAssertTrue(set.waitForExistence(timeout: 5))
        XCTAssertTrue(set.isHittable)
        XCTAssertGreaterThanOrEqual(set.frame.height, 44)
        set.tap()
        assert(set, hasValue: "Completed")
    }

    func testTodayCompletesSetsInArbitraryExerciseAndSetOrder() {
        let app = launchSeededToday()
        let first = app.buttons[firstBenchSet]
        let second = app.buttons[secondBenchSet]
        let row = app.buttons[rowSet]

        XCTAssertTrue(row.waitForExistence(timeout: 5))
        assert(first, hasValue: "Incomplete")
        assert(second, hasValue: "Incomplete")

        row.tap()
        assert(row, hasValue: "Completed")
        assert(first, hasValue: "Incomplete")
        assert(second, hasValue: "Incomplete")

        second.tap()
        assert(second, hasValue: "Completed")
        assert(first, hasValue: "Incomplete")
    }

    func testTodayKeepsLowerSetVisibleAfterCompletion() {
        let app = launchSeededToday()
        let lowerSet = app.buttons[lowerSetIdentifier]

        for _ in 0..<6 where !lowerSet.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(lowerSet.isHittable)

        lowerSet.tap()
        assert(lowerSet, hasValue: "Completed")
        XCTAssertTrue(lowerSet.isHittable)
    }

    func testTodayLongPressOpensEditorWithoutCompletingTheSet() {
        let app = launchSeededToday()
        let set = app.buttons[firstBenchSet]

        XCTAssertTrue(set.waitForExistence(timeout: 5))
        set.press(forDuration: 1)
        XCTAssertTrue(app.navigationBars["Edit set"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["todaySetEditorReps"].exists)
        assert(set, hasValue: "Incomplete")

        app.buttons["todaySetEditorCancel"].tap()
        assert(set, hasValue: "Incomplete")
        XCTAssertTrue(app.staticTexts["8 reps × 60 kg"].exists)
    }

    func testTodayLongPressEditsPlanThenActualWithoutLeavingToday() {
        let app = launchSeededToday()
        let set = app.buttons[firstBenchSet]

        set.press(forDuration: 1)
        replaceText(in: app.textFields["todaySetEditorReps"], with: "6")
        app.buttons["todaySetEditorSave"].tap()
        XCTAssertTrue(app.staticTexts["6 reps × 60 kg"].waitForExistence(timeout: 2))
        assert(set, hasValue: "Incomplete")

        set.tap()
        assert(set, hasValue: "Completed")
        set.press(forDuration: 1)
        XCTAssertTrue(app.navigationBars["Edit actual"].waitForExistence(timeout: 2))
        replaceText(in: app.textFields["todaySetEditorReps"], with: "7")
        app.buttons["todaySetEditorSave"].tap()
        XCTAssertTrue(app.staticTexts["7 reps × 60 kg"].waitForExistence(timeout: 2))
        assert(set, hasValue: "Completed")
        XCTAssertTrue(app.otherElements["todayScreen"].exists)
    }

    func testTodaySkipsExerciseWithoutRemovingRemainingWork() {
        let app = launchSeededToday()
        let benchPressHeader = app.staticTexts[benchPress]

        XCTAssertTrue(benchPressHeader.waitForExistence(timeout: 5))
        benchPressHeader.press(forDuration: 1)
        let skip = app.buttons["Skip exercise"]
        XCTAssertTrue(skip.waitForExistence(timeout: 2))
        skip.tap()

        XCTAssertFalse(benchPressHeader.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts[barbellRow].exists)
        XCTAssertTrue(app.buttons[rowSet].exists)
        assert(app.buttons[rowSet], hasValue: "Incomplete")
    }

    func testTodayRestoresSkippedExerciseWithItsExistingSetState() {
        let app = launchSeededToday()
        let benchPressHeader = app.staticTexts[benchPress]
        let benchSet = app.buttons[firstBenchSet]

        benchSet.tap()
        assert(benchSet, hasValue: "Completed")
        benchPressHeader.press(forDuration: 1)
        app.buttons["Skip exercise"].tap()
        XCTAssertFalse(benchPressHeader.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons[rowSet].exists)

        let restoreMenu = app.buttons["todayRestoreSkippedExercises"]
        XCTAssertTrue(restoreMenu.waitForExistence(timeout: 2))
        restoreMenu.tap()
        let restoreBench = app.buttons["todayRestore-90000000-0000-4000-8000-000000000001"]
        XCTAssertTrue(restoreBench.waitForExistence(timeout: 2))
        restoreBench.tap()

        XCTAssertTrue(benchPressHeader.waitForExistence(timeout: 2))
        assert(benchSet, hasValue: "Completed")
        XCTAssertTrue(app.buttons[rowSet].exists)
        XCTAssertFalse(app.buttons["todayRestoreSkippedExercises"].exists)
    }

    private func launchSeededToday() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_TODAY_WORKOUT"] = "1"
        app.launch()
        XCTAssertTrue(app.otherElements["todayScreen"].waitForExistence(timeout: 5))
        return app
    }

    private func assert(_ element: XCUIElement, hasValue expectedValue: String) {
        let expectation = expectation(
            for: NSPredicate(format: "value == %@", expectedValue),
            evaluatedWith: element
        )
        wait(for: [expectation], timeout: 2)
    }

    private func replaceText(in field: XCUIElement, with value: String) {
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 8))
        field.typeText(value)
    }
}

final class TodayEmptyStateUITests: XCTestCase {
    func testNoProgramStateOpensProgramForToday() {
        let app = launchToday()

        XCTAssertTrue(app.otherElements["todayNoProgramState"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No workout planned yet."].exists)
        XCTAssertTrue(app.buttons["todayCreateWorkout"].exists)
        XCTAssertTrue(app.buttons["Create workout"].exists)
        XCTAssertFalse(app.otherElements["todayRestDayState"].exists)

        app.buttons["todayCreateWorkout"].tap()
        assertProgramIsFocusedOnToday(in: app)
    }

    func testRestDayStateOpensProgramForToday() {
        let app = launchToday(environment: ["UITEST_SEED_REST_DAY_PROGRAM": "1"])

        XCTAssertTrue(app.otherElements["todayRestDayState"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Rest day."].exists)
        XCTAssertTrue(app.staticTexts["See you tomorrow."].exists)
        XCTAssertTrue(app.buttons["todayViewProgram"].exists)
        XCTAssertTrue(app.buttons["View program"].exists)
        XCTAssertFalse(app.otherElements["todayNoProgramState"].exists)

        app.buttons["todayViewProgram"].tap()
        assertProgramIsFocusedOnToday(in: app)
    }

    private func launchToday(environment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        environment.forEach { app.launchEnvironment[$0.key] = $0.value }
        app.launch()
        XCTAssertTrue(app.otherElements["todayScreen"].waitForExistence(timeout: 5))
        return app
    }

    private func assertProgramIsFocusedOnToday(in app: XCUIApplication) {
        XCTAssertTrue(app.otherElements["programScreen"].waitForExistence(timeout: 2))
        let selectedDate = app.staticTexts["programSelectedDate"]
        XCTAssertTrue(selectedDate.exists)
        XCTAssertEqual(selectedDate.label, "Friday, August 14, 2026")
        XCTAssertTrue(app.staticTexts["programEmptyState"].exists)
    }
}

final class TodayCompletionUITests: XCTestCase {
    func testLastRemainingSetShowsDismissibleCompletionPopupOncePerTransition() {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_COMPLETION_WORKOUT"] = "1"
        app.launch()

        let benchPress = app.staticTexts["todayExercise-90000000-0000-4000-8000-000000000001"]
        let rowSet = app.buttons["todaySet-90000000-0000-4000-8000-000000000201"]
        XCTAssertTrue(benchPress.waitForExistence(timeout: 5))
        benchPress.press(forDuration: 1)
        app.buttons["Skip exercise"].tap()
        XCTAssertTrue(rowSet.waitForExistence(timeout: 2))

        rowSet.tap()
        XCTAssertTrue(app.otherElements["todayCompletionPopup"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Another one done."].exists)
        XCTAssertTrue(app.buttons["Done"].exists)
        XCTAssertTrue(app.otherElements["todayScreen"].exists)
        app.buttons["todayCompletionDismiss"].tap()
        XCTAssertTrue(app.otherElements["todayScreen"].exists)
        XCTAssertFalse(app.otherElements["todayCompletionPopup"].exists)

        rowSet.tap()
        XCTAssertFalse(app.otherElements["todayCompletionPopup"].exists)
        rowSet.tap()
        XCTAssertTrue(app.otherElements["todayCompletionPopup"].waitForExistence(timeout: 2))
    }

    func testSkippingLastRemainingExerciseShowsCompletionPopup() {
        let app = launchCompletionWorkout()
        let benchSet = app.buttons["todaySet-90000000-0000-4000-8000-000000000101"]
        let row = app.staticTexts["todayExercise-90000000-0000-4000-8000-000000000002"]

        benchSet.tap()
        XCTAssertFalse(app.otherElements["todayCompletionPopup"].exists)
        row.press(forDuration: 1)
        app.buttons["Skip exercise"].tap()

        XCTAssertTrue(app.otherElements["todayCompletionPopup"].waitForExistence(timeout: 2))
    }

    func testCompletedWorkoutDoesNotShowCompletionPopupOnLaunch() {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_COMPLETION_WORKOUT"] = "1"
        app.launchEnvironment["UITEST_SEED_COMPLETED_WORKOUT"] = "1"
        app.launch()

        XCTAssertTrue(app.otherElements["todayScreen"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["todayCompletionPopup"].exists)
    }

    private func launchCompletionWorkout() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_COMPLETION_WORKOUT"] = "1"
        app.launch()
        XCTAssertTrue(app.otherElements["todayScreen"].waitForExistence(timeout: 5))
        return app
    }
}
