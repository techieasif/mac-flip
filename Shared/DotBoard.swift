import SwiftUI

struct BoardLine: Equatable {
    var text: String
    var weight: CGFloat

    init(_ text: String, weight: CGFloat = 1) {
        self.text = text
        self.weight = weight
    }
}

struct BoardModel: Equatable {
    var lines: [BoardLine]
    var progress: Double?
    /// When set, the board wraps this message to the largest dots that fit.
    var fitMessage: String?
    var accessibilityLabel: String

    init(lines: [BoardLine], progress: Double? = nil, fitMessage: String? = nil, accessibilityLabel: String) {
        self.lines = lines
        self.progress = progress
        self.fitMessage = fitMessage
        self.accessibilityLabel = accessibilityLabel
    }
}

/// Dot-matrix board. Each cell is a split flap. WidgetKit fades a cell when its
/// character changes (`contentTransition(.opacity)`); widgets cannot run a timer,
/// so the desktop boards flip as each minute's timeline entry replaces the last.
struct DotBoard: View {
    var model: BoardModel
    var theme: DotTheme

    var body: some View {
        GeometryReader { geo in
            let lines = resolvedLines(in: geo.size)
            let pad = min(geo.size.width, geo.size.height) * 0.075
            let usable = CGSize(
                width: max(geo.size.width - pad * 2, 1),
                height: max(geo.size.height - pad * 2, 1)
            )
            let units = Self.unitSize(lines: lines, hasBar: model.progress != nil)
            let pitch = max(1.1, min(usable.width / units.width, usable.height / units.height))
            VStack(spacing: pitch * 1.25) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    FlapLine(text: line.text, pitch: pitch * line.weight, theme: theme)
                }
                if let fraction = model.progress {
                    let count = max(8, min(40, Int(usable.width / (pitch * 1.2))))
                    DotBar(fraction: min(max(fraction, 0), 1), pitch: pitch * 0.85, count: count, theme: theme)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(theme.background)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel)
    }

    private func resolvedLines(in size: CGSize) -> [BoardLine] {
        guard let message = model.fitMessage else { return model.lines }
        let clean = DotFont.sanitize(message).trimmingCharacters(in: .whitespacesAndNewlines)
        let source = clean.isEmpty ? "HELLO" : clean
        let pad = min(size.width, size.height) * 0.075
        let usable = CGSize(width: max(size.width - pad * 2, 1), height: max(size.height - pad * 2, 1))
        var best = [BoardLine(source)]
        var bestPitch: CGFloat = -1
        let upper = min(28, max(4, source.count))
        for columns in 4...max(4, upper) {
            let wrapped = Self.wrap(source, columns: columns)
            if wrapped.count > 8 { continue }
            let lines = wrapped.map { BoardLine($0) }
            let units = Self.unitSize(lines: lines, hasBar: false)
            let pitch = min(usable.width / units.width, usable.height / units.height)
            if pitch > bestPitch {
                bestPitch = pitch
                best = lines
            }
        }
        return best
    }

    static func wrap(_ text: String, columns: Int) -> [String] {
        let width = max(1, columns)
        var lines: [String] = []
        var current = ""
        for word in text.split(separator: " ").map(String.init) {
            let pieces = chunk(word, width: width)
            for piece in pieces {
                if current.isEmpty {
                    current = piece
                } else if current.count + 1 + piece.count <= width {
                    current += " " + piece
                } else {
                    lines.append(current)
                    current = piece
                }
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines.isEmpty ? [" "] : lines
    }

    private static func chunk(_ word: String, width: Int) -> [String] {
        guard word.count > width else { return [word] }
        var parts: [String] = []
        var rest = word
        while rest.count > width {
            parts.append(String(rest.prefix(width)))
            rest = String(rest.dropFirst(width))
        }
        if !rest.isEmpty { parts.append(rest) }
        return parts
    }

    static func unitSize(lines: [BoardLine], hasBar: Bool) -> (width: CGFloat, height: CGFloat) {
        var width: CGFloat = 1
        var height: CGFloat = 0
        for (index, line) in lines.enumerated() {
            let count = max(line.text.count, 1)
            let lineWidth = CGFloat(count) * 5 * line.weight + CGFloat(max(count - 1, 0)) * 0.75 * line.weight
            width = max(width, lineWidth)
            if index > 0 { height += 1.25 }
            height += 7 * line.weight
        }
        if hasBar {
            height += 1.25 + 1.3
        }
        return (max(width, 1), max(height, 1))
    }
}

struct FlapLine: View {
    var text: String
    var pitch: CGFloat
    var theme: DotTheme

    var body: some View {
        HStack(spacing: pitch * 0.75) {
            let characters = Array(text)
            ForEach(characters.indices, id: \.self) { index in
                DotGlyph(character: characters[index], pitch: pitch, theme: theme)
                    .contentTransition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: text)
    }
}

struct DotGlyph: View {
    var character: Character
    var pitch: CGFloat
    var theme: DotTheme

    var body: some View {
        let dot = pitch * 0.72
        ZStack {
            RoundedRectangle(cornerRadius: max(1, pitch * 0.18), style: .continuous)
                .fill(theme.flap)
            Canvas { context, _ in
                let bits = DotFont.rows(for: character)
                for row in 0..<DotFont.rows {
                    let mask = row < bits.count ? bits[row] : 0
                    for column in 0..<DotFont.columns {
                        let on = (mask >> (4 - column)) & 1 == 1
                        let originX = CGFloat(column) * pitch + (pitch - dot) / 2
                        let originY = CGFloat(row) * pitch + (pitch - dot) / 2
                        let rect = CGRect(x: originX, y: originY, width: dot, height: dot)
                        if on && theme.glows {
                            let glow = rect.insetBy(dx: -dot * 0.42, dy: -dot * 0.42)
                            context.fill(Path(ellipseIn: glow), with: .color(theme.glow.opacity(0.9)))
                        }
                        context.fill(Path(ellipseIn: rect), with: .color(on ? theme.on : theme.off))
                    }
                }
            }
        }
        .frame(width: pitch * CGFloat(DotFont.columns), height: pitch * CGFloat(DotFont.rows))
        .accessibilityHidden(true)
    }
}

struct DotBar: View {
    var fraction: Double
    var pitch: CGFloat
    var count: Int
    var theme: DotTheme

    var body: some View {
        let lit = Int((fraction * Double(max(count, 1))).rounded())
        HStack(spacing: pitch * 0.42) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index < lit ? theme.on : theme.off)
                    .frame(width: pitch * 0.72, height: pitch * 0.72)
                    .shadow(color: theme.glows && index < lit ? theme.glow.opacity(0.9) : .clear, radius: pitch * 0.28)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: lit)
    }
}
