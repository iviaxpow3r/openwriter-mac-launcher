#!/bin/zsh
set -euo pipefail

repo_root=${0:A:h:h}
build_number=$(<"$repo_root/BUILD_NUMBER")
target_arch=${OPENWRITER_TARGET_ARCH:-$(uname -m)}
node_binary=${OPENWRITER_NODE_BINARY:-$(command -v node)}
output_dir=${OPENWRITER_OUTPUT_DIR:-"$repo_root/dist"}
app_version=$("$node_binary" -p "require('$repo_root/package.json').version")
core_version=$("$node_binary" -p "require('$repo_root/package.json').dependencies.openwriter")

if [[ "$target_arch" != arm64 && "$target_arch" != x86_64 ]]; then
  print -u2 "Target architecture must be arm64 or x86_64."
  exit 1
fi
npm_arch=$target_arch
if [[ "$target_arch" == x86_64 ]]; then npm_arch=x64; fi
if [[ ! "$app_version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' || ! "$core_version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' || ! "$build_number" =~ '^[0-9]+$' ]]; then
  print -u2 "package.json version or BUILD_NUMBER is malformed."
  exit 1
fi
if [[ ! -x "$node_binary" || " $(/usr/bin/lipo -archs "$node_binary" 2>/dev/null) " != *" $target_arch "* ]]; then
  print -u2 "OPENWRITER_NODE_BINARY must point to a runnable $target_arch Node binary."
  exit 1
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/openwriter-mac-build.XXXXXX")
if [[ "${OPENWRITER_KEEP_BUILD:-0}" == 1 ]]; then
  print "Build staging: $work_dir"
else
  trap 'rm -rf "$work_dir"' EXIT
fi
install_dir=${OPENWRITER_STAGING_DIR:-"$work_dir/install"}
if [[ -z "${OPENWRITER_STAGING_DIR:-}" ]]; then
  mkdir -p "$install_dir"
  cp "$repo_root/package.json" "$repo_root/package-lock.json" "$install_dir/"
  npm ci --prefix "$install_dir" --omit=dev --include=optional --ignore-scripts --no-audit --no-fund --os=darwin --cpu="$npm_arch"
elif [[ ! -f "$install_dir/node_modules/openwriter/package.json" || ! -f "$install_dir/node_modules/sharp/package.json" ]]; then
  print -u2 "OPENWRITER_STAGING_DIR must contain the pinned OpenWriter and sharp packages."
  exit 1
fi

package_dir="$install_dir/node_modules/openwriter"
installed_version=$("$node_binary" -p "require('$package_dir/package.json').version")
if [[ "$installed_version" != "$core_version" || ! -f "$package_dir/dist/build-info.json" || ! -f "$package_dir/dist/bin/pad.js" ]]; then
  print -u2 "The staged OpenWriter package is missing or does not match package.json."
  exit 1
fi
if ! "$node_binary" -e "require('$install_dir/node_modules/sharp')"; then
  print -u2 "The bundled sharp binary does not match $target_arch."
  exit 1
fi

app_path="$work_dir/dmg/OpenWriter Mac.app"
resources="$app_path/Contents/Resources"
mkdir -p "$app_path/Contents/MacOS" "$resources/runtime" "$resources/node_modules"
cp "$repo_root/launcher/Info.plist" "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $app_version" "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$app_path/Contents/Info.plist"
cp "$repo_root/launcher/OpenWriter.icns" "$resources/OpenWriter.icns"
cp "$node_binary" "$resources/runtime/node"
cp -R "$package_dir" "$resources/openwriter"
rsync -a --exclude 'openwriter/' --exclude '.bin/' "$install_dir/node_modules/" "$resources/node_modules/"

clang -fobjc-arc -mmacosx-version-min=11.0 -arch "$target_arch" \
  -framework Cocoa \
  "$repo_root/launcher/OpenWriterApp.m" -o "$app_path/Contents/MacOS/OpenWriter"

# This preview build is ad-hoc signed. Developer ID + notarization can be
# added later without changing the drag-to-Applications install layout.
print "Signing app bundle"
codesign --force --deep --sign - "$app_path"
print "Verifying app signature"
codesign --verify --deep --strict "$app_path"
ln -s /Applications "$work_dir/dmg/Applications"
mkdir -p "$output_dir"
output="$output_dir/OpenWriter-Mac-v$app_version-$target_arch.dmg"
attached_image_device() {
  hdiutil info -plist | /usr/bin/python3 -c '
import os, plistlib, sys
target = os.path.realpath(sys.argv[1])
for image in plistlib.loads(sys.stdin.buffer.read()).get("images", []):
    if os.path.realpath(image.get("image-path", "")) == target:
        for entity in image.get("system-entities", []):
            device = entity.get("dev-entry", "")
            if device.startswith("/dev/disk"):
                print(device)
                sys.exit(0)
' "$output"
}
if [[ -n "$(attached_image_device)" ]]; then
  print -u2 "The existing output DMG is mounted. Eject it before rebuilding: $output"
  exit 1
fi
print "Creating DMG"
hdiutil create -volname "OpenWriter Mac" -srcfolder "$work_dir/dmg" -ov -format UDZO "$output"
# DiskImages occasionally leaves a newly created APFS image attached. Detach
# this exact output before checksum verification, never another mounted disk.
attached_device=$(attached_image_device)
if [[ -n "$attached_device" ]]; then
  hdiutil detach "$attached_device"
fi
print "Verifying DMG"
hdiutil verify "$output"
shasum -a 256 "$output" > "$output.sha256"
print "Built $output"
print "Core OpenWriter version: $core_version"
print "SHA-256: $(cat "$output.sha256")"
