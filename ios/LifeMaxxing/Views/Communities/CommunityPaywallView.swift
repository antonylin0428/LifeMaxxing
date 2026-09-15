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
                            .fill(Color(hex: "C5B5F5").opacity(0.4))
                            .frame(width: 100, height: 100)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Color(hex: "7A5CF5"))
                    }
                    .padding(.top, 12)

                    // Copy
                    VStack(spacing: 12) {
                        Text("Create a Community")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("One-time purchase. Create your own community and challenge others to compete alongside you. Joining communities is always free.")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Feature list
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow(icon: "person.3.fill",    text: "Create unlimited communities")
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
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hex: "7A5CF5"))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            Text(priceLabel)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hex: "7A5CF5"))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .disabled(service.isLoading)
                    .padding(.horizontal, 8)

                    // Restore
                    Button("Restore Purchases") {
                        Task { await restore() }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)

                    Text("Payment processed by Apple. Cancel anytime via Settings → Apple Account → Subscriptions is not applicable — this is a one-time purchase.")
                        .font(.system(size: 11))
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
                errorMessage = "No previous purchase found for this Apple ID."
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
                    .fill(Color(hex: "C5B5F5").opacity(0.4))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "7A5CF5"))
            }
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
