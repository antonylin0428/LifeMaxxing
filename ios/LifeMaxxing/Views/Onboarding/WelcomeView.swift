import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Text("LifeMaxxing")
                    .font(.largeTitle.bold())
                Text("Complete daily goals. Earn XP. Rank up.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink("Sign Up") { SignUpView() }
                    .buttonStyle(.borderedProminent)
                NavigationLink("Sign In") { SignInView() }
                    .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}
