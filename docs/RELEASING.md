# Releasing nano.md

Test locally with AI assistance, merge the changes, push a version tag, and review the resulting GitHub draft before publishing. There are no automated tests or scheduled releases.

## Workflows

- **Build** runs unsigned Debug and Release builds on pull requests and pushes to `main`. It reports compilation failures and keeps build logs for seven days.
- **Draft release** runs on `v*` tags. It builds the tagged commit for Apple Silicon, signs with Developer ID, notarizes and staples the app, and creates a draft release with a ZIP and SHA-256 checksum. Tags must point to a commit included in `main`. Normal pushes to `main` never create a release.
- **Deploy website** runs when a release is published, including prereleases, or when manually dispatched. It synchronizes download links, sizes, build metadata, macOS requirements, and structured data from the newest published release's verified ZIP, then deploys the website. It requires the separate `CLOUDFLARE_API_TOKEN` Actions secret described in [website/README.md](../website/README.md#deploy); local Wrangler OAuth does not configure CI credentials.

Both workflows use the standard `macos-26` runner and Xcode 26.6. Build products, package caches, logs, and release staging stay under `Temp/`. The release workflow retains the signed submission ZIP for seven days as `notarization-input-<attempt>` before waiting for Apple, along with its checksum and submission ID in the release logs. This allows packaging the exact accepted build after a timeout. CI compilation does not verify editing behavior, file preservation, or the downloaded app's first launch.

