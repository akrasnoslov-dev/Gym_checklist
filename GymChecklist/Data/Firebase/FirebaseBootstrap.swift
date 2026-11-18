import Foundation
import FirebaseCore
import FirebaseCrashlytics
import OSLog

enum FirebaseBootstrap {
    enum Status: Equatable {
        case configured
        case missingConfiguration
        case invalidConfiguration
    }

    /// Configures Firebase only from a valid app-specific plist.
    /// Callers can treat a non-configured status as a development setup error
    /// without exposing Firebase project values in UI or logs.
    static func configureIfAvailable(in bundle: Bundle = .main) -> Status {
        if FirebaseApp.app() != nil {
            startCrashReporting()
            return .configured
        }
        guard let configurationURL = bundle.url(forResource: "GoogleService-Info", withExtension: "plist") else {
            return .missingConfiguration
        }
        guard let options = FirebaseOptions(contentsOfFile: configurationURL.path) else {
            return .invalidConfiguration
        }
        FirebaseApp.configure(options: options)
        startCrashReporting()
        return .configured
    }

    private static func startCrashReporting() {
        guard FirebaseApp.app() != nil else { return }
        _ = Crashlytics.crashlytics()
        installFirestoreDiagnostics()
    }

    private static let firestoreLogger = Logger(subsystem: "dev.akrasnoslov.GymChecklist", category: "Firestore")

    /// Rejected writes, listener errors and undecodable documents go to the
    /// device log and to Crashlytics as non-fatals (GYM-22).
    private static func installFirestoreDiagnostics() {
        FirestoreDiagnostics.shared.install { event, reportToCrashlytics in
            FirebaseBootstrap.firestoreLogger.error("\(event.logLine, privacy: .public)")
            if reportToCrashlytics {
                Crashlytics.crashlytics().record(error: event.crashlyticsError)
            }
        }
    }

    static func isRunningTests(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
#if DEBUG
        return environment["UITESTING"] == "1" || environment["XCTestConfigurationFilePath"] != nil
#else
        return false
#endif
    }
}


enum DemoMode {
    static var isEnabled: Bool {
#if MVP_DEMO
        return Bundle.main.object(forInfoDictionaryKey: "MVP_DEMO") as? Bool == true
#else
        return false
#endif
    }
}
