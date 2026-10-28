import SwiftUI
import AppKit

public struct WedgeShape: Shape {
    public var startAngle: Angle
    public var endAngle: Angle
    public var innerRadius: CGFloat
    public var outerRadius: CGFloat

    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()

        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )

        path.closeSubpath()
        return path
    }
}

public struct RadialMenuView: View {
    @ObservedObject var appState = AppState.shared

    let outerRadius: CGFloat = 165
    let innerRadius: CGFloat = 62
    let size: CGFloat = 360

    var actions: [RadialAction] {
        ToolRegistry.actions(for: appState.currentCategory, mode: appState.wheelMode, urls: appState.draggedURLs)
    }

    public var body: some View {
        ZStack {
            // Ambient Backdrop Blur
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )

            // Wedges
            let count = max(actions.count, 1)
            let angleSpan = 360.0 / Double(count)

            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                let startDeg = Double(index) * angleSpan - 90.0
                let endDeg = startDeg + angleSpan
                let midDeg = (startDeg + endDeg) / 2.0
                let isHovered = appState.hoveredAction?.id == action.id

                ZStack {
                    // Wedge Background
                    WedgeShape(
                        startAngle: .degrees(startDeg),
                        endAngle: .degrees(endDeg),
                        innerRadius: innerRadius,
                        outerRadius: isHovered ? outerRadius + 6 : outerRadius
                    )
                    .fill(
                        isHovered
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color(red: 1.0, green: 0.52, blue: 0.08), Color(red: 0.95, green: 0.35, blue: 0.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ))
                            : AnyShapeStyle(Color.black.opacity(0.25))
                    )
                    .overlay(
                        WedgeShape(
                            startAngle: .degrees(startDeg),
                            endAngle: .degrees(endDeg),
                            innerRadius: innerRadius,
                            outerRadius: isHovered ? outerRadius + 6 : outerRadius
                        )
                        .stroke(isHovered ? Color.white.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)

                    // Wedge Icon and Label
                    let midRad = midDeg * .pi / 180.0
                    let contentRadius = (innerRadius + outerRadius) / 2.0
                    let cx = size / 2 + CGFloat(cos(midRad)) * contentRadius
                    let cy = size / 2 + CGFloat(sin(midRad)) * contentRadius

                    VStack(spacing: 3) {
                        Image(systemName: action.sfSymbol)
                            .font(.system(size: 16, weight: .semibold))
                        Text(action.title)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundColor(isHovered ? .white : .primary.opacity(0.9))
                    .shadow(color: isHovered ? Color.black.opacity(0.3) : Color.clear, radius: 2)
                    .position(x: cx, y: cy)
                }
            }

            // Center Preview Hub
            Circle()
                .fill(.regularMaterial)
                .frame(width: innerRadius * 2 - 6, height: innerRadius * 2 - 6)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8)
                .overlay(
                    VStack(spacing: 2) {
                        if let hovered = appState.hoveredAction {
                            Image(systemName: hovered.sfSymbol)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                            Text(hovered.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text(hovered.description)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 4)
                        } else {
                            Image(systemName: appState.currentCategory.sfSymbol)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                            Text("\(appState.draggedURLs.count) File\(appState.draggedURLs.count == 1 ? "" : "s")")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text(appState.currentCategory.rawValue)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                )

            // Mode Selector Bar at Top
            VStack {
                HStack(spacing: 6) {
                    modeButton(.convert)
                    modeButton(.tools)
                    modeButton(.actions)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.8))
                .shadow(color: Color.black.opacity(0.18), radius: 6)
                .offset(y: -size / 2 - 16)

                Spacer()
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                updateHover(at: location)
            case .ended:
                appState.hoveredAction = nil
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    updateHover(at: value.location)
                }
                .onEnded { value in
                    let selected = appState.hoveredAction ?? action(at: value.location)
                    if let action = selected {
                        appState.executeAction(action)
                    } else {
                        appState.dismissWheel()
                    }
                }
        )
    }

    private func modeButton(_ mode: WheelMode) -> some View {
        let isSelected = appState.wheelMode == mode
        return Button(action: {
            appState.wheelMode = mode
            appState.hoveredAction = nil
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }) {
            HStack(spacing: 4) {
                Text(mode.keySymbol)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                Text(mode.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(isSelected ? .white : .secondary)
            .background(isSelected ? Color(red: 1.0, green: 0.45, blue: 0.0) : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func action(at point: CGPoint) -> RadialAction? {
        let center = CGPoint(x: size / 2, y: size / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)

        // Inside center circle or outside wheel?
        if distance < innerRadius || distance > outerRadius + 20 {
            return nil
        }

        let rad = atan2(dy, dx)
        var deg = rad * 180.0 / .pi
        // Align with 12 o'clock (-90 degrees)
        deg += 90.0
        if deg < 0 { deg += 360.0 }

        let count = actions.count
        guard count > 0 else { return nil }
        let span = 360.0 / Double(count)
        let index = Int(deg / span) % count

        if index >= 0 && index < actions.count {
            return actions[index]
        }
        return nil
    }

    private func updateHover(at point: CGPoint) {
        if let act = action(at: point) {
            if appState.hoveredAction?.id != act.id {
                appState.hoveredAction = act
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            }
        } else {
            if appState.hoveredAction != nil {
                appState.hoveredAction = nil
            }
        }
    }
}
