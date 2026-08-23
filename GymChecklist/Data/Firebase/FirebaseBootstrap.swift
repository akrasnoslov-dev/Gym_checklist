import Foundation

#if canImport(FirebaseCore)
import FirebaseCore

enum FirebaseBootstrap {
    enum Status: Equatable {
        case configured
        case missingConfiguration
    }

    /// Configures Firebase only when the app-specific plist is present.
    /// Callers can treat `missingConfiguration` as a development setup error
    /// without exposing any Firebase project values in UI or logs.
    static func configureIfAvailable(in bundle: Bundle = .main) -> Status {
        guard FirebaseApp.app() == nil else { return .configured }
        guard bundle.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            return .missingConfiguration
        }
        FirebaseApp.configure()
        return .configured
    }
}
#else
enum FirebaseBootstrap {
    enum Status: Equatable {
        case configured
        case missingConfiguration
    }

    static func configureIfAvailable(in bundle: Bundle = .main) -> Status {
        .missingConfiguration
    }
}
#endif
