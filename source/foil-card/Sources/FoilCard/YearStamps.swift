//
//  YearStamps.swift
//  FoilCard
//

import SwiftUI

/// Passport-style ink stamps, one per calendar year from `since` through
/// this year. The newest is darkest and older ones fade. Each year gets its
/// own stable tilt and nudge, so the stamps look hand pressed but don't move
/// between launches.
///
/// Use it as an overlay on the card's artwork. It lays out in the artwork's
/// own pixel space and scales with the rendered card.
public struct YearStamps: View {
    private let since: Date
    private let now: Date
    private let top: String
    private let bottom: String
    private let ink: Color
    private let region: CGRect
    private let artworkWidth: CGFloat
    private let maxStamps: Int

    /// - Parameters:
    ///   - since: First year to stamp.
    ///   - now: Last year to stamp. Defaults to today.
    ///   - top: Lettering over the top of each stamp. Keep it to about 10
    ///     characters.
    ///   - bottom: Lettering under the bottom of each stamp.
    ///   - ink: Stamp color.
    ///   - region: Empty area of the artwork to fill, in its pixels.
    ///   - artworkWidth: The artwork's full width in pixels.
    ///   - maxStamps: More than this and they'd overlap too much to read, so
    ///     only the newest show.
    public init(
        since: Date,
        now: Date = .now,
        top: String,
        bottom: String,
        ink: Color = Color(red: 0xF2 / 255, green: 0xA7 / 255, blue: 0x0E / 255),
        region: CGRect,
        artworkWidth: CGFloat,
        maxStamps: Int = 6
    ) {
        self.since = since
        self.now = now
        self.top = top
        self.bottom = bottom
        self.ink = ink
        self.region = region
        self.artworkWidth = artworkWidth
        self.maxStamps = max(1, maxStamps)
    }

    // Stamp sizes and offsets below are in units where the region is 206
    // tall, then scaled to the real region.
    private static let designRegionHeight: CGFloat = 206

    // Full size for up to three, a little smaller for each one past that.
    private static func diameter(count: Int) -> CGFloat {
        count <= 3 ? 160 : max(124, 160 - 12 * CGFloat(count - 3))
    }

    private var years: [Int] {
        let calendar = Calendar.current
        let last = calendar.component(.year, from: now)
        let first = min(calendar.component(.year, from: since), last)
        return Array(max(first, last - maxStamps + 1)...last)
    }

    public var body: some View {
        GeometryReader { proxy in
            let unit = proxy.size.width / artworkWidth
            let k = region.height / Self.designRegionHeight
            let years = years
            let newest = years.last ?? 0
            let d = Self.diameter(count: years.count) * k
            // Side by side, just overlapping, squeezing closer when there
            // are many.
            let step = years.count > 1
                ? min(d * 0.95, (region.width - d) / CGFloat(years.count - 1))
                : 0
            // Past three, alternate up and down so neighbors overlap less.
            let stagger: CGFloat = years.count > 3 ? 24 * k : 0
            // Oldest first, so the newest is pressed on top.
            ForEach(Array(years.enumerated()), id: \.element) { index, year in
                YearStamp(year: year, top: top, bottom: bottom, ink: ink, unit: unit * d / YearStamp.designDiameter)
                    .rotationEffect(.degrees(Self.jitter(year, salt: 1) * 16))
                    // Newest darkest, each older year a little lighter.
                    .opacity(max(0.45, 0.9 - 0.12 * Double(newest - year)))
                    .position(
                        x: (region.minX + d / 2 + step * CGFloat(index) + Self.jitter(year, salt: 2) * 8 * k) * unit,
                        y: (region.midY + (index.isMultiple(of: 2) ? -stagger : stagger)
                            + Self.jitter(year, salt: 3) * (stagger > 0 ? 8 : 14) * k) * unit
                    )
            }
        }
        // Like real ink: darkens the card rather than covering it.
        .blendMode(.multiply)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // Stable pseudo-random value in -1...1 for a year, so each stamp keeps
    // its tilt and offset across launches.
    private static func jitter(_ year: Int, salt: UInt64) -> Double {
        var x = UInt64(bitPattern: Int64(year)) &* 0x9E37_79B9_7F4A_7C15 &+ salt &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 31
        x &*= 0x94D0_49BB_1331_11EB
        x ^= x >> 29
        return Double(x % 2001) / 1000 - 1
    }
}

// One round stamp: double ring, lettering over the top and under the bottom,
// stars at the sides and the year in the middle. Sized in design units times
// `unit` (points per design unit).
private struct YearStamp: View {
    let year: Int
    let top: String
    let bottom: String
    let ink: Color
    let unit: CGFloat

    // Size the stamp is drawn at, in design units, before `unit`.
    static let designDiameter: CGFloat = 160

    var body: some View {
        let d = Self.designDiameter
        let ringText: CGFloat = 61     // radius of the lettering's center line
        ZStack {
            Circle()
                .strokeBorder(lineWidth: 6 * unit)
            Circle()
                .strokeBorder(lineWidth: 2.5 * unit)
                .padding(26 * unit)
            StampArcText(text: top, radius: ringText * unit, fontSize: 15 * unit, degreesPerCharacter: 11, bottom: false)
            StampArcText(text: bottom, radius: ringText * unit, fontSize: 15 * unit, degreesPerCharacter: 11, bottom: true)
            ForEach([-1.0, 1.0], id: \.self) { side in
                Text(verbatim: "★")
                    .font(.system(size: 11 * unit))
                    .offset(x: side * ringText * unit)
            }
            // Verbatim so it never gets a grouping separator ("2,026").
            Text(verbatim: String(year))
                .font(.system(size: 34 * unit, weight: .heavy))
        }
        .foregroundStyle(ink)
        .frame(width: d * unit, height: d * unit)
    }
}

// Uppercase monospaced letters set around a circle: over the top reading
// clockwise, or under the bottom reading left to right with the letters'
// tops toward the center, like a rubber stamp.
private struct StampArcText: View {
    let text: String
    let radius: CGFloat
    let fontSize: CGFloat
    let degreesPerCharacter: Double
    let bottom: Bool

    var body: some View {
        let characters = Array(text.uppercased())
        ZStack {
            ForEach(characters.indices, id: \.self) { i in
                let fromMiddle = Double(i) - Double(characters.count - 1) / 2
                Text(verbatim: String(characters[i]))
                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                    .offset(y: bottom ? radius : -radius)
                    .rotationEffect(.degrees(fromMiddle * degreesPerCharacter * (bottom ? -1 : 1)))
            }
        }
    }
}
