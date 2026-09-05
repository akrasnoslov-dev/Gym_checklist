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

enum Appearance: String, Codable, CaseIterable, Hashable, Sendable {
    case system, light, dark
}

enum WeightUnit: String, Codable, CaseIterable, Hashable, Sendable {
    case kilograms = "kg"
    case pounds = "lb"
}

struct UserSettings: Codable, Equatable, Sendable {
    var userID: UserID
    var appearance: Appearance = .system
    var weightUnit: WeightUnit = .kilograms
    var profile: UserProfile = .init()

    init(
        userID: UserID,
        appearance: Appearance = .system,
        weightUnit: WeightUnit = .kilograms,
        profile: UserProfile = .init()
    ) {
        self.userID = userID
        self.appearance = appearance
        self.weightUnit = weightUnit
        self.profile = profile
    }

    private enum CodingKeys: String, CodingKey { case userID, appearance, weightUnit, profile }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(UserID.self, forKey: .userID)
        appearance = try container.decodeIfPresent(Appearance.self, forKey: .appearance) ?? .system
        weightUnit = try container.decodeIfPresent(WeightUnit.self, forKey: .weightUnit) ?? .kilograms
        profile = try container.decodeIfPresent(UserProfile.self, forKey: .profile) ?? .init()
    }
}

enum Sex: String, Codable, CaseIterable, Hashable, Sendable {
    case female, male, preferNotToSay

    var title: String {
        switch self {
        case .female: "Female"
        case .male: "Male"
        case .preferNotToSay: "Prefer not to say"
        }
    }
}

struct UserProfile: Codable, Equatable, Sendable {
    var sex: Sex?
    var dateOfBirth: LocalDate?
    /// Stored in centimetres regardless of the user's weight-unit preference.
    var heightCentimeters: Double?

    init(sex: Sex? = nil, dateOfBirth: LocalDate? = nil, heightCentimeters: Double? = nil) {
        self.sex = sex
        self.dateOfBirth = dateOfBirth
        self.heightCentimeters = heightCentimeters
    }

    func age(on date: LocalDate, calendar: Calendar) -> Int? {
        guard let birthDate = dateOfBirth,
              let birth = birthDate.date(in: calendar),
              let now = date.date(in: calendar),
              birth <= now
        else { return nil }
        return calendar.dateComponents([.year], from: birth, to: now).year
    }

    func bmi(weightInKilograms: Double?) -> Double? {
        guard let heightCentimeters, heightCentimeters.isFinite, heightCentimeters > 0,
              let weightInKilograms, weightInKilograms.isFinite, weightInKilograms > 0
        else { return nil }
        let heightInMeters = heightCentimeters / 100
        let value = weightInKilograms / (heightInMeters * heightInMeters)
        return value.isFinite ? value : nil
    }
}

struct BodyWeightMeasurementID: RawRepresentable, Codable, Hashable, Identifiable, Sendable {
    let rawValue: UUID
    init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
    var id: UUID { rawValue }
}

struct BodyWeightMeasurement: Codable, Equatable, Identifiable, Sendable {
    var id: BodyWeightMeasurementID
    var userID: UserID
    var localDate: LocalDate
    /// Canonical kilograms; presentation converts at the view boundary.
    var weightInKilograms: Double
    var measuredAt: Date
    var updatedAt: Date

    init(
        id: BodyWeightMeasurementID = .init(),
        userID: UserID,
        localDate: LocalDate,
        weightInKilograms: Double,
        measuredAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userID = userID
        self.localDate = localDate
        self.weightInKilograms = weightInKilograms
        self.measuredAt = measuredAt
        self.updatedAt = updatedAt
    }

    /// The current measurement is based on the day the person recorded, not
    /// on when an offline/backfilled record happened to reach a repository.
    static func isMoreRecent(_ lhs: Self, than rhs: Self) -> Bool {
        if lhs.localDate.year != rhs.localDate.year { return lhs.localDate.year > rhs.localDate.year }
        if lhs.localDate.month != rhs.localDate.month { return lhs.localDate.month > rhs.localDate.month }
        if lhs.localDate.day != rhs.localDate.day { return lhs.localDate.day > rhs.localDate.day }
        if lhs.measuredAt != rhs.measuredAt { return lhs.measuredAt > rhs.measuredAt }
        return lhs.id.rawValue.uuidString > rhs.id.rawValue.uuidString
    }

    static func isOnOrBefore(_ measurement: Self, date: LocalDate) -> Bool {
        if measurement.localDate.year != date.year { return measurement.localDate.year < date.year }
        if measurement.localDate.month != date.month { return measurement.localDate.month < date.month }
        return measurement.localDate.day <= date.day
    }
}

