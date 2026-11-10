//
//  FoilSticker.swift
//  FoilCard
//
//  Adapted from Sticker by Benjamin Pisano (https://github.com/bpisano/Sticker),
//  StickerEffect.swift and PointerHoverStickerMotionEffect.swift at v1.4.0.
//  MIT License, Copyright (c) 2024 bpisano. See NOTICE.md.
//
//  Changes from Sticker: one modifier taking a style value instead of
//  environment values, the foil's minimum tint is a setting (see
//  FoilSticker.metal), the tilt rests at exactly 0 off-hover, and the tilt,
//  foil shift and highlight ease in and out instead of snapping.
//

import SwiftUI

/// Settings for `.foilSticker(_:)`. The defaults match Sticker's.
public struct FoilStickerStyle: Equatable, Sendable {
    /// Size of the rainbow bands.
    public var scale: Float
    /// How much foil color mixes into light pixels.
    public var colorIntensity: Float
    /// Foil color mixed into every pixel, however dark. Sticker fixes this
    /// at 0.3, which turns dark ink muddy.
    public var minimumTint: Float
    /// Base brightness of the foil colors.
    public var contrast: Float
    /// Size of the diamond pattern.
    public var checkerScale: Float
    /// 1 hides the diamond pattern. Further from 1 shows it more.
    public var checkerIntensity: Float
    /// Size of the grain.
    public var noiseScale: Float
    /// 1 hides the grain. Further from 1 shows it more.
    public var noiseIntensity: Float
    /// Strength of the highlight that follows the pointer.
    public var lightIntensity: Float
    /// How far the view tilts toward the pointer. 0 turns the tilt off.
    public var hoverTilt: Double
    /// Scale while hovered, eased in and out with the tilt. 1 = no change.
    public var hoverScale: CGFloat

    public init(
        scale: Float = 3,
        colorIntensity: Float = 0.8,
        minimumTint: Float = 0.3,
        contrast: Float = 0.9,
        checkerScale: Float = 5,
        checkerIntensity: Float = 1.2,
        noiseScale: Float = 100,
        noiseIntensity: Float = 1.2,
        lightIntensity: Float = 0.3,
        hoverTilt: Double = 1,
        hoverScale: CGFloat = 1
    ) {
        self.scale = scale
        self.colorIntensity = colorIntensity
        self.minimumTint = minimumTint
        self.contrast = contrast
        self.checkerScale = checkerScale
        self.checkerIntensity = checkerIntensity
        self.noiseScale = noiseScale
        self.noiseIntensity = noiseIntensity
        self.lightIntensity = lightIntensity
        self.hoverTilt = hoverTilt
        self.hoverScale = hoverScale
    }
}

public extension FoilStickerStyle {
    /// Tuned for a wide card of pale artwork with dark ink, like ButterKit's
    /// license card.
    static let card = FoilStickerStyle(
        // The foil tints light pixels hardest, and pale cream art washes out
        // at the default 0.8.
        colorIntensity: 0.25,
        // Keeps dark ink and text from turning a muddy purple-grey.
        minimumTint: 0.1,
        checkerScale: 3.5,
        checkerIntensity: 0.95,
        noiseScale: 200,
        // A stronger highlight reads as a hot spot on pale art.
        lightIntensity: 0.08,
        // The same angle swings a wide card's edges much further than a
        // small sticker's.
        hoverTilt: 0.05,
        hoverScale: 1.02
    )
}

extension View {
    /// Holographic foil look: a rainbow foil tint with a diamond pattern and
    /// grain, plus a highlight and tilt that follow the pointer. Shaped by
    /// this view's alpha, so clip it first for rounded corners.
    public func foilSticker(_ style: FoilStickerStyle = .init()) -> some View {
        modifier(FoilStickerModifier(style: style))
    }
}

// Copy the files into an app target instead of using the package, and the
// shaders build into the app's default library.
private var foilShaders: ShaderLibrary {
    #if SWIFT_PACKAGE
    .bundle(.module)
    #else
    .default
    #endif
}

private struct FoilStickerModifier: ViewModifier {
    let style: FoilStickerStyle

    /// Last pointer position relative to the view's center.
    @State private var pointer: CGPoint = .zero
    /// 0 with the pointer away, 1 while hovering. Animated, so the tilt, foil
    /// shift and highlight ease in and out together.
    @State private var engagement: CGFloat = 0
    @State private var isHovering = false
    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .modifier(FoilStickerRender(style: style, size: size, pointer: pointer, engagement: engagement))
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    let point = CGPoint(x: location.x - size.width / 2, y: location.y - size.height / 2)
                    if isHovering {
                        // Glide after the pointer rather than snapping to it.
                        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.85)) {
                            pointer = point
                        }
                    } else {
                        // Start from the entry point (nothing shows of it
                        // while engagement is 0), then ease in.
                        isHovering = true
                        pointer = point
                        withAnimation(.smooth(duration: 0.25)) { engagement = 1 }
                    }
                case .ended:
                    isHovering = false
                    withAnimation(.smooth(duration: 0.35)) { engagement = 0 }
                }
            }
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
    }
}

/// Draws one frame of the effect. Animatable, so SwiftUI hands it in-between
/// pointer and engagement values while either is animating.
private struct FoilStickerRender: ViewModifier, Animatable {
    let style: FoilStickerStyle
    let size: CGSize
    var pointer: CGPoint
    var engagement: CGFloat

    nonisolated var animatableData: AnimatablePair<CGPoint.AnimatableData, CGFloat> {
        get { AnimatablePair(pointer.animatableData, engagement) }
        set {
            pointer.animatableData = newValue.first
            engagement = newValue.second
        }
    }

    func body(content: Content) -> some View {
        // Plain copies for the @Sendable shader closures. At engagement 0
        // this matches Sticker's idle state: foil offset (0.5, 0.5), no
        // highlight, no tilt.
        let style = style
        let pointer = pointer
        let e = engagement
        let foilOffset = CGPoint(
            x: 0.5 + (pointer.x * -150 - 0.5) * e,
            y: 0.5 + (pointer.y * -150 - 0.5) * e
        )
        let light = style.lightIntensity * Float(e)
        let tiltX = size.width > 0 ? Double(pointer.x / size.width * e) * style.hoverTilt : 0
        let tiltY = size.height > 0 ? Double(pointer.y / size.height * e) * style.hoverTilt : 0

        content
            .visualEffect { view, proxy in
                view.colorEffect(foilShaders.foilStickerReflection(
                    .float2(proxy.size),
                    .float2(
                        (pointer.x + proxy.size.width / 2) / proxy.size.width,
                        (pointer.y + proxy.size.height / 2) / proxy.size.height
                    ),
                    .float(Float(min(proxy.size.width, proxy.size.height) / 2)),
                    .float(light)
                ))
            }
            .visualEffect { view, proxy in
                view.colorEffect(foilShaders.foilSticker(
                    .float2(foilOffset),
                    .float2(proxy.size),
                    .float(style.scale),
                    .float(style.colorIntensity),
                    .float(style.minimumTint),
                    .float(style.contrast),
                    .float(style.checkerScale),
                    .float(style.checkerIntensity),
                    .float(style.noiseScale),
                    .float(style.noiseIntensity)
                ))
            }
            // The shaders also tint transparent pixels. Keep only the
            // view's own shape.
            .mask(content)
            .scaleEffect(1 + (style.hoverScale - 1) * e)
            .rotation3DEffect(.radians(tiltX), axis: (0, 1, 0))
            .rotation3DEffect(.radians(tiltY), axis: (-1, 0, 0))
    }
}
