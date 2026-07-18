# Semiquaver

Semiquaver is an iOS app project built with Xcode.

## Building an IPA for SideStore

SideStore can install an unsigned `.ipa` and sign it during installation. For this project, the output is:

```text
build/Semiquaver.ipa
```

The app currently builds with:

```text
MinimumOSVersion = 26.4
```

Your iPhone must be running iOS 26.4 or newer unless the deployment target is lowered and the app is rebuilt.

## How to Generate the IPA

From the project root, build the iPhoneOS app without signing:

```sh
xcodebuild \
  -project Semiquaver.xcodeproj \
  -scheme Semiquaver \
  -configuration Release \
  -sdk iphoneos \
  -destination generic/platform=iOS \
  -derivedDataPath DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

This creates the app bundle here:

```text
DerivedData/Build/Products/Release-iphoneos/Semiquaver.app
```

Package that `.app` into the IPA layout expected by iOS sideloading tools:

```sh
mkdir -p /tmp/SemiquaverIPA/Payload
ditto DerivedData/Build/Products/Release-iphoneos/Semiquaver.app /tmp/SemiquaverIPA/Payload/Semiquaver.app
mkdir -p build
cd /tmp/SemiquaverIPA
zip -qry -FS -X /Users/mac/Syncthing/Projects/Semiquaver/build/Semiquaver.ipa Payload
```

The final file is:

```text
build/Semiquaver.ipa
```

Load this file in SideStore.

## IPA Packaging

`Semiquaver.ipa` is a clean zip containing only the standard IPA payload:

```text
Payload/Semiquaver.app
```

It is made from this app bundle:

```text
DerivedData/Build/Products/Release-iphoneos/Semiquaver.app
```

The `zip -FS -X` packaging command removes stale archive entries and excludes macOS extended attributes and resource-fork metadata such as `__MACOSX/` and `._Info.plist`.

## How to Get the IPA File

After generating the IPA, get it from the project directory:

```text
/Users/mac/Syncthing/Projects/Semiquaver/build/Semiquaver.ipa
```

Because `build/` and `DerivedData/` are generated Xcode output directories, they are ignored by git and can be recreated with the commands above.