enum WorkoutSetType: String, Codable, CaseIterable, Hashable, Sendable {
    case weighted, repsOnly, timed, legacyMixed

    static let editableCases: [Self] = [.weighted, .repsOnly, .timed]

    var title: String {
        switch self {
        case .weighted: "Weighted"
        case .repsOnly: "Reps only"
        case .timed: "Timed"
        case .legacyMixed: "Legacy set"
        }
    }

    static func inferred(reps: Int, weight: Double, timeSeconds: Int) -> Self {
        let hasWeight = weight > 0
        let hasTime = timeSeconds > 0
        // Earlier timed sets used one rep with no weight as a technical
        // placeholder. Preserve genuinely meaningful rep/time combinations,
        // but infer the old placeholder as the timed presentation.
        if hasTime && !hasWeight && reps <= 1 { return .timed }
        if hasWeight && !hasTime { return .weighted }
        if !hasWeight && !hasTime { return .repsOnly }
        return .legacyMixed
    }

    static func resolved(
        storedType: Self?, reps: Int, weight: Double, timeSeconds: Int
    ) -> Self {
        let inferredType = inferred(reps: reps, weight: weight, timeSeconds: timeSeconds)
        // `legacyMixed` was never an editable choice. A previously persisted
        // placeholder may therefore carry that transitional marker; upgrade
        // it when the values prove it is really a timed set.
        if storedType == .legacyMixed && inferredType == .timed { return .timed }
        return storedType ?? inferredType
    }
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
    var type: WorkoutSetType
    private(set) var isCompleted: Bool
    private(set) var actualReps: Int?
    private(set) var actualWeight: Double?
    private(set) var actualTimeSeconds: Int?
    private(set) var actualType: WorkoutSetType?
    private(set) var completedAt: Date?

    init(
        id: WorkoutSetID = WorkoutSetID(), order: Int, reps: Int = 0,
        weight: Double = 0, timeSeconds: Int = 0, type: WorkoutSetType? = nil
    ) {
        self.id = id
        self.order = order
        self.type = WorkoutSetType.resolved(
            storedType: type, reps: reps, weight: weight, timeSeconds: timeSeconds
        )
        let normalized = Self.normalizedValues(reps: reps, weight: weight, timeSeconds: timeSeconds, type: self.type)
        self.reps = normalized.reps
        self.weight = normalized.weight
        self.timeSeconds = normalized.timeSeconds
        self.isCompleted = false
        self.actualReps = nil
        self.actualWeight = nil
        self.actualTimeSeconds = nil
        self.actualType = nil
        self.completedAt = nil
    }

