import FirebaseAnalytics
import FirebaseCore

enum AnalyticsEvent: String, CaseIterable {
    case signUp = "sign_up"
    case login
    case workoutCreated = "workout_created"
    case workoutCopied = "workout_copied"
    case workoutRepeatCreated = "workout_repeat_created"
    case exerciseAdded = "exercise_added"
    case customExerciseCreated = "custom_exercise_created"
    case setCompleted = "set_completed"
    case setUncompleted = "set_uncompleted"
    case setActualEdited = "set_actual_edited"
    case exerciseSkipped = "exercise_skipped"
    case workoutCompleted = "workout_completed"
}

protocol AnalyticsTracking: AnyObject {
    func log(_ event: AnalyticsEvent)
}

final class NoOpAnalyticsTracker: AnalyticsTracking {
    func log(_ event: AnalyticsEvent) {}
}

final class FirebaseAnalyticsTracker: AnalyticsTracking {
    func log(_ event: AnalyticsEvent) {
        guard FirebaseApp.app() != nil else { return }
        Analytics.logEvent(event.rawValue, parameters: nil)
    }
}

enum AnalyticsTrackerFactory {
    static func makeDefault() -> AnalyticsTracking {
        if DemoMode.isEnabled || FirebaseBootstrap.isRunningTests() {
            return NoOpAnalyticsTracker()
        }
        return FirebaseAnalyticsTracker()
    }
}
