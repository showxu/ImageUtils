//
//  Color+Utils.swift
//  ImageUtils
//
//

import CoreGraphics.CGGeometry
import libkern
import Darwin

extension Color {
    
    public final class func red(_ hex: Int) -> Int {
        let red = (hex >> 16) & 0xff;
        return red
    }
    
    public final class func green(_ hex: Int) -> Int {
        let green = (hex >> 8) & 0xffF
        return green
    }
    
    public final class func blue(_ hex: Int) -> Int {
        let blue = hex & 0xff;
        return blue
    }
    
    public final class func hex(red: Int, green: Int, blue: Int) -> Int {
        let r = (red << 16) & 0x00ff0000 // Shift red 16-bits and mask out other stuff
        let g = (green << 8) & 0x0000ff00 // Shift Green 8-bits and mask out other stuff
        let b = blue & 0x000000ff // Mask out anything not blue.

        // watchOS Int 32-bit overflow
        #if arch(arm) || arch(i386)
            let rgb: UInt = 0xff000000 | UInt(r|g|b) // 0xff000000 for 100% Alpha. Bitwise OR everything together.
            return Int(rgb)
        #else
            let rgb = 0xff000000 | r | g | b
            return rgb
        #endif
    }
}

extension CGError: Error {
    
}

extension Color {
    
    /// Color reducer
    ///
    /// - Parameters:
    ///   - col: red at 0, green at 1, blue at 2, alpha at 3
    ///   - at: comp
    /// - Returns: r, g, b, a value
    /// - Throws: Outbound index error
    @_inlineable
    final public class func rgba(reduce col: Color, at: Int) throws -> CGFloat {
        let cgCol = col.cgColor
        guard at < cgCol.numberOfComponents else {
            throw CGError.rangeCheck
        }
        let cpn = cgCol.components![at]
        return cpn
    }
    
    @_inlineable
    final public class func red(
        _ col: Color, _ reduce: (Color, Int) throws -> CGFloat = rgba) rethrows -> CGFloat {
        return try reduce(col, 0)
    }
    
    @_inlineable
    final public class func green(
        _ col: Color, _ reduce: (Color, Int) throws -> CGFloat = rgba) rethrows -> CGFloat {
        return try reduce(col, 1)
    }
    
    @_inlineable
    final public class func blue(
        _ col: Color, _ reduce: (Color, Int) throws -> CGFloat = rgba) rethrows -> CGFloat {
        return try reduce(col, 2)
    }
    
    @_inlineable
    final public class func alpha(
        _ col: Color, _ reduce: (Color, Int) throws -> CGFloat = rgba) rethrows -> CGFloat {
        return try reduce(col, 3)
    }
}

extension Color {
    
    @_inlineable
    final public var red: CGFloat? {
        return try? Color.rgba(reduce: self, at: 0)
    }
    
    @_inlineable
    final public var green: CGFloat? {
        return try? Color.rgba(reduce: self, at: 1)
    }
    
    @_inlineable
    final public var blue: CGFloat? {
        return try? Color.rgba(reduce: self, at: 2)
    }
    
    @_inlineable
    final public var alpha: CGFloat? {
        return try? Color.rgba(reduce: self, at: 3)
    }
}
