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

    static func bodyWeightMeasurement(userID: UserID, measurementID: BodyWeightMeasurementID) -> String {
        "users/\(validatedUserID(userID))/bodyWeightMeasurements/\(measurementID.rawValue.uuidString)"
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
    case invalidBodyWeightMeasurement
}

struct FirestoreWorkoutSnapshotEntry {
    let documentDate: LocalDate?
    let payload: FirestoreWorkoutPayload?
}

struct DecodedFirestoreWorkoutSnapshot: Equatable {
    let workouts: [Workout]
    let discardedEntryCount: Int
    let discardedDocumentDates: Set<LocalDate>

    func workoutsPreservingCachedEntries(_ cachedWorkouts: [Workout]) -> [Workout] {
        var workoutsByDate = Dictionary(uniqueKeysWithValues: workouts.map { ($0.localDate, $0) })
        for workout in cachedWorkouts where discardedDocumentDates.contains(workout.localDate) {
            workoutsByDate[workout.localDate] = workoutsByDate[workout.localDate] ?? workout
        }
        return workoutsByDate.values.sorted { $0.localDate < $1.localDate }
    }
}

/// A successfully delivered Firestore snapshot is usable even when it is
/// empty or sourced from the local cache. Transport failures and malformed
/// entries are represented separately so Today remains usable offline.
struct FirestoreWorkoutSnapshotAvailability: Equatable {
    let hasUsableSnapshot: Bool
    let loadState: WorkoutLoadState

    static func successfulSnapshot(discardedEntryCount: Int) -> Self {
        let hasDiscardedEntries = discardedEntryCount > 0
        return Self(
            hasUsableSnapshot: true,
            loadState: hasDiscardedEntries
                ? .unavailable(hasUsableSnapshot: true)
                : .available
        )
    }
}

enum FirestoreWorkoutSnapshotDecoder {
    static func decode(_ entries: [FirestoreWorkoutSnapshotEntry], userID: UserID) -> DecodedFirestoreWorkoutSnapshot {
        var workouts: [Workout] = []
        var discardedEntryCount = 0
        var discardedDocumentDates: Set<LocalDate> = []

        for entry in entries {
            guard let documentDate = entry.documentDate,
                  let payload = entry.payload,
                  let workout = try? payload.domainWorkout(userID: userID, documentDate: documentDate)
            else {
                discardedEntryCount += 1
                if let documentDate = entry.documentDate {
                    discardedDocumentDates.insert(documentDate)
                }
                continue
            }
            workouts.append(workout)
        }

        return DecodedFirestoreWorkoutSnapshot(
            workouts: workouts.sorted { $0.localDate < $1.localDate },
            discardedEntryCount: discardedEntryCount,
            discardedDocumentDates: discardedDocumentDates
        )
    }
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
    let type: WorkoutSetType?
    let isCompleted: Bool
    let actualReps: Int?
    let actualWeight: Double?
    let actualTimeSeconds: Int?
    let actualType: WorkoutSetType?
    let completedAt: Date?

    init(set: WorkoutSet) {
        id = set.id.rawValue.uuidString
        order = set.order
        reps = set.reps
        weight = set.weight
        timeSeconds = set.timeSeconds
        type = set.type
        isCompleted = set.isCompleted
        actualReps = set.actualReps
        actualWeight = set.actualWeight
        actualTimeSeconds = set.actualTimeSeconds
        actualType = set.actualType
        completedAt = set.completedAt
    }

    init(
        id: String,
        order: Int,
        reps: Int,
        weight: Double,
        timeSeconds: Int,
        type: WorkoutSetType? = nil,
        isCompleted: Bool,
        actualReps: Int?,
        actualWeight: Double?,
        actualTimeSeconds: Int?,
        actualType: WorkoutSetType? = nil,
        completedAt: Date?
    ) {
        self.id = id
        self.order = order
        self.reps = reps
        self.weight = weight
        self.timeSeconds = timeSeconds
        self.type = type
        self.isCompleted = isCompleted
        self.actualReps = actualReps
        self.actualWeight = actualWeight
        self.actualTimeSeconds = actualTimeSeconds
        self.actualType = actualType
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
                weight: weight, timeSeconds: timeSeconds, type: type, isCompleted: isCompleted,
                actualReps: actualReps, actualWeight: actualWeight,
                actualTimeSeconds: actualTimeSeconds, actualType: actualType, completedAt: completedAt
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
    let sex: Sex?
    let dateOfBirth: String?
    let heightCentimeters: Double?

    private enum CodingKeys: String, CodingKey {
        case appearance
        case weightUnit
        case sex
        case dateOfBirth
        case heightCentimeters
    }

    init(settings: UserSettings) {
        appearance = settings.appearance
        weightUnit = settings.weightUnit
        sex = settings.profile.sex
        dateOfBirth = settings.profile.dateOfBirth?.description
        heightCentimeters = settings.profile.heightCentimeters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appearance = try container.decodeIfPresent(Appearance.self, forKey: .appearance) ?? .system
        weightUnit = try container.decodeIfPresent(WeightUnit.self, forKey: .weightUnit) ?? .kilograms
        sex = try container.decodeIfPresent(Sex.self, forKey: .sex)
        dateOfBirth = try container.decodeIfPresent(String.self, forKey: .dateOfBirth)
        heightCentimeters = try container.decodeIfPresent(Double.self, forKey: .heightCentimeters)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appearance, forKey: .appearance)
        try container.encode(weightUnit, forKey: .weightUnit)
        // Explicit nulls clear optional profile fields when settings are merged.
        try container.encode(sex, forKey: .sex)
        try container.encode(dateOfBirth, forKey: .dateOfBirth)
        try container.encode(heightCentimeters, forKey: .heightCentimeters)
    }

