import Foundation

enum LocalExerciseLibraryError: Error, Equatable {
    case emptyName
    case exerciseNotFound
    case duplicateName
}

enum LocalExerciseCreationResult: Equatable {
    case created(Exercise)
    case existing(Exercise)

    var exercise: Exercise {
        switch self {
        case .created(let exercise), .existing(let exercise):
            return exercise
        }
    }

    var wasCreated: Bool {
        if case .created = self { return true }
        return false
    }
}

struct LocalExerciseLibrary {
    let userID: UserID
    private(set) var customExercises: [Exercise] = []

    init(userID: UserID) {
        self.userID = userID
        self.customExercises = []
    }

    var allExercises: [Exercise] {
        SystemExerciseCatalog.all + customExercises
    }

    mutating func replaceCustomExercises(_ exercises: [Exercise]) {
        precondition(exercises.allSatisfy { !$0.isSystem && $0.createdByUserID == userID })
        customExercises = exercises.sorted {
            if $0.name != $1.name { return $0.name < $1.name }
            return $0.id.rawValue.uuidString < $1.id.rawValue.uuidString
        }
    }

    mutating func createCustomExercise(
        name: String,
        category: String? = nil
    ) throws -> LocalExerciseCreationResult {
        let normalizedName = Self.collapsingWhitespace(in: name)
        guard !normalizedName.isEmpty else { throw LocalExerciseLibraryError.emptyName }

        if let existing = allExercises.first(where: {
            Self.searchKey(for: $0.name) == Self.searchKey(for: normalizedName)
        }) {
            return .existing(existing)
        }

        let normalizedCategory = category.map { Self.collapsingWhitespace(in: $0) }.flatMap {
            $0.isEmpty ? nil : $0
        }
        let exercise = Exercise(
            id: ExerciseID(),
            name: normalizedName,
            category: normalizedCategory,
            isSystem: false,
            createdByUserID: userID
        )
        customExercises.append(exercise)
        return .created(exercise)
    }

    mutating func renameCustomExercise(id: ExerciseID, to name: String) throws -> Exercise {
        let normalizedName = Self.collapsingWhitespace(in: name)
        guard !normalizedName.isEmpty else { throw LocalExerciseLibraryError.emptyName }
        guard let index = customExercises.firstIndex(where: { $0.id == id }) else {
            throw LocalExerciseLibraryError.exerciseNotFound
        }
        guard !allExercises.contains(where: {
            $0.id != id && Self.searchKey(for: $0.name) == Self.searchKey(for: normalizedName)
        }) else { throw LocalExerciseLibraryError.duplicateName }
        customExercises[index].name = normalizedName
        return customExercises[index]
    }

    mutating func removeCustomExercise(id: ExerciseID) throws {
        guard customExercises.contains(where: { $0.id == id }) else {
            throw LocalExerciseLibraryError.exerciseNotFound
        }
        customExercises.removeAll { $0.id == id }
    }

    func search(_ query: String) -> [Exercise] {
        let queryKey = Self.searchKey(for: query)
        guard !queryKey.isEmpty else { return allExercises }
        return allExercises.filter { Self.searchKey(for: $0.name).contains(queryKey) }
    }

    private static func collapsingWhitespace(in value: String) -> String {
        value.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private static func searchKey(for value: String) -> String {
        collapsingWhitespace(in: value).folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
    }
}
