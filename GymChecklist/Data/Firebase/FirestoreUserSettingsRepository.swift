import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreUserSettingsRepository: UserSettingsRepository {
    let userID: UserID
    private let store: Firestore
    private var listener: ListenerRegistration?
    private var observers: [UUID: @MainActor (UserSettings) -> Void] = [:]
    private(set) var settings: UserSettings

    init?(store: Firestore = .firestore(), currentUserID: (() -> UserID?)? = nil) {
        let user = currentUserID?() ?? Auth.auth().currentUser.map { UserID(rawValue: $0.uid) }
        guard let user, !user.rawValue.isEmpty, !user.rawValue.contains("/") else { return nil }
        userID = user
        self.store = store
        settings = UserSettings(userID: user)
        listener = document.addSnapshotListener { [weak self] snapshot, _ in
            guard let payload = try? snapshot?.data(as: FirestoreUserSettingsDocument.self) else { return }
            Task { @MainActor in
                guard let self else { return }
                self.settings = payload.settings(userID: user)
                self.publish()
            }
        }
    }

    deinit { listener?.remove() }

    func observeSettings(_ observer: @escaping @MainActor (UserSettings) -> Void) -> UserSettingsObservation {
        let id = UUID()
        observers[id] = observer
        observer(settings)
        return FirestoreUserSettingsObservation { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    func save(_ settings: UserSettings) throws {
        guard settings.userID == userID else { throw UserSettingsRepositoryError.ownerMismatch }
        self.settings = settings
        publish()
        try document.setData(from: FirestoreUserSettingsDocument(settings: settings))
    }

    private var document: DocumentReference {
        store.document(FirestoreDocumentPath.settings(userID: userID))
    }

    private func publish() { observers.values.forEach { $0(settings) } }
}

@MainActor private final class FirestoreUserSettingsObservation: UserSettingsObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { cancel() }
}
