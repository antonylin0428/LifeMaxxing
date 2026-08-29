import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.08).ignoresSafeArea()
            ProgressView()
                .tint(Theme.ink)
                .scaleEffect(1.2)
                .padding(24)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 6)
        }
    }
}
