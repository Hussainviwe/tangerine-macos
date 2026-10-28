import Testing
import Foundation
import AppKit
@testable import Tangerine

@Test func testFileCategoryDetection() throws {
    let imgUrl = URL(fileURLWithPath: "/tmp/sample.jpg")
    #expect(FileInspector.category(for: imgUrl) == .image)

    let vidUrl = URL(fileURLWithPath: "/tmp/movie.mov")
    #expect(FileInspector.category(for: vidUrl) == .video)

    let audUrl = URL(fileURLWithPath: "/tmp/audio.mp3")
    #expect(FileInspector.category(for: audUrl) == .audio)

    let pdfUrl = URL(fileURLWithPath: "/tmp/doc.pdf")
    #expect(FileInspector.category(for: pdfUrl) == .pdf)

    let zipUrl = URL(fileURLWithPath: "/tmp/archive.zip")
    #expect(FileInspector.category(for: zipUrl) == .archive)
}

@Test func testToolRegistryActions() throws {
    let imgUrl = URL(fileURLWithPath: "/tmp/test.png")
    let convertActions = ToolRegistry.actions(for: .image, mode: .convert, urls: [imgUrl])
    #expect(!convertActions.isEmpty)
    #expect(convertActions.contains(where: { $0.targetExtension == "jpg" }))
    #expect(convertActions.contains(where: { $0.targetExtension == "webp" }))
    #expect(convertActions.contains(where: { $0.targetExtension == "avif" }))

    let toolActions = ToolRegistry.actions(for: .image, mode: .tools, urls: [imgUrl])
    #expect(toolActions.contains(where: { $0.id == "tool_compress" }))
    #expect(toolActions.contains(where: { $0.id == "tool_rotate_cw" }))

    let fileActions = ToolRegistry.actions(for: .image, mode: .actions, urls: [imgUrl])
    #expect(fileActions.contains(where: { $0.id == "act_airdrop" }))
    #expect(fileActions.contains(where: { $0.id == "act_copypath" }))
}

@Test func testFormatMatrixDefinition() throws {
    let imgMatrix = FormatMatrices.images
    #expect(imgMatrix.isSupported(row: "JPG", col: "PNG"))
    #expect(imgMatrix.isSupported(row: "SVG", col: "AVIF"))
    #expect(!imgMatrix.isSupported(row: "JPG", col: "JPG"))

    let docMatrix = FormatMatrices.documents
    #expect(docMatrix.isSupported(row: "PDF", col: "DOCX"))
    #expect(docMatrix.isSupported(row: "DOCX", col: "HTML"))

    let sheetMatrix = FormatMatrices.spreadsheets
    #expect(sheetMatrix.isSupported(row: "XLSX", col: "CSV"))
    #expect(sheetMatrix.isSupported(row: "CSV", col: "PDF"))

    let audioMatrix = FormatMatrices.audio
    #expect(audioMatrix.isSupported(row: "MP3", col: "FLAC"))
    #expect(audioMatrix.isSupported(row: "OGG", col: "WAV"))

    let vidMatrix = FormatMatrices.video
    #expect(vidMatrix.isSupported(row: "MP4", col: "MKV"))
    #expect(vidMatrix.isSupported(row: "MOV", col: "GIF"))
}

