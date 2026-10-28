import SwiftUI

public enum MatrixCategory: String, CaseIterable, Identifiable, Sendable {
    case images = "Images"
    case documents = "Documents"
    case spreadsheets = "Spreadsheets"
    case audio = "Audio"
    case video = "Video"

    public var id: String { rawValue }

    public var sfSymbol: String {
        switch self {
        case .images: return "photo.on.rectangle.angled"
        case .documents: return "doc.text"
        case .spreadsheets: return "tablecells"
        case .audio: return "waveform"
        case .video: return "film"
        }
    }
}

public struct MatrixDefinition: Sendable {
    public let columns: [String]
    public let rows: [String]
    // Map of row -> Set of supported target column names
    public let supported: [String: Set<String>]

    public func isSupported(row: String, col: String) -> Bool {
        if row == col { return false }
        return supported[row]?.contains(col) ?? false
    }
}

public struct FormatMatrices: Sendable {
    public static let images = MatrixDefinition(
        columns: ["JPG", "PNG", "WEBP", "HEIC", "TIFF", "AVIF", "BMP", "PDF"],
        rows: ["JPG", "PNG", "WEBP", "HEIC", "TIFF", "SVG", "AVIF", "BMP"],
        supported: [
            "JPG": ["PNG", "WEBP", "HEIC", "TIFF", "AVIF", "BMP", "PDF"],
            "PNG": ["JPG", "WEBP", "HEIC", "TIFF", "AVIF", "BMP", "PDF"],
            "WEBP": ["JPG", "PNG", "HEIC", "TIFF", "AVIF", "BMP", "PDF"],
            "HEIC": ["JPG", "PNG", "WEBP", "TIFF", "AVIF", "BMP", "PDF"],
            "TIFF": ["JPG", "PNG", "WEBP", "HEIC", "AVIF", "BMP", "PDF"],
            "SVG": ["JPG", "PNG", "WEBP", "HEIC", "TIFF", "AVIF", "BMP", "PDF"],
            "AVIF": ["JPG", "PNG", "WEBP", "HEIC", "TIFF", "BMP", "PDF"],
            "BMP": ["JPG", "PNG", "WEBP", "HEIC", "TIFF", "AVIF", "PDF"]
        ]
    )

    public static let documents = MatrixDefinition(
        columns: ["PDF", "DOCX", "PAGES", "PPTX", "TXT", "MD", "HTML", "EPUB", "JPG", "PNG", "XLSX"],
        rows: ["PDF", "DOCX", "PAGES", "PPT", "PPTX", "TXT", "MD", "RTF", "RTFD", "TEXTCLIP...", "EPUB"],
        supported: [
            "PDF": ["DOCX", "PAGES", "PPTX", "TXT", "MD", "EPUB", "JPG", "PNG", "XLSX"],
            "DOCX": ["PDF", "PAGES", "TXT", "MD", "HTML", "EPUB", "JPG", "PNG"],
            "PAGES": ["PDF", "DOCX", "TXT", "MD", "HTML", "EPUB", "JPG", "PNG"],
            "PPT": ["PDF", "JPG", "PNG"],
            "PPTX": ["PDF", "JPG", "PNG"],
            "TXT": ["PDF", "DOCX", "PAGES", "MD", "HTML", "EPUB", "JPG", "PNG"],
            "MD": ["PDF", "DOCX", "PAGES", "TXT", "HTML", "EPUB", "JPG", "PNG"],
            "RTF": ["PDF", "DOCX", "PAGES", "TXT", "MD", "HTML", "EPUB", "JPG", "PNG"],
            "RTFD": ["PDF", "DOCX", "PAGES", "TXT", "MD", "HTML", "EPUB", "JPG", "PNG"],
            "TEXTCLIP...": ["PDF", "DOCX", "PAGES", "TXT", "MD", "HTML", "EPUB", "JPG", "PNG"],
            "EPUB": ["PDF", "DOCX", "PAGES", "TXT", "MD", "HTML"]
        ]
    )

    public static let spreadsheets = MatrixDefinition(
        columns: ["XLSX", "ODS", "CSV", "TSV", "PDF"],
        rows: ["XLSX", "XLS", "ODS", "CSV", "TSV"],
        supported: [
            "XLSX": ["ODS", "CSV", "TSV", "PDF"],
            "XLS": ["XLSX", "ODS", "CSV", "TSV", "PDF"],
            "ODS": ["XLSX", "CSV", "TSV", "PDF"],
            "CSV": ["XLSX", "ODS", "TSV", "PDF"],
            "TSV": ["XLSX", "ODS", "CSV", "PDF"]
        ]
    )

