import SwiftUI

/// Eight board themes. Midnight, Obsidian, Amber, and Phosphor glow.
/// Paper, Matcha, Lemon, and Sky stay flat.
enum ThemeID: String, Codable, CaseIterable, Identifiable, Sendable {
    case midnight
    case obsidian
    case paper
    case matcha
    case lemon
    case sky
    case amber
    case phosphor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midnight: return "Midnight"
        case .obsidian: return "Obsidian"
        case .paper: return "Paper"
        case .matcha: return "Matcha"
        case .lemon: return "Lemon"
        case .sky: return "Sky"
        case .amber: return "Amber"
        case .phosphor: return "Phosphor"
        }
    }

    var glows: Bool {
        switch self {
        case .midnight, .obsidian, .amber, .phosphor: return true
        case .paper, .matcha, .lemon, .sky: return false
        }
    }
}

struct DotTheme: Equatable {
    var background: Color
    var flap: Color
    var split: Color
    var on: Color
    var off: Color
    var glow: Color
    var glows: Bool
}

enum DotPalette {
    static func theme(_ id: ThemeID) -> DotTheme {
        switch id {
        case .midnight:
            return DotTheme(
                background: Color(hex: 0x141414),
                flap: Color(hex: 0x1C1C1C),
                split: Color(hex: 0x050505),
                on: Color(hex: 0xF4F1EA),
                off: Color(hex: 0xF4F1EA, alpha: 0.07),
                glow: Color(hex: 0xFFF8E6, alpha: 0.55),
                glows: true
            )
        case .obsidian:
            return DotTheme(
                background: Color(hex: 0x000000),
                flap: Color(hex: 0x070707),
                split: Color(hex: 0x000000),
                on: Color(hex: 0xF2F2F2),
                off: Color(hex: 0xFFFFFF, alpha: 0.05),
                glow: Color(hex: 0xB4C8FF, alpha: 0.38),
                glows: true
            )
        case .paper:
            return DotTheme(
                background: Color(hex: 0xF3EFE6),
                flap: Color(hex: 0xE7E1D4),
                split: Color(hex: 0xD4CDB8),
                on: Color(hex: 0x2A261F),
                off: Color(hex: 0x2A261F, alpha: 0.10),
                glow: .clear,
                glows: false
            )
        case .matcha:
            return DotTheme(
                background: Color(hex: 0xD7E4D4),
                flap: Color(hex: 0xC9D9C6),
                split: Color(hex: 0xB7C9B3),
                on: Color(hex: 0x1E3A24),
                off: Color(hex: 0x1E3A24, alpha: 0.12),
                glow: .clear,
                glows: false
            )
        case .lemon:
            return DotTheme(
                background: Color(hex: 0xF6EFC4),
                flap: Color(hex: 0xEFE6AE),
                split: Color(hex: 0xE0D48A),
                on: Color(hex: 0x3D3412),
                off: Color(hex: 0x3D3412, alpha: 0.12),
                glow: .clear,
                glows: false
            )
        case .sky:
            return DotTheme(
                background: Color(hex: 0xD5E4F2),
                flap: Color(hex: 0xC5D8EA),
                split: Color(hex: 0xB3C9DE),
                on: Color(hex: 0x16324D),
                off: Color(hex: 0x16324D, alpha: 0.12),
                glow: .clear,
                glows: false
            )
        case .amber:
            return DotTheme(
                background: Color(hex: 0x140E08),
                flap: Color(hex: 0x1C140C),
                split: Color(hex: 0x050301),
                on: Color(hex: 0xFFB03A),
                off: Color(hex: 0xFFB03A, alpha: 0.09),
                glow: Color(hex: 0xFF961E, alpha: 0.62),
                glows: true
            )
        case .phosphor:
            return DotTheme(
                background: Color(hex: 0x07110C),
                flap: Color(hex: 0x0C1A12),
                split: Color(hex: 0x020805),
                on: Color(hex: 0x9DFF6A),
                off: Color(hex: 0x9DFF6A, alpha: 0.08),
                glow: Color(hex: 0x50FF46, alpha: 0.55),
                glows: true
            )
        }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
