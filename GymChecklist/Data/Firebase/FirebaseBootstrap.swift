import Foundation
import FirebaseCore

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
        guard FirebaseApp.app() == nil else { return .configured }
        guard let configurationURL = bundle.url(forResource: "GoogleService-Info", withExtension: "plist") else {
            return .missingConfiguration
        }
        guard let options = FirebaseOptions(contentsOfFile: configurationURL.path) else {
            return .invalidConfiguration
        }
        FirebaseApp.configure(options: options)
        return .configured
    }

    static func isRunningTests(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        environment["UITESTING"] == "1" || environment["XCTestConfigurationFilePath"] != nil
    }
}
