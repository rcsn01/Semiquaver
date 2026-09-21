import assert from "node:assert/strict";
import test from "node:test";
import { compareSemver, latestSemverTag, parseSemver } from "./release-version.mjs";

test("parses semantic versions", () => {
  assert.deepEqual(parseSemver("1.2.3"), {
    major: 1,
    minor: 2,
    patch: 3,
    prerelease: []
  });
  assert.equal(parseSemver("1.2"), null);
});

test("compares releases and prereleases", () => {
  assert.equal(compareSemver("1.1.0", "1.0.9"), 1);
  assert.equal(compareSemver("1.0.0-beta.2", "1.0.0-beta.1"), 1);
  assert.equal(compareSemver("1.0.0", "1.0.0-beta.2"), 1);
});

test("finds the latest valid release tag", () => {
  assert.equal(latestSemverTag(["other", "v1.0.0", "v1.2.0", "v1.1.9"]), "v1.2.0");
  assert.equal(latestSemverTag([]), null);
});
