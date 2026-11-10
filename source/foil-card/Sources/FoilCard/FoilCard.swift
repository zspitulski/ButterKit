//
//  FoilCard.swift
//  FoilCard
//

import SwiftUI

/// Rounded card outline. The radius scales with the card's width, so the
/// corners keep their proportion at any size.
public struct FoilCardShape: Shape {
    /// Corner radius as a fraction of the card's width. The default is 36 px
    /// on a 1280 px wide card.
    public var cornerFraction: CGFloat

    public init(cornerFraction: CGFloat = 36.0 / 1280) {
        self.cornerFraction = cornerFraction
    }

    public func path(in rect: CGRect) -> Path {
        RoundedRectangle(cornerRadius: rect.width * cornerFraction, style: .continuous).path(in: rect)
    }
}

/// A card under the foil effect, built in the order that keeps it clean:
/// your content, a hairline edge, the rounded clip, one flattened layer,
/// then the foil.
///
/// Put text and other overlays inside `content`, so they get the same foil,
/// highlight and tilt as the artwork. Add a shadow outside the card.
public struct FoilCard<Content: View>: View {
    private let style: FoilStickerStyle
    private let shape: FoilCardShape
    private let edge: Color
    private let content: Content

    /// - Parameters:
    ///   - style: Foil settings. `.card` suits pale artwork with dark ink.
    ///   - shape: The card's rounded outline.
    ///   - edge: Hairline drawn just inside the outline, so a pale card
    ///     doesn't dissolve into a white window. Pass `.clear` to hide it.
    ///   - content: The card itself, usually an image plus overlays.
    public init(
        style: FoilStickerStyle = .card,
        shape: FoilCardShape = .init(),
        edge: Color = .black.opacity(0.1),
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.shape = shape
        self.edge = edge
        self.content = content()
    }

    public var body: some View {
        content
            // Stroked 2pt on the outline, then the clip below keeps only the
            // inner 1pt. Drawn before the foil, so it tilts with the card.
            .overlay { shape.stroke(edge, lineWidth: 2) }
            // Clip before the foil: the effect masks itself with this content,
            // so the rounded corners carry through the foil and the tilt.
            .clipShape(shape)
            // Flatten the card into one layer. Without this the foil runs on
            // each overlay's layer on its own, and its minimum tint fills the
            // overlay's transparent frame, leaving a tinted box around it.
            .compositingGroup()
            .foilSticker(style)
    }
}

#Preview {
    FoilCard {
        Color(red: 0.98, green: 0.95, blue: 0.85)
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                Text(verbatim: "Pro")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(Color(red: 0.17, green: 0.14, blue: 0.06))
                    .padding(32)
            }
    }
    .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
    .padding(24)
    .frame(width: 560)
}
