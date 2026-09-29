# OpenWriter Mac

A small, community-maintained Mac launcher for [OpenWriter](https://github.com/travsteward/openwriter). It bundles a pinned release of the official OpenWriter service and Node.js, starts the service for you, then opens the editor in your usual browser. You do not need Terminal, Node.js, or npm to use the app.

## Install

1. Open the [latest GitHub release](https://github.com/iviaxpow3r/openwriter-mac-launcher/releases/latest).
2. Download **arm64** for an Apple Silicon Mac (M1 or newer), or **x86_64** for an Intel Mac. To check, use Apple menu → **About This Mac** and look for **Chip** or **Processor**.
3. Open the downloaded `.dmg` and drag **OpenWriter Mac** into **Applications**.
4. Open **OpenWriter Mac** from Applications. It starts OpenWriter and opens the editor in your browser. Keep the Mac app running while you write; **Quit OpenWriter Mac** stops its service.

**First launch of this preview release:** The app is ad hoc signed, without an Apple Developer ID or notarization. macOS may refuse to open it at first. If you downloaded it from the release page above and choose to trust it, attempt to open the app once, then go to **System Settings → Privacy & Security → Open Anyway**. Apple describes this process in [its Mac guide](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac). A Developer ID and notarization are the next step toward a normal double-click install.

The app serves OpenWriter only on your Mac at `127.0.0.1:5050`. The official OpenWriter package stores your writing in `~/.openwriter`; replacing the app does not replace that folder. This launcher does not contain a personal profile or book files.

## Update

Choose **OpenWriter Mac → Check for Updates…** in the Mac menu bar. The app compares its version with the latest GitHub release and opens the download page when a newer version exists. Quit the app, download the new DMG, drag the new app into Applications, choose **Replace**, and reopen it. This is a manual download and replace flow; the app does not install updates silently.

Each launcher release pins and bundles a specific official OpenWriter version. Dependabot proposes core package updates here; after review and a new launcher release, the menu check finds that release. See [package.json](package.json) for the bundled version.

## Build from source

On a Mac with Xcode Command Line Tools and Node.js 22:

```sh
./scripts/build-dmg.sh
```

The script uses the committed npm lockfile, compiles the small Cocoa launcher for the current CPU architecture, ad hoc signs the app, creates `dist/OpenWriter-Mac-v<version>-<architecture>.dmg`, and verifies the DMG checksum. GitHub Actions builds both Apple Silicon and Intel variants for each release tag.

To release an updated core version: merge the dependency update and build checks, bump `version` in `package.json` and `BUILD_NUMBER`, then push a matching `v<version>` tag. The tag workflow publishes both installers as a prerelease. Please test the released DMGs on actual Macs before recommending them broadly.

## Relationship to OpenWriter

OpenWriter itself is [MIT licensed](https://github.com/travsteward/openwriter/blob/main/LICENSE) and maintained separately. This launcher is a separate project. It bundles the published OpenWriter npm package and does not change upstream source or publish a forked service. Issues with the writing editor belong in the [OpenWriter issue tracker](https://github.com/travsteward/openwriter/issues); issues with Mac installation, launching, and updates belong here.
