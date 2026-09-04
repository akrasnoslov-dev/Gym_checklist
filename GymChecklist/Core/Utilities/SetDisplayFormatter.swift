import Foundation

struct SetDisplayFormatter {
    var unit: WeightUnit

    /// `weightInKilograms` is the canonical stored weight for every workout set.
    func string(
        reps: Int,
        weightInKilograms: Double,
        timeSeconds: Int,
        type: WorkoutSetType? = nil
    ) -> String {
        if type == nil, WorkoutSetType.inferred(reps: reps, weight: weightInKilograms, timeSeconds: timeSeconds) == .legacyMixed {
            let weighted = "\(reps) reps × \(formatted(unit.displayWeight(fromCanonicalKilograms: weightInKilograms))) \(unit.rawValue)"
            return "\(weighted) × \(timeSeconds) sec"
        }
        switch type ?? WorkoutSetType.inferred(reps: reps, weight: weightInKilograms, timeSeconds: timeSeconds) {
        case .timed:
            return "\(timeSeconds) sec"
        case .weighted:
            let displayWeight = unit.displayWeight(fromCanonicalKilograms: weightInKilograms)
            return "\(reps) reps × \(formatted(displayWeight)) \(unit.rawValue)"
        case .repsOnly:
            return "\(reps) reps"
        case .legacyMixed:
            let weighted = "\(reps) reps × \(formatted(unit.displayWeight(fromCanonicalKilograms: weightInKilograms))) \(unit.rawValue)"
            return "\(weighted) × \(timeSeconds) sec"
        }
    }

    private func formatted(_ value: Double) -> String {
        if value.rounded() == value { return String(Int(value)) }
        return String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
}

extension WeightUnit {
    private static let poundsPerKilogram = 2.204_622_621_85

    func displayWeight(fromCanonicalKilograms weightInKilograms: Double) -> Double {
        switch self {
        case .kilograms: weightInKilograms
        case .pounds: weightInKilograms * Self.poundsPerKilogram
        }
    }

    func canonicalKilograms(fromDisplayWeight weight: Double) -> Double {
        switch self {
        case .kilograms: weight
        case .pounds: weight / Self.poundsPerKilogram
        }
    }
}