@Test func testRealImageConversionAndArchive() async throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    // Create a real 100x100 test PNG
    let pngUrl = tempDir.appendingPathComponent("test.png")
    let img = NSImage(size: NSSize(width: 100, height: 100), flipped: false) { rect in
        NSColor.orange.setFill()
        rect.fill()
        return true
    }
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        Issue.record("Failed to generate test image")
        return
    }
    try data.write(to: pngUrl)

    // Test conversion to JPG
    let jpgAction = RadialAction(id: "img_jpg", title: "JPG", description: "Convert to JPG", sfSymbol: "photo", mode: .convert, targetExtension: "jpg")
    let result = await ConversionEngine.shared.execute(action: jpgAction, urls: [pngUrl])

    switch result {
    case .success(let outputUrls, _):
        #expect(!outputUrls.isEmpty)
        guard let out = outputUrls.first else { return }
        #expect(FileManager.default.fileExists(atPath: out.path))
        #expect(out.pathExtension == "jpg")
    case .failure(let err):
        Issue.record("Conversion failed: \(err)")
    }

    // Test compression tool
    let compressAction = RadialAction(id: "tool_compress", title: "Compress", description: "Compress", sfSymbol: "arrow.down", mode: .tools)
    let compResult = await ConversionEngine.shared.execute(action: compressAction, urls: [pngUrl])
    switch compResult {
    case .success(let outputUrls, _):
        #expect(!outputUrls.isEmpty)
    case .failure(let err):
        Issue.record("Compression failed: \(err)")
    }

    // Test ZIP archive tool
    let zipAction = RadialAction(id: "tool_archive_zip", title: "ZIP", description: "Archive", sfSymbol: "archivebox", mode: .tools)
    let zipResult = await ConversionEngine.shared.execute(action: zipAction, urls: [pngUrl])
    switch zipResult {
    case .success(let outputUrls, _):
        #expect(!outputUrls.isEmpty)
        guard let zipOut = outputUrls.first else { return }
        #expect(FileManager.default.fileExists(atPath: zipOut.path))
    case .failure(let err):
        Issue.record("Zip failed: \(err)")
    }

    // Test PDF to DOCX and DOC conversion
    let pdfUrl = tempDir.appendingPathComponent("test.pdf")
    let attr = NSAttributedString(string: "Tangerine PDF to DOCX Test Document.\nTesting seamless conversion.", attributes: [
        .font: NSFont.systemFont(ofSize: 14)
    ])
    let pdfData = NSMutableData()
    var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
    if let consumer = CGDataConsumer(data: pdfData as CFMutableData),
       let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) {
        ctx.beginPage(mediaBox: &mediaBox)
        let framesetter = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)
        let path = CGPath(rect: CGRect(x: 50, y: 650, width: 500, height: 100), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attr.length), path, nil)
        CTFrameDraw(frame, ctx)
        ctx.endPage()
        ctx.closePDF()
    }
    try pdfData.write(to: pdfUrl)

    let docxAction = RadialAction(id: "pdf_docx", title: "DOCX", description: "Convert to DOCX", sfSymbol: "doc.richtext", mode: .convert, targetExtension: "docx")
    let docxRes = await ConversionEngine.shared.execute(action: docxAction, urls: [pdfUrl])
    switch docxRes {
    case .success(let outUrls, _):
        #expect(!outUrls.isEmpty)
        guard let docxOut = outUrls.first else { return }
        #expect(FileManager.default.fileExists(atPath: docxOut.path))
        #expect(docxOut.pathExtension == "docx")
    case .failure(let err):
        Issue.record("PDF -> DOCX failed: \(err)")
    }

    let docAction = RadialAction(id: "pdf_doc", title: "DOC", description: "Convert to DOC", sfSymbol: "doc.text", mode: .convert, targetExtension: "doc")
    let docRes = await ConversionEngine.shared.execute(action: docAction, urls: [pdfUrl])
    switch docRes {
    case .success(let outUrls, _):
        #expect(!outUrls.isEmpty)
        guard let docOut = outUrls.first else { return }
        #expect(FileManager.default.fileExists(atPath: docOut.path))
        #expect(docOut.pathExtension == "doc")
    case .failure(let err):
        Issue.record("PDF -> DOC failed: \(err)")
    }
}

