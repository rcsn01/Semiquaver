import XCTest
import SwiftUI
import MoirasiaUI
@testable import Semiquaver

// Pins the re-based player theme at its seam with the shared tokens: the
// card treatment must keep surface and border distinct from the canvas in
// both appearances. A regression to glass/ambient styling (surface melted
// into canvas) or a lost hairline border fails loudly here.
final class PlayerThemeTests: XCTestCase {
    func testSurfaceAndBorderTokensStayDistinctFromCanvas() {
        for (name, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            let canvas = Self.components(MoiraColor.canvas, appearance: appearance)
            let surface = Self.components(MoiraColor.surface, appearance: appearance)
            let border = Self.components(MoiraColor.border, appearance: appearance)

            XCTAssertNotEqual(surface, canvas, "surface must contrast with canvas in \(name)")
            XCTAssertNotEqual(border, surface, "border must read against surface in \(name)")
        }

        let lightSurface = Self.components(MoiraColor.surface, appearance: .aqua)
        let darkSurface = Self.components(MoiraColor.surface, appearance: .darkAqua)
        XCTAssertNotEqual(lightSurface, darkSurface, "surface must stay adaptive across appearances")
    }

    private static func components(_ color: Color, appearance: NSAppearance.Name) -> [CGFloat] {
        let nsAppearance = NSAppearance(named: appearance)
        var result: [CGFloat] = []
        nsAppearance?.performAsCurrentDrawingAppearance {
            guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return }
            result = [rgb.redComponent, rgb.greenComponent, rgb.blueComponent]
        }
        return result
    }
}