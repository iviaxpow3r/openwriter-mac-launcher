# OpenWriter Mac

A small, community-maintained Mac launcher for [OpenWriter](https://github.com/travsteward/openwriter). It bundles a pinned release of the official OpenWriter service and Node.js, starts the service for you, then opens the editor in your usual browser. You do not need Terminal, Node.js, or npm to use the app.

**Download status:** The [GitHub release](https://github.com/iviaxpow3r/openwriter-mac-launcher/releases/latest) provides unsigned preview DMGs. macOS will ask you to approve the app in System Settings the first time you open it. Install and update entirely through Finder and System Settings; no Terminal commands are needed. Download only from this repository. [Issue #2](https://github.com/iviaxpow3r/openwriter-mac-launcher/issues/2) tracks future Developer ID signing and notarization for a smoother first launch.

## Install on a Mac

1. Open the [latest GitHub release](https://github.com/iviaxpow3r/openwriter-mac-launcher/releases/latest).
2. Download **arm64** for an Apple Silicon Mac (M1 or newer), or **x86_64** for an Intel Mac. To check, use Apple menu → **About This Mac** and look for **Chip** or **Processor**.
3. Open the downloaded `.dmg` and drag **OpenWriter Mac** into **Applications**.
4. Eject the disk image, then open **OpenWriter Mac** from Applications. It starts OpenWriter and opens the editor in your browser. Keep the Mac app running while you write; **Quit OpenWriter Mac** stops its service.

### If macOS says it cannot verify the app

This preview is not signed with an Apple Developer ID. After you try to open the app from **Applications**, dismiss the warning and open **Apple menu → System Settings → Privacy & Security**. Scroll to **Security** and click **Open Anyway** next to the message about OpenWriter Mac. Enter your Mac password if asked, then confirm **Open**. The button generally appears for about an hour after the blocked launch. If you do not see it, try opening the app from Applications again. Only approve the app if you downloaded it from this repository and trust it. See [Apple's instructions for opening an app from an unknown developer](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac).

The app serves OpenWriter only on your Mac at `127.0.0.1:5050`. The official OpenWriter package stores your writing in `~/.openwriter`; replacing the app does not replace that folder. This launcher does not contain a personal profile or book files.

## Update

Choose **OpenWriter Mac → Check for Updates…** in the Mac menu bar. The app compares its version with the latest GitHub release and opens the download page when a newer version exists. Quit the app, download the new DMG, drag the new app into Applications, choose **Replace**, and reopen it. This is a manual download and replace flow; the app does not install updates silently.

Each launcher release pins and bundles a specific official OpenWriter version. Dependabot proposes core package updates here; after review and a new launcher release, the menu check finds that release. See [package.json](package.json) for the bundled version.

## Build from source

On a Mac with Xcode Command Line Tools and Node.js 22:

```sh
./scripts/build-dmg.sh
```

The script uses the committed npm lockfile, compiles the small Cocoa launcher for the current CPU architecture, ad hoc signs the app, creates `dist/OpenWriter-Mac-v<version>-<architecture>.dmg`, and verifies the DMG checksum. GitHub Actions checks both Apple Silicon and Intel builds. Tagged versions publish both DMGs as unsigned preview releases.

For future core updates, Dependabot proposes changes to the pinned `openwriter` package. Review and test those changes, then bump `version` in `package.json` and `BUILD_NUMBER`. A new tagged release updates the app's **Check for Updates…** result. Developer ID signing and notarization can be added later without changing the install or update model.

## Relationship to OpenWriter

OpenWriter itself is [MIT licensed](https://github.com/travsteward/openwriter/blob/main/LICENSE) and maintained separately. This launcher is a separate project. It bundles the published OpenWriter npm package and does not change upstream source or publish a forked service. Issues with the writing editor belong in the [OpenWriter issue tracker](https://github.com/travsteward/openwriter/issues); issues with Mac installation, launching, and updates belong here.
