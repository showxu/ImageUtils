//
//  Color.swift
//
//

import CoreGraphics.CGError

extension CGError: Error { }

extension Color {
    
    public static let BLACK: Int64       = 0xff000000
    public static let DKGRAY: Int64      = 0xff444444
    public static let GRAY: Int64        = 0xff888888
    public static let LTGRAY: Int64      = 0xffcccccc
    public static let WHITE: Int64       = 0xffffffff
    public static let RED: Int64         = 0xffff0000
    public static let GREEN: Int64       = 0xff00ff00
    public static let BLUE: Int64        = 0xff0000ff
    public static let YELLOW: Int64      = 0xffffff00
    public static let CYAN: Int64        = 0xff00ffff
    public static let MAGENTA: Int64     = 0xffff00ff
    public static let TRANSPARENT: Int64 = 0
    
    /// Color reducer
    ///
    /// - Parameters:
    ///   - col: red at 0, green at 1, blue at 2, alpha at 3
    ///   - at: comp
    /// - Returns: r, g, b, a value
    /// - Throws: Outbound index error
    @_inlineable
    final public func component(_ at: Int) throws -> CGFloat {
        let cgColor = self.cgColor
        guard at < cgColor.numberOfComponents else {
            throw CGError.rangeCheck
        }
        return cgColor.components![at]
    }
    
    /// <p>Returns the value of the red component in the range defined by this
    /// color's color space (see {@link ColorSpace#getMinValue(int)} and
    /// {@link ColorSpace#getMaxValue(int)}).</p>
    ///
    /// <p>If this color's color model is not {@link ColorSpace.Model#RGB RGB},
    /// calling this method is equivalent to <code>getComponent(0)</code>.</p>
    ///
    /// @see #alpha()
    /// @see #red()
    /// @see #green
    /// @see #getComponents()
    @_inlineable
    final public var red: CGFloat? {
        return try? component(0)
    }
    
    /// <p>Returns the value of the green component in the range defined by this
    /// color's color space (see {@link ColorSpace#getMinValue(int)} and
    /// {@link ColorSpace#getMaxValue(int)}).</p>
    ///
    /// <p>If this color's color model is not {@link ColorSpace.Model#RGB RGB},
    /// calling this method is equivalent to <code>getComponent(1)</code>.</p>
    ///
    /// @see #alpha()
    /// @see #red()
    /// @see #green
    /// @see #getComponents()
    @_inlineable
    final public var green: CGFloat? {
        return try? component(1)
    }
    
    /// <p>Returns the value of the blue component in the range defined by this
    /// color's color space (see {@link ColorSpace#getMinValue(int)} and
    /// {@link ColorSpace#getMaxValue(int)}).</p>
    ///
    /// <p>If this color's color model is not {@link ColorSpace.Model#RGB RGB},
    /// calling this method is equivalent to <code>getComponent(2)</code>.</p>
    ///
    /// @see #alpha()
    /// @see #red()
    /// @see #green
    /// @see #getComponents()
    @_inlineable
    final public var blue: CGFloat? {
        return try? component(2)
    }
    
    /// Returns the value of the alpha component in the range \([0..1]\).
    /// Calling this method is equivalent to
    /// <code>getComponent(getComponentCount() - 1)</code>.
    ///
    /// @see #red()
    /// @see #green()
    /// @see #blue()
    /// @see #getComponents()
    /// @see #getComponent(int)
    @_inlineable
    final public var alpha: CGFloat? {
        return try? component(3)
    }
    
    // MARK: - @ColorInt
    /// Return the alpha component of a color int. This is the same as saying
    /// color >>> 24
    public final class func alpha(_ argb: Int) -> Int { return (argb >> 24) & 0xff }
    
    /// Return the red component of a color int. This is the same as saying
    /// (color >> 16) & 0xff
    public final class func red(_ argb: Int) -> Int { return (argb >> 16) & 0xff }
    
