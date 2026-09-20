import SwiftUI
import UniformTypeIdentifiers

struct SettingsTabView: View {
    @ObservedObject var model: IOSAppModel
    @ObservedObject private var folderStore: MusicFolderStore
    @AppStorage("appTheme") private var appTheme: AppTheme = .automatic
    @AppStorage("shuffleByDefault") private var shuffleByDefault = false
    @State private var showThemePicker = false
    @State private var showFolderPicker = false
    @State private var confirmRemoveFolder = false

    init(model: IOSAppModel) {
        self.model = model
        _folderStore = ObservedObject(wrappedValue: model.folderStore)
    }

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
                            isOn: $shuffleByDefault
                        )

                        Divider().overlay(Color.playerDivider)

                        sectionGap

                        sectionHeader("Music Folder")

                        musicFolderRows

                        Divider().overlay(Color.playerDivider)

                        sectionGap

                        sectionHeader("Support")

                        SettingsLinkRow(
                            title: "Make a Donation",
                            subtitle: "Support free and open source multimedia"
                        )

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
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [UTType.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await model.chooseFolder(url) }
            case .failure(let error):
                guard (error as? CocoaError)?.code != .userCancelled else { return }
                model.library.errorMessage = error.localizedDescription
            }
        }
        .confirmationDialog("Remove Music Folder?", isPresented: $confirmRemoveFolder, titleVisibility: .visible) {
            Button("Remove Folder", role: .destructive) {
                Task { await model.removeFolder() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This folder's songs will no longer appear in your library or playlists.")
        }
        .sheet(isPresented: $showThemePicker) {
            themePickerSheet
        }
        .onAppear { model.player.shuffleByDefault = shuffleByDefault }
        .onChange(of: shuffleByDefault) { _, value in model.player.shuffleByDefault = value }
    }

    @ViewBuilder
    private var musicFolderRows: some View {
        if let record = folderStore.record {
            HStack(spacing: 12) {
                Image(systemName: statusIcon(for: record.status))
                    .font(.system(size: 16))
                    .foregroundStyle(record.status == .available ? Color.playerAccent : .orange)
                    .accessibilityLabel(record.status.rawValue)
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.displayName)
                        .font(.bodyMedium())
                        .foregroundStyle(Color.playerTextPrimary)
                    Text(record.lastKnownPath)
                        .font(.caption())
                        .foregroundStyle(Color.playerTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().overlay(Color.playerDivider)

            Button {
                showFolderPicker = true
            } label: {
                SettingsLinkRow(title: "Change Folder…", subtitle: nil)
            }
            .buttonStyle(PressScaleButtonStyle())

            Divider().overlay(Color.playerDivider)

            Button {
                Task { await model.rescan(force: true) }
            } label: {
                SettingsLinkRow(title: "Rescan Now", subtitle: nil)
            }
            .buttonStyle(PressScaleButtonStyle())

            Divider().overlay(Color.playerDivider)

            Button {
                confirmRemoveFolder = true
            } label: {
                SettingsLinkRow(title: "Remove Folder…", subtitle: nil)
            }
            .buttonStyle(PressScaleButtonStyle())
        } else {
            Button {
                showFolderPicker = true
            } label: {
                SettingsLinkRow(
                    title: "Choose Music Folder…",
                    subtitle: "Pick the folder in Files where your music lives"
                )
            }
            .buttonStyle(PressScaleButtonStyle())
        }

        Divider().overlay(Color.playerDivider)
    }

    private func statusIcon(for status: MusicFolderStatus) -> String {
        switch status {
        case .available: "checkmark.circle.fill"
        case .unavailable: "exclamationmark.triangle.fill"
        case .permissionRequired: "exclamationmark.lock.fill"
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
}