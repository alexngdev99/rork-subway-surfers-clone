import SwiftUI
import UIKit

/// Full-screen splash shown while all 3D models preload.
/// Mirrors the classic endless-runner loading screen: big graffiti logo,
/// lively background, and a chunky LOADING bar pinned to the bottom.
struct LoadingView: View {
    let progress: Double

    @State private var raysAngle: Double = 0
    @State private var runnerBounce = false
    @State private var tipIndex = 0

    private static let tips: [String] = [
        "Swipe up to jump over barriers",
        "Swipe down to slide under signs",
        "Spray can pulls music notes to you",
        "Rocket Kicks fly you over every train",
        "Boombox doubles every beat you score",
        "Stumble twice and the inspector wins",
    ]

    private var hasKeyArt: Bool {
        UIImage(named: "street_music_festival_loading") != nil || UIImage(named: "boy_hoverboard_chase") != nil
    }

    private var keyArtName: String {
        UIImage(named: "street_music_festival_loading") != nil ? "street_music_festival_loading" : "boy_hoverboard_chase"
    }

    var body: some View {
        ZStack {
            if hasKeyArt {
                keyArtBackground
            } else {
                background
            }

            VStack(spacing: 0) {
                Spacer().frame(height: 40)
                logo
                Spacer()
                if !hasKeyArt {
                    runnerFigure
                    Spacer()
                }
                tipText
                loadingBar
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                raysAngle = 360
            }
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                runnerBounce = true
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.4))
                withAnimation(.easeInOut(duration: 0.3)) {
                    tipIndex = (tipIndex + 1) % Self.tips.count
                }
            }
        }
    }

    // MARK: Background

    /// Full-bleed generated key art with subtle scrims so the logo and
    /// loading bar stay readable on top of the busy illustration.
    private var keyArtBackground: some View {
        GameTheme.bgDeep
            .overlay {
                Image(keyArtName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.25), location: 0),
                        .init(color: .clear, location: 0.22),
                        .init(color: .clear, location: 0.72),
                        .init(color: .black.opacity(0.45), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            .clipped()
            .ignoresSafeArea()
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.14, blue: 0.62),
                    Color(red: 0.56, green: 0.20, blue: 0.72),
                    Color(red: 0.94, green: 0.40, blue: 0.55),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SunRays()
                .fill(.white.opacity(0.16))
                .frame(width: 900, height: 900)
                .rotationEffect(.degrees(raysAngle))
                .offset(y: -120)

            CitySilhouette()
                .fill(GameTheme.outline.opacity(0.55))
                .frame(height: 220)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea()

            FloatingCoins()
        }
    }

    // MARK: Logo

    private var logo: some View {
        GameLogo(size: 72)
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
    }

    // MARK: Runner figure

    private var runnerFigure: some View {
        Group {
            if let sneaker = UIImage(named: "red_white_sneaker_lightning") {
                Image(uiImage: sneaker)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(runnerBounce ? -8 : 4))
            } else {
                Image(systemName: "figure.run")
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .shadow(color: Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.5), radius: 0, x: 2, y: 4)
        .offset(y: runnerBounce ? -12 : 4)
    }

    // MARK: Tip + bar

    private var tipText: some View {
        Text(Self.tips[tipIndex])
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(GameTheme.chip, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 1.5))
            .id(tipIndex)
            .transition(.opacity)
    }

    private var loadingBar: some View {
        GeometryReader { geo in
            let clamped = min(1, max(0, progress))
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(GameTheme.well.opacity(0.9))

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.30), GameTheme.goldDeep],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white.opacity(0.28))
                            .frame(height: 10)
                            .padding(.horizontal, 6)
                            .padding(.top, 3)
                    }
                    .frame(width: max(28, (geo.size.width - 8) * clamped))
                    .padding(4)
                    .animation(.easeOut(duration: 0.35), value: clamped)

                OutlinedText(text: "LOADING \(Int(clamped * 100))%", size: 19)
                    .frame(maxWidth: .infinity)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.45), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.35), radius: 8, y: 5)
        }
        .frame(height: 54)
    }
}

/// Radial wedge rays for the rotating sunburst backdrop.
private struct SunRays: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height)
        let rayCount = 12
        let step = .pi * 2 / Double(rayCount)
        let halfWidth = step * 0.24

        for i in 0..<rayCount {
            let angle = step * Double(i)
            path.move(to: center)
            path.addLine(to: CGPoint(
                x: center.x + cos(angle - halfWidth) * radius,
                y: center.y + sin(angle - halfWidth) * radius
            ))
            path.addLine(to: CGPoint(
                x: center.x + cos(angle + halfWidth) * radius,
                y: center.y + sin(angle + halfWidth) * radius
            ))
            path.closeSubpath()
        }
        return path
    }
}

/// Simple blocky skyline along the bottom edge.
private struct CitySilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let heights: [CGFloat] = [0.55, 0.8, 0.45, 0.95, 0.6, 0.75, 0.5, 0.88, 0.65]
        let blockWidth = rect.width / CGFloat(heights.count)

        path.move(to: CGPoint(x: 0, y: rect.maxY))
        for (i, h) in heights.enumerated() {
            let x = CGFloat(i) * blockWidth
            let top = rect.maxY - rect.height * h
            path.addLine(to: CGPoint(x: x, y: top))
            path.addLine(to: CGPoint(x: x + blockWidth, y: top))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A handful of coins drifting upward on loop for extra life.
private struct FloatingCoins: View {
    @State private var drift = false

    private static let seeds: [(x: CGFloat, delay: Double, size: CGFloat)] = [
        (0.12, 0.0, 26), (0.3, 0.9, 18), (0.55, 0.4, 22), (0.74, 1.3, 16), (0.9, 0.6, 24),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<Self.seeds.count, id: \.self) { i in
                let seed = Self.seeds[i]
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.88, blue: 0.3), Color(red: 0.95, green: 0.65, blue: 0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 2))
                    .frame(width: seed.size, height: seed.size)
                    .position(x: geo.size.width * seed.x, y: drift ? geo.size.height * 0.15 : geo.size.height * 0.9)
                    .opacity(drift ? 0 : 0.9)
                    .animation(
                        .easeIn(duration: 5.5).repeatForever(autoreverses: false).delay(seed.delay),
                        value: drift
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { drift = true }
    }
}

#Preview {
    LoadingView(progress: 0.45)
}
