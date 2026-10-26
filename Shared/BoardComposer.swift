import Foundation

enum BoardComposer {
    static func make(
        kind: WidgetKind,
        size: BoardSize,
        date: Date,
        settings: MacFlipSettings,
        overrides: WidgetOverrides = .none
    ) -> BoardModel {
        switch kind {
        case .world:
            return world(size: size, date: date, settings: settings, overrides: overrides)
        case .clock:
            return clock(size: size, date: date, settings: settings, overrides: overrides)
        case .day:
            return day(size: size, date: date, settings: settings)
        case .progress:
            return progress(size: size, date: date, settings: settings, overrides: overrides)
        case .countdown:
            return countdown(size: size, date: date, settings: settings, overrides: overrides)
        case .sign:
            return sign(settings: settings, overrides: overrides)
        }
    }

    private static func world(size: BoardSize, date: Date, settings: MacFlipSettings, overrides: WidgetOverrides) -> BoardModel {
        let limit: Int
        let width: Int
        let useCode: Bool
        switch size {
        case .small, .medium:
            limit = 4
            width = 12
            useCode = true
        case .large:
            limit = 8
            width = 14
            useCode = false
        case .extraLarge:
            limit = 7
            width = 16
            useCode = false
        }
        let ids = settings.cityIDs.filter { CityCatalog.stored($0) != nil }.prefix(limit)
        if ids.isEmpty {
            return BoardModel(lines: [BoardLine("ADD CITIES", weight: 0.8)], accessibilityLabel: "Add cities in Mac Flip")
        }
        let cycle = settings.hourCycle
        var lines: [BoardLine] = []
        var spoken: [String] = []
        for id in ids {
            let city = CityCatalog.resolved(id)
            let zone = CityCatalog.timeZone(for: id)
            let time = compactTime(date: date, timeZone: zone, cycle: cycle)
            let label = useCode ? city.code : city.name
            lines.append(BoardLine(pair(label: label, time: time, width: width)))
            spoken.append("\(city.name) \(spokenTime(date: date, timeZone: zone, cycle: cycle))")
        }
        return BoardModel(lines: lines, accessibilityLabel: spoken.joined(separator: ", "))
    }

    private static func clock(size: BoardSize, date: Date, settings: MacFlipSettings, overrides: WidgetOverrides) -> BoardModel {
        let cityID = overrides.cityID ?? settings.clockCityID
        let city = CityCatalog.resolved(cityID)
        let zone = CityCatalog.timeZone(for: cityID)
        let time = clockTime(date: date, timeZone: zone, cycle: settings.hourCycle, compact: size == .small)
        let stamp = dateStamp(date: date, timeZone: zone, weekday: size != .small)
        let lines: [BoardLine] = [
            BoardLine(size == .small ? city.code : city.name, weight: size == .large ? 0.42 : 0.48),
            BoardLine(time, weight: size == .small ? 0.92 : 1.15),
            BoardLine(stamp, weight: 0.4)
        ]
        var fraction: Double?
        if size == .large {
            fraction = dayFraction(date: date, timeZone: zone)
        }
        let spoken = "\(city.name), \(spokenTime(date: date, timeZone: zone, cycle: settings.hourCycle)), \(spokenDate(date: date, timeZone: zone))"
        return BoardModel(lines: lines, progress: fraction, accessibilityLabel: spoken)
    }

