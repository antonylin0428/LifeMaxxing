import SwiftUI

// MARK: - Submitting overlay (replaces spinner for form submission states)

struct SubmittingOverlay: View {
    @State private var phase = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.10).ignoresSafeArea()
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Theme.ink)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase ? 0.5 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Theme.surface)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 5)
        }
        .onAppear { phase = true }
    }
}

// MARK: - Shimmer animation

private struct ShimmerModifier: ViewModifier {
    @State private var move = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0), location: 0),
                            .init(color: .white.opacity(0.45), location: 0.5),
                            .init(color: .white.opacity(0), location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: max(geo.size.width * 0.55, 40))
                    .offset(x: move ? geo.size.width * 1.4 : -geo.size.width * 0.55)
                }
                .clipped()
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    move = true
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Primitive shapes

struct SkeletonBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var cornerRadius: CGFloat = 8

    var body: some View {
        Group {
            if let w = width {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surfaceSecondary)
                    .frame(width: w, height: height)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surfaceSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            }
        }
        .shimmer()
    }
}

struct SkeletonCircle: View {
    let size: CGFloat
    var body: some View {
        Circle()
            .fill(Theme.surfaceSecondary)
            .frame(width: size, height: size)
            .shimmer()
    }
}

struct SkeletonRoundedRect: View {
    let width: CGFloat
    let height: CGFloat
    var cornerRadius: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Theme.surfaceSecondary)
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Home skeleton

struct HomeSkeletonView: View {
    var body: some View {
        VStack(spacing: 28) {
            // Header
            HStack(alignment: .center) {
                SkeletonCircle(size: 46)
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonBox(width: 110, height: 14)
                    SkeletonBox(width: 80, height: 11)
                }
                .padding(.leading, 10)
                Spacer()
                SkeletonCircle(size: 46)
            }

            // Hero card
            SkeletonBox(height: 252, cornerRadius: 28)

            // Week strip
            SkeletonBox(height: 62, cornerRadius: 22)

            // Quests section
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SkeletonBox(width: 120, height: 16)
                    Spacer()
                }
                // Large card
                SkeletonBox(height: 140, cornerRadius: 24)
                // Small cards grid
                HStack(spacing: 12) {
                    SkeletonBox(height: 114, cornerRadius: 22)
                    SkeletonBox(height: 114, cornerRadius: 22)
                }
                HStack(spacing: 12) {
                    SkeletonBox(height: 114, cornerRadius: 22)
                    SkeletonBox(height: 114, cornerRadius: 22)
                }
            }
            .padding(.top, 4)

            // Achievements section
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SkeletonBox(width: 110, height: 16)
                    Spacer()
                    SkeletonBox(width: 50, height: 12)
                }
                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { _ in
                        VStack(spacing: 6) {
                            SkeletonRoundedRect(width: 52, height: 52, cornerRadius: 14)
                            SkeletonBox(width: 44, height: 10)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 36)
    }
}

// MARK: - Quests skeleton

struct QuestsSkeletonView: View {
    var body: some View {
        VStack(spacing: 24) {
            skeletonSection(rows: 4)
            skeletonSection(rows: 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func skeletonSection(rows: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                SkeletonCircle(size: 18)
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonBox(width: 130, height: 13)
                    SkeletonBox(width: 180, height: 11)
                }
            }
            .padding(.bottom, 2)
            VStack(spacing: 8) {
                ForEach(0..<rows, id: \.self) { _ in questRowSkeleton }
            }
        }
    }

    private var questRowSkeleton: some View {
        HStack(spacing: 14) {
            SkeletonRoundedRect(width: 46, height: 46, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 5) {
                SkeletonBox(width: 100, height: 14)
                SkeletonBox(width: 70, height: 11)
            }
            Spacer()
            SkeletonBox(width: 62, height: 30, cornerRadius: 15)
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Profile skeleton

struct ProfileSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header card
            VStack(spacing: 14) {
                SkeletonCircle(size: 80)
                SkeletonBox(width: 120, height: 16)
                SkeletonBox(width: 90, height: 22, cornerRadius: 11)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)

            // Stats row
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonBox(height: 72, cornerRadius: 14)
                }
            }

            // Achievements
            SkeletonBox(height: 96, cornerRadius: 16)

            // Streaks section header
            SkeletonBox(width: 70, height: 14)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Streak rows
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 12) {
                        SkeletonRoundedRect(width: 34, height: 34, cornerRadius: 9)
                        SkeletonBox(width: 100, height: 13)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            SkeletonBox(width: 44, height: 13)
                            SkeletonBox(width: 60, height: 10)
                        }
                    }
                    .padding(12)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            // Settings block
            SkeletonBox(height: 160, cornerRadius: 16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Friends skeleton

struct FriendsListSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonBox(width: 70, height: 13)
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in friendRowSkeleton }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var friendRowSkeleton: some View {
        HStack(spacing: 14) {
            SkeletonCircle(size: 44)
            SkeletonBox(width: 100, height: 14)
            Spacer()
            SkeletonBox(width: 20, height: 14, cornerRadius: 4)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Leaderboard skeleton

struct LeaderboardSkeletonView: View {
    var body: some View {
        VStack(spacing: 0) {
            SkeletonBox(width: 100, height: 13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            VStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in rowSkeleton }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 8)
    }

    private var rowSkeleton: some View {
        HStack(spacing: 14) {
            SkeletonCircle(size: 36)
            SkeletonCircle(size: 40)
            VStack(alignment: .leading, spacing: 4) {
                SkeletonBox(width: 80, height: 13)
                SkeletonBox(width: 60, height: 11)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                SkeletonBox(width: 40, height: 14)
                SkeletonBox(width: 22, height: 10)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Leaderboard feed skeleton

struct FeedSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<2, id: \.self) { _ in feedCardSkeleton }
        }
    }

    private var feedCardSkeleton: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonBox(height: 220, cornerRadius: 0)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 16, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0, topTrailingRadius: 16,
                    style: .continuous
                ))

            HStack(spacing: 12) {
                SkeletonCircle(size: 38)
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonBox(width: 80, height: 13)
                    SkeletonBox(width: 60, height: 11)
                }
                Spacer()
                SkeletonBox(width: 55, height: 24, cornerRadius: 12)
            }
            .padding(14)
            .background(Theme.surface)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 16,
                bottomTrailingRadius: 16, topTrailingRadius: 0,
                style: .continuous
            ))
        }
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - User profile skeleton

struct UserProfileSkeletonView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header card
            VStack(spacing: 14) {
                SkeletonCircle(size: 72)
                SkeletonBox(width: 140, height: 22)
                SkeletonBox(width: 80, height: 16, cornerRadius: 11)
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonBox(height: 60, cornerRadius: 12)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)

            // Achievements
            SkeletonBox(height: 96, cornerRadius: 16)
        }
        .padding(20)
    }
}

// MARK: - Community list skeleton

struct CommunityListSkeletonView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in rowSkeleton }
        }
        .padding(20)
    }

    private var rowSkeleton: some View {
        HStack(spacing: 14) {
            SkeletonRoundedRect(width: 44, height: 44, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 5) {
                SkeletonBox(width: 110, height: 14)
                SkeletonBox(width: 140, height: 11)
            }
            Spacer()
            SkeletonBox(width: 18, height: 14, cornerRadius: 4)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
