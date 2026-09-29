# OpenWriter Mac 0.1.0 — unsigned preview

This Mac launcher bundles OpenWriter 0.41.3. It starts the official service and opens the editor in your usual browser. You do not need Terminal, Node.js, or npm to use it.

## Install

1. Download the **arm64** DMG for an Apple Silicon Mac (M1 or newer), or the **x86_64** DMG for an Intel Mac. Check **Apple menu → About This Mac** if you are unsure.
2. Open the DMG and drag **OpenWriter Mac** to **Applications**. Eject the disk image.
3. Open **OpenWriter Mac** from Applications. If macOS says it cannot verify the app, dismiss the alert. Open **Apple menu → System Settings → Privacy & Security**, scroll to **Security**, and choose **Open Anyway** for OpenWriter Mac. Authenticate if asked, then confirm **Open**. If the button is absent, try opening the app from Applications again.

This preview is **not Developer ID signed or notarized**. Only approve it if you trust this download from this repository. [Apple explains the approval flow](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac).

Keep OpenWriter Mac running while you write. **Quit OpenWriter Mac** stops its service. Your writing is stored by OpenWriter in `~/.openwriter`, outside the app.

## Update

Use **OpenWriter Mac → Check for Updates…**. When a newer release is available, download its DMG, quit the app, drag the new app into Applications, choose **Replace**, and reopen it. Updates are manual; there is no background installation.

## Testing and limits

The Apple Silicon app and service were launched locally. The Intel service was tested under Rosetta; a first launch on a physical Intel Mac has not yet been confirmed. The DMGs are checked during the build. [Developer ID signing and notarization](https://github.com/iviaxpow3r/openwriter-mac-launcher/issues/2) are planned to remove the extra first-launch approval step.
