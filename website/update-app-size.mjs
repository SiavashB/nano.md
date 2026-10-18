import { execFileSync } from "node:child_process";
import { lstatSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const websiteDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryDirectory = dirname(websiteDirectory);
const appPath = resolve(process.argv[2] || process.env.NANO_MD_APP_PATH || "/Applications/NanoMD.app");

function plistValue(key) {
  return execFileSync("/usr/libexec/PlistBuddy", ["-c", `Print :${key}`, join(appPath, "Contents/Info.plist")], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
}

function fileBytes(path) {
  const stat = lstatSync(path);
  if (stat.isFile()) return stat.size;
  if (stat.isDirectory()) return readdirSync(path).reduce((total, name) => total + fileBytes(join(path, name)), 0);
  return 0;
}

function replaceValue(html, id, value) {
  const pattern = new RegExp(`(<span id="${id}">)[^<]*(</span>)`, "g");
  if ([...html.matchAll(pattern)].length !== 1) throw new Error(`Expected one ${id} field in index.html.`);
  return html.replace(pattern, (_, open, close) => `${open}${value}${close}`);
}

try {
  if (!appPath.endsWith(".app") || !lstatSync(appPath).isDirectory()) {
    throw new Error("Provide a built NanoMD.app bundle.");
  }
  if (plistValue("CFBundleIdentifier") !== "com.thirdeyeds.NanoMD") {
    throw new Error("The app bundle is not nano.md.");
  }
  const executable = join(appPath, "Contents/MacOS", plistValue("CFBundleExecutable"));
  const architectures = execFileSync("/usr/bin/lipo", ["-archs", executable], { encoding: "utf8" }).trim();
  if (architectures !== "arm64") {
    throw new Error(`App size requires an Apple Silicon-only Release build; found architectures: ${architectures}. Rebuild with ARCHS=arm64.`);
  }
  if (plistValue("NanoMDBuildConfiguration") !== "Release") {
    throw new Error("App size requires the Release configuration. Rebuild with -configuration Release.");
  }
  const version = plistValue("CFBundleShortVersionString");
  const build = plistValue("CFBundleVersion");
  const minimumMacOS = plistValue("LSMinimumSystemVersion");
  if (![version, build, minimumMacOS].every(value => /^\d+(?:\.\d+)*$/.test(value))) {
    throw new Error("The app's version, build, or macOS requirement is invalid.");
  }
  const project = readFileSync(join(repositoryDirectory, "NanoMD.xcodeproj/project.pbxproj"), "utf8");
  const projectVersions = [...project.matchAll(/MARKETING_VERSION = ([\d.]+);/g)].map(match => match[1]);
  const projectBuilds = [...project.matchAll(/CURRENT_PROJECT_VERSION = ([\d.]+);/g)].map(match => match[1]);
  if (!projectVersions.length || !projectBuilds.length || projectVersions.some(value => value !== version) || projectBuilds.some(value => value !== build)) {
    throw new Error("App version/build does not match the current checkout. Install the updated Release app, or set NANO_MD_APP_PATH to that build.");
  }
  const bytes = fileBytes(appPath);
  if (bytes <= 0) throw new Error("The app bundle is empty.");
  const size = `${(bytes / 1_000_000).toFixed(1)} MB`;
  const pagePath = join(websiteDirectory, "index.html");
  const original = readFileSync(pagePath, "utf8");
  const sizePattern = /<dd id="app-size" data-bytes="\d+">[^<]*<\/dd>/g;
  if ([...original.matchAll(sizePattern)].length !== 1) throw new Error("Expected one app-size field in index.html.");
  let updated = original.replace(sizePattern, `<dd id="app-size" data-bytes="${bytes}">${size}</dd>`);
  updated = replaceValue(updated, "app-version", version);
  updated = replaceValue(updated, "app-build", build);
  updated = replaceValue(updated, "app-minimum-macos", minimumMacOS);
  if (updated !== original) writeFileSync(pagePath, updated);
  console.log(`nano.md ${version} (build ${build}, arm64 Release): ${size}, ${bytes.toLocaleString("en-US")} bytes uncompressed; macOS ${minimumMacOS}+.`);
} catch (error) {
  console.error(`Cannot update the website's app size: ${error.message}`);
  console.error("Use a freshly built arm64 Release app: npm --prefix website run update-app-size -- /path/to/NanoMD.app");
  process.exitCode = 1;
}
