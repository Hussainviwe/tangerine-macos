import Foundation
import AppKit

@main
struct TestRunner {
    static func assertEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String = "") {
        if a != b {
            print("❌ FAIL: \(a) != \(b) \(msg)")
            exit(1)
        }
    }

    static func assertTrue(_ condition: Bool, _ msg: String = "") {
        if !condition {
            print("❌ FAIL: assertion failed: \(msg)")
            exit(1)
        }
    }

    static func main() async throws {
        print("🍊 Running Tangerine Verification Suite...")

        // 1. FileCategory Detection
        print("  Checking FileCategory detection...")
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/photo.jpg")), .image)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/photo.png")), .image)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/photo.webp")), .image)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/photo.avif")), .image)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/video.mp4")), .video)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/video.mov")), .video)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/video.mkv")), .video)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/audio.mp3")), .audio)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/audio.flac")), .audio)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/sheet.xlsx")), .spreadsheet)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/sheet.csv")), .spreadsheet)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/doc.pdf")), .pdf)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/doc.docx")), .document)
        assertEqual(FileInspector.category(for: URL(fileURLWithPath: "/tmp/arch.zip")), .archive)
        print("  ✔ FileCategory detection passed.")

        // 2. Format Matrices
        print("  Checking 5-category conversion matrices...")
        let imgM = FormatMatrices.images
        assertTrue(imgM.isSupported(row: "JPG", col: "PNG"))
        assertTrue(imgM.isSupported(row: "PNG", col: "AVIF"))
        assertTrue(imgM.isSupported(row: "SVG", col: "WEBP"))
        assertTrue(!imgM.isSupported(row: "JPG", col: "JPG"))

        let docM = FormatMatrices.documents
        assertTrue(docM.isSupported(row: "PDF", col: "DOCX"))
        assertTrue(docM.isSupported(row: "DOCX", col: "HTML"))
        assertTrue(docM.isSupported(row: "PAGES", col: "EPUB"))

        let sheetM = FormatMatrices.spreadsheets
        assertTrue(sheetM.isSupported(row: "XLSX", col: "CSV"))
        assertTrue(sheetM.isSupported(row: "CSV", col: "PDF"))
        assertTrue(sheetM.isSupported(row: "ODS", col: "TSV"))

        let audM = FormatMatrices.audio
        assertTrue(audM.isSupported(row: "MP3", col: "FLAC"))
        assertTrue(audM.isSupported(row: "OGG", col: "OPUS"))
        assertTrue(audM.isSupported(row: "WAV", col: "AIFF"))

        let vidM = FormatMatrices.video
        assertTrue(vidM.isSupported(row: "MP4", col: "MOV"))
        assertTrue(vidM.isSupported(row: "MKV", col: "GIF"))
        assertTrue(vidM.isSupported(row: "WEBM", col: "MP3"))
        print("  ✔ Format matrices definitions verified.")

        // 3. ToolRegistry Action Generation
        print("  Checking ToolRegistry actions...")
        let sampleUrl = URL(fileURLWithPath: "/tmp/test.png")
        let convActions = ToolRegistry.actions(for: .image, mode: .convert, urls: [sampleUrl])
        assertTrue(!convActions.isEmpty)
        assertTrue(convActions.contains { $0.targetExtension == "jpg" })
        assertTrue(convActions.contains { $0.targetExtension == "webp" })
        assertTrue(convActions.contains { $0.targetExtension == "avif" })
        print("  ✔ ToolRegistry actions generated successfully.")

        // 4. Real offline image conversion & ZIP archive
        print("  Testing offline ConversionEngine execution...")
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let pngUrl = tempDir.appendingPathComponent("sample.png")
        let img = NSImage(size: NSSize(width: 80, height: 80), flipped: false) { rect in
            NSColor.orange.setFill()
            rect.fill()
            return true
        }
        let tiff = img.tiffRepresentation!
        let rep = NSBitmapImageRep(data: tiff)!
        let pngData = rep.representation(using: .png, properties: [:])!
        try! pngData.write(to: pngUrl)

        let jpgAction = RadialAction(id: "img_jpg", title: "JPG", description: "Convert to JPG", sfSymbol: "photo", mode: .convert, targetExtension: "jpg")
        let res = await ConversionEngine.shared.execute(action: jpgAction, urls: [pngUrl])
        switch res {
        case .success(let outUrls, _):
            guard let out = outUrls.first else { exit(1) }
            assertTrue(FileManager.default.fileExists(atPath: out.path), "Output JPG file should exist")
            assertTrue(out.pathExtension == "jpg", "Extension should be jpg")
            print("  ✔ Real PNG -> JPG conversion succeeded.")
        case .failure(let err):
            print("❌ Conversion failed: \(err)")
            exit(1)
        }

        let zipAction = RadialAction(id: "tool_archive_zip", title: "ZIP", description: "Archive", sfSymbol: "archivebox", mode: .tools)
        let zipRes = await ConversionEngine.shared.execute(action: zipAction, urls: [pngUrl])
        switch zipRes {
        case .success(let outUrls, _):
            guard let zipOut = outUrls.first else { exit(1) }
            assertTrue(FileManager.default.fileExists(atPath: zipOut.path), "Output ZIP archive should exist")
            print("  ✔ Real ZIP archive creation succeeded.")
        case .failure(let err):
            print("❌ ZIP failed: \(err)")
            exit(1)
        }

        // 5. Real offline PDF to DOCX/DOC conversion
        print("  Testing offline PDF to DOCX/DOC conversion...")
        let pdfUrl = tempDir.appendingPathComponent("sample.pdf")
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
        try! (pdfData as Data).write(to: pdfUrl)

        let docxAction = RadialAction(id: "pdf_docx", title: "DOCX", description: "Convert to DOCX", sfSymbol: "doc.richtext", mode: .convert, targetExtension: "docx")
        let docxRes = await ConversionEngine.shared.execute(action: docxAction, urls: [pdfUrl])
        switch docxRes {
        case .success(let outUrls, _):
            guard let docxOut = outUrls.first else { exit(1) }
            assertTrue(FileManager.default.fileExists(atPath: docxOut.path), "Output DOCX file should exist")
            assertTrue(docxOut.pathExtension == "docx", "Extension should be docx")
            print("  ✔ Real PDF -> DOCX conversion succeeded.")
        case .failure(let err):
            print("❌ PDF -> DOCX failed: \(err)")
            exit(1)
        }

        let docAction = RadialAction(id: "pdf_doc", title: "DOC", description: "Convert to DOC", sfSymbol: "doc.text", mode: .convert, targetExtension: "doc")
        let docRes = await ConversionEngine.shared.execute(action: docAction, urls: [pdfUrl])
        switch docRes {
        case .success(let outUrls, _):
            guard let docOut = outUrls.first else { exit(1) }
            assertTrue(FileManager.default.fileExists(atPath: docOut.path), "Output DOC file should exist")
            assertTrue(docOut.pathExtension == "doc", "Extension should be doc")
            print("  ✔ Real PDF -> DOC conversion succeeded.")
        case .failure(let err):
            print("❌ PDF -> DOC failed: \(err)")
            exit(1)
        }

        print("\n🎉 ALL TESTS PASSED! Everything is working correctly!")
    }
}
