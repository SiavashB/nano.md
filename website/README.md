# nano.md website

Source for https://nano.thirdeyeds.com/, served by the existing `nano-md` Cloudflare Worker. Edit `index.html` and the three PNG assets here. The site has no framework or build step. `.assetsignore` limits publication to the page, three images, `analytics.js`, `robots.txt`, and `sitemap.xml`.

## Deploy

Run from the NanoMD repository root on macOS with Node.js 22 or newer and an authenticated GitHub CLI (`gh`). The release synchronizer uses Apple's bundle and signature tools; it does not compile or launch the app.

```sh
# Install the pinned deployment tool once, or after package-lock.json changes.
npm --prefix website ci --cache ./Temp/npm-cache --logs-dir ./Temp/npm-logs

# Authorize this computer once. Open the printed URL and approve in Cloudflare.
npm --prefix website run login

# Synchronize the newest published release and validate without publishing.
npm --prefix website run check

# Publish the site and assets to the existing Worker and custom domain.
npm --prefix website run deploy
```

Wrangler stores its login in the user's standard Cloudflare configuration directory; never commit credentials. Deployment logs and dry-run output go under `Temp/WebsiteDeploy/`. The deployment preserves dashboard environment variables and keeps the existing `nano-md.xyzo1310.workers.dev` address enabled.

Wrangler is a development-only dependency, pinned in `package.json` and `package-lock.json`. It provides Cloudflare's supported upload and authentication flow; no dependency is shipped with the site or Mac app. Its license is MIT OR Apache-2.0. Installation audited 36 packages with no reported vulnerabilities when this setup was added.

Publishing a GitHub release triggers [Deploy website](../.github/workflows/website.yml), including published betas. Drafts do not deploy. The workflow checks out `main`, synchronizes the most recently published versioned release, and deploys through the same npm command. A shared concurrency group serializes website deployments, and every run reselects the newest published release to avoid reverting to an older event's version. Ordinary Git pushes do not publish the website. The workflow can also be run manually from Actions.

One-time setup: store a Cloudflare API token as the `CLOUDFLARE_API_TOKEN` [repository Actions secret](https://github.com/SiavashB/nano.md/settings/secrets/actions). Create it using Cloudflare's **Edit Cloudflare Workers** template at [API Tokens](https://dash.cloudflare.com/profile/api-tokens), restricted to the existing account `c235ff45bfd634ddf7ee1483bbd4cc9a` and the `thirdeyeds.com` zone where applicable. This is separate from the local Wrangler OAuth login. Never put the token in source or chat. Until this secret is configured and the workflow is on `main`, automatic deployment is not active; the job reports the missing secret explicitly. Local deployments continue to use Wrangler's existing login.

Cloudflare's [GitHub Actions guide](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/), [static asset configuration](https://developers.cloudflare.com/workers/static-assets/binding/), and [deployment command](https://developers.cloudflare.com/workers/wrangler/commands/workers/#deploy) document the configuration.

## Visit and download tracking

`analytics.js` sends events to the TEDS Supabase `nano_events` table for display in TEDS Admin. It uses only the public publishable key; table permissions must allow anonymous inserts and restrict reads to authorized administrators. The backend must be ready before deploying this script.

One `page_view` is sent on each page load. `download` events mean **download clicks**, not completed downloads or installs. Both release-asset links are covered, including primary clicks, keyboard activation, and middle clicks. The tracker accepts only versioned URLs matching `https://github.com/SiavashB/nano.md/releases/download/<tag>/<file>`; it does not count latest-release aliases, section navigation, source links, or release notes. Requests use `fetch` with `keepalive`, do not delay navigation, and silently ignore failures without retrying.

Each event has a fresh UUID and an anonymous visitor UUID stored under `nano_md_visitor_id` in localStorage. If storage is unavailable, the visitor UUID lasts only for the page load, so unique visitor counts may be higher. Setting `localStorage.te_analytics_excluded` to `"true"` on this site's origin excludes that browser; the tracker checks it before each event. No cookies or user accounts are used by the tracker.

Events contain the pathname (no query or fragment, maximum 300 characters), referrer hostname only (maximum 500), device category, and browser timezone (maximum 100). The timezone is an approximate region signal, not verified geographic location. A download event also contains the GitHub asset URL without query or fragment (maximum 1,000); page views use `null`. The database supplies the timestamp. Fetch requests omit credentials and the HTTP referrer.

Tracking runs only on `https://nano.thirdeyeds.com`; local files, localhost, Workers preview addresses, and readily detectable automated browsers are excluded. No analytics are added to the native Mac app.

## Search and sharing

The canonical URL is `https://nano.thirdeyeds.com/`. Keep it consistent across the page's canonical link, Open Graph URL, JSON-LD, and sitemap if the domain changes. `robots.txt` allows crawling and points to the sitemap. Add any future public pages to `sitemap.xml`; list canonical URLs only.

The page title and descriptions cover the Markdown reader/editor and its skills and agent-file use cases. Open Graph and Twitter cards use the existing app icon. JSON-LD identifies the application and publisher without claiming reviews. The release synchronizer keeps the release channel, structured-data version, download URL, app size, and OS requirement aligned with the visible download information.

The sitemap can also be submitted in Google Search Console when a verified property is available. Publishing these files does not submit a Search Console request.

## App size and updates

The deployed page displays metadata from the exact published Apple Silicon Release ZIP, not the installed development app. Both `check` and `deploy` first run `update-release.mjs`. It selects the most recently published versioned GitHub release (including prereleases, excluding drafts), downloads its arm64 ZIP and checksum under `Temp/WebsiteRelease/`, checks the size and SHA-256 against the release assets, verifies the bundle signature, and reads its `Info.plist` and executable architecture. Missing assets, invalid checksums, incorrect bundle identity/version/architecture, or missing Release configuration metadata stop deployment.

It updates both download links, release notes, channel labels, ZIP size, uncompressed app size, build/version, minimum macOS requirement, and JSON-LD. `release.json` records the selected release and measured values for source review; it is not a public asset. CI generates these files in its checkout without committing them back. To refresh the local source independently of deployment:

```sh
npm --prefix website run update-release
```

App size is the sum of regular-file bytes, in decimal MB (1 MB = 1,000,000 bytes), excluding symlinks. ZIP download size is displayed separately. Use the [shared measurement policy](../CONTRIBUTING.md#app-size-measurements) for before/after comparisons.

For local development measurements only, `update-app-size` retains its arm64/Release and checkout version/build checks. It defaults to `/Applications/NanoMD.app`, or accepts an explicit bundle:

```sh
npm --prefix website run update-app-size -- /path/to/NanoMD.app
```

Those development measurements are replaced by published-release data before any deployment. Never advertise a Debug build's size. A release's deployment target is recorded as its minimum OS requirement; that metadata does not establish runtime verification on an older macOS version.

The project is MIT-licensed and its source link is https://github.com/SiavashB/nano.md. Continue verifying the packaged app and reviewing release notes before publishing the draft. Publishing is the explicit approval that makes a release eligible for website deployment.
