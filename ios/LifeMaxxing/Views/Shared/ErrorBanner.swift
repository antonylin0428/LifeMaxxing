import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(Theme.font(16, .regular))
                .foregroundStyle(.white)
            Text(message)
                .font(Theme.font(14, .regular))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "FF4444"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
