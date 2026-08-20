import SwiftUI

/// Character select screen (mockup 2): big portrait on a light "paper" panel,
/// graffiti name + crew, a 2x2 roster grid with locked slots, the SELECT
/// button, and Skin / Tag / Trail equipment chips.
struct CharactersView: View {
    let meta: MetaState
    let selectedID: String
    let onSelect: (String) -> Void

    /// Roster slot: playable characters plus locked "coming soon" crew.
    private struct RosterSlot: Identifiable {
        let id: String
        let displayName: String
        let avatar: String
        let isLocked: Bool
    }

    private var roster: [RosterSlot] {
        [
            RosterSlot(id: "boy", displayName: "JAX", avatar: "teenage_boy_dreadlocks_hoodie", isLocked: false),
            RosterSlot(id: "girl", displayName: "ROXY", avatar: "teenage_girl_pink_bunches", isLocked: false),
            RosterSlot(id: "locked1", displayName: "???", avatar: "teenage_boy_green_hair_avatar", isLocked: true),
            RosterSlot(id: "locked2", displayName: "???", avatar: "girl_peace_sign_avatar", isLocked: true),
        ]
    }

    /// Which slot the grid highlights (falls back to the selected runner).
    @State private var focusedID: String

    init(meta: MetaState, selectedID: String, onSelect: @escaping (String) -> Void) {
        self.meta = meta
        self.selectedID = selectedID
        self.onSelect = onSelect
        _focusedID = State(initialValue: selectedID)
    }

    private var focusedSlot: RosterSlot {
        roster.first { $0.id == focusedID } ?? roster[0]
    }

    var body: some View {
        MetaScreen {
            VStack(spacing: 0) {
                CurrencyBar(meta: meta)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        paperPanel

                        equipmentChips

                        GameLogo(size: 40)
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }

                BottomNavBar(active: .me, meta: meta) { tab in
                    meta.route = tab.route
                }
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: Paper panel (portrait + grid)

    private var paperPanel: some View {
        HStack(alignment: .top, spacing: 12) {
            // Big portrait column
            VStack(spacing: 6) {
                if let image = UIImage(named: focusedSlot.avatar) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .saturation(focusedSlot.isLocked ? 0.1 : 1)
                        .overlay {
                            if focusedSlot.isLocked {
                                AssetIcon(name: "padlock_closed_3d", size: 60, fallbackSymbol: "lock.fill")
                                    .shadow(color: .black.opacity(0.7), radius: 4)
                            }
                        }
                } else {
                    Image(systemName: "figure.run")
                        .font(.system(size: 90, weight: .bold))
                        .foregroundStyle(Color(red: 0.45, green: 0.28, blue: 0.72))
                        .frame(height: 250)
                }
            }
            .frame(maxWidth: .infinity)

            // Name + roster grid column
            VStack(spacing: 10) {
                OutlinedText(
                    text: focusedSlot.displayName,
                    size: 40,
                    fill: AnyShapeStyle(
                        LinearGradient(
                            colors: [Color(red: 0.30, green: 0.14, blue: 0.55), Color(red: 0.48, green: 0.22, blue: 0.80)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    ),
                    outline: .white.opacity(0.0)
                )
                .shadow(color: Color(red: 0.55, green: 0.30, blue: 0.90).opacity(0.5), radius: 6)

                Text("Core Crew")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.38, green: 0.20, blue: 0.62))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(roster) { slot in
                        RosterTile(
                            avatar: slot.avatar,
                            isLocked: slot.isLocked,
                            isSelected: slot.id == selectedID,
                            isFocused: slot.id == focusedID,
                            onTap: {
                                withAnimation(.spring(duration: 0.3)) {
                                    focusedID = slot.id
                                }
                            }
                        )
                    }
                }

                selectButton
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.96, green: 0.95, blue: 0.97), Color(red: 0.88, green: 0.84, blue: 0.93)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .topTrailing) {
                    // Crown sticker accent like the mockup's paper wall.
                    AssetIcon(name: "crown_gems_sticker", size: 30, fallbackSymbol: "crown.fill")
                        .opacity(0.75)
                        .padding(14)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(.white.opacity(0.6), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
        )
    }

    private var selectButton: some View {
        Group {
            if focusedSlot.isLocked {
                Button {} label: {
                    HStack(spacing: 6) {
                        AssetIcon(name: "padlock_closed_3d", size: 18, fallbackSymbol: "lock.fill")
                        OutlinedText(text: "COMING SOON", size: 14)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .slate, height: 46, cornerRadius: 14))
                .disabled(true)
            } else if focusedSlot.id == selectedID {
                Button {} label: {
                    OutlinedText(text: "SELECTED", size: 17)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .green, height: 46, cornerRadius: 14))
                .disabled(true)
            } else {
                Button {
                    onSelect(focusedSlot.id)
                } label: {
                    OutlinedText(text: "SELECT", size: 17)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .yellow, height: 46, cornerRadius: 14))
            }
        }
    }

    // MARK: Equipment chips

    private var equipmentChips: some View {
        HStack(spacing: 8) {
            EquipChip(label: "SKIN", value: "Festival Vibes", equipped: true) {
                AssetIcon(name: "gold_sun_medal_s", size: 26, fallbackSymbol: "paintpalette.fill")
            }
            EquipChip(label: "TAG", value: "Default", equipped: false) {
                AssetIcon(name: "music_note_eighth", size: 26, fallbackSymbol: "music.note")
            }
            EquipChip(label: "TRAIL", value: "Neon Spray", equipped: false) {
                AssetIcon(name: "spray_can_lightning", size: 26, fallbackSymbol: "paintbrush.fill")
            }
        }
    }
}

/// One avatar tile in the roster grid — blue backdrop, lock badge, check mark.
private struct RosterTile: View {
    let avatar: String
    let isLocked: Bool
    let isSelected: Bool
    let isFocused: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.42, green: 0.60, blue: 0.95), Color(red: 0.26, green: 0.42, blue: 0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if let image = UIImage(named: avatar) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                        .saturation(isLocked ? 0.15 : 1)
                }

                if isLocked {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(.black.opacity(0.25))
                }
            }
            .frame(height: 82)
            .clipShape(.rect(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(
                        isFocused ? GameTheme.gold : .white.opacity(0.35),
                        lineWidth: isFocused ? 3.5 : 1.5
                    )
            )
            .overlay(alignment: .topTrailing) {
                if isLocked {
                    ZStack {
                        Circle().fill(GameTheme.gold)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(GameTheme.outline)
                    }
                    .frame(width: 20, height: 20)
                    .padding(4)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isSelected && !isLocked {
                    ZStack {
                        Circle().fill(Color(red: 0.35, green: 0.75, blue: 0.20))
                        Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.5)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 22, height: 22)
                    .padding(3)
                }
            }
            .scaleEffect(isFocused ? 1.04 : 1)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Skin / Tag / Trail equipment chip.
private struct EquipChip<Icon: View>: View {
    let label: String
    let value: String
    let equipped: Bool
    @ViewBuilder let icon: Icon

    var body: some View {
        HStack(spacing: 8) {
            icon

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.72, green: 0.60, blue: 0.95))
                HStack(spacing: 3) {
                    Text(value)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if equipped {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.30))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(Color(red: 0.24, green: 0.13, blue: 0.46).opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1.5)
                )
        )
    }
}
