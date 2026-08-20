import SwiftUI

/// Store screen (mockups 5 & 7): graffiti STORE logo with the Jax avatar,
/// OFFERS / COINS / POWER-UPS / MYSTERY tabs, key-priced packs, permanent
/// power-up upgrades, and the mystery box opening flow.
struct StoreView: View {
    let meta: MetaState
    let initialTab: StoreTab

    @State private var tab: StoreTab
    @State private var toast: String?
    @State private var mysteryReveal: MysteryReward?

    init(meta: MetaState, initialTab: StoreTab) {
        self.meta = meta
        self.initialTab = initialTab
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        MetaScreen {
            VStack(spacing: 0) {
                CurrencyBar(meta: meta)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        header

                        tabPicker

                        switch tab {
                        case .offers: offersTab
                        case .coins: coinsTab
                        case .powerUps: powerUpsTab
                        case .mystery: mysteryTab
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }

                BottomNavBar(active: .store, meta: meta) { navTab in
                    meta.route = navTab.route
                }
                .padding(.bottom, 4)
            }

            if let toast {
                VStack {
                    Spacer()
                    ToastView(text: toast)
                        .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(3)
            }

            if let mysteryReveal {
                MysteryRevealOverlay(reward: mysteryReveal) {
                    withAnimation(.spring(duration: 0.3)) { self.mysteryReveal = nil }
                }
                .zIndex(4)
            }
        }
        .animation(.spring(duration: 0.3), value: toast)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                if let logo = UIImage(named: "store_graffiti_logo") {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 74)
                } else {
                    OutlinedText(text: "STORE", size: 44)
                }
                Text("GET NOTES, POWER-UPS & MORE!")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(GameTheme.gold)
            }

            Spacer()

