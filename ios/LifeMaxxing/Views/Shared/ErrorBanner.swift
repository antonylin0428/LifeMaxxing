import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.white)
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(.red)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
