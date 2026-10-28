# 🍊 Tangerine for Mac

> **The zero-click offline file converter for macOS.**  
> Drag a file, tap **Shift** to convert, **Command** for editing tools, or **Control** for file actions.  
> **100% offline.** Everything runs locally on your Mac using native macOS hardware acceleration.

Inspired by [tangerineformac.com](https://tangerineformac.com/).

---

## ⚡️ Key Features

- **Zero-Click Radial Wheel**:
  - **⇧ Shift**: **Convert Formats** (PNG, JPG, WebP, HEIC, TIFF, BMP, PDF, MP4, MOV, MP3, M4A, etc.)
  - **⌘ Command**: **File Tools** (Compress, Resize 50%, Rotate, Grayscale, Strip Metadata, Merge PDFs, Trim Video/Audio, etc.)
  - **⌃ Control**: **File Actions** (AirDrop, Quick Look, Copy, Copy Path, Open in Terminal, Move to Trash)
- **100% Local & Private**: No files ever leave your Mac. No network calls, no cloud dependencies.
- **Native macOS Performance**:
  - **Image Processing**: Scriptable Image Processing System (`sips`), `CoreGraphics`, `ImageIO`, and `vImage`.
  - **PDF Tools**: Native `PDFKit` for page splitting, multi-file merging, text extraction, and 300 DPI image rendering.
  - **Video & Audio**: Hardware-accelerated `AVFoundation` for H.264/HEVC transcoding, audio ripping, and clip trimming.
  - **Document Conversion**: macOS `textutil` for DOCX, RTF, HTML, and TXT processing.
  - **Archives**: High-speed native `ditto` and `tar` compression/decompression.
- **Interactive Playground**: Included interactive test files (Images, Video, Audio, PDF, Docs, Archives) to test the radial menu and instant conversions immediately.
- **Menu Bar Status Item**: Discreet `🍊` status bar icon for quick access, shortcut reference, and drop zone summoning.
- **Haptic & Visual Feedback**: Fluid SwiftUI animations, glassmorphism backdrop blur, wedge highlighting, and native macOS haptic feedback.

---

## 🚀 Quick Start

### Option 1: Launch the Application Bundle
Double-click or launch `Tangerine.app`:
```bash
open Tangerine/Tangerine.app
```

### Option 2: Run via Swift Package Manager
```bash
cd Tangerine
swift run
```

### Option 3: Rebuild Release Bundle
```bash
cd Tangerine
swift build -c release
./package_app.sh
```

---

## 🛠 Supported Formats & Capabilities

| Category | Convert (⇧ Shift) | File Tools (⌘ Command) |
| :--- | :--- | :--- |
| **Images** | PNG, JPG, WebP, HEIC, TIFF, BMP, PDF, GIF | Compress, Resize 50%, Rotate 90°, Grayscale, Strip Metadata, Combine into PDF |
| **Video** | MP4, MOV, WebM, MP3 Audio, M4A Audio, GIF, Poster JPG | Compress (720p/1080p), Mute Audio, Trim first 30s, Extract Audio |
| **Audio** | MP3, M4A, WAV, AIFF, FLAC | Compress Bitrate, Trim first 30s |
| **PDF** | PNG (300 DPI), JPG, TXT Text Extract, Split Pages, DOCX | Compress PDF, Merge PDFs, Split by Page, Grayscale |
| **Documents** | PDF, DOCX, TXT, HTML, RTF | Compress to ZIP, Strip Metadata |
| **Archives** | Repack as ZIP, TAR.GZ, Extract Folder | Quick Compress |
| **Any File** | ⌃ Control: AirDrop, Quick Look, Copy, Copy Path, Open in Terminal, Move to Trash |

---

## 🧪 Testing

Run the automated test suite verifying file type detection, tool registry, and actual image & archive conversions:
```bash
cd Tangerine
swift test
```
