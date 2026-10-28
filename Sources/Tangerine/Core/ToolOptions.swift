import Foundation

public enum WheelMode: String, CaseIterable, Identifiable, Sendable {
    case convert = "Convert"
    case tools = "File Tools"
    case actions = "File Actions"

    public var id: String { rawValue }

    public var keySymbol: String {
        switch self {
        case .convert: return "⇧"
        case .tools: return "⌘"
        case .actions: return "⌃"
        }
    }

    public var keyName: String {
        switch self {
        case .convert: return "Shift"
        case .tools: return "Command"
        case .actions: return "Control"
        }
    }
}

public struct RadialAction: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let sfSymbol: String
    public let mode: WheelMode
    public let targetExtension: String?

    public init(id: String, title: String, description: String, sfSymbol: String, mode: WheelMode, targetExtension: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.sfSymbol = sfSymbol
        self.mode = mode
        self.targetExtension = targetExtension
    }
}

public struct ToolRegistry {
    // Return the list of radial actions available for a specific category and wheel mode
    public static func actions(for category: FileCategory, mode: WheelMode, urls: [URL]) -> [RadialAction] {
        switch mode {
        case .convert:
            return conversionActions(for: category, urls: urls)
        case .tools:
            return fileToolActions(for: category, urls: urls)
        case .actions:
            return fileActions(for: category, urls: urls)
        }
    }

