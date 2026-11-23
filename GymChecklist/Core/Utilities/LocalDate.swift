import Foundation

struct LocalDate: Codable, Hashable, Comparable, Sendable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        precondition((1...12).contains(month), "Month must be between 1 and 12")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(year: year, month: month, day: day)
        precondition(calendar.date(from: components).map { calendar.dateComponents([.year, .month, .day], from: $0) == components } == true, "Invalid calendar date")
        self.year = year
        self.month = month
        self.day = day
    }

    /// Stored dates are Gregorian civil dates. A Hebrew, Buddhist or Japanese
    /// system calendar would otherwise produce month 13 (a crash) or a
    /// different year, so every conversion goes through `gregorianEquivalent`.
    init(date: Date, calendar: Calendar = .gymLocal) {
        let components = calendar.gregorianEquivalent.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            preconditionFailure("Calendar could not produce date components")
        }
        self.init(year: year, month: month, day: day)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let year = try container.decode(Int.self, forKey: .year)
        let month = try container.decode(Int.self, forKey: .month)
        let day = try container.decode(Int.self, forKey: .day)
        guard Self.isValid(year: year, month: month, day: day) else {
            throw DecodingError.dataCorruptedError(forKey: .day, in: container, debugDescription: "Invalid local calendar date")
        }
        self.year = year
        self.month = month
        self.day = day
    }

    private enum CodingKeys: String, CodingKey { case year, month, day }

    private static func isValid(year: Int, month: Int, day: Int) -> Bool {
        guard (1...12).contains(month) else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let requested = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: requested) else { return false }
        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        return resolved.year == year && resolved.month == month && resolved.day == day
    }

    static var today: LocalDate { LocalDate(date: Date()) }

    func date(in calendar: Calendar = .gymLocal) -> Date? {
        calendar.gregorianEquivalent.date(from: DateComponents(year: year, month: month, day: day))
    }

    func adding(days: Int, calendar: Calendar = .gymLocal) -> LocalDate? {
        let gregorian = calendar.gregorianEquivalent
        guard let date = date(in: gregorian), let result = gregorian.date(byAdding: .day, value: days, to: date) else { return nil }
        return LocalDate(date: result, calendar: gregorian)
    }

    func adding(weeks: Int, calendar: Calendar = .gymLocal) -> LocalDate? {
        adding(days: weeks * 7, calendar: calendar)
    }

    func adding(months: Int, calendar: Calendar = .gymLocal) -> LocalDate? {
        let gregorian = calendar.gregorianEquivalent
        guard let date = date(in: gregorian),
              let result = gregorian.date(byAdding: .month, value: months, to: date)
        else { return nil }
        return LocalDate(date: result, calendar: gregorian)
    }

    var description: String { String(format: "%04d-%02d-%02d", year, month, day) }

    static func < (lhs: LocalDate, rhs: LocalDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

extension Calendar {
    /// The app's calendar: Gregorian in the device's current time zone and
    /// locale, whatever calendar the user selected in iOS Settings.
    static var gymLocal: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        calendar.locale = .autoupdatingCurrent
        return calendar
    }

    /// This calendar with the Gregorian system but the same time zone, locale
    /// and week settings, so dates and week ranges keep their meaning.
    var gregorianEquivalent: Calendar {
        guard identifier != .gregorian else { return self }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = locale
        calendar.firstWeekday = firstWeekday
        calendar.minimumDaysInFirstWeek = minimumDaysInFirstWeek
        return calendar
    }
}
