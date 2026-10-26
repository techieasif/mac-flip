import Foundation

enum HourCycle: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case twelve
    case twentyFour

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .twelve: return "12-hour"
        case .twentyFour: return "24-hour"
        }
    }

    func prefers24Hour(locale: Locale = .current) -> Bool {
        switch self {
        case .twentyFour:
            return true
        case .twelve:
            return false
        case .system:
            let template = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) ?? ""
            return !template.contains("a")
        }
    }
}

enum ProgressSpan: String, Codable, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

enum WidgetKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case world
    case clock
    case day
    case progress
    case countdown
    case sign

    var id: String { rawValue }

    var title: String {
        switch self {
        case .world: return "World Board"
        case .clock: return "Clock"
        case .day: return "Day"
        case .progress: return "Progress"
        case .countdown: return "Countdown"
        case .sign: return "Sign"
        }
    }

    var symbol: String {
        switch self {
        case .world: return "globe"
        case .clock: return "clock"
        case .day: return "calendar"
        case .progress: return "chart.bar.fill"
        case .countdown: return "timer"
        case .sign: return "textformat"
        }
    }

    var blurb: String {
        switch self {
        case .world:
            return "The time in the cities you list, stacked like a departures board."
        case .clock:
            return "One city, large enough to read from across the room, with the date underneath."
        case .day:
            return "Weekday and date, plus a bar that fills as the day goes by."
        case .progress:
            return "How much of the day, week, month, or year has passed, and what is left."
        case .countdown:
            return "Days until a moment you name. On the last day it switches to hours and minutes."
        case .sign:
            return "Any short message, set in dots and sized to fill the board."
        }
    }

    var supportedSizes: [BoardSize] {
        switch self {
        case .world:
            return [.medium, .large, .extraLarge]
        case .sign:
            return [.small, .medium, .large, .extraLarge]
        case .clock, .day, .progress, .countdown:
            return [.small, .medium, .large]
        }
    }
}

enum BoardSize: String, CaseIterable, Identifiable, Sendable {
    case small
    case medium
    case large
    case extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    /// Desktop widget point sizes used by the in-app preview.
    var pointSize: CGSize {
        switch self {
        case .small: return CGSize(width: 164, height: 164)
        case .medium: return CGSize(width: 344, height: 164)
        case .large: return CGSize(width: 344, height: 344)
        case .extraLarge: return CGSize(width: 724, height: 344)
        }
    }
}

struct WidgetOverrides: Equatable, Sendable {
    var theme: ThemeID?
    var cityID: String?
    var span: ProgressSpan?
    var countdownTitle: String?
    var countdownDate: Date?
    var message: String?

    static let none = WidgetOverrides(
        theme: nil,
        cityID: nil,
        span: nil,
        countdownTitle: nil,
        countdownDate: nil,
        message: nil
    )
}

struct MacFlipSettings: Codable, Equatable, Sendable {
    var theme: ThemeID
    var hourCycle: HourCycle
    var cityIDs: [String]
    var clockCityID: String
    var progressSpan: ProgressSpan
    var countdownTitle: String
    var countdownDate: Date
    var message: String
    /// Per-widget theme override, keyed by `WidgetKind.rawValue`.
    var themes: [String: ThemeID]

    static func makeDefault(now: Date = Date()) -> MacFlipSettings {
        MacFlipSettings(
            theme: .midnight,
            hourCycle: .system,
            cityIDs: [CityCatalog.localID, "America/New_York", "Europe/London", "Asia/Tokyo"],
            clockCityID: CityCatalog.localID,
            progressSpan: .year,
            countdownTitle: "NEW YEAR",
            countdownDate: upcomingNewYear(from: now),
            message: "MAKE SOMETHING GOOD",
            themes: [:]
        )
    }

    static func upcomingNewYear(from date: Date) -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        var parts = DateComponents()
        parts.year = year + 1
        parts.month = 1
        parts.day = 1
        return calendar.date(from: parts) ?? date.addingTimeInterval(60 * 60 * 24 * 60)
    }

    func theme(for kind: WidgetKind, override: ThemeID? = nil) -> ThemeID {
        if let override { return override }
        return themes[kind.rawValue] ?? theme
    }
}

enum AppGroup {
    static let fallback = "group.dev.macflip.shared"
    static let defaultsKey = "macflip.settings.v1"

    static var identifier: String {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
           !raw.isEmpty,
           !raw.contains("$") {
            return raw
        }
        return fallback
    }
}

enum SettingsRepository {
    static func load() -> (settings: MacFlipSettings, usesAppGroup: Bool) {
        guard let defaults = UserDefaults(suiteName: AppGroup.identifier) else {
            return (.makeDefault(), false)
        }
        guard let data = defaults.data(forKey: AppGroup.defaultsKey),
              let settings = try? JSONDecoder().decode(MacFlipSettings.self, from: data) else {
            return (.makeDefault(), true)
        }
        return (settings, true)
    }

    static func save(_ settings: MacFlipSettings) {
        let defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: AppGroup.defaultsKey)
    }
}

enum MacFlipLink {
    static func url(for kind: WidgetKind) -> URL {
        URL(string: "macflip://configure/\(kind.rawValue)") ?? URL(string: "macflip://configure/clock")!
    }

    static func kind(from url: URL) -> WidgetKind? {
        guard url.scheme == "macflip" else { return nil }
        let name = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return WidgetKind(rawValue: name)
    }
}
