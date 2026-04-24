import SwiftUI

struct SettingsLinkRow: View {
    let title: String
    let subtitle: String?
    var showsInfo = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.playerTextPrimary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.caption())
                        .foregroundStyle(Color.playerTextSecondary)
                }
            }

            Spacer()

            if showsInfo {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.playerAccent)
                    .padding(.trailing, 4)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.playerTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.bodyMedium())
                    .foregroundStyle(Color.playerTextPrimary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.caption())
                        .foregroundStyle(Color.playerTextSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.playerAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
