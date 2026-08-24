import SwiftUI

@main
struct GymChecklistApp: App {
    private let firebaseStatus: FirebaseBootstrap.Status
    private let isRunningTests: Bool

    init() {
        firebaseStatus = FirebaseBootstrap.configureIfAvailable()
        isRunningTests = FirebaseBootstrap.isRunningTests()
#if DEBUG
        if firebaseStatus != .configured, !isRunningTests {
            preconditionFailure("Firebase requires GoogleService-Info.plist. See docs/firebase_setup.md.")
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            if Self.canComposeFirebaseServices(status: firebaseStatus, isRunningTests: isRunningTests) {
                ContentView()
            } else {
                FirebaseConfigurationUnavailableView()
            }
        }
    }

    static func canComposeFirebaseServices(status: FirebaseBootstrap.Status, isRunningTests: Bool) -> Bool {
        isRunningTests || status == .configured
    }
}

private struct FirebaseConfigurationUnavailableView: View {
    var body: some View {
        ContentUnavailableView(
            "App setup unavailable",
            systemImage: "exclamationmark.triangle",
            description: Text("Install a valid app configuration, then reopen Gym Checklist.")
        )
        .accessibilityIdentifier("firebaseConfigurationUnavailable")
    }
}
