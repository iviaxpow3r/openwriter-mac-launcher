# OpenWriter Mac

A small, community-maintained Mac launcher for [OpenWriter](https://github.com/travsteward/openwriter). It bundles a pinned release of the official OpenWriter service and Node.js, starts the service for you, then opens the editor in your usual browser. You do not need Terminal, Node.js, or npm to use the app.

**Download status:** The source and Mac build checks are available, but there is no public installer release yet. macOS Gatekeeper rejects the current ad hoc signed build after download. GitHub Actions artifacts are labeled **UNSIGNED-TEST-ONLY** and are not install downloads. A normal drag-to-Applications release needs Developer ID signing and Apple notarization. This does not require publishing through the Mac App Store. [Issue #2](https://github.com/iviaxpow3r/openwriter-mac-launcher/issues/2) tracks the remaining release work.

## Install after the signed release

1. Open the [latest GitHub release](https://github.com/iviaxpow3r/openwriter-mac-launcher/releases/latest).
2. Download **arm64** for an Apple Silicon Mac (M1 or newer), or **x86_64** for an Intel Mac. To check, use Apple menu → **About This Mac** and look for **Chip** or **Processor**.
3. Open the downloaded `.dmg` and drag **OpenWriter Mac** into **Applications**.
4. Open **OpenWriter Mac** from Applications. It starts OpenWriter and opens the editor in your browser. Keep the Mac app running while you write; **Quit OpenWriter Mac** stops its service.

The app serves OpenWriter only on your Mac at `127.0.0.1:5050`. The official OpenWriter package stores your writing in `~/.openwriter`; replacing the app does not replace that folder. This launcher does not contain a personal profile or book files.

## Update

Choose **OpenWriter Mac → Check for Updates…** in the Mac menu bar. The app compares its version with the latest GitHub release and opens the download page when a newer version exists. Quit the app, download the new DMG, drag the new app into Applications, choose **Replace**, and reopen it. This is a manual download and replace flow; the app does not install updates silently.

Each launcher release pins and bundles a specific official OpenWriter version. Dependabot proposes core package updates here; after review and a new launcher release, the menu check finds that release. See [package.json](package.json) for the bundled version.

## Build from source

On a Mac with Xcode Command Line Tools and Node.js 22:

```sh
./scripts/build-dmg.sh
```

The script uses the committed npm lockfile, compiles the small Cocoa launcher for the current CPU architecture, ad hoc signs a development build, creates `dist/OpenWriter-Mac-v<version>-<architecture>.dmg`, and verifies the DMG checksum. GitHub Actions checks both Apple Silicon and Intel builds. These ad hoc DMGs are build artifacts, not ready-to-share installers.

For future core updates, Dependabot proposes changes to the pinned `openwriter` package. Review and test those changes, then bump `version` in `package.json` and `BUILD_NUMBER`. Signed, notarized releases will be published after the distribution signing flow is in place.

## Relationship to OpenWriter

OpenWriter itself is [MIT licensed](https://github.com/travsteward/openwriter/blob/main/LICENSE) and maintained separately. This launcher is a separate project. It bundles the published OpenWriter npm package and does not change upstream source or publish a forked service. Issues with the writing editor belong in the [OpenWriter issue tracker](https://github.com/travsteward/openwriter/issues); issues with Mac installation, launching, and updates belong here.
