//
//  Color+Utils.swift
//
//

import CoreGraphics.CGError

extension Color {
    
    public convenience init(hex: Int, alpha: Float = 1) {
        self.init(r: Color.red(hex), g: Color.green(hex), b: Color.blue(hex), a: alpha)
    }
    
    public convenience init(r: Int, g: Int, b: Int, a: Float) {
        self.init(red: CGFloat(r) / 255,
                  green: CGFloat(g) / 255,
                  blue: CGFloat(b) / 255,
                  alpha: CGFloat(a))
    }
}

