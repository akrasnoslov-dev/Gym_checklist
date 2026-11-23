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

/// Text shown in, and parsed back from, decimal input fields (GYM-29).
/// Values are formatted without grouping separators, so "1000" never becomes
/// "1,000" (which used to parse back as 1.0). Parsing accepts either "." or
/// "," as the decimal separator and ignores spaces.
enum DecimalInputText {
    static func text(for value: Double, locale: Locale = .autoupdatingCurrent) -> String {
        guard value != 0 else { return "" }
        return value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never).locale(locale))
    }

    /// Returns 0 for empty text and nil for text that is not a number.
    static func value(from text: String) -> Double? {
        let compact = text.filter { !$0.isWhitespace }
        guard !compact.isEmpty else { return 0 }
        guard compact.filter({ $0 == "," || $0 == "." }).count <= 1 else { return nil }
        return Double(compact.replacingOccurrences(of: ",", with: "."))
    }

    /// Converts edited text to canonical kilograms. Unchanged text returns the
    /// original value exactly, so opening and saving never drifts a weight
    /// through display rounding (for example 20 kg -> 44.09 lb -> 19.9989 kg).
    static func canonicalKilograms(
        from text: String,
        initialText: String,
        initialKilograms: Double,
        unit: WeightUnit
    ) -> Double? {
        if text == initialText { return initialKilograms }
        return value(from: text).map { unit.canonicalKilograms(fromDisplayWeight: $0) }
    }
}