    init(
        id: WorkoutSetID,
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
    ) throws {
        guard !isCompleted || (actualReps != nil && actualWeight != nil && actualTimeSeconds != nil && completedAt != nil) else {
            throw WorkoutSetPersistenceError.completedSetMissingActualValues
        }
        guard isCompleted || (actualReps == nil && actualWeight == nil && actualTimeSeconds == nil && completedAt == nil) else {
            throw WorkoutSetPersistenceError.incompleteSetHasActualValues
        }
        let storedType = WorkoutSetType.resolved(
            storedType: type, reps: reps, weight: weight, timeSeconds: timeSeconds
        )
        self.type = storedType
        let normalized: (reps: Int, weight: Double, timeSeconds: Int)
        if type == nil {
            // A document without a type predates mode-specific editing. Keep
            // its raw values intact until the user deliberately chooses one.
            normalized = (reps: reps, weight: weight, timeSeconds: timeSeconds)
        } else {
            normalized = Self.normalizedValues(reps: reps, weight: weight, timeSeconds: timeSeconds, type: storedType)
        }
        self.id = id
        self.order = order
        self.reps = normalized.reps
        self.weight = normalized.weight
        self.timeSeconds = normalized.timeSeconds
        self.isCompleted = isCompleted
        self.actualReps = actualReps
        self.actualWeight = actualWeight
        self.actualTimeSeconds = actualTimeSeconds
        let storedActualType: WorkoutSetType? = actualType ?? ((type == nil || type == .legacyMixed) ? nil : self.type)
        self.actualType = isCompleted
            ? WorkoutSetType.resolved(
                storedType: storedActualType,
                reps: actualReps ?? 0,
                weight: actualWeight ?? 0,
                timeSeconds: actualTimeSeconds ?? 0
            )
            : nil
        self.completedAt = completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(WorkoutSetID.self, forKey: .id)
        order = try container.decode(Int.self, forKey: .order)
        let decodedReps = try container.decode(Int.self, forKey: .reps)
        let decodedWeight = try container.decode(Double.self, forKey: .weight)
        let decodedTimeSeconds = try container.decode(Int.self, forKey: .timeSeconds)
        let decodedType = try container.decodeIfPresent(WorkoutSetType.self, forKey: .type)
        type = WorkoutSetType.resolved(
            storedType: decodedType, reps: decodedReps, weight: decodedWeight, timeSeconds: decodedTimeSeconds
        )
        let normalized: (reps: Int, weight: Double, timeSeconds: Int)
        if decodedType == nil {
            // Preserve legacy mixed payloads during decode/re-save. Explicit
            // type selections still normalize through the branch below.
            normalized = (reps: decodedReps, weight: decodedWeight, timeSeconds: decodedTimeSeconds)
        } else {
            normalized = Self.normalizedValues(
                reps: decodedReps, weight: decodedWeight, timeSeconds: decodedTimeSeconds, type: type
            )
        }
        reps = normalized.reps
        weight = normalized.weight
        timeSeconds = normalized.timeSeconds
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        actualReps = try container.decodeIfPresent(Int.self, forKey: .actualReps)
        actualWeight = try container.decodeIfPresent(Double.self, forKey: .actualWeight)
        actualTimeSeconds = try container.decodeIfPresent(Int.self, forKey: .actualTimeSeconds)
        actualType = try container.decodeIfPresent(WorkoutSetType.self, forKey: .actualType)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        if isCompleted && (actualReps == nil || actualWeight == nil || actualTimeSeconds == nil || completedAt == nil) {
            throw DecodingError.dataCorruptedError(forKey: .isCompleted, in: container, debugDescription: "Completed sets require actual values and a completion timestamp")
        }
        if !isCompleted && (actualReps != nil || actualWeight != nil || actualTimeSeconds != nil || completedAt != nil) {
            throw DecodingError.dataCorruptedError(forKey: .isCompleted, in: container, debugDescription: "Incomplete sets cannot contain actual values or a completion timestamp")
        }
        if isCompleted {
            let storedActualType: WorkoutSetType? = actualType ?? ((decodedType == nil || decodedType == .legacyMixed) ? nil : type)
            actualType = WorkoutSetType.resolved(
                storedType: storedActualType,
                reps: actualReps ?? 0,
                weight: actualWeight ?? 0,
                timeSeconds: actualTimeSeconds ?? 0
            )
        }
        if !isCompleted { actualType = nil }
    }
}

enum WorkoutSetPersistenceError: Error, Equatable {
    case completedSetMissingActualValues
    case incompleteSetHasActualValues
}

import Foundation

extension WorkoutSet {
    var displayedReps: Int { isCompleted ? actualReps ?? reps : reps }
    var displayedWeight: Double { isCompleted ? actualWeight ?? weight : weight }
    var displayedTimeSeconds: Int { isCompleted ? actualTimeSeconds ?? timeSeconds : timeSeconds }
    var displayedType: WorkoutSetType { isCompleted ? actualType ?? type : type }

    mutating func complete(at date: Date = Date()) {
        guard !isCompleted else { return }
        actualReps = reps
        actualWeight = weight
        actualTimeSeconds = timeSeconds
        actualType = type
        completedAt = date
        isCompleted = true
    }

    mutating func undoCompletion() {
        isCompleted = false
        actualReps = nil
        actualWeight = nil
        actualTimeSeconds = nil
        actualType = nil
        completedAt = nil
    }

    mutating func toggleCompletion(at date: Date = Date()) {
        isCompleted ? undoCompletion() : complete(at: date)
    }

    mutating func editPlan(reps: Int, weight: Double, timeSeconds: Int, type: WorkoutSetType? = nil) {
        self.type = type ?? WorkoutSetType.inferred(reps: reps, weight: weight, timeSeconds: timeSeconds)
        let normalized = Self.normalizedValues(reps: reps, weight: weight, timeSeconds: timeSeconds, type: self.type)
        self.reps = normalized.reps
        self.weight = normalized.weight
        self.timeSeconds = normalized.timeSeconds
    }

    mutating func editActual(reps: Int, weight: Double, timeSeconds: Int) {
        guard isCompleted else { return }
        let normalized = Self.normalizedValues(reps: reps, weight: weight, timeSeconds: timeSeconds, type: displayedType)
        actualReps = normalized.reps
        actualWeight = normalized.weight
        actualTimeSeconds = normalized.timeSeconds
    }

    private static func normalizedValues(
        reps: Int, weight: Double, timeSeconds: Int, type: WorkoutSetType
    ) -> (reps: Int, weight: Double, timeSeconds: Int) {
        switch type {
        case .weighted: (reps, weight, 0)
        case .repsOnly: (reps, 0, 0)
        case .timed: (0, 0, timeSeconds)
        case .legacyMixed: (reps, weight, timeSeconds)
        }
    }
}
