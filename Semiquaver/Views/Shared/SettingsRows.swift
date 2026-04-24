import SwiftUI

struct SettingsLinkRow: View {
    let title: String
    let subtitle: String?
    var showsInfo = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.playerTextSecondary)
                }
            }

            Spacer()

            if showsInfo {
                Image(systemName: "info.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.playerAccent)
                    .padding(.trailing, 10)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.playerMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.playerTextSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.playerAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
