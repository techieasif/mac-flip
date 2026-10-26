import AppIntents
import WidgetKit

struct BoardEntry: TimelineEntry {
    var date: Date
    var kind: WidgetKind
    var settings: MacFlipSettings
    var overrides: WidgetOverrides
}

enum MinuteTimeline {
    /// One entry per minute for the next hour. The system sleeps between entries.
    static func make(kind: WidgetKind, overrides: WidgetOverrides, now: Date = Date()) -> Timeline<BoardEntry> {
        let settings = SettingsRepository.load().settings
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let start = calendar.date(from: parts) ?? now
        let entries: [BoardEntry] = (0..<60).map { offset in
            let date = calendar.date(byAdding: .minute, value: offset, to: start) ?? start
            return BoardEntry(date: date, kind: kind, settings: settings, overrides: overrides)
        }
        let refresh = calendar.date(byAdding: .minute, value: 60, to: start) ?? start.addingTimeInterval(3600)
        return Timeline(entries: entries, policy: .after(refresh))
    }

    static func entry(kind: WidgetKind, overrides: WidgetOverrides, date: Date = .now) -> BoardEntry {
        BoardEntry(
            date: date,
            kind: kind,
            settings: SettingsRepository.load().settings,
            overrides: overrides
        )
    }

    static func placeholder(kind: WidgetKind) -> BoardEntry {
        BoardEntry(date: .now, kind: kind, settings: .makeDefault(), overrides: .none)
    }
}

enum ThemeChoice: String, AppEnum {
    case matchApp
    case midnight
    case obsidian
    case paper
    case matcha
    case lemon
    case sky
    case amber
    case phosphor

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Theme")

    static var caseDisplayRepresentations: [ThemeChoice: DisplayRepresentation] = [
        .matchApp: "Match the App",
        .midnight: "Midnight",
        .obsidian: "Obsidian",
        .paper: "Paper",
        .matcha: "Matcha",
        .lemon: "Lemon",
        .sky: "Sky",
        .amber: "Amber",
        .phosphor: "Phosphor"
    ]

    var themeID: ThemeID? { ThemeID(rawValue: rawValue) }
}

enum SpanChoice: String, AppEnum {
    case matchApp
    case day
    case week
    case month
    case year

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Period")

    static var caseDisplayRepresentations: [SpanChoice: DisplayRepresentation] = [
        .matchApp: "Match the App",
        .day: "Day",
        .week: "Week",
        .month: "Month",
        .year: "Year"
    ]

    var span: ProgressSpan? { ProgressSpan(rawValue: rawValue) }
}

struct CityEntity: AppEntity, Hashable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "City")
    static var defaultQuery = CityEntityQuery()

    var id: String

    var displayRepresentation: DisplayRepresentation {
        let name = CityCatalog.stored(id)?.name ?? "City"
        return DisplayRepresentation(title: "\(name)")
    }
}

struct CityEntityQuery: EntityStringQuery {
    func entities(for identifiers: [CityEntity.ID]) async throws -> [CityEntity] {
        identifiers.map { CityEntity(id: $0) }
    }

    func suggestedEntities() async throws -> [CityEntity] {
        Array(CityCatalog.all.prefix(16)).map { CityEntity(id: $0.id) }
    }

    func entities(matching string: String) async throws -> [CityEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return CityCatalog.all.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.code.localizedCaseInsensitiveContains(query)
        }.map { CityEntity(id: $0.id) }
    }
}

struct WorldIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "World Board"
    static var description = IntentDescription("Times for the cities you chose in Mac Flip.")

    @Parameter(title: "Theme", default: ThemeChoice.matchApp)
    var theme: ThemeChoice = .matchApp

    var overrides: WidgetOverrides {
        WidgetOverrides(theme: theme.themeID, cityID: nil, span: nil, countdownTitle: nil, countdownDate: nil, message: nil)
    }
}

struct ClockIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Clock"
    static var description = IntentDescription("A large dot-matrix clock for one city.")

    @Parameter(title: "City")
    var city: CityEntity?

    @Parameter(title: "Theme", default: ThemeChoice.matchApp)
    var theme: ThemeChoice = .matchApp

    var overrides: WidgetOverrides {
        WidgetOverrides(theme: theme.themeID, cityID: city?.id, span: nil, countdownTitle: nil, countdownDate: nil, message: nil)
    }
}

struct DayIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Day"
    static var description = IntentDescription("Today's date on a dot-matrix board.")

    @Parameter(title: "Theme", default: ThemeChoice.matchApp)
    var theme: ThemeChoice = .matchApp

    var overrides: WidgetOverrides {
        WidgetOverrides(theme: theme.themeID, cityID: nil, span: nil, countdownTitle: nil, countdownDate: nil, message: nil)
    }
}

