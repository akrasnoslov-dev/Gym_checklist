import SwiftUI

@main
struct GymChecklistApp: App {
    init() {
        let status = FirebaseBootstrap.configureIfAvailable()
#if DEBUG
        if status != .configured, !FirebaseBootstrap.isRunningTests() {
            preconditionFailure("Firebase requires GoogleService-Info.plist. See docs/firebase_setup.md.")
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
