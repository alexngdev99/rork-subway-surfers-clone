import SwiftUI

/// Home hub overlay: logo, stats, character cards, and the big RUN button.
struct HomeView: View {
    let state: GameState
    let onSelectCharacter: (String) -> Void
    let onRun: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HUDChip {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(GameTheme.gold)
                    OutlinedText(text: "\(state.bestScore)", size: 17)
                }
                Spacer()
                HUDChip {
                    MusicCoinIcon(size: 18)
                    OutlinedText(text: "\(state.totalCoins)", size: 17)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer().frame(height: 18)

            GameLogo(size: 62)

            Spacer()

            VStack(spacing: 16) {
                CharacterPicker(
                    selectedID: state.selectedCharacterID,
                    onSelect: onSelectCharacter
                )
                .padding(.horizontal, 28)

                HStack(spacing: 12) {
                    SwipeHint(symbol: "arrow.left.arrow.right", text: "Lanes")
                    SwipeHint(symbol: "arrow.up", text: "Jump")
                    SwipeHint(symbol: "arrow.down", text: "Slide")
                }

                Button(action: onRun) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(.white)
                            .shadow(color: GameTheme.outline.opacity(0.9), radius: 0, y: 2)
                        OutlinedText(text: "RUN", size: 32)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .yellow, height: 70, cornerRadius: 22))
                .scaleEffect(pulse ? 1.02 : 1.0)
                .padding(.horizontal, 34)
            }
            .padding(.bottom, 34)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

/// Side-by-side roster of playable characters; the live 3D character on the
/// home scene swaps instantly when a card is tapped.
private struct CharacterPicker: View {
    let selectedID: String
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 14) {
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

/// Big avatar card in the style of a character-select grid: gradient
/// backdrop, bust portrait, outlined name plate, gold border when selected.
private struct CharacterCard: View {
    let character: RunnerCharacterAssets
    let isSelected: Bool
    let onTap: () -> Void

    private var cardGradient: [Color] {
        character.id == "girl"
            ? [Color(red: 0.98, green: 0.50, blue: 0.78), Color(red: 0.52, green: 0.14, blue: 0.60)]
            : [Color(red: 0.62, green: 0.42, blue: 0.96), Color(red: 0.26, green: 0.10, blue: 0.58)]
    }

    private var avatar: UIImage? {
        character.avatarImageName.flatMap { UIImage(named: $0) }
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: cardGradient, startPoint: .top, endPoint: .bottom)

                // Subtle burst behind the avatar for depth.
                Circle()
                    .fill(.white.opacity(0.14))
                    .frame(width: 150, height: 150)
                    .offset(y: 26)
                    .blur(radius: 4)

                if let avatar {
                    Image(uiImage: avatar)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 4)
                        .padding(.top, 10)
                } else {
                    Image(systemName: "figure.run")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.bottom, 40)
                }

                // Name plate pinned to the bottom edge.
                LinearGradient(
                    colors: [.clear, GameTheme.outline.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 54)

                OutlinedText(text: character.displayName.uppercased(), size: 21)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            .frame(height: 168)
            .frame(maxWidth: .infinity)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isSelected ? GameTheme.gold : GameTheme.outline.opacity(0.7),
                        lineWidth: isSelected ? 4 : 2.5
                    )
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [GameTheme.gold, GameTheme.goldDeep],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Circle()
                            .strokeBorder(.white.opacity(0.85), lineWidth: 2)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(GameTheme.outline)
                    }
                    .frame(width: 28, height: 28)
                    .padding(7)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .shadow(
                color: isSelected ? GameTheme.gold.opacity(0.45) : .black.opacity(0.35),
                radius: isSelected ? 12 : 8,
                y: 5
            )
            .saturation(isSelected ? 1.0 : 0.72)
            .scaleEffect(isSelected ? 1.04 : 0.98)
            .animation(.spring(duration: 0.3), value: isSelected)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct SwipeHint: View {
    let symbol: String
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(GameTheme.gold)
            OutlinedText(text: text, size: 12)
        }
        .frame(width: 76, height: 54)
        .background(GameTheme.chip, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1.5)
        )
    }
}
