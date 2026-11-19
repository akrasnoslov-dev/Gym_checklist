import Foundation
import FirebaseCore
import FirebaseCrashlytics
import FirebaseFirestore
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

/// Keeps a signed-out or deleted account's Firestore data off the device (GYM-8).
@MainActor
enum FirestoreLocalData {
    /// Waits until queued offline writes reach the server, or the timeout passes.
    /// Returns false when writes are still pending (for example offline).
    static func waitForPendingWrites(timeout: TimeInterval = 5) async -> Bool {
        guard FirebaseApp.app() != nil else { return true }
        return await withCheckedContinuation { continuation in
            let once = ResumeOnce()
            Firestore.firestore().waitForPendingWrites { error in
                if once.claim() { continuation.resume(returning: error == nil) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                if once.claim() { continuation.resume(returning: false) }
            }
        }
    }

    /// Stops the current Firestore instance and deletes its on-disk cache.
    /// The next `Firestore.firestore()` call creates a fresh instance.
    static func clear() async {
        guard FirebaseApp.app() != nil else { return }
        let store = Firestore.firestore()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            store.terminate { _ in continuation.resume() }
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            store.clearPersistence { error in
                if let error {
                    FirestoreDiagnostics.shared.record(FirestoreDiagnosticEvent(
                        operation: .delete, collection: "localCache", documentID: nil, error: error
                    ))
                }
                continuation.resume()
            }
        }
    }

    /// After sign-out: clear the cache unless offline changes are still waiting
    /// to sync. Those stay on the device so they are not lost; they upload the
    /// next time the same account signs in.
    static func clearAfterSignOut(userID: UserID) {
        guard !PendingMutationJournalStorage.hasUnconfirmedWrites(userID: userID) else { return }
        PendingMutationJournalStorage.purge(userID: userID)
        Task { await clear() }
    }

    private final class ResumeOnce: @unchecked Sendable {
        private let lock = NSLock()
        private var resumed = false
        func claim() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            guard !resumed else { return false }
            resumed = true
            return true
        }
    }
}