    func settings(userID: UserID) -> UserSettings {
        UserSettings(
            userID: userID,
            appearance: appearance,
            weightUnit: weightUnit,
            profile: UserProfile(
                sex: sex,
                dateOfBirth: dateOfBirth.flatMap(FirestoreWorkoutDocument.localDate),
                heightCentimeters: heightCentimeters
            )
        )
    }
}

struct FirestoreBodyWeightMeasurementDocument: Codable, Equatable {
    let id: String
    let localDate: String
    let weightInKilograms: Double
    let measuredAt: Date
    let updatedAt: Date

    init(measurement: BodyWeightMeasurement) {
        id = measurement.id.rawValue.uuidString
        localDate = measurement.localDate.description
        weightInKilograms = measurement.weightInKilograms
        measuredAt = measurement.measuredAt
        updatedAt = measurement.updatedAt
    }

    func measurement(userID: UserID) throws -> BodyWeightMeasurement {
        guard let identifier = UUID(uuidString: id),
              let date = FirestoreWorkoutDocument.localDate(localDate),
              weightInKilograms.isFinite, weightInKilograms > 0
        else { throw FirestoreMappingError.invalidBodyWeightMeasurement }
        return BodyWeightMeasurement(
            id: BodyWeightMeasurementID(rawValue: identifier), userID: userID,
            localDate: date, weightInKilograms: weightInKilograms,
            measuredAt: measuredAt, updatedAt: updatedAt
        )
    }
}

/// Decode body-weight snapshots without letting a malformed document erase a
/// usable cached measurement for the same document ID. Firestore's cache can
/// still provide the earlier value while the invalid remote record is fixed.
struct FirestoreBodyWeightSnapshotEntry {
    let documentID: String
    let payload: FirestoreBodyWeightMeasurementDocument?
}

struct DecodedFirestoreBodyWeightSnapshot: Equatable {
    let measurements: [BodyWeightMeasurement]
    let discardedMeasurementIDs: Set<BodyWeightMeasurementID>

    func measurementsPreservingCachedEntries(_ cachedMeasurements: [BodyWeightMeasurement]) -> [BodyWeightMeasurement] {
        let decodedIDs = Set(measurements.map(\.id))
        let preserved = cachedMeasurements.filter {
            discardedMeasurementIDs.contains($0.id) && !decodedIDs.contains($0.id)
        }
        return (measurements + preserved).sorted {
            BodyWeightMeasurement.isMoreRecent($0, than: $1)
        }
    }
}

enum FirestoreBodyWeightSnapshotDecoder {
    static func decode(_ entries: [FirestoreBodyWeightSnapshotEntry], userID: UserID) -> DecodedFirestoreBodyWeightSnapshot {
        var measurements: [BodyWeightMeasurement] = []
        var discardedMeasurementIDs: Set<BodyWeightMeasurementID> = []

        for entry in entries {
            guard let payload = entry.payload,
                  entry.documentID == payload.id,
                  let measurement = try? payload.measurement(userID: userID)
            else {
                if let identifier = UUID(uuidString: entry.documentID) {
                    discardedMeasurementIDs.insert(BodyWeightMeasurementID(rawValue: identifier))
                }
                continue
            }
            measurements.append(measurement)
        }

        return DecodedFirestoreBodyWeightSnapshot(
            measurements: measurements.sorted { BodyWeightMeasurement.isMoreRecent($0, than: $1) },
            discardedMeasurementIDs: discardedMeasurementIDs
        )
    }
}