    private static func conversionActions(for category: FileCategory, urls: [URL]) -> [RadialAction] {
        let firstExt = urls.first?.pathExtension.lowercased() ?? ""

        switch category {
        case .image:
            var list: [RadialAction] = [
                RadialAction(id: "img_jpg", title: "JPG", description: "Convert to JPEG", sfSymbol: "photo.fill", mode: .convert, targetExtension: "jpg"),
                RadialAction(id: "img_png", title: "PNG", description: "Convert to lossless PNG", sfSymbol: "photo", mode: .convert, targetExtension: "png"),
                RadialAction(id: "img_webp", title: "WebP", description: "Convert to modern WebP", sfSymbol: "globe", mode: .convert, targetExtension: "webp"),
                RadialAction(id: "img_heic", title: "HEIC", description: "Convert to Apple HEIC", sfSymbol: "applelogo", mode: .convert, targetExtension: "heic"),
                RadialAction(id: "img_tiff", title: "TIFF", description: "Convert to high-quality TIFF", sfSymbol: "printer.fill", mode: .convert, targetExtension: "tiff"),
                RadialAction(id: "img_avif", title: "AVIF", description: "Convert to next-gen AVIF", sfSymbol: "sparkles", mode: .convert, targetExtension: "avif"),
                RadialAction(id: "img_bmp", title: "BMP", description: "Convert to bitmap BMP", sfSymbol: "square.grid.2x2", mode: .convert, targetExtension: "bmp"),
                RadialAction(id: "img_pdf", title: "PDF", description: "Convert image into PDF", sfSymbol: "doc.text.fill", mode: .convert, targetExtension: "pdf"),
                RadialAction(id: "img_gif", title: "GIF", description: "Convert to GIF", sfSymbol: "play.rectangle.fill", mode: .convert, targetExtension: "gif")
            ]
            list.removeAll { $0.targetExtension == firstExt }
            return list

        case .video:
            var list: [RadialAction] = []
            if firstExt == "gif" {
                list = [
                    RadialAction(id: "vid_mp4", title: "MP4", description: "Convert GIF to MP4 video", sfSymbol: "play.circle.fill", mode: .convert, targetExtension: "mp4"),
                    RadialAction(id: "vid_mov", title: "MOV", description: "Convert GIF to Apple MOV", sfSymbol: "video.fill", mode: .convert, targetExtension: "mov"),
                    RadialAction(id: "vid_mkv", title: "MKV", description: "Convert to Matroska MKV", sfSymbol: "film.fill", mode: .convert, targetExtension: "mkv"),
                    RadialAction(id: "vid_avi", title: "AVI", description: "Convert to AVI", sfSymbol: "film", mode: .convert, targetExtension: "avi"),
                    RadialAction(id: "vid_wmv", title: "WMV", description: "Convert to Windows Media WMV", sfSymbol: "display", mode: .convert, targetExtension: "wmv")
                ]
            } else {
                list = [
                    RadialAction(id: "vid_mp4", title: "MP4", description: "Convert to universal MP4 (H.264)", sfSymbol: "play.circle.fill", mode: .convert, targetExtension: "mp4"),
                    RadialAction(id: "vid_mov", title: "MOV", description: "Convert to Apple QuickTime MOV", sfSymbol: "video.fill", mode: .convert, targetExtension: "mov"),
                    RadialAction(id: "vid_mkv", title: "MKV", description: "Convert to Matroska MKV", sfSymbol: "film.fill", mode: .convert, targetExtension: "mkv"),
                    RadialAction(id: "vid_avi", title: "AVI", description: "Convert to AVI video", sfSymbol: "film", mode: .convert, targetExtension: "avi"),
                    RadialAction(id: "vid_wmv", title: "WMV", description: "Convert to Windows Media WMV", sfSymbol: "display", mode: .convert, targetExtension: "wmv"),
                    RadialAction(id: "vid_gif", title: "GIF", description: "Convert video to animated GIF", sfSymbol: "sparkles", mode: .convert, targetExtension: "gif"),
                    RadialAction(id: "vid_mp3", title: "MP3", description: "Extract audio to MP3", sfSymbol: "music.note", mode: .convert, targetExtension: "mp3")
                ]
            }
            list.removeAll { $0.targetExtension == firstExt }
            return list

        case .audio:
            var list: [RadialAction] = [
                RadialAction(id: "aud_mp3", title: "MP3", description: "Convert to universal MP3", sfSymbol: "music.note", mode: .convert, targetExtension: "mp3"),
                RadialAction(id: "aud_m4a", title: "M4A", description: "Convert to Apple AAC M4A", sfSymbol: "waveform.circle.fill", mode: .convert, targetExtension: "m4a"),
                RadialAction(id: "aud_wav", title: "WAV", description: "Convert to uncompressed WAV", sfSymbol: "waveform", mode: .convert, targetExtension: "wav"),
                RadialAction(id: "aud_flac", title: "FLAC", description: "Convert to lossless FLAC", sfSymbol: "headphones", mode: .convert, targetExtension: "flac"),
                RadialAction(id: "aud_ogg", title: "OGG", description: "Convert to OGG Vorbis", sfSymbol: "music.quarternote.3", mode: .convert, targetExtension: "ogg"),
                RadialAction(id: "aud_opus", title: "OPUS", description: "Convert to high-efficiency OPUS", sfSymbol: "antenna.radiowaves.left.and.right", mode: .convert, targetExtension: "opus"),
                RadialAction(id: "aud_aiff", title: "AIFF", description: "Convert to Apple AIFF", sfSymbol: "hifispeaker.fill", mode: .convert, targetExtension: "aiff"),
                RadialAction(id: "aud_wma", title: "WMA", description: "Convert to Windows Media Audio", sfSymbol: "hifispeaker", mode: .convert, targetExtension: "wma")
            ]
            list.removeAll { $0.targetExtension == firstExt }
            return list

        case .pdf:
            return [
                RadialAction(id: "pdf_docx", title: "DOCX", description: "Convert PDF to Microsoft Word (.docx)", sfSymbol: "doc.richtext", mode: .convert, targetExtension: "docx"),
                RadialAction(id: "pdf_doc", title: "DOC", description: "Convert PDF to Word Document (.doc)", sfSymbol: "doc.text", mode: .convert, targetExtension: "doc"),
                RadialAction(id: "pdf_pages", title: "PAGES", description: "Convert PDF to Apple Pages", sfSymbol: "doc.text.fill", mode: .convert, targetExtension: "pages"),
                RadialAction(id: "pdf_pptx", title: "PPTX", description: "Convert PDF to PowerPoint slides", sfSymbol: "rectangle.inset.filled.and.person.filled", mode: .convert, targetExtension: "pptx"),
                RadialAction(id: "pdf_txt", title: "TXT", description: "Extract all text to plain TXT", sfSymbol: "doc.plaintext", mode: .convert, targetExtension: "txt"),
                RadialAction(id: "pdf_md", title: "MD", description: "Convert document to Markdown", sfSymbol: "text.quote", mode: .convert, targetExtension: "md"),
                RadialAction(id: "pdf_epub", title: "EPUB", description: "Convert PDF to e-reader EPUB", sfSymbol: "book.closed.fill", mode: .convert, targetExtension: "epub"),
                RadialAction(id: "pdf_jpg", title: "JPG", description: "Render all pages as JPG images", sfSymbol: "photo", mode: .convert, targetExtension: "jpg"),
                RadialAction(id: "pdf_png", title: "PNG (300 DPI)", description: "Render all pages as crisp PNGs", sfSymbol: "photo.stack", mode: .convert, targetExtension: "png"),
                RadialAction(id: "pdf_xlsx", title: "XLSX", description: "Extract tables into Excel sheet", sfSymbol: "tablecells", mode: .convert, targetExtension: "xlsx"),
                RadialAction(id: "pdf_split", title: "Split Pages", description: "Split PDF into single pages", sfSymbol: "square.split.2x1", mode: .convert, targetExtension: "pdf")
            ]

        case .document:
            var list: [RadialAction] = []
            if firstExt == "epub" {
                list = [
                    RadialAction(id: "doc_pdf", title: "PDF", description: "Export EPUB to PDF", sfSymbol: "doc.text.fill", mode: .convert, targetExtension: "pdf"),
                    RadialAction(id: "doc_docx", title: "DOCX", description: "Convert EPUB to Word DOCX", sfSymbol: "doc.fill", mode: .convert, targetExtension: "docx"),
                    RadialAction(id: "doc_pages", title: "PAGES", description: "Convert EPUB to Apple Pages", sfSymbol: "doc.text", mode: .convert, targetExtension: "pages"),
                    RadialAction(id: "doc_txt", title: "TXT", description: "Strip to plain text", sfSymbol: "doc.plaintext", mode: .convert, targetExtension: "txt"),
                    RadialAction(id: "doc_md", title: "MD", description: "Convert EPUB to Markdown", sfSymbol: "text.quote", mode: .convert, targetExtension: "md"),
                    RadialAction(id: "doc_html", title: "HTML", description: "Export EPUB chapters to HTML", sfSymbol: "chevron.left.forwardslash.chevron.right", mode: .convert, targetExtension: "html")
                ]
            } else {
                list = [
                    RadialAction(id: "doc_pdf", title: "PDF", description: "Export document to PDF", sfSymbol: "doc.text.fill", mode: .convert, targetExtension: "pdf"),
                    RadialAction(id: "doc_docx", title: "DOCX", description: "Convert to Microsoft Word DOCX", sfSymbol: "doc.fill", mode: .convert, targetExtension: "docx"),
                    RadialAction(id: "doc_pages", title: "PAGES", description: "Convert to Apple Pages", sfSymbol: "doc.text", mode: .convert, targetExtension: "pages"),
                    RadialAction(id: "doc_txt", title: "TXT", description: "Strip formatting to plain TXT", sfSymbol: "doc.plaintext", mode: .convert, targetExtension: "txt"),
                    RadialAction(id: "doc_md", title: "MD", description: "Convert document to Markdown", sfSymbol: "text.quote", mode: .convert, targetExtension: "md"),
                    RadialAction(id: "doc_html", title: "HTML", description: "Export as clean web HTML", sfSymbol: "chevron.left.forwardslash.chevron.right", mode: .convert, targetExtension: "html"),
                    RadialAction(id: "doc_epub", title: "EPUB", description: "Export as EPUB e-book", sfSymbol: "book.closed.fill", mode: .convert, targetExtension: "epub"),
                    RadialAction(id: "doc_jpg", title: "JPG", description: "Render document pages as JPG", sfSymbol: "photo", mode: .convert, targetExtension: "jpg"),
                    RadialAction(id: "doc_png", title: "PNG", description: "Render document pages as PNG", sfSymbol: "photo.stack", mode: .convert, targetExtension: "png")
                ]
            }
            list.removeAll { $0.targetExtension == firstExt }
            return list

        case .spreadsheet:
            var list: [RadialAction] = [
                RadialAction(id: "sheet_pdf", title: "PDF", description: "Print spreadsheet to PDF", sfSymbol: "doc.text.fill", mode: .convert, targetExtension: "pdf"),
                RadialAction(id: "sheet_xlsx", title: "XLSX", description: "Convert to modern Excel XLSX", sfSymbol: "tablecells.fill", mode: .convert, targetExtension: "xlsx"),
                RadialAction(id: "sheet_csv", title: "CSV", description: "Export sheet as standard CSV", sfSymbol: "tablecells", mode: .convert, targetExtension: "csv"),
                RadialAction(id: "sheet_tsv", title: "TSV", description: "Export sheet as tab-separated TSV", sfSymbol: "tablecells.badge.ellipsis", mode: .convert, targetExtension: "tsv"),
                RadialAction(id: "sheet_html", title: "HTML", description: "Export sheet as web HTML table", sfSymbol: "chevron.left.forwardslash.chevron.right", mode: .convert, targetExtension: "html"),
                RadialAction(id: "sheet_ods", title: "ODS", description: "Convert to OpenDocument ODS", sfSymbol: "doc.plaintext", mode: .convert, targetExtension: "ods")
            ]
            list.removeAll { $0.targetExtension == firstExt }
            return list

        case .slides:
            return [
                RadialAction(id: "slide_pdf", title: "PDF", description: "Export presentation slides to PDF", sfSymbol: "doc.text.fill", mode: .convert, targetExtension: "pdf"),
                RadialAction(id: "slide_jpg", title: "JPG Slides", description: "Export each slide as high-res JPG", sfSymbol: "photo.stack", mode: .convert, targetExtension: "jpg"),
                RadialAction(id: "slide_png", title: "PNG Slides", description: "Export each slide as crisp PNG", sfSymbol: "photo.stack.fill", mode: .convert, targetExtension: "png")
            ]

        case .subtitles:
            return [
                RadialAction(id: "sub_vtt", title: "VTT", description: "Convert subtitle to WebVTT", sfSymbol: "captions.bubble", mode: .convert, targetExtension: "vtt"),
                RadialAction(id: "sub_srt", title: "SRT", description: "Convert subtitle to SubRip SRT", sfSymbol: "captions.bubble.fill", mode: .convert, targetExtension: "srt"),
                RadialAction(id: "sub_txt", title: "Clean TXT", description: "Extract dialogue text without timecodes", sfSymbol: "doc.plaintext", mode: .convert, targetExtension: "txt")
            ].filter { $0.targetExtension != firstExt }

        case .archive:
            return [
                RadialAction(id: "arch_zip", title: "ZIP", description: "Repack as standard ZIP archive", sfSymbol: "archivebox.fill", mode: .convert, targetExtension: "zip"),
                RadialAction(id: "arch_tar", title: "TAR.GZ", description: "Repack as compressed Unix TAR.GZ", sfSymbol: "shippingbox.fill", mode: .convert, targetExtension: "tar.gz"),
                RadialAction(id: "arch_extract", title: "Extract Here", description: "Unpack all contents to a folder", sfSymbol: "tray.and.arrow.down.fill", mode: .convert, targetExtension: nil)
            ]

        case .folder:
            return [
                RadialAction(id: "fld_zip", title: "ZIP Archive", description: "Compress folder to ZIP", sfSymbol: "archivebox.fill", mode: .convert, targetExtension: "zip"),
                RadialAction(id: "fld_tar", title: "TAR.GZ", description: "Compress folder to TAR.GZ", sfSymbol: "shippingbox.fill", mode: .convert, targetExtension: "tar.gz")
            ]

        case .other:
            return [
                RadialAction(id: "oth_zip", title: "Compress to ZIP", description: "Archive file as ZIP", sfSymbol: "archivebox.fill", mode: .convert, targetExtension: "zip"),
                RadialAction(id: "oth_txt", title: "Inspect as TXT", description: "Read as plain text", sfSymbol: "doc.plaintext", mode: .convert, targetExtension: "txt")
            ]
        }
    }

