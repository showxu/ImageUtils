//
//  MaterialDesignTests.swift
//
//

import XCTest
@testable import ImageUtils

class MaterialDesignTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPalette() {
        let preview = UIImage(named: "preview.png",
                              in: Bundle(for: MaterialDesignTests.self),
                              compatibleWith: nil)
        let palette = Palette.from(preview!).generate()

        let vibrant = Color(hex: palette.getVibrantColor(0))
        let vibrantView = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 200))
        vibrantView.backgroundColor = vibrant
        
        let vibrantDark = Color(hex: palette.getDarkVibrantColor(0))
        let vibrantDarkView = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 200))
        vibrantDarkView.backgroundColor = vibrantDark
        
        let vibrantLight = Color(hex: (palette.getLightVibrantColor(0)))
        let vibrantLightView = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 200))
        vibrantLightView.backgroundColor = vibrantLight
        
        let muted = Color(hex: palette.getMutedColor(0))
        let mutedView = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 200))
        mutedView.backgroundColor = muted
        
        let mutedDark = Color(hex: palette.getDarkMutedColor(0))
        let mutedDarkView = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 200))
        mutedDarkView.backgroundColor = mutedDark
        
        let mutedLight = Color(hex: palette.getLightMutedColor(0))
        let mutedLightView = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 200))
        mutedLightView.backgroundColor = mutedLight
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
