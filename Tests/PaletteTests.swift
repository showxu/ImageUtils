//
//  PaletteTests.swift
//
//

import XCTest
@testable import ImageUtils

class PaletteTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPalette() {
        #if os(macOS)
        let preview = Image(.init(width: 200, height: 200), color: .red, radius: 20)
        #else
        let preview = Image(named: "preview.png",
                            in: Bundle(for: PaletteTests.self),
                            compatibleWith: nil)
        #endif
        let palette = Palette.from(preview!).generate()
        let _ = palette.getSwatches()
        let _ = Color(hex: palette.getVibrantColor(0))
        let _ = Color(hex: palette.getDarkVibrantColor(0))
        let _ = Color(hex: (palette.getLightVibrantColor(0)))
        let _ = Color(hex: palette.getMutedColor(0))
        let _ = Color(hex: palette.getDarkMutedColor(0))
        let _ = Color(hex: palette.getLightMutedColor(0))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
