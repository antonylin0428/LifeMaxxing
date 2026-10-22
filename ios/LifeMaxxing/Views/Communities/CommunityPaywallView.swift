import SwiftUI
import StoreKit

struct CommunityPaywallView: View {
    @State private var service = PurchaseService.shared
    @State private var navigateToCreate = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.18))
                            .frame(width: 100, height: 100)
                        Image(systemName: "person.3.fill")
                            .font(Theme.font(41))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.top, 12)

                    // Copy
                    VStack(spacing: 12) {
                        Text("Create a Community")
                            .font(Theme.font(27))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Each purchase grants one community-creation credit. Buy another anytime to create more. Joining communities is always free.")
                            .font(Theme.font(16))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Feature list
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow(icon: "person.3.fill",    text: "Create 1 community per credit")
                        featureRow(icon: "chart.bar.fill",   text: "Community leaderboards")
                        featureRow(icon: "pencil.circle.fill", text: "Customize name & description anytime")
                        featureRow(icon: "link",              text: "Share invite links with friends")
                    }
                    .padding(20)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)

                    // CTA
                    Button {
                        Task { await buy() }
                    } label: {
                        if service.isLoading {
                            HStack(spacing: 5) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Circle().fill(Color.white.opacity(0.8)).frame(width: 6, height: 6)
                                }
                            }
                        } else {
                            Text(priceLabel)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(service.isLoading)

                    // Restore
                    Button("Restore Purchases") {
                        Task { await restore() }
                    }
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.textSecondary)

                    Text("Payment processed by Apple. Cancel anytime via Settings → Apple Account → Subscriptions is not applicable — this is a one-time purchase.")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 28)
            }
        }
        .navigationTitle("Community Access")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToCreate) {
            CreateCommunityView()
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            if service.product == nil { await service.loadProduct() }
        }
    }

    // MARK: — Helpers

    private var priceLabel: String {
        if let product = service.product {
            return "Unlock for \(product.displayPrice)"
        }
        return "Unlock Community Access"
    }

    private func buy() async {
        do {
            let granted = try await service.purchaseCommunityAccess()
            if granted { navigateToCreate = true }
        } catch PurchaseError.cancelled {
            // user cancelled — no alert needed
        } catch {
            errorMessage = error.localizedDescription ?? "Something went wrong. Try again."
            showError = true
        }
    }

    private func restore() async {
        do {
            let restored = try await service.restorePurchases()
            if restored {
                navigateToCreate = true
            } else {
                errorMessage = "No community-creation credit found on this account."
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription ?? "Restore failed. Try again."
            showError = true
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.surfaceSecondary)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(Theme.font(14, .regular))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(text)
                .font(Theme.font(15, .regular))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