    public static let audio = MatrixDefinition(
        columns: ["MP3", "M4A", "WAV", "FLAC", "OGG", "OPUS", "AIFF", "WMA"],
        rows: ["MP3", "M4A", "WAV", "FLAC", "OGG", "OPUS", "AIFF", "WMA"],
        supported: [
            "MP3": ["M4A", "WAV", "FLAC", "OGG", "OPUS", "AIFF", "WMA"],
            "M4A": ["MP3", "WAV", "FLAC", "OGG", "OPUS", "AIFF", "WMA"],
            "WAV": ["MP3", "M4A", "FLAC", "OGG", "OPUS", "AIFF", "WMA"],
            "FLAC": ["MP3", "M4A", "WAV", "OGG", "OPUS", "AIFF", "WMA"],
            "OGG": ["MP3", "M4A", "WAV", "FLAC", "OPUS", "AIFF", "WMA"],
            "OPUS": ["MP3", "M4A", "WAV", "FLAC", "OGG", "AIFF", "WMA"],
            "AIFF": ["MP3", "M4A", "WAV", "FLAC", "OGG", "OPUS", "WMA"],
            "WMA": ["MP3", "M4A", "WAV", "FLAC", "OGG", "OPUS", "AIFF"]
        ]
    )

    public static let video = MatrixDefinition(
        columns: ["MP4", "MOV", "MKV", "WEBM", "AVI", "WMV", "GIF", "MP3"],
        rows: ["MP4", "MOV", "MKV", "WEBM", "AVI", "WMV", "GIF"],
        supported: [
            "MP4": ["MOV", "MKV", "AVI", "WMV", "GIF", "MP3"],
            "MOV": ["MP4", "MKV", "AVI", "WMV", "GIF", "MP3"],
            "MKV": ["MP4", "MOV", "AVI", "WMV", "GIF", "MP3"],
            "WEBM": ["MP4", "MOV", "MKV", "AVI", "WMV", "GIF", "MP3"],
            "AVI": ["MP4", "MOV", "MKV", "WMV", "GIF", "MP3"],
            "WMV": ["MP4", "MOV", "MKV", "AVI", "GIF", "MP3"],
            "GIF": ["MP4", "MOV", "MKV", "AVI", "WMV"]
        ]
    )

    public static func matrix(for category: MatrixCategory) -> MatrixDefinition {
        switch category {
        case .images: return images
        case .documents: return documents
        case .spreadsheets: return spreadsheets
        case .audio: return audio
        case .video: return video
        }
    }
}

public struct FormatMatrixView: View {
    @ObservedObject var appState = AppState.shared

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Category selector tabs
            HStack(spacing: 8) {
                ForEach(MatrixCategory.allCases) { cat in
                    Button(action: {
                        appState.selectedMatrixCategory = cat
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: cat.sfSymbol)
                            Text(cat.rawValue)
                        }
                        .font(.system(size: 13, weight: appState.selectedMatrixCategory == cat ? .bold : .medium, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .foregroundColor(appState.selectedMatrixCategory == cat ? .white : .secondary)
                        .background(
                            appState.selectedMatrixCategory == cat
                                ? Color(red: 1.0, green: 0.5, blue: 0.0)
                                : Color.white.opacity(0.08),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            let def = FormatMatrices.matrix(for: appState.selectedMatrixCategory)

            // Matrix Table matching screenshots
            VStack(spacing: 0) {
                // Table Header
                HStack(spacing: 0) {
                    // Top-left corner
                    HStack {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .frame(width: 80, height: 38)
                    .background(Color.white.opacity(0.04))

                    // Column headers
                    ForEach(def.columns, id: \.self) { col in
                        Text(col)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Color.white.opacity(0.04))
                    }
                }
                .overlay(
                    Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.1)),
                    alignment: .bottom
                )

                // Rows
                ForEach(Array(def.rows.enumerated()), id: \.element) { rowIndex, row in
                    HStack(spacing: 0) {
                        // Row header
                        Text(row)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.primary.opacity(0.85))
                            .frame(width: 80, alignment: .leading)
                            .padding(.leading, 12)
                            .frame(height: 34)
                            .background(rowIndex % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)

                        // Cells
                        ForEach(def.columns, id: \.self) { col in
                            let supported = def.isSupported(row: row, col: col)
                            let isSame = (row == col)

                            ZStack {
                                if isSame {
                                    Text("–")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary.opacity(0.35))
                                } else if supported {
                                    Text("✓")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.85))
                                } else {
                                    Text("–")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary.opacity(0.2))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(rowIndex % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)
                        }
                    }
                    .overlay(
                        Rectangle().frame(height: 0.5).foregroundColor(Color.white.opacity(0.05)),
                        alignment: .bottom
                    )
                }
            }
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}
