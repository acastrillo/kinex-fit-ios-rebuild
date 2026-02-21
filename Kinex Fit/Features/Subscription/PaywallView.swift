import SwiftUI

/// Paywall screen showing tier comparison and upgrade CTAs.
struct PaywallView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PaywallViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    PaywallContent(viewModel: viewModel, dismiss: dismiss)
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = PaywallViewModel(
                        apiClient: environment.apiClient,
                        environment: environment
                    )
                }
            }
        }
    }
}

// MARK: - Paywall Content

private struct PaywallContent: View {
    @Bindable var viewModel: PaywallViewModel
    let dismiss: DismissAction

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXL) {
                // Header
                VStack(spacing: AppTheme.spacingMD) {
                    Image(systemName: AppTheme.Icon.star)
                        .font(.system(size: 48))
                        .foregroundStyle(.accent)

                    Text("Upgrade Your Plan")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Unlock more scans, AI features, and take your training further.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppTheme.spacingLG)

                // Current tier badge
                HStack {
                    Text("Current plan:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.currentTier.displayName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.horizontal, AppTheme.spacingMD)
                        .padding(.vertical, AppTheme.spacingXS)
                        .background(.accent.opacity(0.2))
                        .cornerRadius(AppTheme.cornerRadiusSM)
                }

                // Tier cards
                ForEach(SubscriptionTier.allCases.filter { $0 != .free }, id: \.self) { tier in
                    TierCard(
                        tier: tier,
                        isCurrent: tier == viewModel.currentTier,
                        isLoading: viewModel.isLoading,
                        onUpgrade: {
                            Task { await viewModel.startCheckout(for: tier) }
                        }
                    )
                }
            }
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.bottom, AppTheme.spacingXXL)
        }
        .navigationTitle("Plans")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: $viewModel.showCheckout) {
            if let url = viewModel.checkoutURL {
                StripeCheckoutCoordinator(
                    url: url,
                    onComplete: { sessionId in
                        viewModel.showCheckout = false
                        Task { await viewModel.verifySubscription(sessionId: sessionId) }
                    },
                    onCancel: {
                        viewModel.showCheckout = false
                    }
                )
            }
        }
        .onChange(of: viewModel.didUpgrade) { _, upgraded in
            if upgraded { dismiss() }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
}

// MARK: - Tier Card

private struct TierCard: View {
    let tier: SubscriptionTier
    let isCurrent: Bool
    let isLoading: Bool
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            HStack {
                Text(tier.displayName)
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                if isCurrent {
                    Text("Current")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, AppTheme.spacingSM)
                        .padding(.vertical, AppTheme.spacingXS)
                        .background(.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .cornerRadius(AppTheme.cornerRadiusSM)
                }
            }

            Divider()

            // Features
            featureRow(icon: "doc.text.viewfinder", text: scanText)
            featureRow(icon: "sparkles", text: aiText)
            featureRow(icon: "arrow.triangle.2.circlepath", text: "Cloud sync & backup")

            if tier == .pro || tier == .elite {
                featureRow(icon: "star.fill", text: "Priority support")
            }

            if !isCurrent {
                Button {
                    onUpgrade()
                } label: {
                    Text("Upgrade to \(tier.displayName)")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                .padding(.top, AppTheme.spacingSM)
            }
        }
        .padding(AppTheme.spacingLG)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppTheme.cornerRadiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                .stroke(isCurrent ? Color.accent : Color.clear, lineWidth: 2)
        )
    }

    private var scanText: String {
        tier.isUnlimited ? "Unlimited OCR scans" : "\(tier.scanQuotaLimit) OCR scans/month"
    }

    private var aiText: String {
        tier.isUnlimited ? "Unlimited AI features" : "\(tier.aiQuotaLimit) AI operations/month"
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.spacingSM) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.accent)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .withPreviewEnvironment()
}
