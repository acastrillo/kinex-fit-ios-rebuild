import SwiftUI

/// Banner shown in the Library or Home tab when there are pending Instagram imports.
struct InstagramImportBannerView: View {
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: AppTheme.Icon.instagram)
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) Instagram import\(count == 1 ? "" : "s") pending")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Tap to review and save")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: AppTheme.Icon.chevronRight)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(AppTheme.spacingMD)
            .background(Color.accent.opacity(0.1))
            .cornerRadius(AppTheme.cornerRadiusMD)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    InstagramImportBannerView(count: 2) {}
        .padding()
}
