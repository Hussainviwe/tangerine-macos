import SwiftUI
import AppKit

public struct NotificationHUD: View {
    @ObservedObject var appState = AppState.shared

    public var body: some View {
        if let message = appState.hudMessage {
            HStack(spacing: 12) {
                Image(systemName: appState.hudSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(appState.hudSuccess ? Color(red: 0.1, green: 0.8, blue: 0.3) : Color.red)
                    .font(.system(size: 20, weight: .bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(message)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    if !appState.hudOutputURLs.isEmpty {
                        Text(appState.hudOutputURLs.map { $0.lastPathComponent }.joined(separator: ", "))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                if let first = appState.hudOutputURLs.first {
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([first])
                    }) {
                        Text("Show in Finder")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 6)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.hudMessage)
        }
    }
}
