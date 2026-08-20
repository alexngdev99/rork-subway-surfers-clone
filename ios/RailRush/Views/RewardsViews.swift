import Combine
import SwiftUI

/// Daily login dialog: 7-day escalating gift calendar over a dimmed home.
struct DailyLoginView: View {
    let meta: MetaState
    let onClose: () -> Void

    @State private var claimedNow = false

    /// Index (0...6) of the tile that is claimable today.
    private var todayIndex: Int {
        meta.dailyLoginReady ? meta.loginStreak % 7 : (meta.loginStreak - 1 + 7) % 7
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            ZStack(alignment: .top) {
                GamePanel {
                    VStack(spacing: 14) {
                        AssetIcon(name: "daily_calendar_icon", size: 64, fallbackSymbol: "calendar.badge.checkmark")

                        Text("Log in every day to keep your streak!")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(LoginDay.week) { day in
                                LoginDayCell(
                                    day: day,
                                    state: cellState(for: day.id)
                                )
                            }
                        }

                        if meta.dailyLoginReady {
                            Button {
                                withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
                                    meta.claimDailyLogin()
                                    claimedNow = true
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 17, weight: .black))
                                        .foregroundStyle(.white)
                                        .shadow(color: GameTheme.outline.opacity(0.9), radius: 0, y: 1.5)
                                    OutlinedText(text: "CLAIM DAY \(meta.loginStreak % 7 + 1)", size: 19)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ChunkyButtonStyle(palette: .green, height: 56, cornerRadius: 16))
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundStyle(Color(red: 0.45, green: 0.82, blue: 0.28))
                                OutlinedText(
                                    text: claimedNow ? "REWARD CLAIMED!" : "COME BACK TOMORROW!",
                                    size: 15
                                )
                            }
                            .frame(height: 44)
                        }

                        Button(action: onClose) {
                            OutlinedText(text: "CLOSE", size: 15)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(palette: .slate, height: 44, cornerRadius: 14))
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 42)
                    .padding(.bottom, 18)
                }

                BannerTitle(text: "DAILY LOGIN", size: 24)
                    .offset(y: -22)
            }
            .frame(maxWidth: 350)
            .padding(.horizontal, 20)
        }
    }

    private func cellState(for index: Int) -> LoginDayCell.CellState {
        if meta.dailyLoginReady {
            if index < todayIndex { return .past }
            if index == todayIndex { return .today }
            return .future
        }
        // Already claimed today: streak's latest tile shows as collected.
        if index <= todayIndex && meta.loginStreak > 0 { return .past }
        return .future
    }
}

private struct LoginDayCell: View {
    enum CellState {
        case past
        case today
        case future
    }

    let day: LoginDay
    let state: CellState

    var body: some View {
        VStack(spacing: 4) {
            OutlinedText(text: "DAY \(day.id + 1)", size: 10)

            rewardIcon
                .frame(height: 26)

            rewardText
        }
        .frame(maxWidth: .infinity)
        .frame(height: 74)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    state == .today
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Color(red: 0.98, green: 0.75, blue: 0.22), GameTheme.goldDeep],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        : AnyShapeStyle(GameTheme.well)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    state == .today ? .white.opacity(0.75) : .white.opacity(0.12),
                    lineWidth: state == .today ? 2.5 : 1.5
                )
        )
        .overlay {
            if state == .past {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.45))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.30))
                }
            }
        }
        .scaleEffect(state == .today ? 1.06 : 1)
    }

    @ViewBuilder
    private var rewardIcon: some View {
        if day.reward.keys > 0 {
            AssetIcon(name: "blue_key_icon", size: 24, fallbackSymbol: "key.fill")
        } else if day.reward.sprays > 0 {
            AssetIcon(name: "spray_boost_icon", size: 24, fallbackSymbol: "paintbrush.fill")
        } else {
            MusicCoinIcon(size: 22)
        }
    }

    private var rewardText: some View {
        let amount: String
        if day.reward.notes > 0 && day.reward.keys > 0 {
            amount = "BIG!"
        } else if day.reward.notes > 0 {
            amount = day.reward.notes.formatted()
        } else if day.reward.keys > 0 {
            amount = "x\(day.reward.keys)"
        } else {
            amount = "x\(day.reward.sprays)"
        }
        return OutlinedText(text: amount, size: 11)
    }
}

/// Free gift dialog: claimable every 4 hours with a reward reveal.
struct FreeRewardsView: View {
    let meta: MetaState
    let onClose: () -> Void

    @State private var revealed: RewardBundle?
    @State private var bounce = false
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            ZStack(alignment: .top) {
                GamePanel {
                    VStack(spacing: 16) {
                        AssetIcon(name: "gift_box_icon", size: 110, fallbackSymbol: "gift.fill")
                            .scaleEffect(bounce ? 1.06 : 0.98)
                            .rotationEffect(.degrees(bounce ? 2 : -2))
                            .animation(
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                value: bounce
                            )
                            .shadow(color: GameTheme.magenta.opacity(0.5), radius: 16)

                        if let revealed {
                            VStack(spacing: 8) {
                                OutlinedText(text: "YOU GOT", size: 15)
                                RewardLabel(reward: revealed, iconSize: 24, textSize: 26)
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else if meta.freeRewardReady {
                            Text("A free gift is waiting for you!")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))

                            Button {
                                withAnimation(.spring(duration: 0.45, bounce: 0.45)) {
                                    revealed = claim()
                                }
                            } label: {
                                OutlinedText(text: "OPEN GIFT!", size: 21)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ChunkyButtonStyle(palette: .magenta, height: 58, cornerRadius: 17))
                        } else {
                            VStack(spacing: 6) {
                                Text("Next gift in")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                                OutlinedText(text: countdownText, size: 26, fill: AnyShapeStyle(GameTheme.gold))
                            }
                        }

                        Button(action: onClose) {
                            OutlinedText(text: revealed == nil ? "CLOSE" : "SWEET!", size: 15)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(palette: .slate, height: 44, cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 42)
                    .padding(.bottom, 18)
                }

                BannerTitle(text: "FREE REWARDS!", size: 22)
                    .offset(y: -22)
            }
            .frame(maxWidth: 330)
            .padding(.horizontal, 24)
        }
        .onAppear { bounce = true }
        .onReceive(timer) { date in now = date }
    }

    private func claim() -> RewardBundle? {
        guard let reward = meta.claimFreeReward() else { return nil }
        return reward
    }

    private var countdownText: String {
        let remaining = max(0, Int(meta.freeRewardReadyAt.timeIntervalSince(now)))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
