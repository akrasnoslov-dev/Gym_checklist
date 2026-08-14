import Foundation

enum LocalExerciseLibraryError: Error, Equatable {
    case emptyName
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
