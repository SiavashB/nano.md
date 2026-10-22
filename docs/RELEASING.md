# Releasing nano.md

This guide covers release preparation, package verification, and publication. User-visible changes and historical verification results belong in [GitHub Releases](https://github.com/SiavashB/nano.md/releases); open work is tracked in the [roadmap](ROADMAP.md).

## Workflows

| Workflow | Trigger | Result |
| --- | --- | --- |
| [Build](../.github/workflows/ci.yml) | Pull requests and pushes to `main` | Unsigned Debug and Release compilation; logs retained for seven days |
| [Draft release](../.github/workflows/release.yml) | A `v*` tag on a commit included in `main` | Developer ID-signed, notarized, stapled arm64 app; draft release with ZIP and SHA-256 checksum |
| [Deploy website](../.github/workflows/website.yml) | Release publication or manual dispatch | Website metadata synchronized from the newest published release, then deployed |

App builds use the `macos-26` runner, Xcode 26.6, and a macOS 15.0 deployment target. The Build workflow compiles Debug and Release and runs the [regression suite](../CONTRIBUTING.md#automated-tests). The tag-triggered release workflow performs packaging checks; confirm regression tests passed for the release commit before tagging. Minimum-OS runtime compatibility must be verified separately.

Build output, caches, logs, and staging stay under `Temp/`. Distribution uses [explicit entitlements](../Config/Distribution.entitlements) with base entitlement injection disabled. The workflow checks sandboxing, user-selected file read/write access, and absence of debugger access before notarization. Local Debug signing remains unchanged.

The release workflow never publishes automatically. Website deployment requires its own `CLOUDFLARE_API_TOKEN` secret; local Wrangler login does not supply CI credentials. See [website setup](../website/README.md#deploy).

## Current release

[0.1.0 beta 5](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.5), build 20, was published on October 21, 2026, from `50ca88f`. It targets Apple Silicon and macOS 15.0; runtime compatibility on macOS 15 remains unverified.

The [release workflow](https://github.com/SiavashB/nano.md/actions/runs/39548265781) completed signing and notarization. The downloaded package passed distribution checks and focused opening, editing, undo, saving, source-preservation, and feedback-handoff checks. See the release notes for features, exact package sizes, and verification scope, and the [roadmap](ROADMAP.md#verification-baseline) for remaining limitations.

The website was deployed locally. Automatic deployment remains pending configuration of the separate Cloudflare repository secret.

## One-time signing setup

1. Sign in to [Apple Developer](https://developer.apple.com/account/) and confirm an active Developer Program membership and its Team ID. Having an Apple account alone is insufficient; complete [enrollment and membership payment](https://developer.apple.com/programs/enroll/) if activation is pending. Use the team that will own the release certificate; do not assume the local development team is the distribution team.
2. In Xcode's Settings → Accounts, select that account and team, then **Manage Certificates**. Create a **Developer ID Application** certificate with the + button. Certificate creation requires the Account Holder role. If that option is unavailable, follow [Apple's certificate setup](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/) or ask the team's Account Holder to provide an export.
3. Create the repository-root `Temp/ReleaseSigning/` directory. Control-click the certificate and choose **Export Certificate**. Save it as `Temp/ReleaseSigning/DeveloperID.p12` with a nonempty password. The export must include the private key. See [Apple's export instructions](https://help.apple.com/xcode/mac/current/en.lproj/dev154b28f09.html).
4. At [account.apple.com](https://account.apple.com/), open **Sign-In and Security → App-Specific Passwords**, and create a password named `nano.md releases`. This requires two-factor authentication. See [Apple's password instructions](https://support.apple.com/en-us/102654).
5. From the repository root, run these commands exactly as written. The uppercase secret names are literal names, not placeholders for their values. Upload the certificate without printing its contents:

   ```sh
   base64 -i Temp/ReleaseSigning/DeveloperID.p12 | gh secret set CERTIFICATE_P12_BASE64 --repo SiavashB/nano.md
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

## Local validation

Before tagging, use disposable files under `Temp/` to check the changed behavior and these core paths:

- Open `.md` and `.markdown`; check headings, lists, code, links, tables, and copying across cells.
- Switch Read/Edit; check editor selection, scrolling, undo/redo, and independent document windows.
- Create, edit, save, and reopen. Check Save, Discard, and Cancel on close and quit.
- Confirm unchanged files retain identical bytes, including BOM, Unicode, and CRLF samples. Invalid UTF-8 must report an error.

Record the version/build, OS, hardware, outcomes, and limitations in the PR or release notes. Use the broader [validation checklist](../CONTRIBUTING.md#validation) where relevant. Build success alone does not establish functional acceptance. AI-assisted work follows [AGENTS.md](../AGENTS.md), including its visual-testing requirements.

## Installed-app checks

For Finder and Open With checks, use the current signed Release installed at `/Applications/NanoMD.app`. Building or running in Xcode updates its build directory, not the installed app. When updating the installed copy, request normal termination of older NanoMD instances and stop if unsaved work requires user action. Preserve the previous app under `Temp/`, replace it with the validated locally signed Release, unregister only stale NanoMD build copies with Launch Services, and register the installed app. Keep unrelated associations unchanged. Confirm that macOS resolves the bundle identifier to the installed path.

## Each release

This checklist applies to releases, prereleases, and hotfixes. Documentation and website updates are part of completion.

1. Make changes on a branch and complete relevant local validation. Record what was checked in the PR.
2. Set `MARKETING_VERSION` consistently in Debug and Release and increment `CURRENT_PROJECT_VERSION`. The tag's numeric version must match `MARKETING_VERSION`; optional `alpha`, `beta`, or `rc` suffixes need a numeric iteration. Two-part versions such as `v1.0` are also accepted.
3. Prepare README, website, and release-note updates for shipped features, behavior, limitations, version/build/channel, hardware and macOS requirements, installation, and download links. Include search/sharing descriptions. Label upcoming changes until publication; do not advertise draft assets as available. Update architecture and roadmap content where affected.
4. Merge after Build passes. From clean, updated `main`, tag the intended version. The following tag is an example; replace it before running:

   ```sh
   release_tag=v0.1.0-beta.6
   git switch main
   git pull --ff-only
   git tag -a "$release_tag" -m "nano.md $release_tag"
   git push origin "$release_tag"
   ```

5. Wait for Draft release to succeed, then [verify the downloaded package](#verify-the-downloaded-package). Review generated notes against the tagged source, exact package, and validation results. Explain user-visible changes and limitations. Alpha/beta/RC tags are marked as prereleases.
6. Publish the draft after verification. Check Deploy website's result; a failed deployment leaves the app release published and requires follow-up. Draft preparation does not change the live website.
7. Run `npm --prefix website run update-release` to synchronize local website metadata from the published ZIP. Update the README and this guide's Current release section with the published facts and verification scope. Reconcile website feature copy and release notes. The synchronizer does not update prose or the README, and CI does not commit generated metadata. Commit and push those updates; [redeploy](../website/README.md#deploy) if website content changed after deployment.
8. Confirm deployment succeeded and compare live HTML, GitHub README, release notes, and download links against the published package. Check features, limitations, version/build/channel, compatibility, installation, ZIP download size, and uncompressed app size. Use source/API/HTTP checks; visual testing requires explicit authorization. Report release and website URLs and any unresolved work. Publication alone does not complete a release with outstanding documentation or deployment failures.

If a run fails before draft creation, correct the configuration and rerun it. Inspect any partial draft before removing only that unpublished draft; the workflow does not overwrite releases. Source changes require a new commit and tag. Never move a published tag or replace a published binary.

## Verify the downloaded package

Download the draft's ZIP and `SHA256SUMS.txt` into `Temp/ReleaseVerification/<tag>/`. From the repository root, substitute the tag being verified:

```sh
release_tag=v0.1.0-beta.6
cd "Temp/ReleaseVerification/$release_tag"
shasum -a 256 -c SHA256SUMS.txt
ditto -x -k "nano.md-$release_tag-arm64.zip" .
codesign --verify --deep --strict --verbose=2 NanoMD.app
xcrun stapler validate NanoMD.app
spctl --assess --type execute --verbose=2 NanoMD.app
```

Check the Developer ID identity, secure timestamp, hardened runtime, sandbox/file-access entitlements, absence of debugger/network access, arm64 architecture, version/build, minimum OS, and bundled license/notices against the tagged source. Follow the [measurement policy](../CONTRIBUTING.md#app-size-measurements) for package-size claims.

Launch the downloaded app through Finder and repeat opening, editing, saving/reopening, and undo. Investigate first-launch failures; do not bypass Gatekeeper to count a package as verified. Keep compatibility claims tied to the OS versions actually checked.

## Notarization timeouts

A timeout does not cancel Apple's processing or indicate rejection. Check the submission ID in `notarization-submission.json` using `xcrun notarytool info` with the same Apple account and team.

The workflow retains the signed submission ZIP as `notarization-input-<attempt>`, its checksum, and submission logs for seven days. If Apple later accepts it:

1. Download that run attempt's artifacts under `Temp/` and verify `NotarizationUpload.zip` against `notarization-upload-sha256.txt`.
2. Confirm the commit and tag, extract the exact accepted app, and staple and validate its ticket.
3. Repeat signature and Gatekeeper checks, package it with a new checksum using the workflow's commands, and create a draft release.

Rebuilding produces a different binary; earlier notarization acceptance does not verify that replacement. Keep credentials out of source and logs.