    private static func fileToolActions(for category: FileCategory, urls: [URL]) -> [RadialAction] {
        switch category {
        case .image:
            return [
                RadialAction(id: "tool_compress", title: "Compress", description: "Optimize image size without losing quality", sfSymbol: "arrow.down.right.and.arrow.up.left", mode: .tools),
                RadialAction(id: "tool_resize_half", title: "Resize 50%", description: "Downscale width & height by 50%", sfSymbol: "arrow.up.and.down.and.arrow.left.and.right", mode: .tools),
                RadialAction(id: "tool_rotate_cw", title: "Rotate 90°", description: "Rotate clockwise", sfSymbol: "rotate.right.fill", mode: .tools),
                RadialAction(id: "tool_grayscale", title: "Grayscale", description: "Convert colors to black & white", sfSymbol: "circle.lefthalf.filled", mode: .tools),
                RadialAction(id: "tool_strip_exif", title: "Strip Metadata", description: "Remove GPS & camera EXIF for privacy", sfSymbol: "shield.slash.fill", mode: .tools),
                RadialAction(id: "tool_merge_pdf", title: "Images to PDF", description: "Combine selected images into single PDF", sfSymbol: "doc.on.doc.fill", mode: .tools)
            ]

        case .pdf:
            return [
                RadialAction(id: "tool_pdf_compress", title: "Compress PDF", description: "Reduce PDF file size for emailing", sfSymbol: "arrow.down.right.and.arrow.up.left", mode: .tools),
                RadialAction(id: "tool_pdf_merge", title: "Merge PDFs", description: "Combine multiple PDF documents", sfSymbol: "plus.rectangle.on.rectangle", mode: .tools),
                RadialAction(id: "tool_pdf_split", title: "Split by Page", description: "Separate into individual page PDFs", sfSymbol: "scissors", mode: .tools),
                RadialAction(id: "tool_pdf_bw", title: "Grayscale PDF", description: "Convert all pages to black and white", sfSymbol: "circle.lefthalf.filled", mode: .tools)
            ]

        case .video:
            return [
                RadialAction(id: "tool_vid_compress", title: "Compress Video", description: "Downscale bitrate to 1080p/720p", sfSymbol: "arrow.down.right.and.arrow.up.left", mode: .tools),
                RadialAction(id: "tool_vid_mute", title: "Mute Audio", description: "Remove audio track completely", sfSymbol: "speaker.slash.fill", mode: .tools),
                RadialAction(id: "tool_vid_trim30", title: "Trim First 30s", description: "Keep first 30 seconds", sfSymbol: "scissors", mode: .tools),
                RadialAction(id: "tool_vid_extract_audio", title: "Extract Audio", description: "Rip soundtrack to M4A", sfSymbol: "music.note", mode: .tools)
            ]

        case .audio:
            return [
                RadialAction(id: "tool_aud_compress", title: "Compress Audio", description: "Optimize audio bitrate for podcast/sharing", sfSymbol: "arrow.down.right.and.arrow.up.left", mode: .tools),
                RadialAction(id: "tool_aud_trim", title: "Trim First 30s", description: "Clip preview track", sfSymbol: "scissors", mode: .tools)
            ]

        case .document, .spreadsheet, .slides, .subtitles, .archive, .folder, .other:
            return [
                RadialAction(id: "tool_archive_zip", title: "Compress to ZIP", description: "Pack cleanly into ZIP archive", sfSymbol: "archivebox.fill", mode: .tools),
                RadialAction(id: "tool_strip_meta", title: "Strip Metadata", description: "Remove author and creation tags", sfSymbol: "shield.slash.fill", mode: .tools)
            ]
        }
    }

    private static func fileActions(for category: FileCategory, urls: [URL]) -> [RadialAction] {
        return [
            RadialAction(id: "act_airdrop", title: "AirDrop", description: "Share instantly with nearby Apple devices", sfSymbol: "antenna.radiowaves.left.and.right", mode: .actions),
            RadialAction(id: "act_quicklook", title: "Quick Look", description: "Float file in quick preview window", sfSymbol: "eye.fill", mode: .actions),
            RadialAction(id: "act_copy", title: "Copy File", description: "Copy file to clipboard pasteboard", sfSymbol: "doc.on.clipboard.fill", mode: .actions),
            RadialAction(id: "act_copypath", title: "Copy Path", description: "Copy absolute POSIX path to clipboard", sfSymbol: "link", mode: .actions),
            RadialAction(id: "act_terminal", title: "Open in Terminal", description: "Open containing folder in Terminal", sfSymbol: "terminal.fill", mode: .actions),
            RadialAction(id: "act_trash", title: "Move to Trash", description: "Safely move file to macOS Trash", sfSymbol: "trash.fill", mode: .actions)
        ]
    }
}
