#!/usr/bin/env node
import { access, mkdir, readFile, rm, symlink } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
process.chdir(root);

const args = new Set(process.argv.slice(2));
if (args.has("--help")) {
  console.log("Usage: pnpm package:release");
  console.log("Builds an unsigned SideStore IPA and unsigned macOS DMG.");
  process.exit(0);
}
if (args.size > 0) fail(`Unknown option: ${[...args][0]}`);
if (process.platform !== "darwin") fail("Semiquaver release artifacts must be built on macOS.");

const packageJson = JSON.parse(await readFile(join(root, "package.json"), "utf8"));
const version = packageJson.version;
if (typeof version !== "string" || !/^\d+\.\d+\.\d+$/.test(version)) {
  fail("package.json version must use Apple's numeric major.minor.patch format.");
}

const derivedData = join(root, "DerivedData-release");
const releaseDir = join(root, "release");
const stagingDir = join(releaseDir, ".staging");
const ipaStaging = join(stagingDir, "ipa");
const dmgStaging = join(stagingDir, "dmg");
const iosApp = join(derivedData, "Build", "Products", "Release-iphoneos", "Semiquaver.app");
const macApp = join(derivedData, "Build", "Products", "Release", "Semiquaver.app");
const ipa = join(releaseDir, `Semiquaver-${version}.ipa`);
const dmg = join(releaseDir, `Semiquaver-${version}-mac-universal.dmg`);

await rm(stagingDir, { recursive: true, force: true });
await rm(ipa, { force: true });
await rm(dmg, { force: true });
await mkdir(join(ipaStaging, "Payload"), { recursive: true });
await mkdir(dmgStaging, { recursive: true });

console.log(`Building Semiquaver ${version} for iOS...`);
run(
  "xcodebuild",
  [
    "-project", "Semiquaver.xcodeproj",
    "-scheme", "Semiquaver",
    "-configuration", "Release",
    "-sdk", "iphoneos",
    "-destination", "generic/platform=iOS",
    "-derivedDataPath", derivedData,
    `MARKETING_VERSION=${version}`,
    "CODE_SIGNING_ALLOWED=NO",
    "build"
  ],
  "iOS Release build failed."
);
await access(iosApp).catch(() => fail(`Expected iOS app was not produced: ${iosApp}`));

run(
  "ditto",
  [iosApp, join(ipaStaging, "Payload", "Semiquaver.app")],
  "Unable to stage the iOS app."
);
run(
  "zip",
  ["-qry", "-FS", "-X", ipa, "Payload"],
  "Unable to create the IPA.",
  ipaStaging
);

console.log(`Building Semiquaver ${version} for macOS...`);
run(
  "xcodebuild",
  [
    "-project", "Semiquaver.xcodeproj",
    "-scheme", "Semiquaver-macOS",
    "-configuration", "Release",
    "-destination", "generic/platform=macOS",
    "-derivedDataPath", derivedData,
    `MARKETING_VERSION=${version}`,
    "CODE_SIGNING_ALLOWED=NO",
    "build"
  ],
  "macOS Release build failed."
);
await access(macApp).catch(() => fail(`Expected macOS app was not produced: ${macApp}`));

run("ditto", [macApp, join(dmgStaging, "Semiquaver.app")], "Unable to stage the macOS app.");
await symlink("/Applications", join(dmgStaging, "Applications"));
run(
  "hdiutil",
  [
    "create",
    "-volname", "Semiquaver",
    "-srcfolder", dmgStaging,
    "-ov",
    "-format", "UDZO",
    dmg
  ],
  "Unable to create the DMG."
);

await rm(stagingDir, { recursive: true, force: true });
console.log(`Created ${ipa}`);
console.log(`Created ${dmg}`);
console.log("Artifacts are unsigned. SideStore signs the IPA during installation; macOS may require Gatekeeper approval.");

function run(command, commandArgs, message, cwd = root) {
  const result = spawnSync(command, commandArgs, { cwd, stdio: "inherit" });
  if (result.error || result.status !== 0) fail(message);
}

function fail(message) {
  console.error(message);
  process.exit(1);
}
