import Foundation

struct SetDisplayFormatter {
    var unit: WeightUnit

    func string(reps: Int, weight: Double, timeSeconds: Int) -> String {
        if timeSeconds > 0 && weight <= 0 && reps <= 1 {
            return "\(timeSeconds) sec"
        }
        if weight > 0 {
            let weighted = "\(reps) reps × \(formatted(weight)) \(unit.rawValue)"
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
