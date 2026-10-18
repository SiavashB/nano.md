import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { applyAppMetadata, readAppMetadata } from "./app-metadata.mjs";

const websiteDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryDirectory = dirname(websiteDirectory);
const appPath = resolve(process.argv[2] || process.env.NANO_MD_APP_PATH || "/Applications/NanoMD.app");

try {
  const metadata = readAppMetadata(appPath);
  const project = readFileSync(join(repositoryDirectory, "NanoMD.xcodeproj/project.pbxproj"), "utf8");
  const versions = [...project.matchAll(/MARKETING_VERSION = ([\d.]+);/g)].map(match => match[1]);
  const builds = [...project.matchAll(/CURRENT_PROJECT_VERSION = ([\d.]+);/g)].map(match => match[1]);
  if (!versions.length || !builds.length || versions.some(value => value !== metadata.version) || builds.some(value => value !== metadata.build)) {
    throw new Error("App version/build does not match the current checkout. Use its updated arm64 Release build.");
  }
  const pagePath = join(websiteDirectory, "index.html");
  const original = readFileSync(pagePath, "utf8");
  const updated = applyAppMetadata(original, metadata);
  if (updated !== original) writeFileSync(pagePath, updated);
  console.log(`Local build ${metadata.version} (${metadata.build}): ${(metadata.bytes / 1_000_000).toFixed(1)} MB; macOS ${metadata.minimumMacOS}+.`);
} catch (error) {
  console.error(`Cannot update the website's app size: ${error.message}`);
  console.error("Use an arm64 Release app: npm --prefix website run update-app-size -- /path/to/NanoMD.app");
  process.exitCode = 1;
}
