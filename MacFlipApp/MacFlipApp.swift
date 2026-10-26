import SwiftUI
import WidgetKit

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var settings: MacFlipSettings
    @Published private(set) var usesAppGroup: Bool

    init(preview: Bool = false) {
        if preview {
            settings = .makeDefault()
            usesAppGroup = true
            return
        }
        let loaded = SettingsRepository.load()
        settings = loaded.settings
        usesAppGroup = loaded.usesAppGroup
    }

    func update(_ mutate: (inout MacFlipSettings) -> Void) {
        var copy = settings
        mutate(&copy)
        settings = copy
        SettingsRepository.save(copy)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

@main
struct MacFlipApp: App {
    @StateObject private var store = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .tint(Color(hex: 0xE29A3A))
        }
        .defaultSize(width: 1040, height: 720)
    }
}
