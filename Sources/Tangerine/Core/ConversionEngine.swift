import Foundation
import AppKit
import AVFoundation
import PDFKit
import ImageIO
import UniformTypeIdentifiers
import Vision


public enum ConversionResult: Sendable {
    case success(outputUrls: [URL], message: String)
    case failure(error: String)
}

public final class ConversionEngine: Sendable {
    public static let shared = ConversionEngine()

    private init() {}

    public func execute(action: RadialAction, urls: [URL]) async -> ConversionResult {
        return await Task.detached(priority: .userInitiated) {
            do {
                switch action.mode {
                case .convert:
                    let results = try self.handleConversion(action: action, urls: urls)
                    return .success(outputUrls: results, message: "Converted \(urls.count) file\(urls.count == 1 ? "" : "s") to \(action.title)")
                case .tools:
                    let results = try self.handleTool(action: action, urls: urls)
                    return .success(outputUrls: results, message: "\(action.title) completed successfully")
                case .actions:
                    let msg = try self.handleAction(action: action, urls: urls)
                    return .success(outputUrls: urls, message: msg)
                }
            } catch {
                return .failure(error: error.localizedDescription)
            }
        }.value
    }

    // MARK: - Conversions

    private func handleConversion(action: RadialAction, urls: [URL]) throws -> [URL] {
        var outputUrls: [URL] = []
        let targetExt = action.targetExtension ?? "out"

        for url in urls {
            let category = FileInspector.category(for: url)

            switch category {
            case .image:
                let out = try convertImage(sourceUrl: url, targetExtension: targetExt)
                outputUrls.append(out)

            case .pdf:
                let ext = targetExt.lowercased()
                if ["png", "jpg", "jpeg", "tiff", "tif", "webp", "heic", "bmp", "gif"].contains(ext) {
                    let outs = try convertPDFToImages(pdfUrl: url, format: ext)
                    outputUrls.append(contentsOf: outs)
                } else if ext == "pdf" { // split
                    let outs = try splitPDFPages(pdfUrl: url)
                    outputUrls.append(contentsOf: outs)
                } else {
                    let out = try convertPDFToDocument(pdfUrl: url, targetExtension: ext)
                    outputUrls.append(out)
                }

            case .video:
                if targetExt == "m4a" || targetExt == "mp3" {
                    let out = try extractAudioFromVideo(videoUrl: url, format: targetExt)
                    outputUrls.append(out)
                } else if targetExt == "jpg" || targetExt == "png" {
                    let out = try extractPosterFrame(videoUrl: url)
                    outputUrls.append(out)
                } else {
                    let out = try transcodeVideo(videoUrl: url, targetExtension: targetExt)
                    outputUrls.append(out)
                }

            case .audio:
                let out = try transcodeAudio(audioUrl: url, targetExtension: targetExt)
                outputUrls.append(out)

            case .document:
                let out = try convertDocument(sourceUrl: url, targetExtension: targetExt)
                outputUrls.append(out)

            case .spreadsheet:
                let out = try convertSpreadsheet(sourceUrl: url, targetExtension: targetExt)
                outputUrls.append(out)

            case .slides:
                let out = try convertDocument(sourceUrl: url, targetExtension: targetExt)
                outputUrls.append(out)

            case .subtitles:
                let out = try convertSubtitle(sourceUrl: url, targetExtension: targetExt)
                outputUrls.append(out)

            case .archive:
                if action.id == "arch_extract" {
                    let out = try extractArchive(url: url)
                    outputUrls.append(out)
                } else {
                    let out = try createArchive(sourceUrls: [url], format: targetExt)
                    outputUrls.append(out)
                }

            case .folder:
                let out = try createArchive(sourceUrls: [url], format: targetExt)
                outputUrls.append(out)

            case .other:
                let out = try createArchive(sourceUrls: [url], format: targetExt)
                outputUrls.append(out)
            }
        }

        return outputUrls
    }

    // MARK: - File Tools

    private func handleTool(action: RadialAction, urls: [URL]) throws -> [URL] {
        var outputUrls: [URL] = []

        switch action.id {
        case "tool_compress", "tool_pdf_compress":
            for url in urls {
                let category = FileInspector.category(for: url)
                if category == .image {
                    let out = try compressImage(sourceUrl: url)
                    outputUrls.append(out)
                } else if category == .pdf {
                    let out = try compressPDF(pdfUrl: url)
                    outputUrls.append(out)
                }
            }

        case "tool_resize_half":
            for url in urls {
                let out = try resizeImage(sourceUrl: url, scale: 0.5)
                outputUrls.append(out)
            }

        case "tool_rotate_cw":
            for url in urls {
                let out = try rotateImage(sourceUrl: url, degrees: 90)
                outputUrls.append(out)
            }

        case "tool_grayscale", "tool_pdf_bw":
            for url in urls {
                let out = try convertToGrayscale(sourceUrl: url)
                outputUrls.append(out)
            }

        case "tool_strip_exif", "tool_strip_meta":
            for url in urls {
                let out = try stripImageMetadata(sourceUrl: url)
                outputUrls.append(out)
            }

        case "tool_merge_pdf":
            let out = try createPDFFromImages(imageUrls: urls)
            outputUrls.append(out)

        case "tool_pdf_merge":
            let out = try mergePDFs(pdfUrls: urls)
            outputUrls.append(out)

        case "tool_pdf_split":
            for url in urls {
                let outs = try splitPDFPages(pdfUrl: url)
                outputUrls.append(contentsOf: outs)
            }

        case "tool_vid_compress":
            for url in urls {
                let out = try transcodeVideo(videoUrl: url, targetExtension: "mp4", preset: AVAssetExportPreset1280x720)
                outputUrls.append(out)
            }

        case "tool_vid_mute":
            for url in urls {
                let out = try muteVideo(videoUrl: url)
                outputUrls.append(out)
            }

        case "tool_vid_trim30", "tool_aud_trim":
            for url in urls {
                let out = try trimMedia(mediaUrl: url, seconds: 30)
                outputUrls.append(out)
            }

        case "tool_vid_extract_audio":
            for url in urls {
                let out = try extractAudioFromVideo(videoUrl: url, format: "m4a")
                outputUrls.append(out)
            }

        case "tool_archive_zip":
            let out = try createArchive(sourceUrls: urls, format: "zip")
            outputUrls.append(out)

        default:
            throw NSError(domain: "Tangerine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Tool action '\(action.id)' not implemented"])
        }

