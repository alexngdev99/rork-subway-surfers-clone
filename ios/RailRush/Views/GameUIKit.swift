import SwiftUI

/// Shared visual language for every game screen — BEAT RUNNER street-festival
/// style: deep purple panels, chunky beveled 3D buttons, paint-splash accents,
/// and bold white lettering with a dark plum outline.
enum GameTheme {
    static let bgDeep = Color(red: 0.14, green: 0.05, blue: 0.28)
    /// Dark plum used for text outlines and title banners.
    static let outline = Color(red: 0.17, green: 0.06, blue: 0.32)
    static let panelTop = Color(red: 0.58, green: 0.31, blue: 0.88)
    static let panelBottom = Color(red: 0.36, green: 0.14, blue: 0.64)
    /// Darker inset area placed inside bright panels (score boxes, stat rows).
    static let well = Color(red: 0.23, green: 0.09, blue: 0.44)
    /// Semi-opaque dark chip used over the live 3D scene (HUD counters).
    static let chip = Color(red: 0.15, green: 0.05, blue: 0.30).opacity(0.82)
    static let gold = Color(red: 1.0, green: 0.79, blue: 0.24)
    static let goldDeep = Color(red: 0.95, green: 0.58, blue: 0.08)
    /// Hot magenta accent pulled from the key art paint splashes.
    static let magenta = Color(red: 0.94, green: 0.26, blue: 0.62)
    /// Teal accent from spray cans and sneakers in the art.
    static let teal = Color(red: 0.16, green: 0.80, blue: 0.75)
}

/// Face/lip color set for one chunky 3D button.
struct ChunkyPalette {
    let top: Color
    let bottom: Color
    let lip: Color

    static let green = ChunkyPalette(
        top: Color(red: 0.62, green: 0.89, blue: 0.25),
        bottom: Color(red: 0.32, green: 0.70, blue: 0.10),
        lip: Color(red: 0.20, green: 0.50, blue: 0.05)
    )
    static let yellow = ChunkyPalette(
        top: Color(red: 1.0, green: 0.85, blue: 0.30),
        bottom: Color(red: 0.96, green: 0.64, blue: 0.10),
        lip: Color(red: 0.74, green: 0.46, blue: 0.03)
    )
    static let magenta = ChunkyPalette(
        top: Color(red: 0.97, green: 0.45, blue: 0.75),
        bottom: Color(red: 0.80, green: 0.16, blue: 0.53),
        lip: Color(red: 0.54, green: 0.07, blue: 0.37)
    )
    static let purple = ChunkyPalette(
        top: Color(red: 0.66, green: 0.44, blue: 0.94),
        bottom: Color(red: 0.44, green: 0.22, blue: 0.76),
        lip: Color(red: 0.28, green: 0.11, blue: 0.52)
    )
    static let teal = ChunkyPalette(
        top: Color(red: 0.33, green: 0.87, blue: 0.82),
        bottom: Color(red: 0.10, green: 0.62, blue: 0.62),
        lip: Color(red: 0.04, green: 0.40, blue: 0.43)
    )
    static let slate = ChunkyPalette(
        top: Color(red: 0.56, green: 0.48, blue: 0.72),
        bottom: Color(red: 0.38, green: 0.30, blue: 0.54),
        lip: Color(red: 0.23, green: 0.17, blue: 0.37)
    )
}

/// Chunky arcade button: raised gradient face over a darker "lip" that the
/// face presses down into on touch.
struct ChunkyButtonStyle: ButtonStyle {
    var palette: ChunkyPalette
    var height: CGFloat = 60
    var cornerRadius: CGFloat = 18

    private let lipDepth: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(palette.lip)
                .frame(height: height)
                .offset(y: lipDepth)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [palette.top, palette.bottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.30), lineWidth: 1.5)
                )
                .frame(height: height)
                .offset(y: pressed ? lipDepth : 0)

            configuration.label
                .offset(y: pressed ? lipDepth : 0)
        }
        .frame(height: height + lipDepth)
        .compositingGroup()
        .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
        .animation(.easeOut(duration: 0.08), value: pressed)
        .onChange(of: pressed) { _, isPressed in
            if isPressed { HapticsService.shared.uiTap() }
        }
    }
}

/// Heavy rounded text with a dark outline — the signature lettering of the kit.
struct OutlinedText: View {
    let text: String
    var size: CGFloat = 24
    var fill: AnyShapeStyle = AnyShapeStyle(.white)
    var outline: Color = GameTheme.outline
    var outlineWidth: CGFloat = 0

