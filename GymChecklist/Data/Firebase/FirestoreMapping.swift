import Foundation

/// Canonical user-scoped Firestore locations. Callers supply only domain IDs;
/// Firebase repository implementations obtain the user ID from Auth.
enum FirestoreDocumentPath {
    static func workout(userID: UserID, date: LocalDate) -> String {
        "users/\(validatedUserID(userID))/workouts/\(date.description)"
    }

    static func customExercise(userID: UserID, exerciseID: ExerciseID) -> String {
        "users/\(validatedUserID(userID))/customExercises/\(exerciseID.rawValue.uuidString)"
    }

    static func settings(userID: UserID) -> String {
        "users/\(validatedUserID(userID))/settings/default"
    }

    private static func validatedUserID(_ userID: UserID) -> String {
        precondition(!userID.rawValue.isEmpty && !userID.rawValue.contains("/"), "Firestore user ID must be a path component")
        return userID.rawValue
    }
}

enum FirestoreMappingError: Error, Equatable {
    case invalidIdentifier
    case invalidLocalDate
    case invalidSetValues
    case invalidCompletionState
    case systemExerciseCannotBeMapped
}

struct FirestoreWorkoutDocument: Codable, Equatable {
    let id: String
    let localDate: String
    let createdAt: Date
    let updatedAt: Date

    init(workout: Workout) {
        id = workout.id.rawValue.uuidString
        localDate = workout.localDate.description
        createdAt = workout.createdAt
        updatedAt = workout.updatedAt
    }

