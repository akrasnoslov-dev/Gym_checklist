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
        switch type ?? WorkoutSetType.inferred(reps: reps, weight: weightInKilograms, timeSeconds: timeSeconds) {
        case .timed:
            return "\(timeSeconds) sec"
        case .weighted:
            guard weightInKilograms > 0 else { return "\(reps) reps" }
            let displayWeight = unit.displayWeight(fromCanonicalKilograms: weightInKilograms)
            return "\(reps) reps × \(formatted(displayWeight)) \(unit.rawValue)"
        case .repsOnly:
            return "\(reps) reps"
        case .legacyMixed:
            return legacyMixedString(reps: reps, weightInKilograms: weightInKilograms, timeSeconds: timeSeconds)
        }
    }

    private func legacyMixedString(reps: Int, weightInKilograms: Double, timeSeconds: Int) -> String {
        var components: [String] = []
        if reps > 0 { components.append("\(reps) reps") }
        if weightInKilograms > 0 {
            components.append("\(formatted(unit.displayWeight(fromCanonicalKilograms: weightInKilograms))) \(unit.rawValue)")
        }
        if timeSeconds > 0 { components.append("\(timeSeconds) sec") }
        return components.isEmpty ? "0 reps" : components.joined(separator: " × ")
    }

    private func formatted(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), value)
        }
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
