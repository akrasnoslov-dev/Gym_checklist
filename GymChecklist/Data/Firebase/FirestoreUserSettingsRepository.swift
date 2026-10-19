import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreUserSettingsRepository: UserSettingsRepository {
    let userID: UserID
    private let store: Firestore
    private var listener: ListenerRegistration?
    private var observers: [UUID: @MainActor (UserSettings) -> Void] = [:]
    private let failures = PersistenceFailureBroadcaster<UserSettingsPersistenceFailure>()
    private(set) var settings: UserSettings
    private var mutations = ScopedDocumentMutationTracker<String, UserSettings>()
    private var pendingJournal: DurablePendingMutationJournal<String, UserSettings>?
    private let documentKey = "default"

    init?(store: Firestore = .firestore(), currentUserID: (() -> UserID?)? = nil) {
        let user = currentUserID?() ?? Auth.auth().currentUser.map { UserID(rawValue: $0.uid) }
        guard let user, !user.rawValue.isEmpty, !user.rawValue.contains("/") else { return nil }
        userID = user
        self.store = store
        settings = UserSettings(userID: user)
        pendingJournal = DurablePendingMutationJournal(
            storageKey: PendingMutationJournalStorage.key(scope: "settings", userID: user)
        )
        listener = document.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, _ in
            guard let snapshot else { return }
            let observedSettings = (try? snapshot.data(as: FirestoreUserSettingsDocument.self))?.settings(userID: user)
            Task { @MainActor in
                guard let self else { return }
                if let observedSettings {
                    self.settings = observedSettings
                } else if !snapshot.metadata.hasPendingWrites {
                    self.settings = UserSettings(userID: user)
                }
                self.publish()
                if !snapshot.metadata.isFromCache, !snapshot.metadata.hasPendingWrites {
                    let stableValues = observedSettings.map { [self.documentKey: $0] } ?? [:]
                    for unconfirmed in self.pendingJournal?.reconcileRestarted(stableValues: stableValues) ?? [] {
                        if case let .value(attempted) = unconfirmed.attempted {
                            self.publishFailure(.saveUnconfirmedAfterRestart(attempted))
                        }
                    }
                }
            }
        }
    }

    deinit { MainActor.assumeIsolated { listener?.remove() } }

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
        let ticket = mutations.begin(
            key: documentKey,
            baseline: .value(self.settings),
            attempted: .value(settings)
        )
        pendingJournal?.record(ticket, attempted: .value(settings))
        self.settings = settings
        publish()
        do {
            try document.setData(from: FirestoreUserSettingsDocument(settings: settings)) { [weak self] error in
                Task { @MainActor in self?.recordWriteCompletion(error, ticket: ticket) }
            }
        } catch {
            recordWriteCompletion(error, ticket: ticket, publishesFailure: false)
            throw error
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

    private func recordWriteCompletion(
        _ error: Swift.Error?,
        ticket: ScopedDocumentMutationTicket<String>,
        publishesFailure: Bool = true
    ) {
        let result: ScopedDocumentMutationResult = error == nil ? .accepted : .rejected
        pendingJournal?.complete(ticket, result: result)
        let completion = mutations.complete(ticket, result: result)
        guard case let .rejected(restore, attempted) = completion,
              case let .value(restoredSettings) = restore,
              case let .value(attemptedSettings) = attempted
        else { return }
        settings = restoredSettings
        publish()
        if publishesFailure { publishFailure(.saveRejected(attemptedSettings)) }
    }

    private func publish() { observers.values.forEach { $0(settings) } }
    private func publishFailure(_ failure: UserSettingsPersistenceFailure) {
        failures.publish(failure)
    }
}

@MainActor private final class FirestoreUserSettingsObservation: UserSettingsObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}
