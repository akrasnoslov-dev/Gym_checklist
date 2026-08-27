import XCTest

final class GymChecklistUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesOnTodayAndNavigatesAllTabs() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_INITIAL_SELECTED_DATE"] = "2026-08-14"
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))

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
        XCTAssertTrue(waitForLabel(
            of: app.descendants(matching: .any)["programSelectedDate"],
            toEqual: "Friday, August 21, 2026"
        ))
        previousWeek.tap()
        XCTAssertTrue(waitForLabel(
            of: app.descendants(matching: .any)["programSelectedDate"],
            toEqual: "Friday, August 14, 2026"
        ))

        app.buttons["programCreateWorkout"].tap()
        XCTAssertTrue(app.staticTexts["programWorkoutState"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["programEmptyWorkout"].exists)
        XCTAssertFalse(app.buttons["programCreateWorkout"].exists)

        // Navigate away only after the selected date has dynamic workout content.
        // This guards the List subtree refresh used by week navigation.
        let nextWeekAfterCreatingWorkout = app.buttons["programNextWeek"]
        XCTAssertTrue(nextWeekAfterCreatingWorkout.waitForExistence(timeout: 2))
        nextWeekAfterCreatingWorkout.tap()
        XCTAssertTrue(waitForLabel(
            of: app.descendants(matching: .any)["programSelectedDate"],
            toEqual: "Friday, August 21, 2026"
        ))
        XCTAssertTrue(app.staticTexts["programEmptyState"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["programCreateWorkout"].exists)

        // Reacquire this control because changing weeks intentionally recreates
        // the Program content subtree.
        let previousWeekAfterEmptyWeek = app.buttons["programPreviousWeek"]
        XCTAssertTrue(previousWeekAfterEmptyWeek.waitForExistence(timeout: 2))
        previousWeekAfterEmptyWeek.tap()
        XCTAssertTrue(waitForLabel(
            of: app.descendants(matching: .any)["programSelectedDate"],
            toEqual: "Friday, August 14, 2026"
        ))
        XCTAssertTrue(app.staticTexts["programWorkoutState"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["programEmptyWorkout"].exists)

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
        XCTAssertTrue(app.descendants(matching: .any)["settingsPlaceholder"].waitForExistence(timeout: 2))
        let appearance = app.descendants(matching: .any)["settingsAppearance"]
        XCTAssertTrue(appearance.exists)
        XCTAssertEqual(appearance.value as? String, "system")

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.descendants(matching: .any)["settingsPlaceholder"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 2))
    }

    func testAppearanceSelectionKeepsTodayAvailable() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        let appearance = app.descendants(matching: .any)["settingsAppearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 2))
        app.buttons["settingsAppearanceDark"].tap()
        XCTAssertEqual(appearance.value as? String, "dark")
        XCTAssertEqual(app.descendants(matching: .any)["authenticatedContent"].value as? String, "dark")

        XCTAssertTrue(selectAppearance("system", buttonIdentifier: "settingsAppearanceSystem", in: app, picker: appearance))
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 2))
    }

    func testWeightUnitUpdatesTodayAndProgramWithoutChangingStoredWorkout() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_TODAY_WORKOUT"] = "1"
        app.launch()

        XCTAssertTrue(app.staticTexts["8 reps × 60 kg"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Settings"].tap()
        let weightUnit = app.descendants(matching: .any)["settingsWeightUnit"]
        XCTAssertTrue(weightUnit.waitForExistence(timeout: 2))
        XCTAssertEqual(weightUnit.value as? String, "kg")
        XCTAssertTrue(app.staticTexts["settingsAccountSummary"].exists)
        app.buttons["settingsWeightUnitLb"].tap()
        XCTAssertEqual(weightUnit.value as? String, "lb")

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["8 reps × 132.28 lb"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Program"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["programScreen"].waitForExistence(timeout: 5))
        let programSet = app.buttons.matching(
            NSPredicate(format: "value == %@", "8 reps × 132.28 lb")
        ).firstMatch
        XCTAssertTrue(reveal(programSet, in: app))

        app.tabBars.buttons["Settings"].tap()
        app.buttons["settingsWeightUnitKg"].tap()
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["8 reps × 60 kg"].waitForExistence(timeout: 5))
    }

    func testProgramShowsReadOnlyHistoryWithActualIncompleteAndSkippedStates() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_HISTORY_WORKOUT"] = "1"
        app.launchEnvironment["UITEST_INITIAL_SELECTED_DATE"] = "2026-08-07"
        app.launch()

        openProgram(app)
        let historyDate = app.buttons["programDate-2026-08-07"]
        XCTAssertTrue(historyDate.waitForExistence(timeout: 5))
        historyDate.tap()

        let history = app.descendants(matching: .any)["programHistoryWorkout"]
        XCTAssertTrue(reveal(history, in: app))
        let completedSet = app.buttons["programHistorySet-90000000-0000-4000-8000-000000000401"]
        XCTAssertTrue(reveal(completedSet, in: app))
        XCTAssertEqual(completedSet.value as? String, "Completed, actual 7 reps × 65 kg")
        let incompleteSet = app.descendants(matching: .any)["programHistorySet-90000000-0000-4000-8000-000000000402"]
        XCTAssertTrue(reveal(incompleteSet, in: app))
        XCTAssertEqual(incompleteSet.value as? String, "Incomplete, planned 12 reps")
        XCTAssertTrue(reveal(
            app.descendants(matching: .any)["programHistoryExerciseSkipped-90000000-0000-4000-8000-000000000005"],
            in: app
        ))
        XCTAssertFalse(app.buttons["programAddExercise"].exists)
        XCTAssertFalse(app.buttons["programDeleteWorkout"].exists)
        XCTAssertFalse(app.buttons["programEditExercises"].exists)
        XCTAssertFalse(app.buttons["programCopyWorkout"].exists)
        XCTAssertFalse(app.buttons["programRepeatWorkout"].exists)
    }

    func testProgramEditsCompletedHistoricalActualAndRetainsItAfterReopen() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_HISTORY_WORKOUT"] = "1"
        app.launchEnvironment["UITEST_INITIAL_SELECTED_DATE"] = "2026-08-07"
        app.launch()

        openProgram(app)
        let historyDate = app.buttons["programDate-2026-08-07"]
        XCTAssertTrue(historyDate.waitForExistence(timeout: 5))
        historyDate.tap()
        let completedSet = app.buttons["programHistorySet-90000000-0000-4000-8000-000000000401"]
        XCTAssertTrue(reveal(completedSet, in: app))
        XCTAssertFalse(app.buttons["programHistorySet-90000000-0000-4000-8000-000000000402"].exists)

        completedSet.tap()
        XCTAssertTrue(app.navigationBars["Edit actual"].waitForExistence(timeout: 2))
        replaceText(in: app.textFields["programHistoryActualEditorReps"], with: "9")
        app.buttons["programHistoryActualEditorSave"].tap()
        XCTAssertTrue(waitForValue(completedSet, "Completed, actual 9 reps × 65 kg"))

        XCTAssertTrue(revealProgramDate(historyDate, in: app))
        app.buttons["programDate-2026-08-06"].tap()
        XCTAssertTrue(revealProgramDate(historyDate, in: app))
        app.buttons["programDate-2026-08-07"].tap()
        XCTAssertTrue(reveal(completedSet, in: app))
        XCTAssertTrue(waitForValue(completedSet, "Completed, actual 9 reps × 65 kg"))
    }

    func testEmptyWorkoutTodayStateOffersProgramNavigation() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launch()

        app.tabBars.buttons["Program"].tap()
        app.buttons["programCreateWorkout"].tap()
        app.tabBars.buttons["Today"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["todayEmptyWorkoutState"].waitForExistence(timeout: 2))
        app.buttons["todayEmptyWorkoutViewProgram"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["programScreen"].exists)
    }

    func testProgramDoesNotOfferCreationForPastEmptyDate() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_HISTORY_WORKOUT"] = "1"
        app.launchEnvironment["UITEST_INITIAL_SELECTED_DATE"] = "2026-08-06"
        app.launch()

        openProgram(app)
        let pastDate = app.buttons["programDate-2026-08-06"]
        XCTAssertTrue(pastDate.waitForExistence(timeout: 5))
        pastDate.tap()

        XCTAssertTrue(reveal(app.descendants(matching: .any)["programEmptyState"], in: app))
        XCTAssertFalse(app.buttons["programCreateWorkout"].exists)
    }

    private func replaceText(in field: XCUIElement, with value: String) {
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 8))
        field.typeText(value)
    }

    private func openProgram(_ app: XCUIApplication) {
        app.tabBars.buttons["Program"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["programScreen"].waitForExistence(timeout: 5))
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maximumSwipes: Int = 3) -> Bool {
        for attempt in 0...maximumSwipes {
            if element.waitForExistence(timeout: 1) { return true }
            if attempt < maximumSwipes { app.swipeUp() }
        }
        return false
    }

    private func revealProgramDate(_ date: XCUIElement, in app: XCUIApplication) -> Bool {
        for attempt in 0...3 {
            if date.isHittable { return true }
            if attempt < 3 { app.swipeDown() }
        }
        return false
    }

    private func waitForValue(_ element: XCUIElement, _ expectedValue: String) -> Bool {
        let expectation = expectation(
            for: NSPredicate(format: "value == %@", expectedValue),
            evaluatedWith: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: 5) == .completed
    }

    private func waitForLabel(of element: XCUIElement, toEqual expectedLabel: String) -> Bool {
        let expectation = expectation(
            for: NSPredicate(format: "label == %@", expectedLabel),
            evaluatedWith: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: 5) == .completed
    }

    private func selectAppearance(
        _ expectedValue: String,
        buttonIdentifier: String,
        in app: XCUIApplication,
        picker: XCUIElement
    ) -> Bool {
        let button = app.buttons[buttonIdentifier]
        for _ in 0..<2 {
            if picker.value as? String == expectedValue { return true }
            button.tap()
            if waitForValue(picker, expectedValue) { return true }
        }
        return picker.value as? String == expectedValue
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
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].exists)
        XCTAssertFalse(app.alerts.element.exists)

        set.tap()
        assert(set, hasValue: "Incomplete")
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].exists)
    }

    func testTodayFailedSaveShowsRetryMessageAndAllowsSafeRetry() {
        let app = launchSeededToday(environment: ["UITEST_FAIL_NEXT_TODAY_SAVE": "1"])
        let set = app.buttons[firstBenchSet]

        set.tap()
        XCTAssertTrue(app.alerts["Couldn't confirm this change"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Check your workout before trying again."].exists)
        assert(set, hasValue: "Incomplete")

        app.alerts["Couldn't confirm this change"].buttons["OK"].tap()
        set.tap()
        assert(set, hasValue: "Completed")
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].exists)
    }

    func testTodayFailedSkipKeepsExerciseVisibleForManualRetry() {
        let app = launchSeededToday(environment: ["UITEST_FAIL_NEXT_TODAY_SAVE": "1"])
        let header = app.staticTexts[benchPress]

        header.press(forDuration: 1)
        app.buttons["Skip exercise"].tap()
        XCTAssertTrue(app.alerts["Couldn't confirm this change"].waitForExistence(timeout: 2))
        XCTAssertTrue(header.exists)

        app.alerts["Couldn't confirm this change"].buttons["OK"].tap()
        header.press(forDuration: 1)
        app.buttons["Skip exercise"].tap()
        XCTAssertFalse(header.waitForExistence(timeout: 2))
    }

    func testTodayFailedRestoreKeepsSkippedExerciseAvailableForManualRetry() {
        let app = launchSeededToday(environment: ["UITEST_FAIL_TODAY_SAVE_AFTER": "1"])
        let header = app.staticTexts[benchPress]

        header.press(forDuration: 1)
        app.buttons["Skip exercise"].tap()
        let restoreMenu = app.buttons["todayRestoreSkippedExercises"]
        XCTAssertTrue(restoreMenu.waitForExistence(timeout: 2))
        restoreMenu.tap()
        app.buttons["todayRestore-90000000-0000-4000-8000-000000000001"].tap()
        XCTAssertTrue(app.alerts["Couldn't confirm this change"].waitForExistence(timeout: 2))
        XCTAssertFalse(header.exists)

        app.alerts["Couldn't confirm this change"].buttons["OK"].tap()
        restoreMenu.tap()
        app.buttons["todayRestore-90000000-0000-4000-8000-000000000001"].tap()
        XCTAssertTrue(header.waitForExistence(timeout: 2))
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
        app.launchEnvironment["UITESTING"] = "1"
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

    func testProgramDateCommunicatesFullDateStateAndSelection() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launch()

        app.tabBars.buttons["Program"].tap()
        let date = app.buttons["programDate-2026-08-14"]
        XCTAssertTrue(date.waitForExistence(timeout: 2))
        XCTAssertEqual(date.label, "Friday, August 14, 2026")
        assert(date, hasValue: "Empty")
        XCTAssertTrue(date.isSelected)
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
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].exists)
    }

    func testTodayEditorFailedSaveKeepsDraftOpenForManualRetry() {
        let app = launchSeededToday(environment: ["UITEST_FAIL_NEXT_TODAY_SAVE": "1"])
        let set = app.buttons[firstBenchSet]

        set.press(forDuration: 1)
        replaceText(in: app.textFields["todaySetEditorReps"], with: "6")
        app.buttons["todaySetEditorSave"].tap()
        XCTAssertTrue(app.alerts["Couldn't confirm this change"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.navigationBars["Edit set"].exists)
        XCTAssertTrue(app.textFields["todaySetEditorReps"].exists)

        app.alerts["Couldn't confirm this change"].buttons["OK"].tap()
        app.buttons["todaySetEditorSave"].tap()
        XCTAssertTrue(app.staticTexts["6 reps × 60 kg"].waitForExistence(timeout: 2))
        assert(set, hasValue: "Incomplete")
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

    func testTodayRestoresSkippedExerciseWithItsOriginalCompletionState() {
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

    private func launchSeededToday(environment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_TODAY_WORKOUT"] = "1"
        environment.forEach { app.launchEnvironment[$0.key] = $0.value }
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))
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

        XCTAssertTrue(app.descendants(matching: .any)["todayNoProgramState"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No workout planned yet."].exists)
        XCTAssertTrue(app.buttons["todayCreateWorkout"].exists)
        XCTAssertTrue(app.buttons["Create workout"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["todayRestDayState"].exists)

        app.buttons["todayCreateWorkout"].tap()
        assertProgramIsFocusedOnToday(in: app)
    }

    func testRestDayStateOpensProgramForToday() {
        let app = launchToday(environment: ["UITEST_SEED_REST_DAY_PROGRAM": "1"])

        XCTAssertTrue(app.descendants(matching: .any)["todayRestDayState"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Rest day."].exists)
        XCTAssertTrue(app.staticTexts["See you tomorrow."].exists)
        XCTAssertTrue(app.buttons["todayViewProgram"].exists)
        XCTAssertTrue(app.buttons["View program"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["todayNoProgramState"].exists)

        app.buttons["todayViewProgram"].tap()
        assertProgramIsFocusedOnToday(in: app)
    }

    private func launchToday(environment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        environment.forEach { app.launchEnvironment[$0.key] = $0.value }
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))
        return app
    }

    private func assertProgramIsFocusedOnToday(in app: XCUIApplication) {
        XCTAssertTrue(app.descendants(matching: .any)["programScreen"].waitForExistence(timeout: 2))
        let selectedDate = app.staticTexts["programSelectedDate"]
        XCTAssertTrue(selectedDate.exists)
        XCTAssertEqual(selectedDate.label, "Friday, August 14, 2026")
        XCTAssertTrue(app.staticTexts["programEmptyState"].exists)
    }
}

final class RegistrationUITests: XCTestCase {
    func testAccountDeletionCancellationKeepsTheUserSignedIn() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        app.buttons["accountDelete"].tap()
        XCTAssertTrue(app.alerts["Delete account?"].waitForExistence(timeout: 2))
        app.alerts["Delete account?"].buttons["Cancel"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["settingsPlaceholder"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["authRegistrationScreen"].exists)
    }

    func testConfirmedAccountDeletionRoutesToAuthScreen() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        app.buttons["accountDelete"].tap()
        app.alerts["Delete account?"].buttons["Delete account"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["authRegistrationScreen"].waitForExistence(timeout: 5))
    }

    func testAccountDeletionReauthenticationRequirementKeepsTheSession() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_ACCOUNT_DELETION_ERROR"] = "recentAuthentication"
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        app.buttons["accountDelete"].tap()
        app.alerts["Delete account?"].buttons["Delete account"].tap()

        let deletionError = app.staticTexts["authLogoutError"]
        XCTAssertTrue(reveal(deletionError, in: app))
        XCTAssertEqual(deletionError.label, "Error: For security, sign in again and then retry account deletion.")
        XCTAssertTrue(app.descendants(matching: .any)["settingsPlaceholder"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["authRegistrationScreen"].exists)
    }

    func testAppleAccountDeletionVerifiesBeforeRoutingToAuthScreen() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_ACCOUNT_DELETION_PROVIDER"] = "apple"
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        app.buttons["accountDelete"].tap()
        app.alerts["Delete account?"].buttons["Delete account"].tap()
        let verifyApple = app.buttons["accountDeleteVerifyApple"]
        XCTAssertTrue(verifyApple.waitForExistence(timeout: 5))
        verifyApple.tap()

        XCTAssertTrue(app.descendants(matching: .any)["authRegistrationScreen"].waitForExistence(timeout: 8))
        XCTAssertFalse(verifyApple.exists)
    }

    func testAppleAccountDeletionVerificationFailureKeepsTheSession() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_ACCOUNT_DELETION_PROVIDER"] = "apple"
        app.launchEnvironment["UITEST_ACCOUNT_DELETION_ERROR"] = "recentAuthentication"
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        app.buttons["accountDelete"].tap()
        app.alerts["Delete account?"].buttons["Delete account"].tap()
        let verifyApple = app.buttons["accountDeleteVerifyApple"]
        XCTAssertTrue(verifyApple.waitForExistence(timeout: 5))
        verifyApple.tap()

        XCTAssertTrue(app.descendants(matching: .any)["accountDeleteVerificationError"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["settingsPlaceholder"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["authRegistrationScreen"].exists)
    }

    func testGoogleAccountDeletionVerifiesBeforeRoutingToAuthScreen() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_ACCOUNT_DELETION_PROVIDER"] = "google"
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        app.buttons["accountDelete"].tap()
        app.alerts["Delete account?"].buttons["Delete account"].tap()
        let verifyGoogle = app.buttons["accountDeleteVerifyGoogle"]
        XCTAssertTrue(verifyGoogle.waitForExistence(timeout: 5))
        verifyGoogle.tap()

        XCTAssertTrue(app.descendants(matching: .any)["authRegistrationScreen"].waitForExistence(timeout: 5))
        XCTAssertFalse(verifyGoogle.exists)
    }

    func testAppleSignInRoutesToToday() {
        let app = launchRegistration()

        app.buttons["authSignInWithApple"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))
    }

    func testGoogleSignInRoutesToToday() {
        let app = launchRegistration()

        app.buttons["authSignInWithGoogle"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))
    }

    func testPasswordResetShowsNeutralConfirmationWithoutSigningIn() {
        let app = launchRegistration()
        app.buttons["authShowSignIn"].tap()
        app.buttons["authForgotPassword"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["authPasswordResetScreen"].waitForExistence(timeout: 2))
        app.textFields["authEmail"].tap()
        app.textFields["authEmail"].typeText("member@example.com")
        app.buttons["authSendReset"].tap()
        XCTAssertTrue(app.staticTexts["If an account matches this email, we’ll send reset instructions."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["authPasswordResetScreen"].exists)
        app.buttons["authBackToSignIn"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["authSignInScreen"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["authResetMessage"].exists)
    }

    func testLogoutThenSignInDoesNotShowPriorUsersWorkout() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_TODAY_WORKOUT"] = "1"
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["todayExercise-90000000-0000-4000-8000-000000000001"].waitForExistence(timeout: 8))

        app.tabBars.buttons["Settings"].tap()
        app.buttons["authLogout"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["authRegistrationScreen"].waitForExistence(timeout: 5))
        app.buttons["authShowSignIn"].tap()
        app.textFields["authEmail"].tap()
        app.textFields["authEmail"].typeText("member@example.com")
        app.secureTextFields["authPassword"].tap()
        app.secureTextFields["authPassword"].typeText("password")
        app.buttons["authSignIn"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["todayNoProgramState"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Bench Press"].exists)
    }

    func testSignInAndLogoutReturnToAuthScreen() {
        let app = launchRegistration()

        app.buttons["authShowSignIn"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["authSignInScreen"].waitForExistence(timeout: 2))
        app.textFields["authEmail"].tap()
        app.textFields["authEmail"].typeText("member@example.com")
        app.secureTextFields["authPassword"].tap()
        app.secureTextFields["authPassword"].typeText("password")
        app.buttons["authSignIn"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Settings"].tap()
        app.buttons["authLogout"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["authRegistrationScreen"].waitForExistence(timeout: 5))
    }

    func testRegistrationScreenShowsInvalidEmailInline() {
        let app = launchRegistration()

        app.textFields["authEmail"].tap()
        app.textFields["authEmail"].typeText("not-an-email")
        app.secureTextFields["authPassword"].tap()
        app.secureTextFields["authPassword"].typeText("password")
        app.secureTextFields["authConfirmPassword"].tap()
        app.secureTextFields["authConfirmPassword"].typeText("password")
        app.buttons["authRegister"].tap()

        let error = app.staticTexts["authRegistrationError"]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertEqual(error.label, "Error: Enter a valid email address.")
        XCTAssertTrue(app.descendants(matching: .any)["authRegistrationScreen"].exists)
    }

    func testRegistrationControlsRemainUsableAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_AUTH_MODE"] = "registration"
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()

        let email = app.textFields["authEmail"]
        let password = app.secureTextFields["authPassword"]
        let confirmation = app.secureTextFields["authConfirmPassword"]
        let submit = app.buttons["authRegister"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        XCTAssertTrue(password.isHittable)
        XCTAssertTrue(confirmation.isHittable)
        for _ in 0..<3 where !submit.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(submit.isHittable)
        XCTAssertGreaterThanOrEqual(submit.frame.height, 44)
    }

    func testRegistrationScreenShowsPasswordMismatchInline() {
        let app = launchRegistration()

        app.textFields["authEmail"].tap()
        app.textFields["authEmail"].typeText("member@example.com")
        app.secureTextFields["authPassword"].tap()
        app.secureTextFields["authPassword"].typeText("password")
        app.secureTextFields["authConfirmPassword"].tap()
        app.secureTextFields["authConfirmPassword"].typeText("different")
        app.buttons["authRegister"].tap()

        let error = app.staticTexts["authRegistrationError"]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertEqual(error.label, "Error: Passwords do not match.")
        XCTAssertTrue(app.descendants(matching: .any)["authRegistrationScreen"].exists)
    }

    func testSuccessfulRegistrationRoutesDirectlyToTodayEmptyState() {
        let app = launchRegistration()

        app.textFields["authEmail"].tap()
        app.textFields["authEmail"].typeText("member@example.com")
        app.secureTextFields["authPassword"].tap()
        app.secureTextFields["authPassword"].typeText("password")
        app.secureTextFields["authConfirmPassword"].tap()
        app.secureTextFields["authConfirmPassword"].typeText("password")
        app.buttons["authRegister"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No workout planned yet."].exists)
        XCTAssertFalse(app.descendants(matching: .any)["authRegistrationScreen"].exists)
    }

    private func launchRegistration() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_AUTH_MODE"] = "registration"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["authRegistrationScreen"].waitForExistence(timeout: 5))
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maximumSwipes: Int = 3) -> Bool {
        for attempt in 0...maximumSwipes {
            if element.waitForExistence(timeout: 1) { return true }
            if attempt < maximumSwipes { app.swipeUp() }
        }
        return false
    }
}

final class TodayCompletionUITests: XCTestCase {
    func testCompletingEveryRequiredSetShowsDismissibleCompletionPopup() {
        let app = launchCompletionWorkout()
        let benchSet = app.buttons["todaySet-90000000-0000-4000-8000-000000000101"]
        let rowSet = app.buttons["todaySet-90000000-0000-4000-8000-000000000201"]

        benchSet.tap()
        XCTAssertFalse(app.descendants(matching: .any)["todayCompletionPopup"].exists)
        rowSet.tap()
        XCTAssertTrue(app.descendants(matching: .any)["todayCompletionPopup"].waitForExistence(timeout: 2))
        XCTAssertFalse(rowSet.exists)
        let dismiss = app.buttons["todayCompletionDismiss"]
        XCTAssertTrue(dismiss.isHittable)
        XCTAssertFalse(benchSet.isHittable)
        dismiss.tap()
        XCTAssertTrue(rowSet.waitForExistence(timeout: 2))
        XCTAssertTrue(rowSet.isHittable)
    }

    func testLastRemainingSetShowsDismissibleCompletionPopupOncePerTransition() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
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
        XCTAssertTrue(app.descendants(matching: .any)["todayCompletionPopup"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Another one done."].exists)
        XCTAssertTrue(app.buttons["Done"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].exists)
        app.buttons["todayCompletionDismiss"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["todayCompletionPopup"].exists)

        rowSet.tap()
        XCTAssertFalse(app.descendants(matching: .any)["todayCompletionPopup"].exists)
        rowSet.tap()
        XCTAssertTrue(app.descendants(matching: .any)["todayCompletionPopup"].waitForExistence(timeout: 2))
    }

    func testSkippingLastRemainingExerciseShowsCompletionPopup() {
        let app = launchCompletionWorkout()
        let benchSet = app.buttons["todaySet-90000000-0000-4000-8000-000000000101"]
        let row = app.staticTexts["todayExercise-90000000-0000-4000-8000-000000000002"]

        benchSet.tap()
        XCTAssertFalse(app.descendants(matching: .any)["todayCompletionPopup"].exists)
        row.press(forDuration: 1)
        app.buttons["Skip exercise"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["todayCompletionPopup"].waitForExistence(timeout: 2))
    }

    func testCompletedWorkoutDoesNotShowCompletionPopupOnLaunch() {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_COMPLETION_WORKOUT"] = "1"
        app.launchEnvironment["UITEST_SEED_COMPLETED_WORKOUT"] = "1"
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["todayCompletionPopup"].exists)
    }

    private func launchCompletionWorkout() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["UITEST_REFERENCE_DATE"] = "2026-08-14"
        app.launchEnvironment["UITEST_SEED_COMPLETION_WORKOUT"] = "1"
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["todayScreen"].waitForExistence(timeout: 5))
        return app
    }
}