    /// Return the green component of a color int. This is the same as saying
    /// (color >> 8) & 0xff
    public final class func green(_ argb: Int) -> Int { return (argb >> 8) & 0xff }
    
    /// Return the blue component of a color int. This is the same as saying
    /// rgba & 0xff
    public final class func blue(_ argb: Int) -> Int { return argb & 0xff }
    
    /// Return a color-int from red, green, blue components.
    /// The alpha component is implicitly 255 (fully opaque).
    /// These component values should be \([0..255]\), but there is no
    /// range check performed, so if they are out of range, the
    /// returned color is undefined.
    ///
    /// - Parameters:
    ///   - red: Red component \([0..255]\) of the color
    ///   - green: Green component \([0..255]\) of the color
    ///   - blue: Blue component \([0..255]\) of the color
    /// - Returns: A color-int from red, green, blue components.
    public final class func rgb(_ red: Int, _ green: Int, _ blue: Int) -> Int {
        return argb(255, red, green, blue)
    }
    
    /// Return a color-int from red, green, blue float components
    /// in the range \([0..1]\). The alpha component is implicitly
    /// 1.0 (fully opaque). If the components are out of range, the
    /// returned color is undefined.
    ///
    /// - Parameters:
    ///   - red: Red component \([0..1]\) of the color
    ///   - green: Green component \([0..1]\) of the color
    ///   - blue: Blue component \([0..1]\) of the color
    /// - Returns: A color-int from red, green, blue float components
    public class func rgb(_ red: Float, _ green: Float, _ blue: Float) -> Int {
        return rgb(
            Int(red * 0xff + 0.5),
            Int(green * 0xff + 0.5),
            Int(blue * 0xff + 0.5)
        )
    }
    
    /// Return a color-int from alpha, red, green, blue components.
    /// These component values should be \([0..255]\), but there is no
    /// range check performed, so if they are out of range, the
    /// returned color is undefined.
    ///
    /// - Parameters:
    ///   - alpha: Alpha component \([0..255]\) of the color
    ///   - red: Red component \([0..255]\) of the color
    ///   - green: Green component \([0..255]\) of the color
    ///   - blue: Blue component \([0..255]\) of the color
    /// - Returns: A color-int from red, green, blue float components
    public class func argb(_ alpha: Int = 255, _ red: Int, _ green: Int, _ blue: Int) -> Int {
        #if arch(arm) || arch(i386)
            let a: Int64 = (Int64(alpha) << 24) & 0xff000000 // Shift alpha 24-bits and mask out other stuff
        #else
            let a = (alpha << 24) & 0xff000000
        #endif
        let r = (red << 16) & 0x00ff0000 // Shift red 16-bits and mask out other stuff
        let g = (green << 8) & 0x0000ff00 // Shift Green 8-bits and mask out other stuff
        let b = blue & 0x000000ff // Mask out anything not blue.
        
        // watchOS 32-bit Int overflow
        #if arch(arm) || arch(i386)
            let rgb: Int64 = 0xff00000000 | a | Int64(r|g|b) // 0xff000000 for 100% Alpha. Bitwise OR everything together.
            return Int(rgb)
        #else
            let rgb = 0xff00000000 | a | r | g | b
            return rgb
        #endif
    }
    
    /// Return a color-int from alpha, red, green, blue float components
    /// in the range \([0..1]\). If the components are out of range, the
    /// returned color is undefined.
    ///
    /// - Parameters:
    ///   - alpha: Alpha component \([0..1]\) of the color
    ///   - red: Red component \([0..1]\) of the color
    ///   - green: Green component \([0..1]\) of the color
    ///   - blue: Blue component \([0..1]\) of the color
    /// - Returns: A color-int from alpha, red, green, blue float components
    public class func argb(_ alpha: Float = 1.0, _ red: Float, _ green: Float, _ blue: Float) -> Int {
        return argb(
            Int(alpha * 0xff + 0.5),
            Int(red * 0xff + 0.5),
            Int(green * 0xff + 0.5),
            Int(blue * 0xff + 0.5)
        )
    }
}
