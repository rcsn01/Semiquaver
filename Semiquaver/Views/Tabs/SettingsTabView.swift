import SwiftUI

struct SettingsTabView: View {
    @ObservedObject var player: AudioPlayerController
    @AppStorage("appTheme") private var appTheme: AppTheme = .automatic
    @State private var showThemePicker = false
    @State private var showFilesOpenHelp = false

    var body: some View {
        ZStack {
            PlayerBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionHeader("Appearance")

                        Button {
                            showThemePicker = true
                        } label: {
                            SettingsLinkRow(
                                title: "Theme",
                                subtitle: appTheme.displayName
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle())

                        Divider().overlay(Color.playerDivider)

                        sectionGap

                        sectionHeader("Playback")

                        SettingsToggleRow(
                            title: "Shuffle new queues",
                            subtitle: "Automatically shuffle when starting new playback",
                            isOn: $player.shuffleByDefault
                        )

                        Divider().overlay(Color.playerDivider)

                        sectionGap

                        sectionHeader("Support")

                        SettingsLinkRow(
                            title: "Make a Donation",
                            subtitle: "Support free and open source multimedia"
                        )

                        Divider().overlay(Color.playerDivider)

                        sectionGap

                        sectionHeader("Library")

                        Button {
                            openLibraryInFiles()
                        } label: {
                            SettingsLinkRow(
                                title: "Open library in Files",
                                subtitle: "On My iPhone > Semiquaver > Music"
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle())

                        Divider().overlay(Color.playerDivider)

                        Link(destination: URL(string: "https://github.com/rcsn01/Semiquaver")!) {
                            SettingsLinkRow(
                                title: "Privacy Policy",
                                subtitle: nil
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showThemePicker) {
            themePickerSheet
        }
        .alert("Open Files to View Library", isPresented: $showFilesOpenHelp) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Open Files and go to On My iPhone > Semiquaver > Music.")
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("Settings")
                .font(.display())
                .foregroundStyle(Color.playerTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private var themePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.playerBackground.ignoresSafeArea()

                List {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button {
                            appTheme = theme
                            showThemePicker = false
                        } label: {
                            HStack {
                                Text(theme.displayName)
                                    .foregroundStyle(Color.playerTextPrimary)
                                Spacer()
                                if appTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.playerAccent)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showThemePicker = false
                    }
                    .foregroundStyle(Color.playerAccent)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(Color.playerAccent)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    private var sectionGap: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 16)
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
