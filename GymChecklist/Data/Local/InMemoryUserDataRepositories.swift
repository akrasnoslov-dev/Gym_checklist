import Foundation

@MainActor
final class InMemoryCustomExerciseRepository: CustomExerciseRepository {
    let userID: UserID
    private var storage: [ExerciseID: Exercise] = [:]
    private var observers: [UUID: @MainActor ([Exercise]) -> Void] = [:]

    init(userID: UserID) {
        self.userID = userID
    }

    var customExercises: [Exercise] {
        storage.values.sorted {
            if $0.name != $1.name { return $0.name < $1.name }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }
    }

    func observeCustomExercises(_ observer: @escaping @MainActor ([Exercise]) -> Void) -> CustomExerciseObservation {
        let id = UUID()
        observers[id] = observer
        observer(customExercises)
        return InMemoryCustomExerciseObservation { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    func save(_ exercise: Exercise) throws {
        guard exercise.createdByUserID == userID else { throw CustomExerciseRepositoryError.ownerMismatch }
        guard !exercise.isSystem else { throw CustomExerciseRepositoryError.systemExerciseCannotBePersisted }
        if let existing = storage[exercise.id], existing.createdByUserID != exercise.createdByUserID {
            throw CustomExerciseRepositoryError.identityConflict
        }
        storage[exercise.id] = exercise
        publish()
    }

    func deleteCustomExercise(id: ExerciseID) throws {
        storage.removeValue(forKey: id)
        publish()
    }

    private func publish() { observers.values.forEach { $0(customExercises) } }
}

@MainActor private final class InMemoryCustomExerciseObservation: CustomExerciseObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}

@MainActor
final class InMemoryUserSettingsRepository: UserSettingsRepository {
    let userID: UserID
    private var storage: UserSettings
    private var observers: [UUID: @MainActor (UserSettings) -> Void] = [:]

    init(userID: UserID, settings: UserSettings? = nil) {
        self.userID = userID
        let initial = settings ?? UserSettings(userID: userID)
        precondition(initial.userID == userID, "Settings repository owner must match settings owner")
        self.storage = initial
    }

    var settings: UserSettings { storage }

    func observeSettings(_ observer: @escaping @MainActor (UserSettings) -> Void) -> UserSettingsObservation {
        let id = UUID()
        observers[id] = observer
        observer(settings)
        return InMemoryUserSettingsObservation { [weak self] in
            self?.observers.removeValue(forKey: id)
        }
    }

    func save(_ settings: UserSettings) throws {
        guard settings.userID == userID else { throw UserSettingsRepositoryError.ownerMismatch }
        storage = settings
        publish()
    }

    private func publish() { observers.values.forEach { $0(settings) } }
}

@MainActor private final class InMemoryUserSettingsObservation: UserSettingsObservation {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func cancel() { handler?(); handler = nil }
    deinit { MainActor.assumeIsolated { cancel() } }
}
