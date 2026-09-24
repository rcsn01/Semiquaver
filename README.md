# Semiquaver

Semiquaver is a native SwiftUI music player for iOS and macOS. The Mac app indexes user-selected folders in place using sandbox-compatible security-scoped bookmarks; Mac playlists and settings stay local and never synchronize with iOS.

## Monorepo colocation

Both app targets link the shared `MoirasiaUI` token package through a local SwiftPM reference (`../../../packages/ui-swift`). That path resolves only while this repository sits at `apps/standalone/Semiquaver` inside the Moirasia monorepo — the same colocated-home assumption the Electron siblings make with their pnpm workspace links. A standalone clone of this repository will not build until the package reference is re-pointed.

## macOS app

The `Semiquaver-macOS` scheme targets macOS 15 or newer.

### Development build and launch

From the Semiquaver project root:

```sh
xcodebuild -project Semiquaver.xcodeproj \
  -scheme Semiquaver-macOS \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath DerivedData-macOS \
  build && open -n DerivedData-macOS/Build/Products/Debug/Semiquaver.app
```

Alternatively, open `Semiquaver.xcodeproj`, select the `Semiquaver-macOS` scheme and **My Mac**, then press `⌘R`.

### Release archive

```sh
xcodebuild -project Semiquaver.xcodeproj \
  -scheme Semiquaver-macOS \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath build/Semiquaver-macOS.xcarchive \
  archive
```

The macOS target uses App Sandbox, app-scoped bookmarks, user-selected read/write access, and hardened runtime. Its bundle identifier is `com.opense.Semiquaver.mac`.

## iOS app

The `Semiquaver` scheme currently requires iOS 26.4 or newer.

### Development build

Open `Semiquaver.xcodeproj`, select the `Semiquaver` scheme and an iPhone simulator, then press `⌘R`.

To build from the command line:

```sh
xcodebuild -project Semiquaver.xcodeproj \
  -scheme Semiquaver \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

### Build and install on a physical iPhone

Pair the iPhone with the Mac over USB, unlock it, and tap **Trust** if prompted. Enable **Developer Mode** if prompted. For wireless installs after pairing, select the iPhone in Xcode's **Window → Devices and Simulators** and enable **Connect via network**. The iPhone must be reachable; `xcrun devicectl list devices` should show it as `available`.

Sign in to Xcode with an Apple Account that can use the development team configured for this project. The iPhone must run iOS 26.4 or newer. List paired devices, then enter the identifier shown next to Ivn's iPhone:

```sh
xcrun devicectl list devices
printf "Enter target identifier: "
read -r DEVICE

xcodebuild -project Semiquaver.xcodeproj \
  -scheme Semiquaver \
  -destination "platform=iOS,id=$DEVICE" \
  -configuration Debug \
  -derivedDataPath DerivedData \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  build

xcrun devicectl device install app \
  --device "$DEVICE" \
  DerivedData/Build/Products/Debug-iphoneos/Semiquaver.app
```

### Build an IPA for SideStore

Build the unsigned iPhoneOS app:

```sh
xcodebuild -project Semiquaver.xcodeproj \
  -scheme Semiquaver \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Package the resulting app bundle:

```sh
PROJECT_ROOT="$(pwd)"
rm -rf /tmp/SemiquaverIPA
mkdir -p /tmp/SemiquaverIPA/Payload build
ditto \
  DerivedData/Build/Products/Release-iphoneos/Semiquaver.app \
  /tmp/SemiquaverIPA/Payload/Semiquaver.app
(cd /tmp/SemiquaverIPA && zip -qry -FS -X "$PROJECT_ROOT/build/Semiquaver.ipa" Payload)
```

The finished IPA is:

```text
build/Semiquaver.ipa
```

Transfer that file to the iPhone and open it in SideStore. SideStore signs the IPA during installation.

The IPA contains only the standard payload at `Payload/Semiquaver.app`. The generated `build/` and `DerivedData/` directories are ignored by Git and can be recreated with these commands.

## Automated release packaging

Semiquaver includes pnpm scripts for packaging both platform artifacts and publishing them to GitHub Releases. They require macOS, Xcode, Node.js 22 or newer, pnpm 10, and the GitHub CLI.

Set the release version in `package.json`, then build both unsigned artifacts:

```sh
pnpm package:release
```

This creates:

```text
release/Semiquaver-<version>.ipa
release/Semiquaver-<version>-mac-universal.dmg
```

SideStore signs the IPA during installation. The DMG is not Developer ID signed or notarized, so macOS may require explicit Gatekeeper approval.

Preview the complete release flow without changing anything:

```sh
pnpm release --dry-run
```

Publish a release:

```sh
gh auth login
pnpm release
```

The release command requires a clean `main` branch containing the latest `origin/main`. It builds both artifacts, writes SHA-256 checksum files, creates and pushes the `v<version>` tag, and uploads the IPA, DMG, and checksums to a generated GitHub Release.
