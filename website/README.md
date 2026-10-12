# nano.md website

Source for https://nano.thirdeyeds.com/, served by the existing `nano-md` Cloudflare Worker. Edit `index.html` and the three PNG assets here. The site has no framework or build step. `.assetsignore` limits publication to those four files.

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

Keep release claims aligned with the app. The landing page currently says the public download is coming soon because no public macOS release is available yet.