struct ProgressIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Progress"
    static var description = IntentDescription("How much of a day, week, month, or year has passed.")

    @Parameter(title: "Period", default: SpanChoice.matchApp)
    var span: SpanChoice = .matchApp

    @Parameter(title: "Theme", default: ThemeChoice.matchApp)
    var theme: ThemeChoice = .matchApp

    var overrides: WidgetOverrides {
        WidgetOverrides(theme: theme.themeID, cityID: nil, span: span.span, countdownTitle: nil, countdownDate: nil, message: nil)
    }
}

struct CountdownIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Countdown"
    static var description = IntentDescription("Days, hours, and minutes until a moment you choose.")

    @Parameter(title: "Title")
    var titleText: String?

    @Parameter(title: "Moment")
    var moment: Date?

    @Parameter(title: "Theme", default: ThemeChoice.matchApp)
    var theme: ThemeChoice = .matchApp

    var overrides: WidgetOverrides {
        WidgetOverrides(
            theme: theme.themeID,
            cityID: nil,
            span: nil,
            countdownTitle: trimmed(titleText),
            countdownDate: moment,
            message: nil
        )
    }
}

struct SignIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Sign"
    static var description = IntentDescription("A message in dots, sized to fill the widget.")

    @Parameter(title: "Message")
    var message: String?

    @Parameter(title: "Theme", default: ThemeChoice.matchApp)
    var theme: ThemeChoice = .matchApp

    var overrides: WidgetOverrides {
        WidgetOverrides(theme: theme.themeID, cityID: nil, span: nil, countdownTitle: nil, countdownDate: nil, message: trimmed(message))
    }
}

private func trimmed(_ value: String?) -> String? {
    let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return text.isEmpty ? nil : text
}

struct WorldProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BoardEntry { MinuteTimeline.placeholder(kind: .world) }
    func snapshot(for configuration: WorldIntent, in context: Context) async -> BoardEntry {
        MinuteTimeline.entry(kind: .world, overrides: configuration.overrides)
    }
    func timeline(for configuration: WorldIntent, in context: Context) async -> Timeline<BoardEntry> {
        MinuteTimeline.make(kind: .world, overrides: configuration.overrides)
    }
}

struct ClockProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BoardEntry { MinuteTimeline.placeholder(kind: .clock) }
    func snapshot(for configuration: ClockIntent, in context: Context) async -> BoardEntry {
        MinuteTimeline.entry(kind: .clock, overrides: configuration.overrides)
    }
    func timeline(for configuration: ClockIntent, in context: Context) async -> Timeline<BoardEntry> {
        MinuteTimeline.make(kind: .clock, overrides: configuration.overrides)
    }
}

struct DayProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BoardEntry { MinuteTimeline.placeholder(kind: .day) }
    func snapshot(for configuration: DayIntent, in context: Context) async -> BoardEntry {
        MinuteTimeline.entry(kind: .day, overrides: configuration.overrides)
    }
    func timeline(for configuration: DayIntent, in context: Context) async -> Timeline<BoardEntry> {
        MinuteTimeline.make(kind: .day, overrides: configuration.overrides)
    }
}

struct ProgressProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BoardEntry { MinuteTimeline.placeholder(kind: .progress) }
    func snapshot(for configuration: ProgressIntent, in context: Context) async -> BoardEntry {
        MinuteTimeline.entry(kind: .progress, overrides: configuration.overrides)
    }
    func timeline(for configuration: ProgressIntent, in context: Context) async -> Timeline<BoardEntry> {
        MinuteTimeline.make(kind: .progress, overrides: configuration.overrides)
    }
}

struct CountdownProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BoardEntry { MinuteTimeline.placeholder(kind: .countdown) }
    func snapshot(for configuration: CountdownIntent, in context: Context) async -> BoardEntry {
        MinuteTimeline.entry(kind: .countdown, overrides: configuration.overrides)
    }
    func timeline(for configuration: CountdownIntent, in context: Context) async -> Timeline<BoardEntry> {
        MinuteTimeline.make(kind: .countdown, overrides: configuration.overrides)
    }
}

struct SignProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BoardEntry { MinuteTimeline.placeholder(kind: .sign) }
    func snapshot(for configuration: SignIntent, in context: Context) async -> BoardEntry {
        MinuteTimeline.entry(kind: .sign, overrides: configuration.overrides)
    }
    func timeline(for configuration: SignIntent, in context: Context) async -> Timeline<BoardEntry> {
        MinuteTimeline.make(kind: .sign, overrides: configuration.overrides)
    }
}