    private static func day(size: BoardSize, date: Date, settings: MacFlipSettings) -> BoardModel {
        _ = settings
        let zone = TimeZone.current
        let calendar = calendar(zone)
        let weekday = calendar.component(.weekday, from: date)
        let shortName = weekdays[weekday - 1]
        let fullName = weekdayNames[weekday - 1]
        let month = months[calendar.component(.month, from: date) - 1]
        let dayNumber = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)
        let fraction = dayFraction(date: date, timeZone: zone)
        switch size {
        case .small:
            return BoardModel(
                lines: [
                    BoardLine(shortName, weight: 0.7),
                    BoardLine(month, weight: 0.55),
                    BoardLine(String(format: "%02d", dayNumber), weight: 1.05)
                ],
                accessibilityLabel: "\(fullName) \(month) \(dayNumber)"
            )
        case .medium, .extraLarge:
            return BoardModel(
                lines: [
                    BoardLine(fullName, weight: 0.62),
                    BoardLine("\(dayNumber) \(month)", weight: 0.95)
                ],
                progress: fraction,
                accessibilityLabel: "\(fullName) \(month) \(dayNumber)"
            )
        case .large:
            let week = calendar.component(.weekOfYear, from: date)
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
            return BoardModel(
                lines: [
                    BoardLine(fullName, weight: 0.55),
                    BoardLine("\(dayNumber) \(month)", weight: 1),
                    BoardLine(String(year), weight: 0.42),
                    BoardLine(String(format: "W%02d  DAY %d", week, dayOfYear), weight: 0.36)
                ],
                progress: fraction,
                accessibilityLabel: "\(fullName) \(month) \(dayNumber), \(year). Week \(week), day \(dayOfYear)."
            )
        }
    }

    private static func progress(size: BoardSize, date: Date, settings: MacFlipSettings, overrides: WidgetOverrides) -> BoardModel {
        let span = overrides.span ?? settings.progressSpan
        let stats = spanStats(span: span, date: date, timeZone: .current)
        let percent = "\(Int((stats.fraction * 100).rounded()))%"
        let name = span.title.uppercased()
        switch size {
        case .small:
            return BoardModel(
                lines: [
                    BoardLine(name, weight: 0.5),
                    BoardLine(percent, weight: 1.05)
                ],
                progress: stats.fraction,
                accessibilityLabel: "\(span.title) \(percent), \(stats.spoken)"
            )
        case .medium, .extraLarge:
            return BoardModel(
                lines: [
                    BoardLine(pair(label: name, time: percent, width: 12), weight: 0.72),
                    BoardLine(stats.short, weight: 0.42)
                ],
                progress: stats.fraction,
                accessibilityLabel: "\(span.title) \(percent), \(stats.spoken)"
            )
        case .large:
            return BoardModel(
                lines: [
                    BoardLine(name, weight: 0.48),
                    BoardLine(percent, weight: 1.2),
                    BoardLine(stats.long, weight: 0.4)
                ],
                progress: stats.fraction,
                accessibilityLabel: "\(span.title) \(percent), \(stats.spoken)"
            )
        }
    }

    private static func countdown(size: BoardSize, date: Date, settings: MacFlipSettings, overrides: WidgetOverrides) -> BoardModel {
        let titleSource = overrides.countdownTitle ?? settings.countdownTitle
        let title = DotFont.sanitize(titleSource).trimmingCharacters(in: .whitespaces)
        let label = title.isEmpty ? "SOON" : title
        let target = overrides.countdownDate ?? settings.countdownDate
        let remaining = target.timeIntervalSince(date)
        if remaining <= 0 {
            return BoardModel(
                lines: [
                    BoardLine(trim(label, size == .small ? 8 : 14), weight: 0.5),
                    BoardLine("NOW", weight: 1.2)
                ],
                accessibilityLabel: "\(label) is now"
            )
        }
        let minutes = Int(remaining / 60)
        let days = minutes / (60 * 24)
        let hours = (minutes / 60) % 24
        let mins = minutes % 60
        let cap = size == .small ? 8 : (size == .large ? 12 : 16)
        if days >= 1 {
            let unit = days == 1 ? "DAY" : "DAYS"
            var lines = [
                BoardLine(trim(label, cap), weight: 0.48),
                BoardLine(String(days), weight: size == .small ? 1.05 : 1.25),
                BoardLine(unit, weight: 0.45)
            ]
            if size != .small {
                lines.append(BoardLine(String(format: "%02dD %02dH %02dM", days, hours, mins), weight: 0.36))
            }
            return BoardModel(lines: lines, accessibilityLabel: "\(label), \(days) \(unit.lowercased()), \(hours) hours, \(mins) minutes")
        }
        var lines = [
            BoardLine(trim(label, cap), weight: 0.48),
            BoardLine(String(format: "%02d:%02d", hours, mins), weight: 1.05)
        ]
        if size != .small {
            lines.append(BoardLine(String(format: "%02dH %02dM", hours, mins), weight: 0.4))
        } else {
            lines.append(BoardLine("LEFT", weight: 0.42))
        }
        return BoardModel(lines: lines, accessibilityLabel: "\(label), \(hours) hours and \(mins) minutes left")
    }

    private static func sign(settings: MacFlipSettings, overrides: WidgetOverrides) -> BoardModel {
        let raw = overrides.message ?? settings.message
        let spoken = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return BoardModel(
            lines: [],
            fitMessage: spoken.isEmpty ? "HELLO" : spoken,
            accessibilityLabel: spoken.isEmpty ? "Hello" : spoken
        )
    }

    static func pair(label: String, time: String, width: Int) -> String {
        let timeText = DotFont.sanitize(time)
        var name = DotFont.sanitize(label).replacingOccurrences(of: "  ", with: " ")
        name = name.trimmingCharacters(in: .whitespaces)
        let room = max(1, width - timeText.count - 1)
        if name.count > room {
            name = String(name.prefix(room)).trimmingCharacters(in: .whitespaces)
        }
        let gap = max(1, width - name.count - timeText.count)
        return name + String(repeating: " ", count: gap) + timeText
    }

    private static func trim(_ text: String, _ maxCount: Int) -> String {
        let clean = DotFont.sanitize(text).trimmingCharacters(in: .whitespaces)
        if clean.count <= maxCount { return clean }
        return String(clean.prefix(maxCount)).trimmingCharacters(in: .whitespaces)
    }

    private static func compactTime(date: Date, timeZone: TimeZone, cycle: HourCycle) -> String {
        let parts = parts(date: date, timeZone: timeZone)
        if cycle.prefers24Hour() {
            return String(format: "%02d:%02d", parts.hour, parts.minute)
        }
        let hour = parts.hour % 12 == 0 ? 12 : parts.hour % 12
        let mark = parts.hour < 12 ? "A" : "P"
        return String(format: "%02d:%02d%@", hour, parts.minute, mark)
    }

    private static func clockTime(date: Date, timeZone: TimeZone, cycle: HourCycle, compact: Bool) -> String {
        let parts = parts(date: date, timeZone: timeZone)
        if cycle.prefers24Hour() {
            return String(format: "%02d:%02d", parts.hour, parts.minute)
        }
        let hour = parts.hour % 12 == 0 ? 12 : parts.hour % 12
        if compact {
            return String(format: "%02d:%02d%@", hour, parts.minute, parts.hour < 12 ? "A" : "P")
        }
        return String(format: "%02d:%02d %@", hour, parts.minute, parts.hour < 12 ? "AM" : "PM")
    }

    private static func spokenTime(date: Date, timeZone: TimeZone, cycle: HourCycle) -> String {
        let parts = parts(date: date, timeZone: timeZone)
        if cycle.prefers24Hour() {
            return String(format: "%d:%02d", parts.hour, parts.minute)
        }
        let hour = parts.hour % 12 == 0 ? 12 : parts.hour % 12
        return "\(hour):\(String(format: "%02d", parts.minute)) \(parts.hour < 12 ? "AM" : "PM")"
    }

    private static func dateStamp(date: Date, timeZone: TimeZone, weekday: Bool) -> String {
        let calendar = calendar(timeZone)
        let month = months[calendar.component(.month, from: date) - 1]
        let day = calendar.component(.day, from: date)
        if !weekday {
            return "\(month) \(day)"
        }
        let name = weekdays[calendar.component(.weekday, from: date) - 1]
        return "\(name) \(month) \(day)"
    }

    private static func spokenDate(date: Date, timeZone: TimeZone) -> String {
        let calendar = calendar(timeZone)
        let month = months[calendar.component(.month, from: date) - 1]
        let day = calendar.component(.day, from: date)
        let name = weekdayNames[calendar.component(.weekday, from: date) - 1]
        return "\(name) \(month) \(day)"
    }

    private static func dayFraction(date: Date, timeZone: TimeZone) -> Double {
        spanStats(span: .day, date: date, timeZone: timeZone).fraction
    }

    private static func spanStats(span: ProgressSpan, date: Date, timeZone: TimeZone) -> (fraction: Double, short: String, long: String, spoken: String) {
        let calendar = calendar(timeZone)
        let interval: DateInterval
        switch span {
        case .day:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
            interval = DateInterval(start: start, end: end)
        case .week:
            interval = calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 1)
        case .month:
            interval = calendar.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 1)
        case .year:
            interval = calendar.dateInterval(of: .year, for: date) ?? DateInterval(start: date, duration: 1)
        }
        let fraction = interval.duration > 0 ? min(max(date.timeIntervalSince(interval.start) / interval.duration, 0), 1) : 0
        let left = max(0, interval.end.timeIntervalSince(date))
        if span == .day {
            let hours = Int(left) / 3600
            let mins = (Int(left) % 3600) / 60
            let text = String(format: "%dH %02dM LEFT", hours, mins)
            return (fraction, text, text, "\(hours) hours \(mins) minutes left")
        }
        let days = Int(ceil(left / 86400))
        let word = days == 1 ? "DAY" : "DAYS"
        return (fraction, "\(days)D LEFT", "\(days) \(word) LEFT", "\(days) \(word.lowercased()) left")
    }

    private static func parts(date: Date, timeZone: TimeZone) -> (hour: Int, minute: Int) {
        let calendar = calendar(timeZone)
        return (calendar.component(.hour, from: date), calendar.component(.minute, from: date))
    }

    private static func calendar(_ timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    private static let weekdayNames = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
    private static let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
}
