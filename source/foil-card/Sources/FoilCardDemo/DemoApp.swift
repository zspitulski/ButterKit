//
//  DemoApp.swift
//  FoilCardDemo
//
//  A small Mac app to try the card. Run `swift run FoilCardDemo` in this
//  folder, or open Package.swift in Xcode and run the FoilCardDemo scheme.
//

#if os(macOS)
import AppKit
import FoilCard
import SwiftUI

@main
struct FoilCardDemoApp: App {
    init() {
        // `swift run` starts a bare executable. Make it a regular app with a
        // Dock icon and bring its window forward.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()
    }

    var body: some Scene {
        WindowGroup("Foil Card") {
            DemoView()
        }
        .windowResizability(.contentSize)
    }
}

private struct DemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isUnlocked = true
    @State private var yearsAgo = 2
    @State private var style = FoilStickerStyle.card

    private let artwork: NSImage = Bundle.module.url(forResource: "card", withExtension: "webp")
        .flatMap(NSImage.init(contentsOf:)) ?? NSImage()

    private var since: Date {
        Calendar.current.date(byAdding: .year, value: -yearsAgo, to: .now) ?? .now
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            cards
                .frame(width: 600)
            controls
                .frame(width: 300)
        }
        .frame(height: 420)
    }

    // The locked card always sits below the unlocked one, so unlocking sweeps
    // the new card in over the old, and locking fades it out to reveal the
    // old one.
    private var cards: some View {
        ZStack {
            if !isUnlocked {
                card(isUnlocked: false)
                    .transition(.asymmetric(insertion: .identity, removal: .foilCardHold))
            }
            if isUnlocked {
                card(isUnlocked: true)
                    .transition(.asymmetric(
                        insertion: reduceMotion ? .opacity : .foilCardSweep(),
                        removal: .opacity
                    ))
            }
        }
        .animation(.snappy(duration: 0.25), value: isUnlocked)
        // On the stack rather than each card, so the sweep doesn't briefly
        // double it.
        .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
        // Room for the hover lift and tilt. Matches the sweep's overflow.
        .padding(24)
    }

    private func card(isUnlocked: Bool) -> some View {
        FoilCard(style: style) {
            Image(nsImage: artwork)
                .resizable()
                .scaledToFit()
                // Stands in for a separate locked artwork.
                .grayscale(isUnlocked ? 0 : 1)
                .overlay {
                    MemberSince(date: since, isUnlocked: isUnlocked)
                    if isUnlocked {
                        YearStamps(
                            since: since,
                            top: "PRO MEMBER",
                            bottom: "YOUR APP",
                            region: CGRect(x: 684, y: 396, width: 552, height: 206),
                            artworkWidth: 1280
                        )
                    }
                }
        }
    }

    private var controls: some View {
        Form {
            Section {
                Toggle("Unlocked", isOn: $isUnlocked)
                Stepper(value: $yearsAgo, in: 0...7) {
                    Text("Member since \(String(Calendar.current.component(.year, from: since)))")
                }
            }
            Section("Foil") {
                slider("Color", value: $style.colorIntensity, in: 0...1)
                slider("Minimum tint", value: $style.minimumTint, in: 0...0.5)
                slider("Highlight", value: $style.lightIntensity, in: 0...0.5)
                slider("Tilt", value: $style.hoverTilt, in: 0...0.3)
                slider("Hover scale", value: $style.hoverScale, in: 1...1.06)
                Button("Reset") { style = .card }
                    .disabled(style == .card)
            }
        }
        .formStyle(.grouped)
    }

    private func slider<V: BinaryFloatingPoint>(_ title: String, value: Binding<V>, in range: ClosedRange<V>) -> some View
    where V.Stride: BinaryFloatingPoint {
        LabeledContent(title) {
            Slider(value: value, in: range)
                .labelsHidden()
                .frame(width: 140)
        }
    }
}

// The date under the artwork's printed "MEMBER SINCE" label, with a
// highlight bar behind it. Laid out in the artwork's own 1280×720 pixel
// space and scaled to the rendered card, so it stays locked to the artwork
// at any size.
private struct MemberSince: View {
    let date: Date
    let isUnlocked: Bool

    nonisolated private static let artworkWidth: CGFloat = 1280
    nonisolated private static let leading: CGFloat = 684        // column of the printed label
    nonisolated private static let baseline: CGFloat = 327
    nonisolated private static let fontSize: CGFloat = 54
    nonisolated private static let barHeight: CGFloat = 12
    nonisolated private static let barBelowBaseline: CGFloat = 3

    nonisolated private static let ink = Color(red: 0x2C / 255, green: 0x24 / 255, blue: 0x10 / 255)
    nonisolated private static let butter = Color(red: 0xFF / 255, green: 0xD1 / 255, blue: 0x49 / 255)
    // Warm enough to stay beige under the foil. A neutral grey turns lilac.
    nonisolated private static let sand = Color(red: 0xE5 / 255, green: 0xD3 / 255, blue: 0xB0 / 255)

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / Self.artworkWidth
            ZStack(alignment: .topLeading) {
                Color.clear
                Text(date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.system(size: Self.fontSize * scale, weight: .bold))
                    .foregroundStyle(Self.ink)
                    .fixedSize()
                    // Bar spans the text's width and sits on its baseline.
                    .background(alignment: Alignment(horizontal: .center, vertical: .firstTextBaseline)) {
                        Rectangle()
                            .fill(isUnlocked ? Self.butter : Self.sand)
                            .frame(height: Self.barHeight * scale)
                            .alignmentGuide(.firstTextBaseline) { d in
                                d.height - Self.barBelowBaseline * scale
                            }
                    }
                    // Pin the text's left edge and baseline to artwork pixels.
                    .alignmentGuide(.leading) { _ in -Self.leading * scale }
                    .alignmentGuide(.top) { d in d[.firstTextBaseline] - Self.baseline * scale }
            }
        }
    }
}
#else
@main
enum FoilCardDemo {
    static func main() {
        print("The demo runs on macOS.")
    }
}
#endif
