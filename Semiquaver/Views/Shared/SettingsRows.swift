import SwiftUI
import MoirasiaUI

struct SettingsLinkRow: View {
    let title: String
    let subtitle: String?
    var showsInfo = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(MoiraType.body(weight: .semibold))
                    .foregroundStyle(MoiraColor.textPrimary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(MoiraType.small(weight: .medium))
                        .foregroundStyle(MoiraColor.textMuted)
                }
            }

            Spacer()

            if showsInfo {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(MoiraColor.textMuted)
                    .padding(.trailing, 4)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MoiraColor.textSubtle)
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
                    .font(MoiraType.body(weight: .semibold))
                    .foregroundStyle(MoiraColor.textPrimary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(MoiraType.small(weight: .medium))
                        .foregroundStyle(MoiraColor.textMuted)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
