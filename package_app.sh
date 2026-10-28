#!/bin/bash
set -e

APP_NAME="Tangerine"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Creating bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "Copying binary..."
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "Creating Info.plist..."
cat << 'PLIST' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Tangerine</string>
    <key>CFBundleDisplayName</key>
    <string>Tangerine</string>
    <key>CFBundleIdentifier</key>
    <string>com.tangerine.fileconverter</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Tangerine</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Tangerine. All rights reserved.</string>
</dict>
</plist>
PLIST

echo "Generating AppIcon..."
ICONSET_DIR="AppIcon.iconset"
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

# Create a master icon using swift
swift - << 'SWIFT'
import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size, flipped: false) { rect in
    // Background squircle
    let path = NSBezierPath(roundedRect: rect.insetBy(dx: 40, dy: 40), xRadius: 220, yRadius: 220)
    let gradient = NSGradient(starting: NSColor(calibratedRed: 1.0, green: 0.62, blue: 0.18, alpha: 1.0),
                              ending: NSColor(calibratedRed: 0.94, green: 0.32, blue: 0.0, alpha: 1.0))
    gradient?.draw(in: path, angle: -45)

    // Inner shadow & subtle ring
    NSColor(white: 1.0, alpha: 0.3).setStroke()
    path.lineWidth = 12
    path.stroke()

    // Tangerine Emoji / Mark
    let str = NSString(string: "🍊")
    let font = NSFont.systemFont(ofSize: 520)
    let attrs: [NSAttributedString.Key: Any] = [.font: font]
    let strSize = str.size(withAttributes: attrs)
    let strRect = NSRect(x: (size.width - strSize.width)/2,
                         y: (size.height - strSize.height)/2 - 20,
                         width: strSize.width,
                         height: strSize.height)
    str.draw(in: strRect, withAttributes: attrs)
    return true
}

if let tiff = image.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "master_icon.png"))
}
SWIFT

for s in 16 32 64 128 256 512; do
    sips -z $s $s master_icon.png --out "${ICONSET_DIR}/icon_${s}x${s}.png" >/dev/null
    s2=$((s * 2))
    sips -z $s2 $s2 master_icon.png --out "${ICONSET_DIR}/icon_${s}x${s}@2x.png" >/dev/null
done

iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/AppIcon.icns"
rm -rf "${ICONSET_DIR}" master_icon.png

echo "Tangerine.app created successfully!"
