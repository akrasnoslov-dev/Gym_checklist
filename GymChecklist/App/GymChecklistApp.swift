import GoogleSignIn
import SwiftUI

@main
struct GymChecklistApp: App {
    private let firebaseStatus: FirebaseBootstrap.Status
    private let isRunningTests: Bool

    init() {
        isRunningTests = FirebaseBootstrap.isRunningTests()
        firebaseStatus = Self.initialFirebaseStatus(
            isRunningTests: isRunningTests,
            isDemoModeEnabled: DemoMode.isEnabled,
            configure: { FirebaseBootstrap.configureIfAvailable() }
        )
#if DEBUG
        if firebaseStatus != .configured, !isRunningTests, !DemoMode.isEnabled {
            preconditionFailure("Firebase requires GoogleService-Info.plist. See docs/firebase_setup.md.")
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if Self.canComposeFirebaseServices(status: firebaseStatus, isRunningTests: isRunningTests) {
                    ContentView()
                } else {
                    FirebaseConfigurationUnavailableView()
                }
            }
            .onOpenURL { url in
                _ = GIDSignIn.sharedInstance.handle(url)
            }
        }
    }

    static func canComposeFirebaseServices(status: FirebaseBootstrap.Status, isRunningTests: Bool) -> Bool {
        DemoMode.isEnabled || isRunningTests || status == .configured
    }

    static func initialFirebaseStatus(
        isRunningTests: Bool,
        isDemoModeEnabled: Bool,
        configure: () -> FirebaseBootstrap.Status
    ) -> FirebaseBootstrap.Status {
        guard !isRunningTests, !isDemoModeEnabled else { return .missingConfiguration }
        return configure()
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
