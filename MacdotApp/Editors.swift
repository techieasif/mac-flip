import SwiftUI

struct AppearanceEditor: View {
    @EnvironmentObject private var store: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Appearance")
                .font(.title2.weight(.semibold))
            Text("One theme for every board, unless a board picks its own. Midnight, Obsidian, Amber, and Phosphor glow. Paper, Matcha, Lemon, and Sky stay flat.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ThemeSwatches(selection: store.settings.theme, showsAppMatch: false) { theme in
                guard let theme else { return }
                store.update { $0.theme = theme }
            }
            Picker("Hour format", selection: hourBinding) {
                ForEach(HourCycle.allCases) { cycle in
                    Text(cycle.title).tag(cycle)
                }
            }
            .pickerStyle(.segmented)
            Text("12-hour boards mark morning and afternoon with A and P. 24-hour boards use 00:00 through 23:59.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var hourBinding: Binding<HourCycle> {
        Binding(
            get: { store.settings.hourCycle },
            set: { cycle in store.update { $0.hourCycle = cycle } }
        )
    }
}

struct WidgetEditor: View {
    @EnvironmentObject private var store: SettingsStore
    var kind: WidgetKind

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(kind.title)
                .font(.title2.weight(.semibold))
            Text(kind.blurb)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            switch kind {
            case .world:
                worldEditor
            case .clock:
                clockEditor
            case .day:
                dayNote
            case .progress:
                progressEditor
            case .countdown:
                countdownEditor
            case .sign:
                signEditor
            }
            Divider()
            Text("Theme for this board")
                .font(.headline)
            ThemeSwatches(selection: store.settings.themes[kind.rawValue], showsAppMatch: true) { theme in
                store.update { settings in
                    if let theme {
                        settings.themes[kind.rawValue] = theme
                    } else {
                        settings.themes.removeValue(forKey: kind.rawValue)
                    }
                }
            }
            Text("Right-click a desktop widget and choose Edit Widget to give that one its own theme, city, period, or message. Tap the widget to come back here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var worldEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cities")
                .font(.headline)
            Text("Medium shows the first four, large the first eight, extra large the first seven.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(store.settings.cityIDs, id: \.self) { id in
                cityRow(id)
            }
            if store.settings.cityIDs.count < 12 {
                AddCityButton(existing: store.settings.cityIDs) { city in
                    store.update { settings in
                        guard !settings.cityIDs.contains(city.id) else { return }
                        settings.cityIDs.append(city.id)
                    }
                }
            } else {
                Text("Twelve cities is the limit. The boards show the first ones in this list.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func cityRow(_ id: String) -> some View {
        let city = CityCatalog.stored(id)
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(city?.name ?? id)
                Text(city?.code ?? "")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                move(id, by: -1)
            } label: {
                Image(systemName: "chevron.up")
            }
            .help("Move up")
            Button {
                move(id, by: 1)
            } label: {
                Image(systemName: "chevron.down")
            }
            .help("Move down")
            Button(role: .destructive) {
                store.update { $0.cityIDs.removeAll { $0 == id } }
            } label: {
                Image(systemName: "minus.circle")
            }
            .help("Remove")
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 4)
    }

    private func move(_ id: String, by delta: Int) {
        store.update { settings in
            guard let index = settings.cityIDs.firstIndex(of: id) else { return }
            let next = index + delta
            guard settings.cityIDs.indices.contains(next) else { return }
            settings.cityIDs.swapAt(index, next)
        }
    }

    private var clockEditor: some View {
        Picker("City", selection: Binding(
            get: { store.settings.clockCityID },
            set: { id in store.update { $0.clockCityID = id } }
        )) {
            ForEach(CityCatalog.all) { city in
                Text(city.name).tag(city.id)
            }
        }
    }

    private var dayNote: some View {
        Text("Day follows this Mac. The large size adds the week number and the day of the year. The bar is how much of today has passed.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var progressEditor: some View {
        Picker("Period", selection: Binding(
            get: { store.settings.progressSpan },
            set: { span in store.update { $0.progressSpan = span } }
        )) {
            ForEach(ProgressSpan.allCases) { span in
                Text(span.title).tag(span)
            }
        }
        .pickerStyle(.segmented)
    }

    private var countdownEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Name", text: Binding(
                get: { store.settings.countdownTitle },
                set: { title in store.update { $0.countdownTitle = title } }
            ))
            .textFieldStyle(.roundedBorder)
            DatePicker(
                "Moment",
                selection: Binding(
                    get: { store.settings.countdownDate },
                    set: { date in store.update { $0.countdownDate = date } }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
            Text("Counts in days until the last day, then hours and minutes. When the moment passes, the board says NOW.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var signEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Message", text: Binding(
                get: { store.settings.message },
                set: { message in store.update { $0.message = String(message.prefix(80)) } }
            ), axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(2...5)
            Text("\(store.settings.message.count)/80 · Latin letters, digits, and basic punctuation. The board uppercases them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ThemeSwatches: View {
    var selection: ThemeID?
    var showsAppMatch: Bool
    var onSelect: (ThemeID?) -> Void

    private let columns = [GridItem(.adaptive(minimum: 86), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            if showsAppMatch {
                swatchButton(title: "Match app", theme: DotPalette.theme(.midnight), selected: selection == nil) {
                    onSelect(nil)
                }
            }
            ForEach(ThemeID.allCases) { theme in
                swatchButton(title: theme.title, theme: DotPalette.theme(theme), selected: selection == theme) {
                    onSelect(theme)
                }
            }
        }
    }

    private func swatchButton(title: String, theme: DotTheme, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(theme.background)
                    .overlay {
                        HStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle().fill(theme.on).frame(width: 7, height: 7)
                                    .shadow(color: theme.glows ? theme.glow : .clear, radius: 2)
                            }
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(selected ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: selected ? 2.5 : 1)
                    }
                    .frame(height: 46)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct AddCityButton: View {
    var existing: [String]
    var onAdd: (City) -> Void
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label("Add city", systemImage: "plus")
        }
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            CitySearch(existing: existing) { city in
                onAdd(city)
                isPresented = false
            }
        }
    }
}

struct CitySearch: View {
    var existing: [String]
    var onAdd: (City) -> Void
    @State private var query = ""

    private var matches: [City] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return CityCatalog.all.filter { city in
            guard !existing.contains(city.id) else { return false }
            guard !needle.isEmpty else { return true }
            return city.name.localizedCaseInsensitiveContains(needle) || city.code.localizedCaseInsensitiveContains(needle)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a city")
                .font(.headline)
            TextField("Search by name or code", text: $query)
                .textFieldStyle(.roundedBorder)
            List(matches) { city in
                Button {
                    onAdd(city)
                } label: {
                    HStack {
                        Text(city.code)
                            .font(.body.monospaced())
                            .frame(width: 44, alignment: .leading)
                        VStack(alignment: .leading) {
                            Text(city.name)
                            Text(city.id == CityCatalog.localID ? "Follows this Mac" : city.timeZoneIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        .padding(12)
        .frame(width: 360, height: 420)
    }
}