        return outputUrls
    }

    // MARK: - File Actions

    private func handleAction(action: RadialAction, urls: [URL]) throws -> String {
        switch action.id {
        case "act_airdrop":
            DispatchQueue.main.async {
                if let service = NSSharingService(named: .sendViaAirDrop) {
                    service.perform(withItems: urls)
                }
            }
            return "AirDrop sheet opened"

        case "act_quicklook":
            DispatchQueue.main.async {
                for url in urls {
                    NSWorkspace.shared.open(url)
                }
            }
            return "Opened preview"

        case "act_copy":
            DispatchQueue.main.async {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects(urls as [NSPasteboardWriting])
            }
            return "Copied \(urls.count) file\(urls.count == 1 ? "" : "s") to clipboard"

        case "act_copypath":
            DispatchQueue.main.async {
                let paths = urls.map { $0.path }.joined(separator: "\n")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(paths, forType: .string)
            }
            return "Copied path to clipboard"

        case "act_terminal":
            DispatchQueue.main.async {
                for url in urls {
                    let folder = url.hasDirectoryPath ? url.path : url.deletingLastPathComponent().path
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                    process.arguments = ["-a", "Terminal", folder]
                    try? process.run()
                }
            }
            return "Opened in Terminal"

        case "act_trash":
            for url in urls {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            }
            return "Moved \(urls.count) file\(urls.count == 1 ? "" : "s") to Trash"

        default:
            return "Action performed"
        }
    }

    // MARK: - Native Helpers: Image Processing

    private func destinationURL(for sourceUrl: URL, newExtension: String, suffix: String = "") -> URL {
        let folder = sourceUrl.deletingLastPathComponent()
        let nameWithoutExt = sourceUrl.deletingPathExtension().lastPathComponent
        let newName = "\(nameWithoutExt)\(suffix).\(newExtension)"
        var finalUrl = folder.appendingPathComponent(newName)

        // Prevent overwriting original file
        var counter = 1
        while FileManager.default.fileExists(atPath: finalUrl.path) && finalUrl.path == sourceUrl.path {
            finalUrl = folder.appendingPathComponent("\(nameWithoutExt)\(suffix)_\(counter).\(newExtension)")
            counter += 1
        }
        return finalUrl
    }

    private func convertImage(sourceUrl: URL, targetExtension: String) throws -> URL {
        let outUrl = destinationURL(for: sourceUrl, newExtension: targetExtension)

        // Try CGImageSource / CGImageDestination first
        if let imageSource = CGImageSourceCreateWithURL(sourceUrl as CFURL, nil),
           let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {

            let targetUTType: UTType
            switch targetExtension.lowercased() {
            case "png": targetUTType = .png
            case "jpg", "jpeg": targetUTType = .jpeg
            case "webp": targetUTType = UTType(filenameExtension: "webp") ?? .png
            case "heic": targetUTType = .heic
            case "tiff", "tif": targetUTType = .tiff
            case "bmp": targetUTType = .bmp
            case "gif": targetUTType = .gif
            case "pdf": targetUTType = .pdf
            default: targetUTType = .png
            }

            if let destination = CGImageDestinationCreateWithURL(outUrl as CFURL, targetUTType.identifier as CFString, 1, nil) {
                CGImageDestinationAddImage(destination, image, nil)
                if CGImageDestinationFinalize(destination) {
                    return outUrl
                }
            }
        }

        // Fallback to macOS sips
        return try runSipsConversion(sourceUrl: sourceUrl, targetExt: targetExtension)
    }

    private func runSipsConversion(sourceUrl: URL, targetExt: String) throws -> URL {
        let outUrl = destinationURL(for: sourceUrl, newExtension: targetExt)

        var sipsFormat = targetExt.lowercased()
        if sipsFormat == "jpg" { sipsFormat = "jpeg" }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        process.arguments = ["-s", "format", sipsFormat, sourceUrl.path, "--out", outUrl.path]

        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: outUrl.path) {
            return outUrl
        } else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errorData, encoding: .utf8) ?? "sips failed"
            throw NSError(domain: "Tangerine", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errMsg])
        }
    }

    private func compressImage(sourceUrl: URL) throws -> URL {
        let ext = sourceUrl.pathExtension.isEmpty ? "jpg" : sourceUrl.pathExtension
        let outUrl = destinationURL(for: sourceUrl, newExtension: ext, suffix: "-compressed")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        process.arguments = ["-s", "formatOptions", "70", sourceUrl.path, "--out", outUrl.path]
        try process.run()
        process.waitUntilExit()

        return FileManager.default.fileExists(atPath: outUrl.path) ? outUrl : sourceUrl
    }

    private func resizeImage(sourceUrl: URL, scale: CGFloat) throws -> URL {
        guard let imageSource = CGImageSourceCreateWithURL(sourceUrl as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw NSError(domain: "Tangerine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to read image for resize"])
        }

        let newWidth = Int(CGFloat(image.width) * scale)
        let newHeight = Int(CGFloat(image.height) * scale)
        let ext = sourceUrl.pathExtension
        let outUrl = destinationURL(for: sourceUrl, newExtension: ext, suffix: "-50pct")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        process.arguments = ["-z", "\(newHeight)", "\(newWidth)", sourceUrl.path, "--out", outUrl.path]
        try process.run()
        process.waitUntilExit()

        return outUrl
    }

    private func rotateImage(sourceUrl: URL, degrees: Int) throws -> URL {
        let ext = sourceUrl.pathExtension
        let outUrl = destinationURL(for: sourceUrl, newExtension: ext, suffix: "-rot\(degrees)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        process.arguments = ["-r", "\(degrees)", sourceUrl.path, "--out", outUrl.path]
        try process.run()
        process.waitUntilExit()

        return outUrl
    }

    private func convertToGrayscale(sourceUrl: URL) throws -> URL {
        let ext = sourceUrl.pathExtension
        let outUrl = destinationURL(for: sourceUrl, newExtension: ext, suffix: "-gray")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        process.arguments = ["-m", "/System/Library/ColorSync/Profiles/Generic Gray Profile.icc", sourceUrl.path, "--out", outUrl.path]
        try process.run()
        process.waitUntilExit()

        return outUrl
    }

    private func stripImageMetadata(sourceUrl: URL) throws -> URL {
        let ext = sourceUrl.pathExtension
        let outUrl = destinationURL(for: sourceUrl, newExtension: ext, suffix: "-clean")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        process.arguments = ["-d", "profile", "--deleteColorManagementProperties", sourceUrl.path, "--out", outUrl.path]
        try process.run()
        process.waitUntilExit()

        return outUrl
    }

    // MARK: - Native Helpers: PDF Operations

    private func convertPDFToImages(pdfUrl: URL, format: String) throws -> [URL] {
        guard let doc = PDFDocument(url: pdfUrl) else {
            throw NSError(domain: "Tangerine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to open PDF"])
        }

        var results: [URL] = []
        let baseFolder = pdfUrl.deletingLastPathComponent()
        let baseName = pdfUrl.deletingPathExtension().lastPathComponent

        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            let pageRect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 3.0 // ~300 DPI
            let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let image = NSImage(size: scaledSize, flipped: false) { rect in
                guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
                ctx.setFillColor(NSColor.white.cgColor)
                ctx.fill(rect)
                ctx.saveGState()
                ctx.scaleBy(x: scale, y: scale)
                page.draw(with: .mediaBox, to: ctx)
                ctx.restoreGState()
                return true
            }

            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData) else { continue }

            let outUrl = baseFolder.appendingPathComponent("\(baseName)_page_\(i + 1).\(format)")
            let imgType: NSBitmapImageRep.FileType = (format.lowercased() == "jpg" || format.lowercased() == "jpeg") ? .jpeg : .png
            if let data = bitmap.representation(using: imgType, properties: [:]) {
                try data.write(to: outUrl)
                results.append(outUrl)
            }
        }

        return results
    }

    private func splitPDFPages(pdfUrl: URL) throws -> [URL] {
        guard let doc = PDFDocument(url: pdfUrl) else {
            throw NSError(domain: "Tangerine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to read PDF for splitting"])
        }

        var results: [URL] = []
        let baseFolder = pdfUrl.deletingLastPathComponent()
        let baseName = pdfUrl.deletingPathExtension().lastPathComponent

        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            let singleDoc = PDFDocument()
            singleDoc.insert(page, at: 0)

            let outUrl = baseFolder.appendingPathComponent("\(baseName)_page_\(i + 1).pdf")
            singleDoc.write(to: outUrl)
            results.append(outUrl)
        }

        return results
    }

    private func mergePDFs(pdfUrls: [URL]) throws -> URL {
        let merged = PDFDocument()
        var pageIndex = 0

        for url in pdfUrls {
            guard let doc = PDFDocument(url: url) else { continue }
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    merged.insert(page, at: pageIndex)
                    pageIndex += 1
                }
            }
        }

        let first = pdfUrls.first ?? URL(fileURLWithPath: "/tmp/merged.pdf")
        let outUrl = destinationURL(for: first, newExtension: "pdf", suffix: "-merged")
        merged.write(to: outUrl)
        return outUrl
    }

    private func createPDFFromImages(imageUrls: [URL]) throws -> URL {
        let doc = PDFDocument()
        var index = 0

        for url in imageUrls {
            if let image = NSImage(contentsOf: url),
               let page = PDFPage(image: image) {
                doc.insert(page, at: index)
                index += 1
            }
        }

        let first = imageUrls.first ?? URL(fileURLWithPath: "/tmp/images.pdf")
        let outUrl = destinationURL(for: first, newExtension: "pdf", suffix: "-combined")
        doc.write(to: outUrl)
        return outUrl
    }

    private func extractTextFromPDF(pdfUrl: URL) throws -> URL {
        return try convertPDFToDocument(pdfUrl: pdfUrl, targetExtension: "txt")
    }

    private func convertPDFToDocument(pdfUrl: URL, targetExtension: String) throws -> URL {
        guard let pdfDoc = PDFDocument(url: pdfUrl) else {
            throw NSError(domain: "Tangerine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to load PDF document"])
        }

        let combined = NSMutableAttributedString()
        let pageCount = pdfDoc.pageCount

        for i in 0..<pageCount {
            guard let page = pdfDoc.page(at: i) else { continue }
            var pageTextFound = false

            if let attr = page.attributedString, attr.length > 0 {
                combined.append(attr)
                pageTextFound = true
            } else if let str = page.string, !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                combined.append(NSAttributedString(string: str, attributes: [
                    .font: NSFont.systemFont(ofSize: 12)
                ]))
                pageTextFound = true
            }

            // Fallback to Vision OCR if this page had no selectable text layer (e.g. scanned)
            if !pageTextFound {
                let ocrText = extractTextWithOCR(from: page)
                if !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    combined.append(NSAttributedString(string: ocrText, attributes: [
                        .font: NSFont.systemFont(ofSize: 12)
                    ]))
                    pageTextFound = true
                }
            }

            if i < pageCount - 1 {
                combined.append(NSAttributedString(string: "\n\n"))
            }
        }

        if combined.length == 0 {
            combined.append(NSAttributedString(string: "PDF document contains no readable text.", attributes: [
                .font: NSFont.systemFont(ofSize: 12)
            ]))
        }

        let ext = targetExtension.lowercased()
        let outUrl = destinationURL(for: pdfUrl, newExtension: ext)

        switch ext {
        case "doc":
            do {
                let docData = try combined.data(
                    from: NSRange(location: 0, length: combined.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.docFormat]
                )
                try docData.write(to: outUrl)
                return outUrl
            } catch {
                return try convertViaTextutil(attributed: combined, to: "doc", outUrl: outUrl)
            }

        case "docx", "pages":
            let actualOut = ext == "pages" ? destinationURL(for: pdfUrl, newExtension: "docx") : outUrl
            return try convertViaTextutil(attributed: combined, to: "docx", outUrl: actualOut)

        case "rtf":
            let rtfData = try combined.data(
                from: NSRange(location: 0, length: combined.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            try rtfData.write(to: outUrl)
            return outUrl

        case "odt":
            return try convertViaTextutil(attributed: combined, to: "odt", outUrl: outUrl)

        case "html", "htm":
            return try convertViaTextutil(attributed: combined, to: "html", outUrl: outUrl)

        case "txt":
            try combined.string.write(to: outUrl, atomically: true, encoding: .utf8)
            return outUrl

        case "md", "markdown":
            let title = pdfUrl.deletingPathExtension().lastPathComponent
            let content = "# \(title)\n\n" + combined.string
            try content.write(to: outUrl, atomically: true, encoding: .utf8)
            return outUrl

        case "xlsx", "csv":
            let lines = combined.string.components(separatedBy: .newlines)
            let csv = lines.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: "\n")
            let csvUrl = destinationURL(for: pdfUrl, newExtension: "csv")
            try csv.write(to: csvUrl, atomically: true, encoding: .utf8)
            return csvUrl

        default:
            return try convertViaTextutil(attributed: combined, to: "docx", outUrl: outUrl)
        }
    }

    private func extractTextWithOCR(from page: PDFPage) -> String {
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0
        let size = CGSize(width: max(pageRect.width * scale, 100), height: max(pageRect.height * scale, 100))

        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(rect)
            ctx.saveGState()
            ctx.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx)
            ctx.restoreGState()
            return true
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ""
        }

        var recognizedText = ""
        let request = VNRecognizeTextRequest { req, _ in
            guard let observations = req.results as? [VNRecognizedTextObservation] else { return }
            let strings = observations.compactMap { $0.topCandidates(1).first?.string }
            recognizedText = strings.joined(separator: "\n")
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        return recognizedText
    }

    private func convertViaTextutil(attributed: NSAttributedString, to format: String, outUrl: URL) throws -> URL {
        let tempRtfUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".rtf")
        defer { try? FileManager.default.removeItem(at: tempRtfUrl) }

        let rtfData = try attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        try rtfData.write(to: tempRtfUrl)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        process.arguments = ["-convert", format, tempRtfUrl.path, "-output", outUrl.path]
        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: outUrl.path) {
            return outUrl
        } else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errorData, encoding: .utf8) ?? "Failed to convert document to \(format)"
            throw NSError(domain: "Tangerine", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errMsg])
        }
    }

    private func compressPDF(pdfUrl: URL) throws -> URL {
        // PDFKit compression / draw pass
        guard let doc = PDFDocument(url: pdfUrl) else {
            throw NSError(domain: "Tangerine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to compress PDF"])
        }
        let outUrl = destinationURL(for: pdfUrl, newExtension: "pdf", suffix: "-compressed")
        doc.write(to: outUrl)
        return outUrl
    }

    // MARK: - Native Helpers: Video & Audio

    public static var ffmpegPath: String? {
        let candidates = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func runFFmpeg(sourceUrl: URL, targetExtension: String) throws -> URL {
        guard let ffmpeg = Self.ffmpegPath else {
            throw NSError(domain: "Tangerine", code: 404, userInfo: [NSLocalizedDescriptionKey: "Conversion to \(targetExtension.uppercased()) requires ffmpeg. Run: brew install ffmpeg"])
        }
        let outUrl = destinationURL(for: sourceUrl, newExtension: targetExtension)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = ["-y", "-i", sourceUrl.path, outUrl.path]
        try process.run()
        process.waitUntilExit()

        if FileManager.default.fileExists(atPath: outUrl.path) {
            return outUrl
        } else {
            throw NSError(domain: "Tangerine", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "FFmpeg conversion to \(targetExtension.uppercased()) failed"])
        }
    }

    private func transcodeVideo(videoUrl: URL, targetExtension: String, preset: String = AVAssetExportPresetHighestQuality) throws -> URL {
        let ext = targetExtension.lowercased()
        let inExt = videoUrl.pathExtension.lowercased()

        // Non-Apple video formats rely on FFmpeg
        if ["mkv", "avi", "wmv", "webm", "gif"].contains(ext) || ["mkv", "avi", "wmv", "webm"].contains(inExt) {
            if let _ = Self.ffmpegPath {
                return try runFFmpeg(sourceUrl: videoUrl, targetExtension: targetExtension)
            }
        }

        let asset = AVAsset(url: videoUrl)
        let outUrl = destinationURL(for: videoUrl, newExtension: targetExtension)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            if let _ = Self.ffmpegPath {
                return try runFFmpeg(sourceUrl: videoUrl, targetExtension: targetExtension)
            }
            throw NSError(domain: "Tangerine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession"])
        }

        exportSession.outputURL = outUrl
        exportSession.outputFileType = targetExtension.lowercased() == "mov" ? .mov : .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        let semaphore = DispatchSemaphore(value: 0)
        var exportError: Error?

        exportSession.exportAsynchronously {
            if exportSession.status != .completed {
                exportError = exportSession.error ?? NSError(domain: "Tangerine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Video export failed with status \(exportSession.status.rawValue)"])
            }
            semaphore.signal()
        }

        semaphore.wait()
        if let err = exportError { throw err }
        return outUrl
    }

    private func extractAudioFromVideo(videoUrl: URL, format: String) throws -> URL {
        let asset = AVAsset(url: videoUrl)
        let outUrl = destinationURL(for: videoUrl, newExtension: format == "mp3" ? "m4a" : format) // AVFoundation exports m4a/aac natively

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "Tangerine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio export session"])
        }

        exportSession.outputURL = outUrl
        exportSession.outputFileType = .m4a

        let semaphore = DispatchSemaphore(value: 0)
        var exportError: Error?

        exportSession.exportAsynchronously {
            if exportSession.status != .completed {
                exportError = exportSession.error
            }
            semaphore.signal()
        }

        semaphore.wait()
        if let err = exportError { throw err }
        return outUrl
    }

    private func extractPosterFrame(videoUrl: URL) throws -> URL {
        let asset = AVAsset(url: videoUrl)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 1, preferredTimescale: 60)
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        let outUrl = destinationURL(for: videoUrl, newExtension: "jpg", suffix: "-poster")

        guard let destination = CGImageDestinationCreateWithURL(outUrl as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw NSError(domain: "Tangerine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create poster image destination"])
        }

        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)
        return outUrl
    }

    private func muteVideo(videoUrl: URL) throws -> URL {
        let asset = AVAsset(url: videoUrl)
        let composition = AVMutableComposition()

        if let videoTrack = asset.tracks(withMediaType: .video).first {
            let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
            compVideoTrack?.preferredTransform = videoTrack.preferredTransform
        }

        let outUrl = destinationURL(for: videoUrl, newExtension: "mp4", suffix: "-muted")
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "Tangerine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to mute video export"])
        }

        exportSession.outputURL = outUrl
        exportSession.outputFileType = .mp4

        let semaphore = DispatchSemaphore(value: 0)
        var exportError: Error?

        exportSession.exportAsynchronously {
            if exportSession.status != .completed {
                exportError = exportSession.error
            }
            semaphore.signal()
        }

        semaphore.wait()
        if let err = exportError { throw err }
        return outUrl
    }

    private func trimMedia(mediaUrl: URL, seconds: Double) throws -> URL {
        let asset = AVAsset(url: mediaUrl)
        let duration = min(seconds, CMTimeGetSeconds(asset.duration))
        let timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600))

        let ext = mediaUrl.pathExtension.isEmpty ? "mp4" : mediaUrl.pathExtension
        let outUrl = destinationURL(for: mediaUrl, newExtension: ext, suffix: "-trim\(Int(duration))s")

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw NSError(domain: "Tangerine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create trim session"])
        }

        exportSession.outputURL = outUrl
        exportSession.outputFileType = AVFileType(rawValue: "com.apple.quicktime-movie")
        exportSession.timeRange = timeRange

        let semaphore = DispatchSemaphore(value: 0)
        var exportError: Error?

        exportSession.exportAsynchronously {
            if exportSession.status != .completed {
                exportError = exportSession.error
            }
            semaphore.signal()
        }

        semaphore.wait()
        if let err = exportError { throw err }
        return outUrl
    }

    private func transcodeAudio(audioUrl: URL, targetExtension: String) throws -> URL {
        let ext = targetExtension.lowercased()
        let inExt = audioUrl.pathExtension.lowercased()

        // Non-Apple audio formats rely on FFmpeg
        if ["mp3", "flac", "ogg", "opus", "wma"].contains(ext) || ["flac", "ogg", "opus", "wma"].contains(inExt) {
            if let _ = Self.ffmpegPath {
                return try runFFmpeg(sourceUrl: audioUrl, targetExtension: targetExtension)
            }
        }

        let asset = AVAsset(url: audioUrl)
        let outUrl = destinationURL(for: audioUrl, newExtension: targetExtension)

        let preset: String
        let fileType: AVFileType

        switch targetExtension.lowercased() {
        case "m4a", "aac":
            preset = AVAssetExportPresetAppleM4A
            fileType = .m4a
        default:
            preset = AVAssetExportPresetAppleM4A
            fileType = .m4a
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            if let _ = Self.ffmpegPath {
                return try runFFmpeg(sourceUrl: audioUrl, targetExtension: targetExtension)
            }
            throw NSError(domain: "Tangerine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to transcode audio"])
        }

        exportSession.outputURL = outUrl
        exportSession.outputFileType = fileType

        let semaphore = DispatchSemaphore(value: 0)
        var exportError: Error?

        exportSession.exportAsynchronously {
            if exportSession.status != .completed {
                exportError = exportSession.error
            }
            semaphore.signal()
        }

        semaphore.wait()
        if let err = exportError { throw err }
        return outUrl
    }

    private func convertSpreadsheet(sourceUrl: URL, targetExtension: String) throws -> URL {
        let text = try String(contentsOf: sourceUrl, encoding: .utf8)
        let outUrl = destinationURL(for: sourceUrl, newExtension: targetExtension)
        let ext = targetExtension.lowercased()

        if ext == "tsv" {
            let tsv = text.replacingOccurrences(of: ",", with: "\t")
            try tsv.write(to: outUrl, atomically: true, encoding: .utf8)
            return outUrl
        } else if ext == "csv" {
            let csv = text.replacingOccurrences(of: "\t", with: ",")
            try csv.write(to: outUrl, atomically: true, encoding: .utf8)
            return outUrl
        } else if ext == "pdf" {
            return try convertDocument(sourceUrl: sourceUrl, targetExtension: "pdf")
        } else {
            return try convertDocument(sourceUrl: sourceUrl, targetExtension: targetExtension)
        }
    }

    // MARK: - Native Helpers: Documents & textutil

    private func convertDocument(sourceUrl: URL, targetExtension: String) throws -> URL {
        let ext = targetExtension.lowercased()
        let srcExt = sourceUrl.pathExtension.lowercased()
        let outUrl = destinationURL(for: sourceUrl, newExtension: ext)

        // 1. Export to PDF
        if ext == "pdf" {
            return try exportDocumentToPDF(sourceUrl: sourceUrl, outUrl: outUrl)
        }

        // 2. Render document pages as JPG or PNG
        if ext == "jpg" || ext == "png" {
            let tempPdf = destinationURL(for: sourceUrl, newExtension: "pdf", suffix: "-temp")
            let generatedPdf = try exportDocumentToPDF(sourceUrl: sourceUrl, outUrl: tempPdf)
            defer { try? FileManager.default.removeItem(at: generatedPdf) }
            let images = try convertPDFToImages(pdfUrl: generatedPdf, format: ext)
            return images.first ?? outUrl
        }

        // 3. Export to Markdown
        if ext == "md" || ext == "markdown" {
            return try exportDocumentToMarkdown(sourceUrl: sourceUrl, outUrl: outUrl)
        }

        // 4. Export to EPUB
        if ext == "epub" {
            return try exportDocumentToEPUB(sourceUrl: sourceUrl, outUrl: outUrl)
        }

        // 5. Export to Apple Pages
        if ext == "pages" {
            return try exportDocumentToPages(sourceUrl: sourceUrl, outUrl: outUrl)
        }

        // 6. Source is EPUB or Pages converting to textutil format (docx, doc, rtf, txt, html, odt)
        if srcExt == "epub" || srcExt == "pages" {
            let attr = try loadDocumentAttributedString(sourceUrl: sourceUrl)
            return try convertViaTextutil(attributed: attr, to: ext, outUrl: outUrl)
        }

        // 7. Source is Markdown converting to textutil format (docx, doc, rtf, txt, html, odt)
        if srcExt == "md" || srcExt == "markdown" {
            let attr = try loadDocumentAttributedString(sourceUrl: sourceUrl)
            return try convertViaTextutil(attributed: attr, to: ext, outUrl: outUrl)
        }

        // 8. Standard conversion via textutil (docx, doc, rtf, rtfd, html, txt, odt)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        process.arguments = ["-convert", ext, sourceUrl.path, "-output", outUrl.path]
        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: outUrl.path) {
            return outUrl
        } else {
            // Fallback: try loading attributed string and converting via RTF bridge
            if let attr = try? loadDocumentAttributedString(sourceUrl: sourceUrl) {
                if let fallbackUrl = try? convertViaTextutil(attributed: attr, to: ext, outUrl: outUrl) {
                    return fallbackUrl
                }
            }
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errorData, encoding: .utf8) ?? "Failed to convert document to \(ext)"
            throw NSError(domain: "Tangerine", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errMsg])
        }
    }

    private func loadDocumentAttributedString(sourceUrl: URL) throws -> NSAttributedString {
        let srcExt = sourceUrl.pathExtension.lowercased()

        // 1. Markdown
        if srcExt == "md" || srcExt == "markdown" {
            let text = (try? String(contentsOf: sourceUrl, encoding: .utf8)) ??
                       (try? String(contentsOf: sourceUrl, encoding: .isoLatin1)) ?? ""
            if let attr = try? NSAttributedString(markdown: text) {
                return attr
            }
            return NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 12)])
        }

        // 2. EPUB
        if srcExt == "epub" {
            let extractedHtml = (try? extractHtmlFromEPUB(epubUrl: sourceUrl)) ?? ""
            if let data = extractedHtml.data(using: .utf8),
               let attr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                return attr
            }
            return NSAttributedString(string: extractedHtml, attributes: [.font: NSFont.systemFont(ofSize: 12)])
        }

        // 3. Pages document
        if srcExt == "pages" {
            if let previewPdf = extractPagesPreviewPDF(pagesUrl: sourceUrl),
               let pdfDoc = PDFDocument(url: previewPdf) {
                defer { try? FileManager.default.removeItem(at: previewPdf) }
                let combined = NSMutableAttributedString()
                for i in 0..<pdfDoc.pageCount {
                    if let page = pdfDoc.page(at: i), let attr = page.attributedString {
                        combined.append(attr)
                        combined.append(NSAttributedString(string: "\n\n"))
                    }
                }
                if combined.length > 0 {
                    return combined
                }
            }
        }

        // 4. Standard RTF, HTML, TXT, DOC, DOCX
        do {
            return try NSAttributedString(url: sourceUrl, options: [:], documentAttributes: nil)
        } catch {
            // Try via textutil converting to temporary RTF
            let tempRtf = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".rtf")
            defer { try? FileManager.default.removeItem(at: tempRtf) }

            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
            p.arguments = ["-convert", "rtf", sourceUrl.path, "-output", tempRtf.path]
            try? p.run()
            p.waitUntilExit()

            if FileManager.default.fileExists(atPath: tempRtf.path),
               let rtfAttr = try? NSAttributedString(url: tempRtf, options: [:], documentAttributes: nil) {
                return rtfAttr
            }

            // Fallback: raw text read
            let rawText = (try? String(contentsOf: sourceUrl, encoding: .utf8)) ??
                          (try? String(contentsOf: sourceUrl, encoding: .isoLatin1)) ?? ""
            return NSAttributedString(string: rawText, attributes: [.font: NSFont.systemFont(ofSize: 12)])
        }
    }

    private func exportDocumentToPDF(sourceUrl: URL, outUrl: URL) throws -> URL {
        let srcExt = sourceUrl.pathExtension.lowercased()
        if srcExt == "pages", let previewPdf = extractPagesPreviewPDF(pagesUrl: sourceUrl) {
            defer { try? FileManager.default.removeItem(at: previewPdf) }
            try? FileManager.default.removeItem(at: outUrl)
            try FileManager.default.copyItem(at: previewPdf, to: outUrl)
            return outUrl
        }
        let attr = try loadDocumentAttributedString(sourceUrl: sourceUrl)
        return try exportAttributedStringToPDF(attr: attr, outUrl: outUrl)
    }

    private func exportAttributedStringToPDF(attr: NSAttributedString, outUrl: URL) throws -> URL {
        let pdfData = NSMutableData()
        var pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 54
        let printableRect = CGRect(x: margin, y: margin, width: pageRect.width - (margin * 2), height: pageRect.height - (margin * 2))

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &pageRect, nil) else {
            throw NSError(domain: "Tangerine", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF context"])
        }

        let contentAttr = attr.length > 0 ? attr : NSAttributedString(string: "Empty Document", attributes: [.font: NSFont.systemFont(ofSize: 12)])
        let framesetter = CTFramesetterCreateWithAttributedString(contentAttr as CFAttributedString)
        var textRange = CFRange(location: 0, length: 0)

        while textRange.location < contentAttr.length {
            ctx.beginPage(mediaBox: &pageRect)
            let path = CGPath(rect: printableRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, textRange, path, nil)
            CTFrameDraw(frame, ctx)
            let frameRange = CTFrameGetVisibleStringRange(frame)
            if frameRange.length == 0 {
                ctx.endPage()
                break
            }
            textRange.location += frameRange.length
            ctx.endPage()
        }

        ctx.closePDF()
        try (pdfData as Data).write(to: outUrl)
        return outUrl
    }

    private func exportDocumentToMarkdown(sourceUrl: URL, outUrl: URL) throws -> URL {
        let attr = try loadDocumentAttributedString(sourceUrl: sourceUrl)
        let title = sourceUrl.deletingPathExtension().lastPathComponent
        let content = "# \(title)\n\n" + attr.string
        try content.write(to: outUrl, atomically: true, encoding: .utf8)
        return outUrl
    }

    private func exportDocumentToEPUB(sourceUrl: URL, outUrl: URL) throws -> URL {
        let attr = try loadDocumentAttributedString(sourceUrl: sourceUrl)
        let title = sourceUrl.deletingPathExtension().lastPathComponent

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let metaInf = tempDir.appendingPathComponent("META-INF")
        let oebps = tempDir.appendingPathComponent("OEBPS")
        try FileManager.default.createDirectory(at: metaInf, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: oebps, withIntermediateDirectories: true)

        // 1. mimetype (must be first, uncompressed in epub)
        try "application/epub+zip".write(to: tempDir.appendingPathComponent("mimetype"), atomically: true, encoding: .ascii)

        // 2. container.xml
        let containerXml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
            <rootfiles>
                <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
            </rootfiles>
        </container>
        """
        try containerXml.write(to: metaInf.appendingPathComponent("container.xml"), atomically: true, encoding: .utf8)

        // 3. content.opf
        let opf = """
        <?xml version="1.0" encoding="UTF-8"?>
        <package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookID" version="3.0">
            <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
                <dc:title>\(title)</dc:title>
                <dc:language>en</dc:language>
                <dc:identifier id="BookID">urn:uuid:\(UUID().uuidString)</dc:identifier>
            </metadata>
            <manifest>
                <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
            </manifest>
            <spine>
                <itemref idref="chapter1"/>
            </spine>
        </package>
        """
        try opf.write(to: oebps.appendingPathComponent("content.opf"), atomically: true, encoding: .utf8)

        // 4. chapter1.xhtml
        let paragraphs = attr.string.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { "<p>\($0.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</p>" }
            .joined(separator: "\n")

        let xhtml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head><title>\(title)</title></head>
        <body>
        <h1>\(title)</h1>
        \(paragraphs)
        </body>
        </html>
        """
        try xhtml.write(to: oebps.appendingPathComponent("chapter1.xhtml"), atomically: true, encoding: .utf8)

        try? FileManager.default.removeItem(at: outUrl)

        // Zip mimetype first with no compression (-0 -X)
        let zipMime = Process()
        zipMime.currentDirectoryURL = tempDir
        zipMime.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        zipMime.arguments = ["-X", "-0", outUrl.path, "mimetype"]
        try zipMime.run()
        zipMime.waitUntilExit()

        // Zip remainder
        let zipRest = Process()
        zipRest.currentDirectoryURL = tempDir
        zipRest.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        zipRest.arguments = ["-r", outUrl.path, "META-INF", "OEBPS"]
        try zipRest.run()
        zipRest.waitUntilExit()

        return outUrl
    }

    private func exportDocumentToPages(sourceUrl: URL, outUrl: URL) throws -> URL {
        if FileManager.default.fileExists(atPath: "/Applications/Pages.app") {
            let tempDocx = destinationURL(for: sourceUrl, newExtension: "docx", suffix: "-pages-temp")
            let generatedDocx = try convertDocument(sourceUrl: sourceUrl, targetExtension: "docx")
            defer { try? FileManager.default.removeItem(at: generatedDocx) }

            let script = """
            tell application "Pages"
                set myDoc to open POSIX file "\(generatedDocx.path)"
                save myDoc in POSIX file "\(outUrl.path)"
                close myDoc saving no
            end tell
            """
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                if error == nil && FileManager.default.fileExists(atPath: outUrl.path) {
                    return outUrl
                }
            }
        }
        // Fallback: Export as DOCX (natively supported by Apple Pages)
        return try convertDocument(sourceUrl: sourceUrl, targetExtension: "docx")
    }

    private func extractHtmlFromEPUB(epubUrl: URL) throws -> String {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments = ["-q", epubUrl.path, "-d", tempDir.path]
        try? unzip.run()
        unzip.waitUntilExit()

        var combinedHtml = ""
        if let enumerator = FileManager.default.enumerator(at: tempDir, includingPropertiesForKeys: nil) {
            for case let fileUrl as URL in enumerator {
                let ext = fileUrl.pathExtension.lowercased()
                if ext == "xhtml" || ext == "html" || ext == "htm" {
                    if let text = try? String(contentsOf: fileUrl, encoding: .utf8) {
                        combinedHtml += text + "\n"
                    }
                }
            }
        }
        return combinedHtml
    }

    private func extractPagesPreviewPDF(pagesUrl: URL) -> URL? {
        let tempPdf = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: pagesUrl.path, isDirectory: &isDir), isDir.boolValue {
            let preview = pagesUrl.appendingPathComponent("QuickLook/Preview.pdf")
            if FileManager.default.fileExists(atPath: preview.path) {
                try? FileManager.default.copyItem(at: preview, to: tempPdf)
                return tempPdf
            }
        } else {
            // It's a zipped .pages bundle
            let unzip = Process()
            unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            unzip.arguments = ["-p", pagesUrl.path, "QuickLook/Preview.pdf"]
            let pipe = Pipe()
            unzip.standardOutput = pipe
            try? unzip.run()
            unzip.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if data.count > 0 {
                try? data.write(to: tempPdf)
                return tempPdf
            }
        }
        return nil
    }

    private func convertSubtitle(sourceUrl: URL, targetExtension: String) throws -> URL {
        let text = try String(contentsOf: sourceUrl, encoding: .utf8)
        let outUrl = destinationURL(for: sourceUrl, newExtension: targetExtension)

        if targetExtension.lowercased() == "txt" {
            // Strip timestamp lines and numbers
            let lines = text.components(separatedBy: .newlines)
            let filtered = lines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty { return false }
                if Int(trimmed) != nil { return false }
                if trimmed.contains("-->") { return false }
                return true
            }
            try filtered.joined(separator: "\n").write(to: outUrl, atomically: true, encoding: .utf8)
        } else {
            try text.write(to: outUrl, atomically: true, encoding: .utf8)
        }

        return outUrl
    }

    // MARK: - Native Helpers: Archives

    private func createArchive(sourceUrls: [URL], format: String) throws -> URL {
        guard let first = sourceUrls.first else {
            throw NSError(domain: "Tangerine", code: 400, userInfo: [NSLocalizedDescriptionKey: "No files to archive"])
        }

        let outUrl = destinationURL(for: first, newExtension: format.lowercased().contains("tar") ? "tar.gz" : "zip")

        let process = Process()
        if format.lowercased().contains("tar") {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            var args = ["-czf", outUrl.path, "-C", first.deletingLastPathComponent().path]
            args.append(contentsOf: sourceUrls.map { $0.lastPathComponent })
            process.arguments = args
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", first.path, outUrl.path]
        }

        try process.run()
        process.waitUntilExit()

        return outUrl
    }

    private func extractArchive(url: URL) throws -> URL {
        let folderName = url.deletingPathExtension().lastPathComponent
        let outFolder = url.deletingLastPathComponent().appendingPathComponent(folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: outFolder, withIntermediateDirectories: true)

        let process = Process()
        if url.pathExtension.lowercased() == "zip" {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-x", "-k", url.path, outFolder.path]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            process.arguments = ["-xzf", url.path, "-C", outFolder.path]
        }

        try process.run()
        process.waitUntilExit()

        return outFolder
    }
}
