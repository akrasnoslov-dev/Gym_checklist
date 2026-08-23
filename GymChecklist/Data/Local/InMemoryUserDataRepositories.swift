import Foundation

final class InMemoryCustomExerciseRepository: CustomExerciseRepository {
    let userID: UserID
    private var storage: [ExerciseID: Exercise] = [:]

    init(userID: UserID) {
        self.userID = userID
    }

    var customExercises: [Exercise] {
        storage.values.sorted { $0.id.rawValue.uuidString < $1.id.rawValue.uuidString }
    }

    func save(_ exercise: Exercise) throws {
        guard exercise.createdByUserID == userID else { throw CustomExerciseRepositoryError.ownerMismatch }
        guard !exercise.isSystem else { throw CustomExerciseRepositoryError.systemExerciseCannotBePersisted }
        if let existing = storage[exercise.id], existing.createdByUserID != exercise.createdByUserID {
            throw CustomExerciseRepositoryError.identityConflict
        }
        storage[exercise.id] = exercise
    }

    func deleteCustomExercise(id: ExerciseID) throws {
        storage.removeValue(forKey: id)
    }
}

final class InMemoryUserSettingsRepository: UserSettingsRepository {
    let userID: UserID
    private var storage: UserSettings

    init(userID: UserID, settings: UserSettings? = nil) {
        self.userID = userID
        let initial = settings ?? UserSettings(userID: userID)
        precondition(initial.userID == userID, "Settings repository owner must match settings owner")
        self.storage = initial
    }

    var settings: UserSettings { storage }

    func save(_ settings: UserSettings) throws {
        guard settings.userID == userID else { throw UserSettingsRepositoryError.ownerMismatch }
        storage = settings
    }
}