            if let avatar = UIImage(named: "teenage_boy_dreadlocks_hoodie") {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 90)
            }
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 6) {
            ForEach(StoreTab.allCases) { item in
                Button {
                    withAnimation(.spring(duration: 0.3)) { tab = item }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(item == tab ? GameTheme.gold : .white.opacity(0.6))
                        OutlinedText(text: item.label, size: 10)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                item == tab
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [Color(red: 0.30, green: 0.52, blue: 0.95), Color(red: 0.16, green: 0.30, blue: 0.72)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    : AnyShapeStyle(GameTheme.chip)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                item == tab ? GameTheme.gold.opacity(0.9) : .white.opacity(0.14),
                                lineWidth: item == tab ? 2 : 1.5
                            )
                    )
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    // MARK: Offers

    private var offersTab: some View {
        VStack(spacing: 14) {
            SectionRibbon(text: "SPECIAL OFFERS")

            HStack(spacing: 10) {
                OfferCard(offer: .starter) { buyOffer(.starter) }
                OfferCard(offer: .mega) { buyOffer(.mega) }
            }

            mysteryOfferCard
        }
    }

    private var mysteryOfferCard: some View {
        VStack(spacing: 8) {
            OutlinedText(text: "MYSTERY BOX", size: 16)
            AssetIcon(name: "mystery_cube_box_coins", size: 88, fallbackSymbol: "shippingbox.fill")
                .shadow(color: GameTheme.magenta.opacity(0.6), radius: 12)
            Text("Epic Rewards Inside!")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))

            Button { openMystery() } label: {
                HStack(spacing: 5) {
                    OutlinedText(text: "\(MetaState.mysteryBoxCost)", size: 17)
                    AssetIcon(name: "skeleton_key_blue", size: 19, fallbackSymbol: "key.fill")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(palette: .green, height: 46, cornerRadius: 14))
            .frame(width: 160)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(storeCardBackground(highlight: true))
    }

    // MARK: Coins

    private var coinsTab: some View {
        VStack(spacing: 14) {
            SectionRibbon(text: "COIN PACKS")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(CoinPack.all) { pack in
                    CoinPackCard(pack: pack) { buyCoinPack(pack) }
                }
            }
        }
    }

    // MARK: Power-ups

    private var powerUpsTab: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                OutlinedText(text: "POWER-UPS", size: 26, fill: AnyShapeStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 0.80, green: 0.66, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                ))
                Text("Supercharge your run and beat your high score!")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.65, green: 0.75, blue: 1.0))
            }

            ForEach(UpgradeKind.allCases) { kind in
                UpgradeCard(
                    kind: kind,
                    level: meta.level(of: kind),
                    onUpgrade: { buyUpgrade(kind) }
                )
            }
        }
    }

    // MARK: Mystery

    private var mysteryTab: some View {
        VStack(spacing: 16) {
            SectionRibbon(text: "MYSTERY BOXES")

            AssetIcon(name: "mystery_cube_box_coins", size: 170, fallbackSymbol: "shippingbox.fill")
                .shadow(color: GameTheme.magenta.opacity(0.7), radius: 20)

            Text("Notes, spray cans, keys — or a FREE power-up upgrade!")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button { openMystery() } label: {
                HStack(spacing: 8) {
                    OutlinedText(text: "OPEN FOR \(MetaState.mysteryBoxCost)", size: 19)
                    AssetIcon(name: "skeleton_key_blue", size: 22, fallbackSymbol: "key.fill")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(palette: .magenta, height: 60, cornerRadius: 18))
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 8)
    }

    // MARK: Actions

    private func buyCoinPack(_ pack: CoinPack) {
        if !meta.buyCoinPack(pack) {
            showToast("Not enough keys! Earn more from missions.")
        }
    }

    private func buyOffer(_ offer: OfferPack) {
        if !meta.buyOffer(offer) {
            showToast("Not enough keys! Earn more from missions.")
        }
    }

    private func buyUpgrade(_ kind: UpgradeKind) {
        if !meta.buyUpgrade(kind) {
            showToast(
                meta.level(of: kind) >= UpgradeKind.maxLevel
                    ? "\(kind.displayName) is already maxed!"
                    : "Not enough notes! Run to collect more."
            )
        }
    }

    private func openMystery() {
        if let reward = meta.openMysteryBox() {
            withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
                mysteryReveal = reward
            }
        } else {
            showToast("Not enough keys! Earn more from missions.")
        }
    }

    private func showToast(_ text: String) {
        toast = text
        Task {
            try? await Task.sleep(for: .seconds(2))
            if toast == text { toast = nil }
        }
    }
}

// MARK: - Cards

private func storeCardBackground(highlight: Bool = false) -> some View {
    RoundedRectangle(cornerRadius: 18)
        .fill(
            LinearGradient(
                colors: highlight
                    ? [Color(red: 0.34, green: 0.16, blue: 0.60).opacity(0.95), Color(red: 0.20, green: 0.09, blue: 0.42).opacity(0.95)]
                    : [Color(red: 0.24, green: 0.34, blue: 0.72).opacity(0.94), Color(red: 0.14, green: 0.20, blue: 0.52).opacity(0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    highlight ? GameTheme.magenta.opacity(0.7) : .white.opacity(0.2),
                    lineWidth: highlight ? 2.5 : 1.5
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
}

/// One coin pack tile with amount, icon, badge, and key-price button.
private struct CoinPackCard: View {
    let pack: CoinPack
    let onBuy: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            OutlinedText(
                text: pack.notes.formatted(),
                size: 22,
                fill: AnyShapeStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.88, blue: 0.35), GameTheme.goldDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )

            AssetIcon(name: pack.iconAsset, size: 84, fallbackSymbol: "star.circle.fill")

            Button(action: onBuy) {
                HStack(spacing: 5) {
                    OutlinedText(text: "\(pack.keyCost)", size: 17)
                    AssetIcon(name: "skeleton_key_blue", size: 19, fallbackSymbol: "key.fill")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(palette: .green, height: 44, cornerRadius: 13))
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(storeCardBackground(highlight: pack.badge != nil))
        .overlay(alignment: .top) {
            if let badge = pack.badge {
                OutlinedText(text: badge, size: 10)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [GameTheme.magenta, Color(red: 0.68, green: 0.10, blue: 0.42)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: Capsule()
                    )
                    .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1.5))
                    .offset(y: -10)
            }
        }
    }
}

/// Starter Pack / Mega Bundle card with the contents listed.
private struct OfferCard: View {
    let offer: OfferPack
    let onBuy: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            OutlinedText(text: offer.title, size: 14)

            AssetIcon(name: offer.iconAsset, size: 88, fallbackSymbol: "gift.fill")

            RewardLabel(reward: offer.reward, iconSize: 14, textSize: 13)

            Button(action: onBuy) {
                HStack(spacing: 5) {
                    OutlinedText(text: "\(offer.keyCost)", size: 16)
                    AssetIcon(name: "skeleton_key_blue", size: 18, fallbackSymbol: "key.fill")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(palette: .green, height: 42, cornerRadius: 12))
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(storeCardBackground())
        .overlay(alignment: .topTrailing) {
            if let discount = offer.discountLabel {
                OutlinedText(text: discount, size: 12)
                    .padding(8)
                    .background(GameTheme.magenta, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1.5))
                    .offset(x: 6, y: -8)
            }
        }
    }
}

