import SwiftUI

enum SidebarItem: Hashable {
    case appearance
    case widget(WidgetKind)
}

struct ContentView: View {
    @EnvironmentObject private var store: SettingsStore
    @State private var selection: SidebarItem = .appearance
    @State private var size: BoardSize = .medium

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Appearance", systemImage: "paintpalette")
                    .tag(SidebarItem.appearance)
                Section("Boards") {
                    ForEach(WidgetKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.symbol)
                            .tag(SidebarItem.widget(kind))
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Macdot")
            .safeAreaInset(edge: .bottom) {
                Text("Private. Settings stay on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
        } detail: {
            HStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if !store.usesAppGroup {
                            Text("Turn on the App Group for Macdot and the widget extension, then relaunch, so the desktop boards can read these settings.")
                                .font(.callout)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                        }
                        editor
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minWidth: 340, idealWidth: 420, maxWidth: 480)
                Divider()
                PreviewColumn(selection: selection, size: $size, settings: store.settings)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onOpenURL { url in
            if let kind = MacdotLink.kind(from: url) {
                selection = .widget(kind)
                if !kind.supportedSizes.contains(size) {
                    size = kind.supportedSizes[0]
                }
            }
        }
        .onChange(of: selection) { _, item in
            guard case .widget(let kind) = item else { return }
            if !kind.supportedSizes.contains(size) {
                size = kind.supportedSizes[0]
            }
        }
    }

    @ViewBuilder
    private var editor: some View {
        switch selection {
        case .appearance:
            AppearanceEditor()
        case .widget(let kind):
            WidgetEditor(kind: kind)
        }
    }
}

struct PreviewColumn: View {
    var selection: SidebarItem
    @Binding var size: BoardSize
    var settings: MacdotSettings

    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(spacing: 16) {
                header
                if case .widget(let kind) = selection {
                    singlePreview(kind: kind, date: context.date)
                } else {
                    gallery(date: context.date)
                }
                Text("Desktop widgets refresh about once a minute and sleep the rest of the time. This preview flips when the minute changes, or as soon as you edit a board.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: 0x343C42), Color(hex: 0x1B2024)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 8) {
            Text(selectionTitle)
                .font(.headline)
                .foregroundStyle(.white)
            Picker("Size", selection: $size) {
                ForEach(availableSizes) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 420)
            Text("\(Int(size.pointSize.width)) × \(Int(size.pointSize.height))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var selectionTitle: String {
        switch selection {
        case .appearance: return "Every board"
        case .widget(let kind): return kind.title
        }
    }

    private var availableSizes: [BoardSize] {
        switch selection {
        case .appearance:
            return BoardSize.allCases
        case .widget(let kind):
            return kind.supportedSizes
        }
    }

    private func singlePreview(kind: WidgetKind, date: Date) -> some View {
        WidgetFrame(kind: kind, size: size, date: date, settings: settings, maxWidth: 560)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func gallery(date: Date) -> some View {
        let kinds = WidgetKind.allCases.filter { $0.supportedSizes.contains(size) }
        return ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 18)], spacing: 18) {
                ForEach(kinds) { kind in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(kind.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                        WidgetFrame(kind: kind, size: size, date: date, settings: settings, maxWidth: 300)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct WidgetFrame: View {
    var kind: WidgetKind
    var size: BoardSize
    var date: Date
    var settings: MacdotSettings
    var maxWidth: CGFloat = 520

    var body: some View {
        let model = BoardComposer.make(kind: kind, size: size, date: date, settings: settings)
        let theme = DotPalette.theme(settings.theme(for: kind))
        let scale = min(1, maxWidth / size.pointSize.width)
        DotBoard(model: model, theme: theme)
            .frame(width: size.pointSize.width, height: size.pointSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.38), radius: 14, y: 8)
            .scaleEffect(scale)
            .frame(width: size.pointSize.width * scale, height: size.pointSize.height * scale)
    }
}
