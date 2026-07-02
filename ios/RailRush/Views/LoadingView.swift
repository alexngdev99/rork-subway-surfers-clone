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
        "Swipe down to roll under signs",
        "Grab the magnet to pull coins in",
        "Jetpack lifts you over every train",
        "Stumble twice and the inspector wins",
    ]

    private var hasKeyArt: Bool {
        UIImage(named: "boy_hoverboard_chase") != nil
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
        Color(red: 0.16, green: 0.3, blue: 0.5)
            .overlay {
                Image("boy_hoverboard_chase")
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
                    Color(red: 0.36, green: 0.72, blue: 0.95),
                    Color(red: 0.45, green: 0.82, blue: 0.9),
                    Color(red: 0.99, green: 0.78, blue: 0.45),
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
                .fill(Color(red: 0.16, green: 0.3, blue: 0.5).opacity(0.5))
                .frame(height: 220)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea()

            FloatingCoins()
        }
    }

    // MARK: Logo

    private var logo: some View {
        VStack(spacing: 4) {
            Text("RAIL")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.78, blue: 0.15), Color(red: 1.0, green: 0.45, blue: 0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text("RUSH")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.15, green: 0.9, blue: 0.85), Color(red: 0.0, green: 0.62, blue: 0.68)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.top, -30)
        }
        .shadow(color: Color(red: 0.1, green: 0.15, blue: 0.35).opacity(0.55), radius: 0, x: 3, y: 5)
        .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        .rotationEffect(.degrees(-5))
    }

    // MARK: Runner figure

    private var runnerFigure: some View {
        Image(systemName: "figure.run")
            .font(.system(size: 96, weight: .bold))
            .foregroundStyle(.white)
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
            .background(.black.opacity(0.35), in: Capsule())
            .id(tipIndex)
            .transition(.opacity)
    }

    private var loadingBar: some View {
        GeometryReader { geo in
            let clamped = min(1, max(0, progress))
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.1, green: 0.16, blue: 0.32).opacity(0.75))

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.84, blue: 0.2), Color(red: 1.0, green: 0.65, blue: 0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(28, (geo.size.width - 8) * clamped))
                    .padding(4)
                    .animation(.easeOut(duration: 0.35), value: clamped)

                Text("LOADING \(Int(clamped * 100))%")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 1, y: 2)
                    .frame(maxWidth: .infinity)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.5), lineWidth: 2)
            )
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
