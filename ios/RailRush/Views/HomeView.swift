import SwiftUI

/// Home hub overlay: title, stats, character picker, and the big RUN button.
struct HomeView: View {
    let state: GameState
    let onSelectCharacter: (String) -> Void
    let onRun: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 30)

            VStack(spacing: 4) {
                Text("RAIL")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.65, blue: 0.1), Color(red: 1.0, green: 0.4, blue: 0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("RUSH")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.1, green: 0.85, blue: 0.8), Color(red: 0.0, green: 0.6, blue: 0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.top, -26)
            }
            .shadow(color: .black.opacity(0.35), radius: 4, y: 3)
            .rotationEffect(.degrees(-4))

            HStack(spacing: 12) {
                StatChip(
                    icon: "trophy.fill",
                    iconColor: Color(red: 1.0, green: 0.75, blue: 0.1),
                    label: "Best",
                    value: "\(state.bestScore)"
                )
                StatChip(
                    icon: "circle.circle.fill",
                    iconColor: Color(red: 1.0, green: 0.82, blue: 0.1),
                    label: "Coins",
                    value: "\(state.totalCoins)"
                )
            }
            .padding(.top, 18)

            Spacer()

            VStack(spacing: 14) {
                CharacterPicker(
                    selectedID: state.selectedCharacterID,
                    onSelect: onSelectCharacter
                )

                HStack(spacing: 18) {
                    SwipeHint(symbol: "arrow.left.arrow.right", text: "Lanes")
                    SwipeHint(symbol: "arrow.up", text: "Jump")
                    SwipeHint(symbol: "arrow.down", text: "Roll")
                }

                Button(action: onRun) {
                    Text("RUN")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 74)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.55, blue: 0.1), Color(red: 0.95, green: 0.35, blue: 0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 24)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.05).opacity(0.5), radius: 14, y: 6)
                        .scaleEffect(pulse ? 1.03 : 1.0)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 34)
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

/// Horizontal roster of playable characters; the live 3D character on the
/// home scene swaps instantly when a card is tapped.
private struct CharacterPicker: View {
    let selectedID: String
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(GeneratedAssets.characters) { character in
                CharacterCard(
                    character: character,
                    isSelected: character.id == selectedID,
                    onTap: { onSelect(character.id) }
                )
            }
        }
    }
}

private struct CharacterCard: View {
    let character: RunnerCharacterAssets
    let isSelected: Bool
    let onTap: () -> Void

    private var accent: Color {
        character.id == "girl"
            ? Color(red: 0.98, green: 0.4, blue: 0.6)
            : Color(red: 0.1, green: 0.78, blue: 0.74)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accent, accent.opacity(0.65)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 46, height: 46)
                    Image(systemName: "figure.run")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text(character.displayName)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 88, height: 86)
            .background(.black.opacity(isSelected ? 0.5 : 0.3), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accent : .white.opacity(0.15), lineWidth: isSelected ? 2.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white, accent)
                        .padding(6)
                }
            }
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(duration: 0.3), value: isSelected)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct StatChip: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                Text(value)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.black.opacity(0.4), in: Capsule())
    }
}

private struct SwipeHint: View {
    let symbol: String
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .frame(width: 74, height: 56)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Squish-on-press button style with haptic tap.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
