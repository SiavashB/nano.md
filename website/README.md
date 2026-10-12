# nano.md website

Source for https://nano.thirdeyeds.com/, served by the existing `nano-md` Cloudflare Worker. Edit `index.html` and the three PNG assets here. The site has no framework or build step. `.assetsignore` limits publication to the page, three images, `robots.txt`, and `sitemap.xml`.

## Deploy

Run from the NanoMD repository root with Node.js 22 or newer:

```sh
# Install the pinned deployment tool once, or after package-lock.json changes.
npm --prefix website ci --cache ./Temp/npm-cache --logs-dir ./Temp/npm-logs

# Authorize this computer once. Open the printed URL and approve in Cloudflare.
npm --prefix website run login

# Validate the configuration without publishing.
npm --prefix website run check

# Publish the site and assets to the existing Worker and custom domain.
npm --prefix website run deploy
```

Wrangler stores its login in the user's standard Cloudflare configuration directory; never commit credentials. Deployment logs and dry-run output go under `Temp/WebsiteDeploy/`. The deployment preserves dashboard environment variables and keeps the existing `nano-md.xyzo1310.workers.dev` address enabled.

Wrangler is a development-only dependency, pinned in `package.json` and `package-lock.json`. It provides Cloudflare's supported upload and authentication flow; no dependency is shipped with the site or Mac app. Its license is MIT OR Apache-2.0. Installation audited 36 packages with no reported vulnerabilities when this setup was added.

This is an explicit, one-command deployment workflow. Git pushes do not automatically publish. Cloudflare's [static asset configuration](https://developers.cloudflare.com/workers/static-assets/binding/) and [deployment command](https://developers.cloudflare.com/workers/wrangler/commands/workers/#deploy) document the configuration.

## Search and sharing

The canonical URL is `https://nano.thirdeyeds.com/`. Keep it consistent across the page's canonical link, Open Graph URL, JSON-LD, and sitemap if the domain changes. `robots.txt` allows crawling and points to the sitemap. Add any future public pages to `sitemap.xml`; list canonical URLs only.

The page title and descriptions cover the Markdown reader/editor and its skills and agent-file use cases. Open Graph and Twitter cards use the existing app icon. JSON-LD identifies the application and its publisher without claiming a public download, license, or reviews. Version and size appear only in the automatically refreshed visible fields so metadata cannot retain an old build's values.

The sitemap can also be submitted in Google Search Console when a verified property is available. Publishing these files does not submit a Search Console request.

## App size and updates

The page displays the sum of regular-file sizes in the current Release `.app` bundle, in decimal MB (1 MB = 1,000,000 bytes). This is the uncompressed app size, not a ZIP/DMG download size or memory usage. Symbolic links are not counted twice. The app's version, build number, and minimum macOS version come from its `Info.plist`.

Both `check` and `deploy` refresh these values automatically from `/Applications/NanoMD.app`. They stop if the app's identifier or version/build does not match the current checkout, or if the app cannot be read. After each app update, install the new Release build and refresh the page:

```sh
npm --prefix website run update-app-size
```

To measure a Release build before installing it, pass its path:

```sh
npm --prefix website run update-app-size -- /path/to/NanoMD.app
NANO_MD_APP_PATH=/path/to/NanoMD.app npm --prefix website run deploy
```

Review and commit the updated `index.html` with the app update. Never use a Debug build to advertise app size.

Keep release claims aligned with the app. No public download is available yet. The project is MIT-licensed and the source link is https://github.com/SiavashB/nano.md. Confirm the repository is publicly accessible before deploying that link. Keep the download marked as coming soon until a verified app release is published.
