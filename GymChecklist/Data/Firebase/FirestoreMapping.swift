import CryptoKit
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

/// Restores a locally removed measurement when Firestore rejects an
/// optimistic delete. A later snapshot may already have restored it, so IDs
/// remain unique.
enum BodyWeightDeletionFailureRecovery {
    static func measurementsRestoring(
        _ removedMeasurement: BodyWeightMeasurement,
        to measurements: [BodyWeightMeasurement]
    ) -> [BodyWeightMeasurement] {
        guard !measurements.contains(where: { $0.id == removedMeasurement.id }) else { return measurements }
        return (measurements + [removedMeasurement]).sorted {
            BodyWeightMeasurement.isMoreRecent($0, than: $1)
        }
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

/// Decode custom-exercise snapshots without letting an unreadable document
/// erase a usable cached exercise for that same ID.
struct FirestoreCustomExerciseSnapshotEntry {
    let documentID: String
    let payload: FirestoreCustomExerciseDocument?
}

struct DecodedFirestoreCustomExerciseSnapshot: Equatable {
    let exercises: [Exercise]
    let discardedExerciseIDs: Set<ExerciseID>

    func exercisesPreservingCachedEntries(_ cachedExercises: [Exercise]) -> [Exercise] {
        let decodedIDs = Set(exercises.map(\.id))
        let preserved = cachedExercises.filter {
            discardedExerciseIDs.contains($0.id) && !decodedIDs.contains($0.id)
        }
        return exercises + preserved
    }
}

enum FirestoreCustomExerciseSnapshotDecoder {
    static func decode(
        _ entries: [FirestoreCustomExerciseSnapshotEntry],
        userID: UserID
    ) -> DecodedFirestoreCustomExerciseSnapshot {
        var exercises: [Exercise] = []
        var discardedExerciseIDs: Set<ExerciseID> = []

        for entry in entries {
            guard let payload = entry.payload,
                  entry.documentID == payload.id,
                  let exercise = try? payload.exercise(userID: userID)
            else {
                if let identifier = UUID(uuidString: entry.documentID) {
                    discardedExerciseIDs.insert(ExerciseID(rawValue: identifier))
                }
                continue
            }
            exercises.append(exercise)
        }

        return DecodedFirestoreCustomExerciseSnapshot(
            exercises: exercises,
            discardedExerciseIDs: discardedExerciseIDs
        )
    }
}

enum PersistedDocument<Value: Equatable>: Equatable {
    case missing
    case value(Value)
}

extension PersistedDocument: Codable where Value: Codable {}

struct ScopedDocumentMutationTicket<Key: Hashable>: Hashable {
    let key: Key
    fileprivate let id: UUID
}

enum ScopedDocumentMutationResult {
    case accepted
    case rejected
}

enum ScopedDocumentMutationCompletion<Value: Equatable>: Equatable {
    case accepted
    case superseded
    case rejected(restore: PersistedDocument<Value>, attempted: PersistedDocument<Value>)
    case unknown
}

/// Tracks optimistic full-document writes independently per Firestore document.
/// Newer writes to the same document supersede older failures because they carry
/// the complete current value; writes to other documents never affect recovery.
struct ScopedDocumentMutationTracker<Key: Hashable, Value: Equatable> {
    private struct Mutation {
        let id: UUID
        let sequence: Int
        let attempted: PersistedDocument<Value>
    }

    private struct Chain {
        var baseline: PersistedDocument<Value>
        var mutations: [Mutation]
        var nextSequence: Int
        var latestAcceptedSequence: Int?
    }

    private var chains: [Key: Chain] = [:]

    mutating func begin(
        key: Key,
        baseline: PersistedDocument<Value>,
        attempted: PersistedDocument<Value>
    ) -> ScopedDocumentMutationTicket<Key> {
        let ticket = ScopedDocumentMutationTicket(key: key, id: UUID())
        let sequence = chains[key]?.nextSequence ?? 0
        let mutation = Mutation(id: ticket.id, sequence: sequence, attempted: attempted)
        if chains[key] == nil {
            chains[key] = Chain(
                baseline: baseline,
                mutations: [mutation],
                nextSequence: 1,
                latestAcceptedSequence: nil
            )
        } else {
            chains[key]?.mutations.append(mutation)
            chains[key]?.nextSequence += 1
        }
        return ticket
    }

    func hasPendingMutation(for key: Key) -> Bool {
        chains[key]?.mutations.isEmpty == false
    }

    mutating func complete(
        _ ticket: ScopedDocumentMutationTicket<Key>,
        result: ScopedDocumentMutationResult
    ) -> ScopedDocumentMutationCompletion<Value> {
        guard var chain = chains[ticket.key],
              let index = chain.mutations.firstIndex(where: { $0.id == ticket.id })
        else { return .unknown }

        let mutation = chain.mutations[index]
        let hasNewerPendingMutation = chain.mutations.contains { $0.sequence > mutation.sequence }
        let hasNewerAcceptedMutation = chain.latestAcceptedSequence.map { $0 > mutation.sequence } ?? false
        chain.mutations.remove(at: index)

        switch result {
        case .accepted:
            if chain.latestAcceptedSequence.map({ mutation.sequence > $0 }) ?? true {
                chain.baseline = mutation.attempted
                chain.latestAcceptedSequence = mutation.sequence
            }
            if chain.mutations.isEmpty {
                chains.removeValue(forKey: ticket.key)
            } else {
                chains[ticket.key] = chain
            }
            return .accepted

        case .rejected where hasNewerPendingMutation || hasNewerAcceptedMutation:
            if chain.mutations.isEmpty {
                chains.removeValue(forKey: ticket.key)
            } else {
                chains[ticket.key] = chain
            }
            return .superseded

        case .rejected:
            let latestPending = chain.mutations.max(by: { $0.sequence < $1.sequence })
            let restore: PersistedDocument<Value>
            if let latestPending,
               latestPending.sequence > (chain.latestAcceptedSequence ?? -1) {
                restore = latestPending.attempted
            } else {
                restore = chain.baseline
            }
            if chain.mutations.isEmpty {
                chains.removeValue(forKey: ticket.key)
            } else {
                chains[ticket.key] = chain
            }
            return .rejected(restore: restore, attempted: mutation.attempted)
        }
    }
}

struct DurableUnconfirmedMutation<Key: Hashable, Value: Equatable>: Equatable {
    let key: Key
    let attempted: PersistedDocument<Value>
    let stable: PersistedDocument<Value>
}

enum PendingMutationJournalStorage {
    static let scopes = ["workouts", "settings", "customExercises", "bodyWeight"]

    static func key(scope: String, userID: UserID) -> String {
        "GymChecklist.pendingWrites.v1.\(scope).\(userID.rawValue)"
    }

    static func purge(userID: UserID, directoryURL: URL? = nil) {
        for scope in scopes {
            ProtectedMutationJournalFile(
                storageKey: key(scope: scope, userID: userID),
                directoryURL: directoryURL
            ).remove()
        }
    }
}

private struct ProtectedMutationJournalFile {
    private let fileURL: URL

    init(storageKey: String, directoryURL: URL? = nil) {
        let directory = directoryURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PendingMutationJournals", isDirectory: true)
        let filename = SHA256.hash(data: Data(storageKey.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        fileURL = directory.appendingPathComponent(filename).appendingPathExtension("json")
    }

    func read() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    func write(_ data: Data?) {
        guard let data else {
            remove()
            return
        }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            assertionFailure("Pending mutation journal could not be persisted")
        }
    }

    func remove() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
}

/// Persists mutation intent only so Firestore's own offline queue remains the
/// source of truth while a restarted process can still flag an unconfirmed change.
struct DurablePendingMutationJournal<Key: Codable & Hashable, Value: Codable & Equatable> {
    private struct Entry: Codable {
        let ticketID: UUID
        let key: Key
        let attempted: PersistedDocument<Value>
    }

    private let storage: ProtectedMutationJournalFile
    private var entries: [Entry]
    private var restartedTicketIDs: Set<UUID>
    private var reportedTicketIDs: Set<UUID> = []

    init(storageKey: String, directoryURL: URL? = nil) {
        storage = ProtectedMutationJournalFile(storageKey: storageKey, directoryURL: directoryURL)
        let decoded = storage.read().flatMap { try? JSONDecoder().decode([Entry].self, from: $0) } ?? []
        entries = decoded
        restartedTicketIDs = Set(decoded.map(\.ticketID))
    }

    mutating func record(
        _ ticket: ScopedDocumentMutationTicket<Key>,
        attempted: PersistedDocument<Value>
    ) {
        let supersededIDs = entries
            .filter { $0.key == ticket.key && restartedTicketIDs.contains($0.ticketID) }
            .map(\.ticketID)
        entries.removeAll { supersededIDs.contains($0.ticketID) }
        restartedTicketIDs.subtract(supersededIDs)
        reportedTicketIDs.subtract(supersededIDs)
        entries.append(Entry(ticketID: ticket.id, key: ticket.key, attempted: attempted))
        persist()
    }

    mutating func complete(
        _ ticket: ScopedDocumentMutationTicket<Key>,
        result: ScopedDocumentMutationResult
    ) {
        guard let ticketIndex = entries.firstIndex(where: { $0.ticketID == ticket.id }) else { return }
        let ticketKey = entries[ticketIndex].key
        switch result {
        case .accepted:
            entries = entries.enumerated().compactMap { index, entry in
                entry.key == ticketKey && index <= ticketIndex ? nil : entry
            }
        case .rejected:
            entries.remove(at: ticketIndex)
        }
        restartedTicketIDs.remove(ticket.id)
        restartedTicketIDs.formIntersection(entries.map(\.ticketID))
        reportedTicketIDs.remove(ticket.id)
        reportedTicketIDs.formIntersection(entries.map(\.ticketID))
        persist()
    }

    mutating func reconcileRestarted(
        stableValues: [Key: Value]
    ) -> [DurableUnconfirmedMutation<Key, Value>] {
        let restartedEntries = entries.filter { restartedTicketIDs.contains($0.ticketID) }
        var latestByKey: [Key: Entry] = [:]
        for entry in restartedEntries { latestByKey[entry.key] = entry }
        var resolvedIDs: Set<UUID> = []
        var reportedIDs = reportedTicketIDs
        let unconfirmed = latestByKey.values.compactMap { entry -> DurableUnconfirmedMutation<Key, Value>? in
            let stable = stableValues[entry.key].map { PersistedDocument.value($0) } ?? .missing
            let sameKeyEntries = restartedEntries.filter { $0.key == entry.key }
            if stable == entry.attempted {
                resolvedIDs.formUnion(sameKeyEntries.map(\.ticketID))
                return nil
            }
            guard !reportedIDs.contains(entry.ticketID) else { return nil }
            reportedIDs.insert(entry.ticketID)
            return DurableUnconfirmedMutation(key: entry.key, attempted: entry.attempted, stable: stable)
        }
        entries.removeAll { resolvedIDs.contains($0.ticketID) }
        restartedTicketIDs.subtract(resolvedIDs)
        reportedIDs.subtract(resolvedIDs)
        reportedTicketIDs = reportedIDs
        persist()
        return unconfirmed.sorted { String(describing: $0.key) < String(describing: $1.key) }
    }

    private func persist() {
        guard !entries.isEmpty else {
            storage.write(nil)
            return
        }
        if let data = try? JSONEncoder().encode(entries) {
            storage.write(data)
        }
    }
}
