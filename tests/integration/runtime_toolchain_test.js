const assert = require("node:assert/strict");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

assert.equal(process.version, "v26.3.1");
assert.ok(process.env.JS_BINARY__NODE_BINARY);
assert.ok(process.env.JS_BINARY__NPM_BINARY);

const addonArgument = process.argv[2];
const addonPath = path.isAbsolute(addonArgument)
  ? addonArgument
  : path.resolve(__dirname, addonArgument);
const addon = require(addonPath);
assert.equal(addon.answer(), 42);

const npm = spawnSync(
  process.execPath,
  [process.env.JS_BINARY__NPM_BINARY, "--version"],
  { encoding: "utf8" },
);
assert.equal(npm.status, 0, npm.stderr);
assert.match(npm.stdout.trim(), /^\d+\.\d+\.\d+$/);
