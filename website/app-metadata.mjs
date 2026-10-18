import { execFileSync } from "node:child_process";
import { lstatSync, readdirSync } from "node:fs";
import { join } from "node:path";

export function readAppMetadata(appPath) {
  function plistValue(key) {
    return execFileSync("/usr/libexec/PlistBuddy", ["-c", `Print :${key}`, join(appPath, "Contents/Info.plist")], {
      encoding: "utf8", stdio: ["ignore", "pipe", "pipe"],
    }).trim();
  }
  function fileBytes(path) {
    const stat = lstatSync(path);
    if (stat.isFile()) return stat.size;
    if (stat.isDirectory()) return readdirSync(path).reduce((total, name) => total + fileBytes(join(path, name)), 0);
    return 0;
  }
  if (!appPath.endsWith(".app") || !lstatSync(appPath).isDirectory()) throw new Error("Provide a built NanoMD.app bundle.");
  if (plistValue("CFBundleIdentifier") !== "com.thirdeyeds.NanoMD") throw new Error("The app bundle is not nano.md.");
  const executable = join(appPath, "Contents/MacOS", plistValue("CFBundleExecutable"));
  const architectures = execFileSync("/usr/bin/lipo", ["-archs", executable], { encoding: "utf8" }).trim();
  if (architectures !== "arm64") throw new Error(`App size requires arm64-only Release; found architectures: ${architectures}.`);
  if (plistValue("NanoMDBuildConfiguration") !== "Release") throw new Error("App size requires the Release configuration.");
  const version = plistValue("CFBundleShortVersionString");
  const build = plistValue("CFBundleVersion");
  const minimumMacOS = plistValue("LSMinimumSystemVersion");
  if (![version, build, minimumMacOS].every(value => /^\d+(?:\.\d+)*$/.test(value))) throw new Error("Invalid app version, build, or macOS requirement.");
  const bytes = fileBytes(appPath);
  if (bytes <= 0) throw new Error("The app bundle is empty.");
  return { version, build, minimumMacOS, bytes };
}

export function applyAppMetadata(html, { version, build, minimumMacOS, bytes }) {
  function replace(pattern, value, name) {
    if ([...html.matchAll(pattern)].length !== 1) throw new Error(`Expected one ${name} field in index.html.`);
    html = html.replace(pattern, value);
  }
  replace(/<dd id="app-size" data-bytes="\d+">[^<]*<\/dd>/g,
    `<dd id="app-size" data-bytes="${bytes}">${(bytes / 1_000_000).toFixed(1)} MB</dd>`, "app-size");
  for (const [id, value] of [["app-version", version], ["app-build", build], ["app-minimum-macos", minimumMacOS]]) {
    replace(new RegExp(`(<span id="${id}">)[^<]*(</span>)`, "g"), (_, open, close) => `${open}${value}${close}`, id);
  }
  return html;
}
