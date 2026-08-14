import Foundation

enum SystemExerciseCatalog {
    static let all: [Exercise] = definitions.map { definition in
        Exercise(
            id: exerciseID(for: definition.ordinal),
            name: definition.name,
            category: definition.category,
            isSystem: true,
            createdByUserID: nil
        )
    }

    static func search(_ query: String) -> [Exercise] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return all }

        return all.filter { exercise in
            exercise.name.range(
                of: trimmedQuery,
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            ) != nil
        }
    }

    private struct Definition {
        let ordinal: Int
        let name: String
        let category: String
    }

    private static func exerciseID(for ordinal: Int) -> ExerciseID {
        let suffix = String(format: "%012d", ordinal)
        guard let uuid = UUID(uuidString: "00000000-0000-4000-8000-\(suffix)") else {
            preconditionFailure("Invalid bundled exercise identifier")
        }
        return ExerciseID(rawValue: uuid)
    }

    private static let definitions: [Definition] = [
        Definition(ordinal: 1, name: "Bench Press", category: "Chest"),
        Definition(ordinal: 2, name: "Incline Dumbbell Press", category: "Chest"),
        Definition(ordinal: 3, name: "Push-Up", category: "Chest"),
        Definition(ordinal: 4, name: "Cable Fly", category: "Chest"),

        Definition(ordinal: 5, name: "Pull-Up", category: "Back"),
        Definition(ordinal: 6, name: "Lat Pulldown", category: "Back"),
        Definition(ordinal: 7, name: "Barbell Row", category: "Back"),
        Definition(ordinal: 8, name: "Seated Cable Row", category: "Back"),

        Definition(ordinal: 9, name: "Back Squat", category: "Legs"),
        Definition(ordinal: 10, name: "Front Squat", category: "Legs"),
        Definition(ordinal: 11, name: "Romanian Deadlift", category: "Legs"),
        Definition(ordinal: 12, name: "Leg Press", category: "Legs"),
        Definition(ordinal: 13, name: "Walking Lunge", category: "Legs"),
        Definition(ordinal: 14, name: "Standing Calf Raise", category: "Legs"),

        Definition(ordinal: 15, name: "Overhead Press", category: "Shoulders"),
        Definition(ordinal: 16, name: "Dumbbell Lateral Raise", category: "Shoulders"),
        Definition(ordinal: 17, name: "Reverse Fly", category: "Shoulders"),
        Definition(ordinal: 18, name: "Arnold Press", category: "Shoulders"),

        Definition(ordinal: 19, name: "Barbell Curl", category: "Biceps"),
        Definition(ordinal: 20, name: "Dumbbell Curl", category: "Biceps"),
        Definition(ordinal: 21, name: "Hammer Curl", category: "Biceps"),
        Definition(ordinal: 22, name: "Preacher Curl", category: "Biceps"),

        Definition(ordinal: 23, name: "Cable Triceps Pushdown", category: "Triceps"),
        Definition(ordinal: 24, name: "Skull Crusher", category: "Triceps"),
        Definition(ordinal: 25, name: "Overhead Triceps Extension", category: "Triceps"),
        Definition(ordinal: 26, name: "Close-Grip Bench Press", category: "Triceps"),

        Definition(ordinal: 27, name: "Plank", category: "Core"),
        Definition(ordinal: 28, name: "Hanging Knee Raise", category: "Core"),
        Definition(ordinal: 29, name: "Cable Crunch", category: "Core"),
        Definition(ordinal: 30, name: "Russian Twist", category: "Core"),

        Definition(ordinal: 31, name: "Treadmill Run", category: "Cardio/Other"),
        Definition(ordinal: 32, name: "Stationary Bike", category: "Cardio/Other"),
        Definition(ordinal: 33, name: "Rowing Machine", category: "Cardio/Other"),
        Definition(ordinal: 34, name: "Elliptical", category: "Cardio/Other")
    ]
}
