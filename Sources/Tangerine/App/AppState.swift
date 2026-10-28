import Foundation
import SwiftUI
import AppKit

@MainActor
public class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public var draggedURLs: [URL] = []
    @Published public var currentCategory: FileCategory = .image
    @Published public var wheelMode: WheelMode = .convert
    @Published public var hoveredAction: RadialAction?
    @Published public var isWheelVisible: Bool = false
    @Published public var wheelPosition: CGPoint = CGPoint(x: 400, y: 400)

    // HUD / Status notification
    @Published public var hudMessage: String?
    @Published public var hudSuccess: Bool = true
    @Published public var hudOutputURLs: [URL] = []
    @Published public var isProcessing: Bool = false

    // Window / UI toggles
    @Published public var isDropZoneVisible: Bool = true
    @Published public var showFormatCatalog: Bool = false
    @Published public var showSettings: Bool = false
    @Published public var isTargeted: Bool = false
    @Published public var selectedDemoCategory: FileCategory = .image
    @Published public var selectedMatrixCategory: MatrixCategory = .images

    private var hudTimer: Timer?

    private init() {}

    public func setDraggedFiles(_ urls: [URL]) {
        self.draggedURLs = urls
        if let first = urls.first {
            self.currentCategory = FileInspector.category(for: first)
        } else {
            self.currentCategory = .other
        }
    }

    public func presentWheel(at screenPoint: CGPoint, with urls: [URL], mode: WheelMode? = nil) {
        setDraggedFiles(urls)
        if let mode = mode {
            self.wheelMode = mode
        }
        self.wheelPosition = screenPoint
        self.hoveredAction = nil
        self.isWheelVisible = true
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    public func dismissWheel() {
        self.isWheelVisible = false
        self.hoveredAction = nil
    }

    public func executeAction(_ action: RadialAction) {
        guard !draggedURLs.isEmpty else { return }
        let urls = draggedURLs
        dismissWheel()

        self.isProcessing = true
        showHUD(message: "Processing \(action.title)...", success: true, urls: [])

        Task { @MainActor in
            let result = await ConversionEngine.shared.execute(action: action, urls: urls)
            self.isProcessing = false

            switch result {
            case .success(let outputUrls, let message):
                self.showHUD(message: message, success: true, urls: outputUrls)
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)

            case .failure(let error):
                self.showHUD(message: error, success: false, urls: [])
            }
        }
    }

    public func showHUD(message: String, success: Bool, urls: [URL]) {
        self.hudMessage = message
        self.hudSuccess = success
        self.hudOutputURLs = urls

        hudTimer?.invalidate()
        hudTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.hudMessage = nil
                self?.hudOutputURLs = []
            }
        }
    }
}