Local and distribution builds target Apple Silicon (`arm64`) only. Standardize app-size measurements on Release and follow the [measurement policy](../CONTRIBUTING.md#app-size-measurements); published size metadata comes from the exact signed release bundle. The website updater rejects universal/Intel executables, Debug builds, and bundles without build-configuration metadata.

Beta 4 and new builds target macOS 15.0 and later using Xcode 26.6. Before advertising verified macOS 15 compatibility, check launch, Read/Edit, undo, saving/reopening, and theme/toolbar behavior on macOS 15. Compilation on the current OS does not establish those runtime results. Older beta 3 assets retain their macOS 26.5 requirement; keep historical compatibility and verification records tied to their actual release.

Distribution builds use [Config/Distribution.entitlements](../Config/Distribution.entitlements) with base entitlement injection disabled. The release workflow checks the signed app for sandboxing, user-selected file read/write access, and the absence of debugger access before submission. Keep these distribution permissions aligned with the app's capabilities. Normal Xcode builds retain their generated entitlements for local debugging.

Standard runner time is free for public repositories. Private repositories use the account's included Actions allowance and may incur charges beyond it; check the account's Actions budget before enabling paid overages.

## One-time signing setup

1. Sign in to [Apple Developer](https://developer.apple.com/account/) and confirm an active Developer Program membership and its Team ID. Having an Apple account alone is insufficient; complete [enrollment and membership payment](https://developer.apple.com/programs/enroll/) if activation is pending. Use the team that will own the release certificate; do not assume the local development team is the distribution team.
2. In Xcode's Settings → Accounts, select that account and team, then **Manage Certificates**. Create a **Developer ID Application** certificate with the + button. Certificate creation requires the Account Holder role. If that option is unavailable, follow [Apple's certificate setup](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/) or ask the team's Account Holder to provide an export.
3. Control-click the certificate and choose **Export Certificate**. Save it as `Temp/FirstRelease/DeveloperID.p12` with a nonempty password. The export must include the private key. See [Apple's export instructions](https://help.apple.com/xcode/mac/current/en.lproj/dev154b28f09.html).
4. At [account.apple.com](https://account.apple.com/), open **Sign-In and Security → App-Specific Passwords**, and create a password named `nano.md releases`. This requires two-factor authentication. See [Apple's password instructions](https://support.apple.com/en-us/102654).
5. From the repository root, run these commands exactly as written. The uppercase secret names are literal names, not placeholders for their values. Upload the certificate without printing its contents:

   ```sh
   base64 -i Temp/FirstRelease/DeveloperID.p12 | gh secret set CERTIFICATE_P12_BASE64 --repo SiavashB/nano.md
   gh secret set CERTIFICATE_PASSWORD --repo SiavashB/nano.md
   gh secret set APPLE_TEAM_ID --repo SiavashB/nano.md
   gh secret set APPLE_ID --repo SiavashB/nano.md
   gh secret set APPLE_APP_PASSWORD --repo SiavashB/nano.md
   gh secret list --repo SiavashB/nano.md
   ```

   Enter the four remaining values at the CLI's hidden prompts, using the meanings below. Alternatively, add them at [repository Actions secrets](https://github.com/SiavashB/nano.md/settings/secrets/actions). Confirm all five names are listed, then delete the temporary `.p12` export after storing it securely if a backup is needed.

| Secret | Value |
| --- | --- |
| `CERTIFICATE_P12_BASE64` | Base64-encoded `.p12` export of a Developer ID Application certificate and its private key |
| `CERTIFICATE_PASSWORD` | Password protecting that `.p12` export; use a nonempty password |
| `APPLE_TEAM_ID` | Developer Program team that owns the certificate |
| `APPLE_ID` | Apple account used for notarization |
| `APPLE_APP_PASSWORD` | App-specific password for that Apple account |

Use `gh secret set NAME` to enter a value securely, or GitHub's repository secrets settings. Keep any temporary certificate export under `Temp/` and remove it when finished. Never paste credentials into chat or commit them. The release runner imports the certificate into a temporary keychain and removes it after the job. No signing secrets are used by the Build workflow.

Missing credentials stop the release workflow with the missing secret's name. A local ad-hoc signature cannot replace Developer ID signing for this workflow. See [GitHub's certificate setup](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications) and [Apple's Developer ID guidance](https://developer.apple.com/developer-id/).

## Upcoming beta 5

Version 0.1.0 beta 5, build 20, is being prepared with browser-based feedback choices, the feedback email in About, the Control-R Read/Edit footer shortcut, compact document bars, clearer toolbar icons, and the native nano.md display name. The published download remains beta 4 until the draft's exact signed/notarized package has been verified and published. Local unsigned arm64 Debug and Release builds passed with Xcode 26.6; this does not establish packaged-app behavior or macOS 15 runtime compatibility.

## Current release

[0.1.0 beta 4](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.4), build 18, was published on October 18, 2026, from `708de89`. It adds Nano Dark and Linen Light themes with saved Dark / Light / System controls, themed metadata panels, outlined code blocks, clearer Read/Edit controls, and quoted/dotted front-matter keys. The Apple Silicon release targets macOS 15.0 or later. Runtime validation on macOS 15 remains pending.

The [release workflow](https://github.com/SiavashB/nano.md/actions/runs/39105735771) signed and notarized the app; Apple accepted submission `91478fa3-9756-4cbc-962f-3399ec24f051`. Recorded verification of the exact downloaded package passed checksum, strict Developer ID signature and timestamp, hardened runtime, sandbox/file-access entitlements without debugger or network access, stapling, Gatekeeper, bundle metadata, and bundled-license comparisons. The ZIP is 2,194,367 bytes (2.19 MB); regular nonsymlink files in the app total 3,872,473 bytes (3.9 MB). Package verification is recorded in ignored `Temp/ReleaseBeta4/VERIFICATION.md`; it does not establish runtime compatibility on macOS 15. Broader runtime cases remain tracked in the [roadmap](ROADMAP.md).

## Previous beta 3

[0.1.0 beta 3](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.3), build 11, was published on October 17, 2026, from `4e6710e`. It adds compact, selectable panels for SKILL.md front matter while preserving the original source in Edit. The [release workflow](https://github.com/SiavashB/nano.md/actions/runs/38976804481) signed and notarized the arm64 app; Apple accepted submission `1b361e0c-d6ad-43d1-b19f-0d5ecc92a224`.

The downloaded package passed checksum, strict Developer ID signature and secure timestamp, hardened runtime, sandbox/file-access permissions without debugger access, stapling, Gatekeeper, bundle metadata, and bundled-license checks. The exact packaged app also passed opening a real SKILL.md, metadata/body rendering, editing its name, undo/redo, saving, closing, and reopening. A file comparison showed only the intended name changed. The ZIP is 2,143,224 bytes; regular nonsymlink files in the app total 3,671,818 bytes. Evidence is retained under ignored `Temp/SkillFrontMatter/`. Broader editor and compatibility limitations remain in the roadmap.

## First beta

The first published beta is version **0.1.0**, build **8**, tagged **`v0.1.0-beta.2`** at `3358691`. It targets Apple Silicon and macOS 26.5 or later, using Xcode 26.6. Its downloaded package passed signature, entitlement, notarization, stapling, checksum, and Gatekeeper checks. The maintainer confirmed that launch, opening, editing, undo, saving, and reopening passed on the notarized package and approved [publication](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.2). Broader hardware and older macOS support have not been verified.

Focused local UI checks passed on October 14, 2026, using the Apple Development-signed arm64 Release at `76dfc6f` on macOS 26.6.2. Reader/tables, Read/Edit, editing/undo, saving, close/quit, and file preservation passed for the exercised fixtures. The [roadmap records the scope, observed focus/reader-state limitations, and remaining runtime cases](ROADMAP.md#focused-local-ui-validation-010-build-7). This result does not verify Developer ID signing, notarization, or the downloaded package's first launch.

The project uses the MIT license, bundled alongside the dependency notices. Before tagging, complete these local checks with disposable files under `Temp/`. If using an AI assistant for UI checks, explicitly authorize visual testing in that chat.

- Open `.md` and `.markdown` files in Read mode; check headings, lists, code, links, and tables, including selecting and copying across table cells.
- Switch Read/Edit repeatedly; check selection, scroll position, undo/redo, and two independent document windows.
- Create, edit, save, and reopen a document. Check close/quit confirmation, including Save, Discard, and Cancel.
- Confirm a file opened and closed without editing retains identical bytes. Include UTF-8 BOM, Unicode, and CRLF samples; invalid UTF-8 should report an error.
- Record outcomes and any limitations. Build success alone does not complete this checklist.

After the draft is created, download both assets into `Temp/FirstRelease/Download/`, verify the checksum there, and extract the ZIP. Confirm the packaged app's signature and notarization before its first launch:

```sh
cd Temp/FirstRelease/Download
shasum -a 256 -c SHA256SUMS.txt
ditto -x -k nano.md-v0.1.0-beta.2-arm64.zip .
codesign --verify --deep --strict --verbose=2 NanoMD.app
xcrun stapler validate NanoMD.app
spctl --assess --type execute --verbose=2 NanoMD.app
```

Launch the downloaded app through Finder and repeat opening, editing, saving/reopening, and undo. Check any first-launch failure before publishing; do not bypass Gatekeeper to count the release as verified. Review the draft's notes, mark known unsupported syntax, and publish only after the packaged app passes the intended checks. Make the repository public after its license is in place. Subsequent release publications trigger the website workflow once its Cloudflare credential is configured.

## Each release

This checklist is required for every release, including prereleases and hotfixes. Documentation and website updates are part of completing the release.

1. Make changes on a branch and test locally with AI assistance. Focus on the changed behavior and opening, editing, saving/reopening, and undo. Record what was actually checked in the PR; do not treat a green build as functional verification.
2. Set `MARKETING_VERSION` consistently in Debug and Release and increment `CURRENT_PROJECT_VERSION`. For example, version `0.1.0` can use the tag `v0.1.0-beta.2`, then `v0.1.0` for the stable release. Tags also accept two-part app versions, such as `v1.0`. Local size measurements remain available, but website deployment always synchronizes metadata from the exact published release bundle.
3. Review changes since the previous published release and prepare corresponding updates to `README.md`, website copy in `website/index.html` (including search/sharing descriptions), and GitHub release notes. Cover shipped features, changed behavior, known limitations, version/build and release channel, supported hardware and minimum macOS, installation instructions, and download/release links wherever stated. Distinguish development-only features and build targets from the published app, and runtime verification from compilation. Keep upcoming release claims clearly labeled until publication; do not advertise draft assets as available downloads. Refresh affected roadmap and architecture statements as needed.
4. Merge after the Build workflow passes, including the prepared documentation and website copy. The website deployment reads `main`. From a clean, updated `main`, create and push the intended version tag:

   ```sh
   git switch main
   git pull --ff-only
   git tag -a v0.1.0-beta.2 -m "nano.md 0.1.0 beta 2"
   git push origin v0.1.0-beta.2
   ```

   Replace the example version with the app version being released. The tag's numeric version must exactly match `MARKETING_VERSION`; `alpha`, `beta`, and `rc` suffixes use a numeric iteration. Pushing the tag starts release preparation, not publication.

5. Wait for **Draft release** to succeed. Inspect the generated draft, download the ZIP, verify it with `shasum -a 256 -c SHA256SUMS.txt`, and perform the intended local checks on that packaged app. Edit the generated notes to explain user-visible changes and known limitations. Check all release facts against the tagged source, exact packaged app, and recorded validation; do not infer them from an installed development build. Beta/alpha/RC tags are automatically marked as prereleases.
6. Publish the draft when ready. This triggers **Deploy website** once its Cloudflare secret is configured and the workflow is on `main`. Check that job's result; a website deployment failure leaves the published app release intact and can be retried from Actions. Draft preparation never changes the live website.
7. Run `npm --prefix website run update-release` after publication to synchronize local website metadata from the published ZIP. Update the README's status and download sections and this document's **Current release** section with the published version, build, date, links, compatibility, and actual verification results. Reconcile the website's feature copy and GitHub release notes with those facts. The synchronizer updates metadata, not feature descriptions or the README; CI does not commit its generated changes back. Commit and push the final documentation and synchronized website source. If website content changed after deployment, redeploy using [the website instructions](../website/README.md#deploy).
8. Before reporting the release complete, confirm the website deployment succeeded and compare the live page's HTML, GitHub README, release notes, and download links with the published release. Check release labels, compatibility, features/limitations, and ZIP download size versus uncompressed app size wherever stated. Use source/API/HTTP checks; visual testing still requires an explicit request. Report the release and website URLs, the documentation updated, and any unresolved item. A failed or blocked documentation update or deployment leaves release follow-up incomplete even if the app is already published.

The workflow never publishes automatically. If a run fails before creating the draft, correct the configuration and rerun it when appropriate. If a partial draft already exists, inspect it and remove only that unpublished draft before retrying; the workflow does not overwrite existing releases. Source changes need a new commit and tag. Never move a published tag or replace a published binary; ship a new version.

### Notarization timeouts

A wait timeout does not cancel Apple's processing or mean the submission was rejected. Check the submission ID from `notarization-submission.json` with `xcrun notarytool info`. Use the same Apple account and team, entering the app-specific password only at its secure prompt.

If Apple later accepts the submission, download that run attempt's `notarization-input-<attempt>` artifact and release logs into `Temp/`. Verify `NotarizationUpload.zip` against `notarization-upload-sha256.txt` before extracting it with `ditto`. Confirm the run's commit and tag, then staple and validate that exact app, run the signature and Gatekeeper checks above, and package it with a new checksum using the workflow's packaging commands. Create only a draft release. Do not rebuild and assume the earlier acceptance applies to the new binary.

These recovery artifacts apply to future runs using the updated workflow. Beta.2's first attempt retained only logs, so it required a complete rerun and a new notarization submission.

## Current setup status

All five signing/notarization secrets are configured and worked in CI. The first beta was rejected for the injected `com.apple.security.get-task-allow` entitlement; build 8 corrected distribution signing without changing app source or local debugging behavior.

On October 14, 2026, [beta.2 attempt 2](https://github.com/SiavashB/nano.md/actions/runs/38641897124/attempts/2) completed successfully. Apple accepted submission `724df31c-f072-43a8-9e88-cb3ce00429d3`. Independent verification of the downloaded draft passed checksum, Developer ID signature and secure timestamp, hardened runtime, sandbox/file-access permissions, absence of debugger access, stapling, Gatekeeper, bundle metadata, and bundled-license comparisons. The ZIP is 2,138,600 bytes; regular nonsymlink files in the app total 3,652,073 bytes. Local evidence is retained under `Temp/FirstRelease/Beta2RetryVerification/`. The maintainer subsequently confirmed that the notarized package passed launch, opening, editing, undo, saving, and reopening, and approved publication. Beta.2 is now published as a prerelease; broader runtime cases remain tracked in the roadmap. The timeout-recovery workflow change has been reviewed separately; it was not part of this release run.
