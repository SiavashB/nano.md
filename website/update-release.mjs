import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdirSync, mkdtempSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { applyAppMetadata, readAppMetadata } from "./app-metadata.mjs";

const websiteDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryDirectory = dirname(websiteDirectory);
const repository = "SiavashB/nano.md";
const tagPattern = /^v(\d+\.\d+(?:\.\d+)?)(?:-(alpha|beta|rc)\.(\d+))?$/;
function gh(args) {
  return execFileSync("gh", args, { encoding: "utf8", maxBuffer: 16 * 1024 * 1024 });
}

try {
  // GitHub's /releases/latest endpoint excludes published betas.
  const releases = JSON.parse(gh(["api", `repos/${repository}/releases?per_page=100`, "--paginate", "--slurp"]))
    .flat().filter(release => !release.draft && release.published_at && tagPattern.test(release.tag_name))
    .sort((a, b) => Date.parse(b.published_at) - Date.parse(a.published_at));
  // Once a stable release exists, keep public downloads off the prerelease channel.
  const release = releases.find(item => !item.prerelease && !item.tag_name.includes("-")) || releases[0];
  if (!release) throw new Error("No published versioned release is available.");
  const [, version, channel, sequence] = release.tag_name.match(tagPattern);
  const label = `${version}${channel ? ` ${channel} ${sequence}` : ""}`;
  const archive = `nano.md-${release.tag_name}-arm64.zip`;
  const asset = release.assets.find(item => item.name === archive);
  const checksumAsset = release.assets.find(item => item.name === "SHA256SUMS.txt");
  const downloadUrl = `https://github.com/${repository}/releases/download/${release.tag_name}/${archive}`;
  const releaseUrl = `https://github.com/${repository}/releases/tag/${release.tag_name}`;
  if (!asset || !checksumAsset || asset.browser_download_url !== downloadUrl || release.html_url !== releaseUrl) {
    throw new Error(`Published release ${release.tag_name} is missing the expected arm64 ZIP or checksum.`);
  }
  const stagingRoot = join(repositoryDirectory, "Temp/WebsiteRelease");
  mkdirSync(stagingRoot, { recursive: true });
  const staging = mkdtempSync(join(stagingRoot, `${release.tag_name}-`));
  gh(["release", "download", release.tag_name, "--repo", repository, "--pattern", archive, "--pattern", "SHA256SUMS.txt", "--dir", staging]);
  const archivePath = join(staging, archive);
  if (statSync(archivePath).size !== asset.size) throw new Error("Downloaded ZIP size does not match GitHub.");
  const checksum = readFileSync(join(staging, "SHA256SUMS.txt"), "utf8").split(/\r?\n/)
    .map(line => line.match(/^([a-f0-9]{64})\s+\*?(.+)$/i)).find(match => match && match[2] === archive)?.[1].toLowerCase();
  const digest = createHash("sha256").update(readFileSync(archivePath)).digest("hex");
  if (checksum !== digest || (asset.digest && asset.digest !== `sha256:${digest}`)) throw new Error("Release ZIP checksum mismatch.");
  execFileSync("/usr/bin/ditto", ["-x", "-k", archivePath, staging]);
  const appPath = join(staging, "NanoMD.app");
  execFileSync("/usr/bin/codesign", ["--verify", "--deep", "--strict", appPath], { stdio: "pipe" });
  const metadata = readAppMetadata(appPath);
  if (metadata.version !== version) throw new Error("Packaged app version does not match the release tag.");
  const pagePath = join(websiteDirectory, "index.html");
  let html = applyAppMetadata(readFileSync(pagePath, "utf8"), metadata);
  function replaceOne(pattern, value, field) {
    if ([...html.matchAll(pattern)].length !== 1) throw new Error(`Expected one ${field} field in index.html.`);
    html = html.replace(pattern, value);
  }
  const downloadPattern = /(<a\b[^>]*\bdata-release-download\b[^>]*\bhref=")[^"]+("[^>]*>)[^<]*(<\/a>)/g;
  const links = [...html.matchAll(downloadPattern)];
  if (links.length !== 2) throw new Error("Expected two marked release download links.");
  html = html.replace(downloadPattern, (_, open, middle, close, offset) =>
    `${open}${downloadUrl}${middle}${offset === links[0].index ? `Download${channel ? ` ${channel}` : ""} for Mac` : `Download ${label}`}${close}`);
  for (const [id, value] of [
    ["download-size", `${(asset.size / 1_000_000).toFixed(2)} MB`],
    ["release-label", label],
    ["release-title", channel ? `Free. Try the ${channel}.` : "Free. Download for Mac."],
    ["release-requirement", `Requires macOS ${metadata.minimumMacOS} or newer on Apple Silicon.`],
  ]) {
    replaceOne(new RegExp(`(<(?:span|strong|h2)\\b[^>]*\\bid="${id}"[^>]*>)[^<]*(</(?:span|strong|h2)>)`, "g"),
      (_, open, close) => `${open}${value}${close}`, id);
  }
  replaceOne(/(<a id="release-notes" href=")[^"]+("[^>]*>)/g, (_, open, close) => `${open}${releaseUrl}${close}`, "release-notes");
  html = html.replace(/\b(?:(?:Beta|Alpha|RC|Rc|Public) )?[Dd]ownload available for Apple Silicon\./g,
    `${channel ? `${channel[0].toUpperCase()}${channel.slice(1)} download` : "Download"} available for Apple Silicon.`);
  replaceOne(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g, (_, source) => {
    const data = JSON.parse(source);
    const app = data["@graph"].find(item => item["@type"] === "SoftwareApplication");
    if (!app) throw new Error("Missing SoftwareApplication structured data.");
    Object.assign(app, { softwareVersion: release.tag_name.slice(1), operatingSystem: `macOS ${metadata.minimumMacOS} or later`,
      fileSize: `${(metadata.bytes / 1_000_000).toFixed(1)} MB`, downloadUrl, releaseNotes: releaseUrl });
    return `<script type="application/ld+json">\n${JSON.stringify(data, null, 2).split("\n").map(line => `      ${line}`).join("\n")}\n    </script>`;
  }, "structured data");
  writeFileSync(pagePath, html);
  writeFileSync(join(websiteDirectory, "release.json"), `${JSON.stringify({ tag: release.tag_name, publishedAt: release.published_at,
    ...metadata, zipBytes: asset.size, downloadUrl, releaseUrl, sha256: digest }, null, 2)}\n`);
  console.log(`Website updated to ${release.tag_name}, build ${metadata.build}: ${(metadata.bytes / 1_000_000).toFixed(1)} MB app, ${(asset.size / 1_000_000).toFixed(2)} MB ZIP; macOS ${metadata.minimumMacOS}+.`);
} catch (error) {
  console.error(`Cannot synchronize the published release: ${error.message}`);
  process.exitCode = 1;
}
