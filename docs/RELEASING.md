# Releasing nano.md

Test locally with AI assistance, merge the changes, push a version tag, and review the resulting GitHub draft before publishing. There are no automated tests or scheduled releases.

## Workflows

- **Build** runs unsigned Debug and Release builds on pull requests and pushes to `main`. It reports compilation failures and keeps build logs for seven days.
- **Draft release** runs on `v*` tags. It builds the tagged commit for Apple Silicon, signs with Developer ID, notarizes and staples the app, and creates a draft release with a ZIP and SHA-256 checksum. Tags must point to a commit included in `main`. Normal pushes to `main` never create a release.

Both workflows use the standard `macos-26` runner and Xcode 26.6. Build products, package caches, logs, and release staging stay under `Temp/`. Only selected logs and release files are uploaded. CI compilation does not verify editing behavior, file preservation, or the downloaded app's first launch.

Standard runner time is free for public repositories. Private repositories use the account's included Actions allowance and may incur charges beyond it. This repository is currently private; check its Actions budget before enabling paid overages.

## One-time signing setup

1. Sign in to [Apple Developer](https://developer.apple.com/account/) and confirm an active Developer Program membership and its Team ID. Use the team that will own the release certificate; do not assume the local development team is the distribution team.
2. In Xcode's Settings → Accounts, select that account and team, then **Manage Certificates**. Create a **Developer ID Application** certificate with the + button. Certificate creation requires the Account Holder role. If that option is unavailable, follow [Apple's certificate setup](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/) or ask the team's Account Holder to provide an export.
3. Control-click the certificate and choose **Export Certificate**. Save it as `Temp/FirstRelease/DeveloperID.p12` with a nonempty password. The export must include the private key. See [Apple's export instructions](https://help.apple.com/xcode/mac/current/en.lproj/dev154b28f09.html).
4. At [account.apple.com](https://account.apple.com/), open **Sign-In and Security → App-Specific Passwords**, and create a password named `nano.md releases`. This requires two-factor authentication. See [Apple's password instructions](https://support.apple.com/en-us/102654).
5. From the repository root, upload the certificate without printing its contents:

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

## First beta

The first candidate is version **0.1.0**, build **7**, with the intended tag **`v0.1.0-beta.1`**. It targets Apple Silicon and macOS 26.5 or later, using Xcode 26.6. Broader hardware and older macOS support have not been verified. Preparing this version does not create a release tag or certify runtime behavior.

Before tagging, choose and add the project license and complete these local checks with disposable files under `Temp/`. If using an AI assistant for UI checks, explicitly authorize visual testing in that chat.

- Open `.md` and `.markdown` files in Read mode; check headings, lists, code, links, and tables, including selecting and copying across table cells.
- Switch Read/Edit repeatedly; check selection, scroll position, undo/redo, and two independent document windows.
- Create, edit, save, and reopen a document. Check close/quit confirmation, including Save, Discard, and Cancel.
- Confirm a file opened and closed without editing retains identical bytes. Include UTF-8 BOM, Unicode, and CRLF samples; invalid UTF-8 should report an error.
- Record outcomes and any limitations. Build success alone does not complete this checklist.

After the draft is created, download both assets into `Temp/FirstRelease/Download/`, verify the checksum there, and extract the ZIP. Confirm the packaged app's signature and notarization before its first launch:

```sh
cd Temp/FirstRelease/Download
shasum -a 256 -c SHA256SUMS.txt
ditto -x -k nano.md-v0.1.0-beta.1-arm64.zip .
codesign --verify --deep --strict --verbose=2 NanoMD.app
xcrun stapler validate NanoMD.app
spctl --assess --type execute --verbose=2 NanoMD.app
```

Launch the downloaded app through Finder and repeat opening, editing, saving/reopening, and undo. Check any first-launch failure before publishing; do not bypass Gatekeeper to count the release as verified. Review the draft's notes, mark known unsupported syntax, and publish only after the packaged app passes the intended checks. Make the repository public after its license is in place, then update and explicitly deploy the website with the verified release download and source links.

## Each release

1. Make changes on a branch and test locally with AI assistance. Focus on the changed behavior and opening, editing, saving/reopening, and undo. Record what was actually checked in the PR; do not treat a green build as functional verification.
2. Set `MARKETING_VERSION` consistently in Debug and Release and increment `CURRENT_PROJECT_VERSION`. For example, version `0.1.0` can use the tag `v0.1.0-beta.1`, then `v0.1.0` for the stable release. Tags also accept two-part app versions, such as `v1.0`. Refresh the website's size/version from the updated Release bundle as described in [website/README.md](../website/README.md).
3. Merge after the Build workflow passes. From a clean, updated `main`, create and push the intended version tag:

   ```sh
   git switch main
   git pull --ff-only
   git tag -a v0.1.0-beta.1 -m "nano.md 0.1.0 beta 1"
   git push origin v0.1.0-beta.1
   ```

   Replace the example version with the app version being released. The tag's numeric version must exactly match `MARKETING_VERSION`; `alpha`, `beta`, and `rc` suffixes use a numeric iteration. Pushing the tag starts release preparation, not publication.

4. Wait for **Draft release** to succeed. Inspect the generated draft, download the ZIP, verify it with `shasum -a 256 -c SHA256SUMS.txt`, and perform the intended local checks on that packaged app. Edit the generated notes to explain user-visible changes and known limitations. Beta/alpha/RC tags are automatically marked as prereleases.
5. Publish the draft when ready. Choose the project license before making the repository publicly available as open source. Website deployment remains a separate explicit action.

The workflow never publishes automatically. If a run fails before creating the draft, correct the configuration and rerun it when appropriate. If a partial draft already exists, inspect it and remove only that unpublished draft before retrying; the workflow does not overwrite existing releases. Source changes need a new commit and tag. Never move a published tag or replace a published binary; ship a new version.

## Current setup status

Workflow definitions and a shared Xcode scheme are included in the repository. Signing secrets must be configured before the first signed release run. Build checks, signing/notarization, and local functional verification are separate results; record each only after it has actually succeeded.
