import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct DemoFileItem: Identifiable {
    public let id = UUID()
    public let name: String
    public let ext: String
    public let category: FileCategory
    public let size: String

    public var tempURL: URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileUrl = tempDir.appendingPathComponent("\(name).\(ext)")
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            if category == .image {
                // Generate a 200x200 sample image
                let image = NSImage(size: NSSize(width: 200, height: 200), flipped: false) { rect in
                    NSColor.systemOrange.setFill()
                    rect.fill()
                    let str = NSString(string: "🍊")
                    str.draw(in: rect.insetBy(dx: 60, dy: 60), withAttributes: [.font: NSFont.systemFont(ofSize: 64)])
                    return true
                }
                if let tiff = image.tiffRepresentation,
                   let rep = NSBitmapImageRep(data: tiff),
                   let data = rep.representation(using: .jpeg, properties: [:]) {
                    try? data.write(to: fileUrl)
                }
            } else if ext == "docx" {
                // Generate real DOCX via textutil
                let tempTxt = tempDir.appendingPathComponent("\(UUID().uuidString).txt")
                let content = "Tangerine Sample Document\n\nThis is a sample Word DOCX document for Tangerine file converter testing.\nSupports offline conversion to PDF, Markdown, Apple Pages, HTML, and images."
                try? content.write(to: tempTxt, atomically: true, encoding: .utf8)
                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
                p.arguments = ["-convert", "docx", tempTxt.path, "-output", fileUrl.path]
                try? p.run()
                p.waitUntilExit()
                try? FileManager.default.removeItem(at: tempTxt)
            } else if ext == "pdf" {
                // Generate real PDF
                let pdfData = NSMutableData()
                var pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
                if let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                   let ctx = CGContext(consumer: consumer, mediaBox: &pageRect, nil) {
                    ctx.beginPage(mediaBox: &pageRect)
                    let attr = NSAttributedString(string: "Tangerine Annual Report\n\n100% Offline Native macOS File Converter.\nTesting PDF extraction, conversion, and rendering.", attributes: [
                        .font: NSFont.systemFont(ofSize: 16)
                    ])
                    let framesetter = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)
                    let path = CGPath(rect: CGRect(x: 54, y: 54, width: 504, height: 684), transform: nil)
                    let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: attr.length), path, nil)
                    CTFrameDraw(frame, ctx)
                    ctx.endPage()
                    ctx.closePDF()
                    try? (pdfData as Data).write(to: fileUrl)
                }
            } else if ext == "zip" {
                // Generate real ZIP archive
                let subDir = tempDir.appendingPathComponent(UUID().uuidString)
                try? FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
                let item = subDir.appendingPathComponent("welcome.txt")
                try? "Welcome to Tangerine Offline File Converter!".write(to: item, atomically: true, encoding: .utf8)
                let p = Process()
                p.currentDirectoryURL = subDir
                p.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
                p.arguments = ["-q", "-r", fileUrl.path, "."]
                try? p.run()
                p.waitUntilExit()
                try? FileManager.default.removeItem(at: subDir)
            } else {
                let dummyText = "Sample content for \(name).\(ext) - Tangerine Offline File Converter"
                try? dummyText.data(using: .utf8)?.write(to: fileUrl)
            }
        }
        return fileUrl
    }
}

public struct FloatingDropZoneView: View {
    @ObservedObject var appState = AppState.shared

    let demoFiles: [DemoFileItem] = [
        DemoFileItem(name: "photo-landscape", ext: "jpg", category: .image, size: "3.2 MB"),
        DemoFileItem(name: "screen-recording", ext: "mov", category: .video, size: "18.4 MB"),
        DemoFileItem(name: "podcast-episode", ext: "mp3", category: .audio, size: "8.1 MB"),
        DemoFileItem(name: "annual-report", ext: "pdf", category: .pdf, size: "1.5 MB"),
        DemoFileItem(name: "brief-overview", ext: "docx", category: .document, size: "420 KB"),
        DemoFileItem(name: "project-assets", ext: "zip", category: .archive, size: "12.8 MB")
    ]

