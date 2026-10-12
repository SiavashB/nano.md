# Releasing nano.md

Test locally with AI assistance, merge the changes, push a version tag, and review the resulting GitHub draft before publishing. There are no automated tests or scheduled releases.

## Workflows

- **Build** runs unsigned Debug and Release builds on pull requests and pushes to `main`. It reports compilation failures and keeps build logs for seven days.
- **Draft release** runs on `v*` tags. It builds the tagged commit for Apple Silicon, signs with Developer ID, notarizes and staples the app, and creates a draft release with a ZIP and SHA-256 checksum. Tags must point to a commit included in `main`. Normal pushes to `main` never create a release.

Both workflows use the standard `macos-26` runner and Xcode 26.6. Build products, package caches, logs, and release staging stay under `Temp/`. Only selected logs and release files are uploaded. CI compilation does not verify editing behavior, file preservation, or the downloaded app's first launch.

Standard runner time is free for public repositories. Private repositories use the account's included Actions allowance and may incur charges beyond it. This repository is currently private; check its Actions budget before enabling paid overages.

## One-time signing setup

In the repository's GitHub Actions secrets, add:

| Secret | Value |
| --- | --- |
| `CERTIFICATE_P12_BASE64` | Base64-encoded `.p12` export of a Developer ID Application certificate and its private key |
| `CERTIFICATE_PASSWORD` | Password protecting that `.p12` export; use a nonempty password |
| `APPLE_TEAM_ID` | Developer Program team that owns the certificate |
| `APPLE_ID` | Apple account used for notarization |
| `APPLE_APP_PASSWORD` | App-specific password for that Apple account |

Use `gh secret set NAME` to enter a value securely, or GitHub's repository secrets settings. Keep any temporary certificate export under `Temp/` and remove it when finished. Never paste credentials into chat or commit them. The release runner imports the certificate into a temporary keychain and removes it after the job. No signing secrets are used by the Build workflow.

Missing credentials stop the release workflow with the missing secret's name. A local ad-hoc signature cannot replace Developer ID signing for this workflow. See [GitHub's certificate setup](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications) and [Apple's Developer ID guidance](https://developer.apple.com/developer-id/).

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
