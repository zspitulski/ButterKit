//
//  FoilCardSweep.swift
//  FoilCard
//

import SwiftUI

public extension AnyTransition {
    /// Reveals the inserted card with a soft diagonal sweep, left to right,
    /// with a faint sheen riding the edge. Stack it over the card it
    /// replaces, and give that card `.foilCardHold` as its removal, so the
    /// old card stays fully visible under the sweep. When the two artworks
    /// line up, the card reads as taking on color.
    ///
    /// - Parameters:
    ///   - overflow: How far the reveal mask reaches past the card on every
    ///     side. The mask stays on the card after the transition, so this
    ///     must cover the hover lift and tilt. Match the padding around the
    ///     card.
    ///   - shape: The card's outline, which keeps the sheen off its corners.
    static func foilCardSweep(overflow: CGFloat = 24, shape: FoilCardShape = .init()) -> AnyTransition {
        .modifier(
            active: FoilCardSweep(progress: 0, overflow: overflow, shape: shape),
            identity: FoilCardSweep(progress: 1, overflow: overflow, shape: shape)
        )
    }

    /// Keeps a removed card fully visible until the animation ends, under an
    /// incoming `.foilCardSweep`.
    static var foilCardHold: AnyTransition {
        .modifier(active: FoilCardHold(progress: 1), identity: FoilCardHold(progress: 0))
    }
}

private struct FoilCardSweep: ViewModifier, Animatable {
    var progress: CGFloat  // 0 = hidden, 1 = fully shown
    let overflow: CGFloat
    let shape: FoilCardShape

    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    // Sweep direction, 15° below horizontal, so the edge leans like "/".
    private static let angle = 15.0 * Double.pi / 180
    private static let direction = CGVector(dx: cos(angle), dy: sin(angle))

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let (start, end) = edge(card: proxy.size, inMaskSpace: false, from: -0.6, to: 1)
                    Rectangle()
                        .fill(LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0), location: 0),
                                .init(color: .white.opacity(0.35), location: 0.6),
                                .init(color: .white.opacity(0), location: 1),
                            ],
                            startPoint: start,
                            endPoint: end
                        ))
                        // Peaks mid-sweep and is gone by the end.
                        .opacity(max(0, sin(Double(progress) * .pi)))
                        .blendMode(.plusLighter)
                }
                // Keep the sheen off the cut-away corners.
                .clipShape(shape)
                .allowsHitTesting(false)
            }
            .mask {
                GeometryReader { proxy in
                    let card = CGSize(
                        width: proxy.size.width - 2 * overflow,
                        height: proxy.size.height - 2 * overflow
                    )
                    let (start, end) = edge(card: card, inMaskSpace: true, from: 0, to: 1)
                    Rectangle().fill(LinearGradient(
                        colors: [.black, .clear],
                        startPoint: start,
                        endPoint: end
                    ))
                }
                .padding(-overflow)
            }
    }

    // The soft edge as gradient end points, in unit coordinates (which may
    // fall outside the drawing rect). The sweep runs across the card grown by
    // `overflow` on every side, so it fully covers the mask. `inMaskSpace`
    // picks the rect the points are for: that grown rect (the mask) or the
    // card itself (the sheen), so both line up. `from` and `to` pick a slice
    // of the edge band, as fractions of its width. At progress 0 the band
    // sits wholly before the first corner. At 1 it has passed the last.
    private func edge(card: CGSize, inMaskSpace: Bool, from: CGFloat, to: CGFloat) -> (UnitPoint, UnitPoint) {
        guard card.width > 0, card.height > 0 else { return (.leading, .trailing) }
        let o = overflow
        let swept = CGSize(width: card.width + 2 * o, height: card.height + 2 * o)
        let rect = inMaskSpace ? swept : card
        let shift = inMaskSpace ? 0 : o
        let d = Self.direction
        // Narrow enough that the two cards barely overlap mid-sweep.
        let soft = card.width * 0.16
        let span = swept.width * d.dx + swept.height * d.dy + soft
        let lead = progress * span - soft
        func point(_ t: CGFloat) -> UnitPoint {
            let along = lead + t * soft
            return UnitPoint(x: (along * d.dx - shift) / rect.width, y: (along * d.dy - shift) / rect.height)
        }
        return (point(from), point(to))
    }
}

// Draws nothing itself. Only its animatable value tells SwiftUI to keep the
// removed card around for the length of the animation.
private struct FoilCardHold: ViewModifier, Animatable {
    var progress: CGFloat

    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View { content }
}