    init(id: String, localDate: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.localDate = localDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func workout(userID: UserID, documentDate: LocalDate, exercises: [WorkoutExercise]) throws -> Workout {
        guard localDate == documentDate.description, let id = UUID(uuidString: id), Self.localDate(localDate) == documentDate else {
            throw FirestoreMappingError.invalidLocalDate
        }
        return Workout(
            id: WorkoutID(rawValue: id),
            userID: userID,
            localDate: documentDate,
            exercises: exercises,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func localDate(_ value: String) -> LocalDate? {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        let payload = Data("{\"year\":\(year),\"month\":\(month),\"day\":\(day)}".utf8)
        return try? JSONDecoder().decode(LocalDate.self, from: payload)
    }
}

struct FirestoreWorkoutExerciseDocument: Codable, Equatable {
    let id: String
    let exerciseID: String
    let customName: String?
    let order: Int
    let isSkipped: Bool

    init(exercise: WorkoutExercise) {
        id = exercise.id.rawValue.uuidString
        exerciseID = exercise.exerciseID.rawValue.uuidString
        customName = exercise.customName
        order = exercise.order
        isSkipped = exercise.isSkipped
    }

    func workoutExercise(sets: [WorkoutSet]) throws -> WorkoutExercise {
        guard let id = UUID(uuidString: id), let exerciseID = UUID(uuidString: exerciseID), order >= 0 else {
            throw FirestoreMappingError.invalidIdentifier
        }
        return WorkoutExercise(
            id: WorkoutExerciseID(rawValue: id),
            exerciseID: ExerciseID(rawValue: exerciseID),
            customName: customName,
            order: order,
            isSkipped: isSkipped,
            sets: sets
        )
    }
}

struct FirestoreWorkoutPayload: Codable, Equatable {
    let workout: FirestoreWorkoutDocument
    let exercises: [FirestoreWorkoutExercisePayload]

    init(workout: Workout) {
        self.workout = FirestoreWorkoutDocument(workout: workout)
        exercises = workout.exercises.map(FirestoreWorkoutExercisePayload.init)
    }

    func domainWorkout(userID: UserID, documentDate: LocalDate) throws -> Workout {
        let exercises = try exercises.map { try $0.domainExercise() }
        return try workout.workout(userID: userID, documentDate: documentDate, exercises: exercises)
    }
}

struct FirestoreWorkoutExercisePayload: Codable, Equatable {
    let exercise: FirestoreWorkoutExerciseDocument
    let sets: [FirestoreWorkoutSetDocument]

    init(exercise: WorkoutExercise) {
        self.exercise = FirestoreWorkoutExerciseDocument(exercise: exercise)
        sets = exercise.sets.map(FirestoreWorkoutSetDocument.init)
    }

    func domainExercise() throws -> WorkoutExercise {
        try exercise.workoutExercise(sets: sets.map { try $0.workoutSet() })
    }
}

struct FirestoreWorkoutSetDocument: Codable, Equatable {
    let id: String
    let order: Int
    let reps: Int
    let weight: Double
    let timeSeconds: Int
    let isCompleted: Bool
    let actualReps: Int?
    let actualWeight: Double?
    let actualTimeSeconds: Int?
    let completedAt: Date?

    init(set: WorkoutSet) {
        id = set.id.rawValue.uuidString
        order = set.order
        reps = set.reps
        weight = set.weight
        timeSeconds = set.timeSeconds
        isCompleted = set.isCompleted
        actualReps = set.actualReps
        actualWeight = set.actualWeight
        actualTimeSeconds = set.actualTimeSeconds
        completedAt = set.completedAt
    }

    init(
        id: String,
        order: Int,
        reps: Int,
        weight: Double,
        timeSeconds: Int,
        isCompleted: Bool,
        actualReps: Int?,
        actualWeight: Double?,
        actualTimeSeconds: Int?,
        completedAt: Date?
    ) {
        self.id = id
        self.order = order
        self.reps = reps
        self.weight = weight
        self.timeSeconds = timeSeconds
        self.isCompleted = isCompleted
        self.actualReps = actualReps
        self.actualWeight = actualWeight
        self.actualTimeSeconds = actualTimeSeconds
        self.completedAt = completedAt
    }

    func workoutSet() throws -> WorkoutSet {
        guard let id = UUID(uuidString: id), order >= 0, reps >= 0, timeSeconds >= 0, weight.isFinite, weight >= 0 else {
            throw FirestoreMappingError.invalidSetValues
        }
        guard actualReps.map({ $0 >= 0 }) ?? true,
              actualTimeSeconds.map({ $0 >= 0 }) ?? true,
              actualWeight.map({ $0.isFinite && $0 >= 0 }) ?? true else {
            throw FirestoreMappingError.invalidSetValues
        }
        do {
            return try WorkoutSet(
                id: WorkoutSetID(rawValue: id), order: order, reps: reps,
                weight: weight, timeSeconds: timeSeconds, isCompleted: isCompleted,
                actualReps: actualReps, actualWeight: actualWeight,
                actualTimeSeconds: actualTimeSeconds, completedAt: completedAt
            )
        } catch {
            throw FirestoreMappingError.invalidCompletionState
        }
    }
}

struct FirestoreCustomExerciseDocument: Codable, Equatable {
    let id: String
    let name: String
    let category: String?

    init(exercise: Exercise) throws {
        guard !exercise.isSystem, exercise.createdByUserID != nil else {
            throw FirestoreMappingError.systemExerciseCannotBeMapped
        }
        id = exercise.id.rawValue.uuidString
        name = exercise.name
        category = exercise.category
    }

    func exercise(userID: UserID) throws -> Exercise {
        guard let id = UUID(uuidString: id), !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FirestoreMappingError.invalidIdentifier
        }
        return Exercise(id: ExerciseID(rawValue: id), name: name, category: category, isSystem: false, createdByUserID: userID)
    }
}

struct FirestoreUserSettingsDocument: Codable, Equatable {
    let appearance: Appearance
    let weightUnit: WeightUnit

    init(settings: UserSettings) {
        appearance = settings.appearance
        weightUnit = settings.weightUnit
    }

    func settings(userID: UserID) -> UserSettings {
        UserSettings(userID: userID, appearance: appearance, weightUnit: weightUnit)
    }
}
