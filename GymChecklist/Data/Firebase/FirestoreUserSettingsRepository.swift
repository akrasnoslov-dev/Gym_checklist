import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreUserSettingsRepository: UserSettingsRepository {
    let userID: UserID
    private let store: Firestore
    private var listener: ListenerRegistration?
    private lazy var restarter = FirestoreListenerRestarter { [weak self] in self?.startListening() }
    private var observers: [UUID: @MainActor (UserSettings) -> Void] = [:]
    private let failures = PersistenceFailureBroadcaster<UserSettingsPersistenceFailure>()
    private(set) var settings: UserSettings
    private let documentKey = "default"
    private lazy var documents = OptimisticDocumentStore<String, UserSettings>(
        collection: "settings",
        journalScope: "settings",
        userID: self.userID,
        restore: { [weak self] _, snapshot in self?.restore(snapshot) },
        report: { [weak self] failure in self?.publishFailure(failure) }
    )

    init?(store: Firestore = .firestore(), currentUserID: (() -> UserID?)? = nil) {
        let user = currentUserID?() ?? Auth.auth().currentUser.map { UserID(rawValue: $0.uid) }
        guard let user, !user.rawValue.isEmpty, !user.rawValue.contains("/") else { return nil }
        userID = user
        self.store = store
        settings = UserSettings(userID: user)
        _ = documents // Loads the pending-write journal before the first snapshot.
        startListening()
    }

    private func startListening() {
        let user = userID
        listener = document.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            guard let snapshot else {
                if let error {
                    FirestoreDiagnostics.shared.record(FirestoreDiagnosticEvent(
                        operation: .listen, collection: "settings", documentID: "default", error: error
                    ))
                }
                Task { @MainActor in self?.recordListenerFailure() }
                return
            }
            // A missing document is the normal first-launch state, not a decode failure.
            let observedSettings = snapshot.exists
                ? FirestoreDiagnostics.shared.decodeLogging(
                    FirestoreUserSettingsDocument.self, from: snapshot, collection: "settings"
                )?.settings(userID: user)
                : nil
            Task { @MainActor in
                guard let self else { return }
                self.restarter.listenerDelivered(isFromCache: snapshot.metadata.isFromCache)
                if let observedSettings {
                    self.settings = observedSettings
                } else if !snapshot.metadata.hasPendingWrites {
                    self.settings = UserSettings(userID: user)
                }
                self.publish()
                self.documents.reconcileRestarted(
                    isFromCache: snapshot.metadata.isFromCache,
                    hasPendingWrites: snapshot.metadata.hasPendingWrites,
                    stableValues: observedSettings.map { [self.documentKey: $0] } ?? [:]
                )
            }
        }
    }

    deinit { MainActor.assumeIsolated { listener?.remove() } }

    /// GYM-37: the listener is dead after an error; keep the last settings and
    /// attach a new listener after a back-off, unless the user signed out.
    private func recordListenerFailure() {
        listener?.remove()
        listener = nil
        guard Auth.auth().currentUser?.uid == userID.rawValue else { return }
        restarter.listenerFailed()
    }

    func observeSettings(_ observer: @escaping @MainActor (UserSettings) -> Void) -> UserSettingsObservation {
        let id = UUID()
        observers[id] = observer
        observer(settings)
        return FirestoreUserSettingsObservation { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    func observePersistenceFailures(
        _ observer: @escaping @MainActor (UserSettingsPersistenceFailure) -> Void
    ) -> PersistenceFailureObservation {
        failures.observe(observer)
    }

    func save(_ settings: UserSettings) throws {
        guard settings.userID == userID else { throw UserSettingsRepositoryError.ownerMismatch }
        let ticket = documents.begin(
            key: documentKey,
            baseline: .value(self.settings),
            attempted: .value(settings)
        )
        self.settings = settings
        publish()
        let document = self.document
        try documents.write(ticket, documentID: documentKey) { completion in
            try document.setData(from: FirestoreUserSettingsDocument(settings: settings), completion: completion)
        }
    }

    func saveAppearance(_ appearance: Appearance) throws {
        var updated = settings
        updated.appearance = appearance
        try save(updated)
    }

    func saveWeightUnit(_ weightUnit: WeightUnit) throws {
        var updated = settings
        updated.weightUnit = weightUnit
        try save(updated)
    }

    private var document: DocumentReference {
        store.document(FirestoreDocumentPath.settings(userID: userID))
    }

    private func restore(_ snapshot: PersistedDocument<UserSettings>) {
        guard case let .value(restoredSettings) = snapshot else { return }
        settings = restoredSettings
        publish()
    }

    private func publish() { observers.values.forEach { $0(settings) } }

    private func publishFailure(_ failure: OptimisticDocumentFailure<String, UserSettings>) {
        switch failure {
        case let .saveRejected(attempted):
            failures.publish(.saveRejected(attempted))
        case let .saveUnconfirmedAfterRestart(attempted):
            failures.publish(.saveUnconfirmedAfterRestart(attempted))
        case .deleteRejected, .deleteRejectedWithoutLocalCopy, .deleteUnconfirmedAfterRestart:
            break // Settings are never deleted.
        }
    }
}

@MainActor private final class FirestoreUserSettingsObservation: UserSettingsObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}