    private var strokeWidth: CGFloat {
        outlineWidth > 0 ? outlineWidth : max(1.5, size * 0.075)
    }

    private static let directions: [CGSize] = [
        CGSize(width: 1, height: 0), CGSize(width: -1, height: 0),
        CGSize(width: 0, height: 1), CGSize(width: 0, height: -1),
        CGSize(width: 0.7, height: 0.7), CGSize(width: -0.7, height: 0.7),
        CGSize(width: 0.7, height: -0.7), CGSize(width: -0.7, height: -0.7),
    ]

    var body: some View {
        ZStack {
            ForEach(0..<Self.directions.count, id: \.self) { i in
                styledText
                    .foregroundStyle(outline)
                    .offset(
                        x: Self.directions[i].width * strokeWidth,
                        y: Self.directions[i].height * strokeWidth
                    )
            }
            styledText
                .foregroundStyle(fill)
        }
    }

    private var styledText: Text {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
    }
}

/// Vivid purple rounded panel used for pause / game-over dialogs.
struct GamePanel<Content: View>: View {
    var cornerRadius: CGFloat = 28
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [GameTheme.panelTop, GameTheme.panelBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(.white.opacity(0.22), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
            )
    }
}

/// Dark plum ribbon with big outlined lettering, slightly tilted — sits on
/// top of a GamePanel like the "SO CLOSE!" banner.
struct BannerTitle: View {
    let text: String
    var size: CGFloat = 30

    var body: some View {
        OutlinedText(text: text, size: size)
            .padding(.horizontal, 26)
            .padding(.vertical, 10)
            .background(GameTheme.outline, in: RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(GameTheme.gold)
                    .offset(x: 4, y: -5)
                    .rotationEffect(.degrees(14))
            }
            .rotationEffect(.degrees(-2))
            .shadow(color: .black.opacity(0.4), radius: 8, y: 5)
    }
}

/// Dark inset well placed inside a bright panel.
struct PanelWell<Content: View>: View {
    var cornerRadius: CGFloat = 16
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(GameTheme.well)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(.black.opacity(0.18), lineWidth: 1.5)
                    )
            )
    }
}

/// Semi-opaque dark capsule floated over the 3D scene (HUD counters).
struct HUDChip<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 6) { content }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(GameTheme.chip, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 1.5))
    }
}

/// Small golden music-note coin used in counters and stat rows —
/// the collectible currency of BEAT RUNNER.
struct MusicCoinIcon: View {
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.88, blue: 0.35), GameTheme.goldDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .strokeBorder(Color(red: 0.72, green: 0.45, blue: 0.03), lineWidth: size * 0.11)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.5, weight: .black))
                .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.05))
        }
        .frame(width: size, height: size)
    }
}

/// Two-line tilted BEAT RUNNER logo shared by the loading and home screens:
/// hot magenta-to-purple "BEAT" over gold "RUNNER", with star sparkles like
/// the key art graffiti lockup.
struct GameLogo: View {
    var size: CGFloat = 64

    var body: some View {
        VStack(spacing: 0) {
            OutlinedText(
                text: "BEAT",
                size: size,
                fill: AnyShapeStyle(
                    LinearGradient(
                        colors: [Color(red: 0.99, green: 0.45, blue: 0.80), Color(red: 0.62, green: 0.22, blue: 0.90)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            OutlinedText(
                text: "RUNNER",
                size: size * 0.82,
                fill: AnyShapeStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.86, blue: 0.30), Color(red: 0.98, green: 0.56, blue: 0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .padding(.top, -size * 0.26)
        }
        .overlay(alignment: .topLeading) {
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.24, weight: .black))
                .foregroundStyle(GameTheme.teal)
                .offset(x: -size * 0.34, y: -size * 0.08)
                .rotationEffect(.degrees(-12))
        }
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "music.note")
                .font(.system(size: size * 0.30, weight: .black))
                .foregroundStyle(GameTheme.magenta)
                .offset(x: size * 0.36, y: size * 0.04)
                .rotationEffect(.degrees(14))
        }
        .shadow(color: .black.opacity(0.35), radius: 0, x: 3, y: 5)
        .rotationEffect(.degrees(-4))
    }
}

/// Squish-on-press button style for cards and icon buttons.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed { HapticsService.shared.uiTap() }
            }
    }
}
