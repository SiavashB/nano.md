import { copyFileSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const websiteDirectory = dirname(fileURLToPath(import.meta.url));
const assetsDirectory = join(websiteDirectory, "../Temp/WebsiteAssets");
const publicFiles = [
  "index.html", "feedback.html", "privacy.html", "analytics.js",
  "nano-md-logo.png", "nano-md-icon.png", "favicon.png", "mac-app-store-badge.svg",
  "robots.txt", "sitemap.xml",
];

function stagePublicFiles() {
  mkdirSync(assetsDirectory, { recursive: true });
  // Exclude stale files in the staging directory, even if they were public in an older build.
  writeFileSync(join(assetsDirectory, ".assetsignore"), [
    "/**", ...publicFiles.map(name => `!/${name}`), "!/download", "",
  ].join("\n"));
  for (const name of publicFiles) {
    copyFileSync(join(websiteDirectory, name), join(assetsDirectory, name));
  }
}

export function stageWebsiteAssets(verifiedArchive) {
  stagePublicFiles();
  writeFileSync(join(assetsDirectory, "download"), verifiedArchive);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  stagePublicFiles();
}