@Test func testDocumentConversions() async throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    // 1. Create a real DOCX file
    let docxUrl = tempDir.appendingPathComponent("sample.docx")
    let txtUrl = tempDir.appendingPathComponent("sample.txt")
    try "Tangerine Native Document Test.\nSeamless offline conversions on macOS.\nBullet point 1\nBullet point 2".write(to: txtUrl, atomically: true, encoding: .utf8)

    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
    p.arguments = ["-convert", "docx", txtUrl.path, "-output", docxUrl.path]
    try p.run()
    p.waitUntilExit()
    #expect(FileManager.default.fileExists(atPath: docxUrl.path))

    // 2. Test DOCX -> PDF
    let pdfAction = RadialAction(id: "doc_pdf", title: "PDF", description: "Export to PDF", sfSymbol: "doc.text.fill", mode: .convert, targetExtension: "pdf")
    let pdfRes = await ConversionEngine.shared.execute(action: pdfAction, urls: [docxUrl])
    switch pdfRes {
    case .success(let outUrls, _):
        guard let out = outUrls.first else { Issue.record("Empty outUrls"); return }
        #expect(FileManager.default.fileExists(atPath: out.path))
        #expect(out.pathExtension == "pdf")
    case .failure(let err):
        Issue.record("DOCX -> PDF failed: \(err)")
    }

    // 3. Test DOCX -> MD (Markdown)
    let mdAction = RadialAction(id: "doc_md", title: "MD", description: "Convert to Markdown", sfSymbol: "text.quote", mode: .convert, targetExtension: "md")
    let mdRes = await ConversionEngine.shared.execute(action: mdAction, urls: [docxUrl])
    switch mdRes {
    case .success(let outUrls, _):
        guard let out = outUrls.first else { Issue.record("Empty outUrls"); return }
        #expect(FileManager.default.fileExists(atPath: out.path))
        #expect(out.pathExtension == "md")
        let mdText = (try? String(contentsOf: out, encoding: .utf8)) ?? ""
        #expect(mdText.contains("Tangerine Native Document Test"))
    case .failure(let err):
        Issue.record("DOCX -> MD failed: \(err)")
    }

    // 4. Test DOCX -> TXT
    let txtAction = RadialAction(id: "doc_txt", title: "TXT", description: "Convert to TXT", sfSymbol: "doc.plaintext", mode: .convert, targetExtension: "txt")
    let txtRes = await ConversionEngine.shared.execute(action: txtAction, urls: [docxUrl])
    switch txtRes {
    case .success(let outUrls, _):
        guard let out = outUrls.first else { Issue.record("Empty outUrls"); return }
        #expect(FileManager.default.fileExists(atPath: out.path))
        #expect(out.pathExtension == "txt")
    case .failure(let err):
        Issue.record("DOCX -> TXT failed: \(err)")
    }

    // 5. Test DOCX -> HTML
    let htmlAction = RadialAction(id: "doc_html", title: "HTML", description: "Convert to HTML", sfSymbol: "chevron.left.forwardslash.chevron.right", mode: .convert, targetExtension: "html")
    let htmlRes = await ConversionEngine.shared.execute(action: htmlAction, urls: [docxUrl])
    switch htmlRes {
    case .success(let outUrls, _):
        guard let out = outUrls.first else { Issue.record("Empty outUrls"); return }
        #expect(FileManager.default.fileExists(atPath: out.path))
        #expect(out.pathExtension == "html")
    case .failure(let err):
        Issue.record("DOCX -> HTML failed: \(err)")
    }

    // 6. Test DOCX -> EPUB
    let epubAction = RadialAction(id: "doc_epub", title: "EPUB", description: "Convert to EPUB", sfSymbol: "book.closed.fill", mode: .convert, targetExtension: "epub")
    let epubRes = await ConversionEngine.shared.execute(action: epubAction, urls: [docxUrl])
    switch epubRes {
    case .success(let outUrls, _):
        guard let out = outUrls.first else { Issue.record("Empty outUrls"); return }
        #expect(FileManager.default.fileExists(atPath: out.path))
        #expect(out.pathExtension == "epub")
    case .failure(let err):
        Issue.record("DOCX -> EPUB failed: \(err)")
    }

    // 7. Test MD -> DOCX & MD -> PDF
    let mdSourceUrl = tempDir.appendingPathComponent("notes.md")
    try "# Project Notes\n\n- Task 1: Complete offline conversion\n- Task 2: Deliver crisp UX".write(to: mdSourceUrl, atomically: true, encoding: .utf8)

    let mdDocxAction = RadialAction(id: "doc_docx", title: "DOCX", description: "Convert to DOCX", sfSymbol: "doc.fill", mode: .convert, targetExtension: "docx")
    let mdDocxRes = await ConversionEngine.shared.execute(action: mdDocxAction, urls: [mdSourceUrl])
    switch mdDocxRes {
    case .success(let outUrls, _):
        guard let out = outUrls.first else { Issue.record("Empty outUrls"); return }
        #expect(FileManager.default.fileExists(atPath: out.path))
        #expect(out.pathExtension == "docx")
    case .failure(let err):
        Issue.record("MD -> DOCX failed: \(err)")
    }

    let mdPdfRes = await ConversionEngine.shared.execute(action: pdfAction, urls: [mdSourceUrl])
    switch mdPdfRes {
    case .success(let outUrls, _):
        guard let out = outUrls.first else { Issue.record("Empty outUrls"); return }
        #expect(FileManager.default.fileExists(atPath: out.path))
        #expect(out.pathExtension == "pdf")
    case .failure(let err):
        Issue.record("MD -> PDF failed: \(err)")
    }
}

