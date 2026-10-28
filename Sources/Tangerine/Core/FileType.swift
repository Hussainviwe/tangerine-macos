import Foundation
import UniformTypeIdentifiers

public enum FileCategory: String, CaseIterable, Identifiable, Sendable {
    case image = "Images"
    case video = "Video"
    case audio = "Audio"
    case pdf = "PDF"
    case document = "Documents"
    case slides = "Slides"
    case spreadsheet = "Spreadsheets"
    case subtitles = "Subtitles"
    case archive = "Archives"
    case folder = "Folder"
    case other = "Other"

    public var id: String { rawValue }

    public var sfSymbol: String {
        switch self {
        case .image: return "photo"
        case .video: return "film"
        case .audio: return "waveform"
        case .pdf: return "doc.text.fill"
        case .document: return "doc.richtext"
        case .slides: return "rectangle.inset.filled.and.person.filled"
        case .spreadsheet: return "tablecells"
        case .subtitles: return "captions.bubble"
        case .archive: return "archivebox"
        case .folder: return "folder"
        case .other: return "doc"
        }
    }
}

public struct FileInspector {
    public static func category(for url: URL) -> FileCategory {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return .folder
        }

        let ext = url.pathExtension.lowercased()

        switch ext {
        case "jpg", "jpeg", "png", "webp", "heic", "heif", "tiff", "tif", "avif", "bmp", "gif", "svg", "ico":
            return .image
        case "mp4", "mov", "mkv", "webm", "avi", "wmv", "m4v", "flv":
            return .video
        case "mp3", "m4a", "wav", "flac", "ogg", "opus", "aiff", "aif", "wma", "aac":
            return .audio
        case "pdf":
            return .pdf
        case "docx", "doc", "pages", "txt", "md", "markdown", "rtf", "rtfd", "epub", "html", "htm":
            return .document
        case "pptx", "ppt", "key":
            return .slides
        case "xlsx", "xls", "numbers", "csv", "tsv", "ods":
            return .spreadsheet
        case "srt", "vtt":
            return .subtitles
        case "zip", "tar", "gz", "tgz", "rar", "7z", "bz2":
            return .archive
        default:
            // Check system UTType
            if let utType = UTType(filenameExtension: ext) {
                if utType.conforms(to: .image) { return .image }
                if utType.conforms(to: .movie) || utType.conforms(to: .video) { return .video }
                if utType.conforms(to: .audio) { return .audio }
                if utType.conforms(to: .pdf) { return .pdf }
                if utType.conforms(to: .text) || utType.conforms(to: .compositeContent) { return .document }
                if utType.conforms(to: .spreadsheet) { return .spreadsheet }
                if utType.conforms(to: .presentation) { return .slides }
                if utType.conforms(to: .archive) { return .archive }
            }
            return .other
        }
    }
}
