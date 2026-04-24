import SwiftUI
import UIKit

struct SettingsTabView: View {
    @State private var playVideoFullscreen = true
    @State private var enableTextScrolling = false
    @State private var rememberPlayerState = true
    @State private var restoreLastPlayedMedia = false
    @State private var showFilesOpenHelp = false

    var body: some View {
        ZStack {
            PlayerBackground()

            VStack(spacing: 0) {
                HStack {
                    Button("About") {}
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.playerAccent)

                    Spacer()

                    Text("Settings")
                        .font(.system(size: 43, weight: .semibold, design: .rounded))

                    Spacer()

                    Button("Documentation") {}
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.playerAccent)
                }
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 16)

                Divider()
                    .overlay(Color.playerDivider)

                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsLinkRow(
                            title: "Privacy",
                            subtitle: "Open in Settings"
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Appearance",
                            subtitle: "Automatic"
                        )

                        sectionGap

                        SettingsLinkRow(
                            title: "Make a Donation to VideoLAN",
                            subtitle: "Support free and open source multimedia"
                        )

                        sectionGap

                        Text("Generic")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)

                        Button {
                            openLibraryInFiles()
                        } label: {
                            SettingsLinkRow(
                                title: "View library in files",
                                subtitle: "Open Files > On My iPhone > Semiquaver > Music"
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Default playback speed",
                            subtitle: "1.00x"
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Continue audio playback",
                            subtitle: "Always",
                            showsInfo: true
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Play video in fullscreen",
                            subtitle: nil,
                            isOn: $playVideoFullscreen
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Continue video playback",
                            subtitle: "Always",
                            showsInfo: true
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsLinkRow(
                            title: "Automatically play next item",
                            subtitle: nil
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Enable text scrolling in media list",
                            subtitle: nil,
                            isOn: $enableTextScrolling
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Remember player state (shuffle, loop)",
                            subtitle: nil,
                            isOn: $rememberPlayerState
                        )

                        Divider().overlay(Color.playerDivider)

                        SettingsToggleRow(
                            title: "Restore last played media on launch",
                            subtitle: "Not applicable to externally stored media",
                            isOn: $restoreLastPlayedMedia
                        )
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("Open Files to View Library", isPresented: $showFilesOpenHelp) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text("Open Files and go to On My iPhone > Semiquaver > Music.")
        }
    }

    private var sectionGap: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 26)
            .overlay(alignment: .top) {
                Divider().overlay(Color.playerDivider)
            }
            .overlay(alignment: .bottom) {
                Divider().overlay(Color.playerDivider)
            }
    }

    private func openLibraryInFiles() {
        guard AppMusicDirectory.ensureExists() != nil else {
            showFilesOpenHelp = true
            return
        }

        guard let filesRootURL = URL(string: "shareddocuments://") else {
            showFilesOpenHelp = true
            return
        }

        UIApplication.shared.open(filesRootURL, options: [:]) { success in
            if !success {
                DispatchQueue.main.async {
                    showFilesOpenHelp = true
                }
            }
        }
    }
}