/// Power-up upgrade card: icon, name, subtitle, level pips, and cost button.
private struct UpgradeCard: View {
    let kind: UpgradeKind
    let level: Int
    let onUpgrade: () -> Void

    private var isMaxed: Bool { level >= UpgradeKind.maxLevel }

    var body: some View {
        HStack(spacing: 12) {
            AssetIcon(name: kind.iconAsset, size: 64, fallbackSymbol: "bolt.fill")

            VStack(alignment: .leading, spacing: 4) {
                OutlinedText(text: kind.displayName, size: 17)
                Text(kind.subtitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.62, green: 0.78, blue: 1.0))
                LevelPipsBar(level: level)
            }

            Spacer(minLength: 4)

            if isMaxed {
                VStack(spacing: 3) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.30))
                    OutlinedText(text: "MAX", size: 13)
                }
                .frame(width: 82)
            } else {
                Button(action: onUpgrade) {
                    HStack(spacing: 4) {
                        OutlinedText(text: "\(UpgradeKind.upgradeCost(fromLevel: level))", size: 14)
                        MusicCoinIcon(size: 16)
                    }
                    .frame(width: 82)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .green, height: 42, cornerRadius: 12))
            }
        }
        .padding(12)
        .background(storeCardBackground(highlight: kind == .jetpack))
    }
}

/// Full-screen reveal after opening a mystery box.
private struct MysteryRevealOverlay: View {
    let reward: MysteryReward
    let onClose: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 18) {
                ZStack {
                    ForEach(0..<8, id: \.self) { index in
                        Capsule()
                            .fill(
                                [GameTheme.gold, GameTheme.magenta, GameTheme.teal, Color(red: 0.65, green: 0.40, blue: 0.95)][index % 4]
                                    .opacity(0.85)
                            )
                            .frame(width: 5, height: appeared ? 34 : 8)
                            .offset(y: appeared ? -95 : -40)
                            .rotationEffect(.degrees(Double(index) * 45))
                    }

                    AssetIcon(name: reward.iconAsset, size: 130, fallbackSymbol: "gift.fill")
                        .scaleEffect(appeared ? 1 : 0.3)
                        .rotationEffect(.degrees(appeared ? 0 : -20))
                        .shadow(color: GameTheme.gold.opacity(0.7), radius: 22)
                }
                .frame(height: 210)

                OutlinedText(text: "YOU GOT", size: 17)
                OutlinedText(
                    text: reward.title,
                    size: 27,
                    fill: AnyShapeStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.88, blue: 0.35), GameTheme.goldDeep],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

                Button(action: onClose) {
                    OutlinedText(text: "AWESOME!", size: 19)
                        .frame(width: 200)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .green, height: 54, cornerRadius: 16))
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.55, bounce: 0.5)) {
                appeared = true
            }
        }
    }
}
