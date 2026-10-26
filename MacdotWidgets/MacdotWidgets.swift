import SwiftUI
import WidgetKit

extension BoardSize {
    init(family: WidgetFamily) {
        switch family {
        case .systemSmall: self = .small
        case .systemMedium: self = .medium
        case .systemLarge: self = .large
        case .systemExtraLarge: self = .extraLarge
        default: self = .medium
        }
    }
}

struct BoardWidgetView: View {
    var entry: BoardEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        let size = BoardSize(family: family)
        let themeID = entry.settings.theme(for: entry.kind, override: entry.overrides.theme)
        let theme = DotPalette.theme(themeID)
        let model = BoardComposer.make(
            kind: entry.kind,
            size: size,
            date: entry.date,
            settings: entry.settings,
            overrides: entry.overrides
        )
        DotBoard(model: model, theme: theme)
            .containerBackground(theme.background, for: .widget)
    }
}

struct WorldWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "dev.macdot.world", intent: WorldIntent.self, provider: WorldProvider()) { entry in
            BoardWidgetView(entry: entry)
                .widgetURL(MacdotLink.url(for: .world))
        }
        .configurationDisplayName("World Board")
        .description("The time in the cities you picked, like a departures board.")
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

struct ClockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "dev.macdot.clock", intent: ClockIntent.self, provider: ClockProvider()) { entry in
            BoardWidgetView(entry: entry)
                .widgetURL(MacdotLink.url(for: .clock))
        }
        .configurationDisplayName("Clock")
        .description("The time in large dots, with the date underneath.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

struct DayWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "dev.macdot.day", intent: DayIntent.self, provider: DayProvider()) { entry in
            BoardWidgetView(entry: entry)
                .widgetURL(MacdotLink.url(for: .day))
        }
        .configurationDisplayName("Day")
        .description("Weekday, date, and how much of the day is left.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

struct ProgressWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "dev.macdot.progress", intent: ProgressIntent.self, provider: ProgressProvider()) { entry in
            BoardWidgetView(entry: entry)
                .widgetURL(MacdotLink.url(for: .progress))
        }
        .configurationDisplayName("Progress")
        .description("How much of the day, week, month, or year has passed.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "dev.macdot.countdown", intent: CountdownIntent.self, provider: CountdownProvider()) { entry in
            BoardWidgetView(entry: entry)
                .widgetURL(MacdotLink.url(for: .countdown))
        }
        .configurationDisplayName("Countdown")
        .description("Days, hours, and minutes until a moment you choose.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

struct SignWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "dev.macdot.sign", intent: SignIntent.self, provider: SignProvider()) { entry in
            BoardWidgetView(entry: entry)
                .widgetURL(MacdotLink.url(for: .sign))
        }
        .configurationDisplayName("Sign")
        .description("A message in dots, sized to fill the widget.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
    }
}

@main
struct MacdotWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorldWidget()
        ClockWidget()
        DayWidget()
        ProgressWidget()
        CountdownWidget()
        SignWidget()
    }
}