    public var body: some View {
        ZStack {
            // Background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                Divider().opacity(0.3)

                // Main Content
                ScrollView {
                    VStack(spacing: 20) {
                        if appState.showFormatCatalog {
                            FormatMatrixView()
                                .padding(.top, 4)
                        } else {
                            // Real Drop Zone Target
                            dropTargetCard

                            // Interactive Sample Files Carousel (Just like tangerineformac.com)
                            demoPlaygroundSection

                            // Supported Formats Bento Preview
                            bentoFeaturesSection
                        }
                    }
                    .padding(20)
                }

                Divider().opacity(0.3)

                // Bottom Footer Info
                footerView
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }

            // Radial Wheel Overlay
            if appState.isWheelVisible {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        appState.dismissWheel()
                    }

                RadialMenuView()
                    .position(appState.wheelPosition)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .animation(.spring(response: 0.28, dampingFraction: 0.76), value: appState.isWheelVisible)
            }

            // Notification HUD
            VStack {
                NotificationHUD()
                    .padding(.top, 24)
                Spacer()
            }
        }
        .frame(minWidth: 700, minHeight: 620)
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 1.0, green: 0.58, blue: 0.15), Color(red: 0.95, green: 0.35, blue: 0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                Text("🍊")
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("Tangerine")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("for Mac")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                Text("Zero-click offline file converter")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // View Mode Switcher
            HStack(spacing: 2) {
                Button(action: {
                    appState.showFormatCatalog = false
                }) {
                    Text("Drop Zone")
                        .font(.system(size: 11, weight: !appState.showFormatCatalog ? .bold : .medium, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .foregroundColor(!appState.showFormatCatalog ? .white : .secondary)
                        .background(!appState.showFormatCatalog ? Color(red: 1.0, green: 0.5, blue: 0.0) : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)

                Button(action: {
                    appState.showFormatCatalog = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "tablecells")
                            .font(.system(size: 10))
                        Text("Matrix")
                            .font(.system(size: 11, weight: appState.showFormatCatalog ? .bold : .medium, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .foregroundColor(appState.showFormatCatalog ? .white : .secondary)
                    .background(appState.showFormatCatalog ? Color(red: 1.0, green: 0.5, blue: 0.0) : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(2)
            .background(Color.white.opacity(0.08), in: Capsule())

            // Key shortcut tags
            HStack(spacing: 8) {
                keyTag(key: "⇧", label: "Convert")
                keyTag(key: "⌘", label: "Tools")
                keyTag(key: "⌃", label: "Actions")
            }

            Button(action: {
                chooseFilesManually()
            }) {
                Label("Open File...", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private func keyTag(key: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Drop Target Card
    private var dropTargetCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(appState.isTargeted ? Color.orange.opacity(0.12) : Color.secondary.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            appState.isTargeted
                                ? Color(red: 1.0, green: 0.5, blue: 0.0)
                                : Color.secondary.opacity(0.25),
                            style: StrokeStyle(lineWidth: appState.isTargeted ? 2 : 1.5, dash: [8, 6])
                        )
                )

            VStack(spacing: 12) {
                Image(systemName: appState.isTargeted ? "arrow.down.circle.fill" : "arrow.down.doc.fill")
                    .font(.system(size: 38))
                    .foregroundColor(appState.isTargeted ? Color(red: 1.0, green: 0.5, blue: 0.0) : .secondary)
                    .scaleEffect(appState.isTargeted ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25), value: appState.isTargeted)

                VStack(spacing: 4) {
                    Text(appState.isTargeted ? "Drop to open radial wheel" : "Drag any file here")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Tap ⇧ Shift to Convert, ⌘ Command for Tools, or ⌃ Control for Actions")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 14) {
                    badge(icon: "lock.shield.fill", text: "100% Offline")
                    badge(icon: "bolt.fill", text: "Instant Conversion")
                    badge(icon: "circle.hexagongrid.fill", text: "275+ Formats")
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
        }
        .onDrop(of: [.fileURL], isTargeted: Binding(
            get: { appState.isTargeted },
            set: { appState.isTargeted = $0 }
        )) { providers, location in
            loadFiles(from: providers, at: location)
            return true
        }
    }

    private func badge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.12), in: Capsule())
    }

    // MARK: - Interactive Demo Files Section
    private var demoPlaygroundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Try with sample files")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                Text("Click any file to trigger Tangerine's radial wheel")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 160), spacing: 12)], spacing: 12) {
                ForEach(demoFiles) { file in
                    Button(action: {
                        let center = CGPoint(x: 350, y: 310)
                        appState.presentWheel(at: center, with: [file.tempURL], mode: .convert)
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: file.category.sfSymbol)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                                Spacer()
                                Text(file.ext.uppercased())
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.18), in: RoundedRectangle(cornerRadius: 4))
                            }

                            Text(file.name)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .lineLimit(1)

                            HStack {
                                Text(file.size)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary.opacity(0.6))
                            }
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Bento Features Section
    private var bentoFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Browse Tools & Conversions")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
            }

            // Category selector tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([FileCategory.image, .video, .audio, .pdf, .document, .archive], id: \.self) { cat in
                        Button(action: {
                            appState.selectedDemoCategory = cat
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: cat.sfSymbol)
                                Text(cat.rawValue)
                            }
                            .font(.system(size: 12, weight: appState.selectedDemoCategory == cat ? .bold : .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundColor(appState.selectedDemoCategory == cat ? .white : .secondary)
                            .background(
                                appState.selectedDemoCategory == cat
                                    ? Color(red: 1.0, green: 0.5, blue: 0.0)
                                    : Color.secondary.opacity(0.12),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Cards showing available tools for chosen category
            let actions = ToolRegistry.actions(for: appState.selectedDemoCategory, mode: .convert, urls: [])
            let tools = ToolRegistry.actions(for: appState.selectedDemoCategory, mode: .tools, urls: [])

            HStack(alignment: .top, spacing: 14) {
                // Conversions card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("⇧ Convert Formats")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                        Spacer()
                        Text("\(actions.count) options")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    ForEach(actions.prefix(4)) { act in
                        HStack(spacing: 8) {
                            Image(systemName: act.sfSymbol)
                                .font(.system(size: 12))
                                .frame(width: 18)
                            Text(act.title)
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text(act.description)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(14)
                .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))

                // Tools card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("⌘ File Tools")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.accentColor)
                        Spacer()
                        Text("\(tools.count) tools")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    ForEach(tools.prefix(4)) { act in
                        HStack(spacing: 8) {
                            Image(systemName: act.sfSymbol)
                                .font(.system(size: 12))
                                .frame(width: 18)
                            Text(act.title)
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text(act.description)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(14)
                .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Text("🍊 Tangerine Offline File Converter")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            Text("Everything runs 100% locally on your Mac. No files uploaded.")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.8))
        }
    }

    // MARK: - Actions
    private func chooseFilesManually() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true

        if panel.runModal() == .OK {
            let urls = panel.urls
            if !urls.isEmpty {
                let center = CGPoint(x: 350, y: 310)
                appState.presentWheel(at: center, with: urls, mode: .convert)
            }
        }
    }

    private func loadFiles(from providers: [NSItemProvider], at location: CGPoint) {
        Task { @MainActor in
            var loadedUrls: [URL] = []
            for provider in providers {
                if let item = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) {
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        loadedUrls.append(url)
                    } else if let url = item as? URL {
                        loadedUrls.append(url)
                    }
                }
            }

            if !loadedUrls.isEmpty {
                self.appState.presentWheel(at: location, with: loadedUrls, mode: .convert)
            }
        }
    }
}
