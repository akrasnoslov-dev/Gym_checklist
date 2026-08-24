import Foundation

struct SetDisplayFormatter {
    var unit: WeightUnit

    /// `weightInKilograms` is the canonical stored weight for every workout set.
    func string(reps: Int, weightInKilograms: Double, timeSeconds: Int) -> String {
        if timeSeconds > 0 && weightInKilograms <= 0 && reps <= 1 {
            return "\(timeSeconds) sec"
        }
        if weightInKilograms > 0 {
            let displayWeight = unit.displayWeight(fromCanonicalKilograms: weightInKilograms)
            let weighted = "\(reps) reps × \(formatted(displayWeight)) \(unit.rawValue)"
            return timeSeconds > 0 ? "\(weighted) × \(timeSeconds) sec" : weighted
        }
        if timeSeconds > 0 {
            return reps > 1 ? "\(reps) reps × \(timeSeconds) sec" : "\(timeSeconds) sec"
        }
        return "\(reps) reps"
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
