import Foundation

struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
}

struct ExerciseID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

struct WorkoutID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

struct WorkoutExerciseID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

struct WorkoutSetID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

enum Appearance: String, Codable, CaseIterable, Sendable {
    case system, light, dark
}

enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case kilograms = "kg"
    case pounds = "lb"
}

struct UserSettings: Codable, Equatable, Sendable {
    var userID: UserID
    var appearance: Appearance = .system
    var weightUnit: WeightUnit = .kilograms
}

struct Exercise: Codable, Equatable, Identifiable, Sendable {
    var id: ExerciseID
    var name: String
    var category: String?
    var isSystem: Bool
    var createdByUserID: UserID?
}

enum WorkoutStatus: String, Codable, Sendable {
    case planned, partial, completed, incomplete
}

struct WorkoutDateKey: Codable, Hashable, Sendable {
    let userID: UserID
    let localDate: LocalDate
}

struct Workout: Codable, Equatable, Identifiable, Sendable {
    var id: WorkoutID
    var userID: UserID
    var localDate: LocalDate
    var exercises: [WorkoutExercise]
    var createdAt: Date
    var updatedAt: Date

    var dateKey: WorkoutDateKey { WorkoutDateKey(userID: userID, localDate: localDate) }
}

struct WorkoutExercise: Codable, Equatable, Identifiable, Sendable {
    var id: WorkoutExerciseID
    var exerciseID: ExerciseID
    var customName: String?
    var order: Int
    var isSkipped: Bool
    var sets: [WorkoutSet]
}

struct WorkoutSet: Codable, Equatable, Identifiable, Sendable {
    var id: WorkoutSetID
    var order: Int
    var reps: Int
    var weight: Double
    var timeSeconds: Int
    private(set) var isCompleted: Bool
    private(set) var actualReps: Int?
    private(set) var actualWeight: Double?
    private(set) var actualTimeSeconds: Int?
    private(set) var completedAt: Date?

    init(
        id: WorkoutSetID = WorkoutSetID(), order: Int, reps: Int = 0,
        weight: Double = 0, timeSeconds: Int = 0
    ) {
        self.id = id
        self.order = order
        self.reps = reps
        self.weight = weight
        self.timeSeconds = timeSeconds
        self.isCompleted = false
        self.actualReps = nil
        self.actualWeight = nil
        self.actualTimeSeconds = nil
        self.completedAt = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(WorkoutSetID.self, forKey: .id)
        order = try container.decode(Int.self, forKey: .order)
        reps = try container.decode(Int.self, forKey: .reps)
        weight = try container.decode(Double.self, forKey: .weight)
        timeSeconds = try container.decode(Int.self, forKey: .timeSeconds)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        actualReps = try container.decodeIfPresent(Int.self, forKey: .actualReps)
        actualWeight = try container.decodeIfPresent(Double.self, forKey: .actualWeight)
        actualTimeSeconds = try container.decodeIfPresent(Int.self, forKey: .actualTimeSeconds)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        if isCompleted && (actualReps == nil || actualWeight == nil || actualTimeSeconds == nil || completedAt == nil) {
            throw DecodingError.dataCorruptedError(forKey: .isCompleted, in: container, debugDescription: "Completed sets require actual values and a completion timestamp")
        }
    }
}

import Foundation

extension WorkoutSet {
    var displayedReps: Int { isCompleted ? actualReps ?? reps : reps }
    var displayedWeight: Double { isCompleted ? actualWeight ?? weight : weight }
    var displayedTimeSeconds: Int { isCompleted ? actualTimeSeconds ?? timeSeconds : timeSeconds }

    mutating func complete(at date: Date = Date()) {
        guard !isCompleted else { return }
        actualReps = reps
        actualWeight = weight
        actualTimeSeconds = timeSeconds
        completedAt = date
        isCompleted = true
    }

    mutating func undoCompletion() {
        isCompleted = false
        actualReps = nil
        actualWeight = nil
        actualTimeSeconds = nil
        completedAt = nil
    }

    mutating func toggleCompletion(at date: Date = Date()) {
        isCompleted ? undoCompletion() : complete(at: date)
    }

    mutating func editPlan(reps: Int, weight: Double, timeSeconds: Int) {
        self.reps = reps
        self.weight = weight
        self.timeSeconds = timeSeconds
    }

    mutating func editActual(reps: Int, weight: Double, timeSeconds: Int) {
        guard isCompleted else { return }
        actualReps = reps
        actualWeight = weight
        actualTimeSeconds = timeSeconds
    }
}
