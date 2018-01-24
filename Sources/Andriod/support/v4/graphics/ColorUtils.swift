//
//  Color.swift
//
//

import UIKit

// infix operator <<<< : AdditionPrecedence

extension Color { public struct Utils { } }

extension Color.Utils {
    
    private static let minAlphaSearchMaxIterations: Int = 10
    private static let minAlphaSearchPrecision: Int = 1
    
    /// Composite two potentially translucent colors over each other and returns the result.
    public static func compositeColors(_ foreground: Int, _ background: Int) -> Int {
        let bgAlpha = Color.alpha(background)
        let fgAlpha = Color.alpha(foreground)
        let a = compositeAlpha(fgAlpha, bgAlpha)
    
        let r = compositeComponent(Color.red(foreground), fgAlpha, Color.red(background), bgAlpha, a)
        let g = compositeComponent(Color.green(foreground), fgAlpha, Color.green(background), bgAlpha, a)
        let b = compositeComponent(Color.blue(foreground), fgAlpha, Color.blue(background), bgAlpha, a)
    
        return Color.argb(a, r, g, b)
    }
    
    private static func compositeAlpha(_ foregroundAlpha: Int, _ backgroundAlpha: Int) -> Int {
        return 0xff - (((0xff - backgroundAlpha) * (0xff - foregroundAlpha)) / 0xff)
    }
    
    private static func compositeComponent(_ fgC: Int, _ fgA: Int, _ bgC: Int, _ bgA: Int, _ a: Int) -> Int {
        if (a == 0) { return 0 }
        return ((0xff * fgC * fgA) + (bgC * bgA * (0xFF - fgA))) / (a * 0xFF)
    }
    
    /// Returns the luminance of a color as a float between {@code 0.0} and {@code 1.0}.
    /// <p>Defined as the Y component in the XYZ representation of {@code color}.</p>
    ///
    /// - Returns: @FloatRange(from = 0.0, to = 1.0)
    public static func calculateLuminance(_ color: Int) -> Double {
        var result = getTempDouble3Array()
        colorToXYZ(color, outXyz: &result)
        // Luminance is the Y component
        return result[1] / 100
    }

    /// Returns the contrast ratio between {@code foreground} and {@code background}.
    /// {@code background} must be opaque.
    /// <p>
    /// Formula defined
    /// <a href="http://www.w3.org/TR/2008/REC-WCAG20-20081211/#contrast-ratiodef">here</a>.
    ///
    public static func calculateContrast(_ foreground: Int, _ background: Int) throws -> Double {
        if (Color.alpha(background) != 255) {
            assertionFailure("background can not be translucent: \(background)")
            throw CGError.illegalArgument
        }
        var foreground = foreground
        if (Color.alpha(foreground) < 255) {
            // If the foreground is translucent, composite the foreground over the background
            foreground = compositeColors(foreground, background)
        }
        let luminance1 = calculateLuminance(foreground) + 0.05
        let luminance2 = calculateLuminance(background) + 0.05
        // Now return the lighter luminance divided by the darker luminance
        return max(luminance1, luminance2) / min(luminance1, luminance2)
    }
    
    /**
     * Calculates the minimum alpha value which can be applied to {@code foreground} so that would
     * have a contrast value of at least {@code minContrastRatio} when compared to
     * {@code background}.
     *
     * @param foreground       the foreground color
     * @param background       the opaque background color
     * @param minContrastRatio the minimum contrast ratio
     * @return the alpha value in the range 0-255, or -1 if no value could be calculated
     */
    public static func calculateMinimumAlpha(_ foreground: Int, _ background: Int, _ minContrastRatio: Float) throws -> Int {
        if (Color.alpha(background) != 255) {
            assertionFailure("background can not be translucent: \(background))")
            throw CGError.illegalArgument
        }
        // First lets check that a fully opaque foreground has sufficient contrast
        do {
            var testForeground = try setAlphaComponent(foreground, alpha: 255)
            var testRatio = try calculateContrast(testForeground, background)
            if (testRatio < Double(minContrastRatio)) {
                // Fully opaque foreground does not have sufficient contrast, return error
                return -1
            }
            // Binary search to find a value with the minimum value which provides sufficient contrast
            var numIterations = 0
            var minAlpha = 0
            var maxAlpha = 255
            
            while numIterations <= minAlphaSearchMaxIterations && (maxAlpha - minAlpha) > minAlphaSearchPrecision {
                let testAlpha = (minAlpha + maxAlpha) / 2
                testForeground = try setAlphaComponent(foreground, alpha: testAlpha)
                testRatio = try calculateContrast(testForeground, background)
                    
                if testRatio < Double(minContrastRatio) {
                    minAlpha = testAlpha
                } else {
                    maxAlpha = testAlpha
                }
                numIterations += 1
            }
            // Conservatively return the max of the range of possible alphas, which is known to pass.
            return maxAlpha
        } catch {
            throw error
        }
    }
    
    /// Convert RGB components to HSL (hue-saturation-lightness).
    /// <ul>
    /// <li>outHsl[0] is Hue [0 .. 360)</li>
    /// <li>outHsl[1] is Saturation [0...1]</li>
    /// <li>outHsl[2] is Lightness [0...1]</li>
    /// </ul>
    ///
    /// - Parameters:
    ///   - r: red component value [0..255]
    ///   - g: green component value [0..255]
    ///   - b: blue component value [0..255]
    ///   - outHsl: 3-element array which holds the resulting HSL components
    public static func rgbToHSL(r: Int, g: Int, b: Int, outHsl: inout [Float]) {
        let rf = Float(r) / 255
        let gf = Float(g) / 255
        let bf = Float(b) / 255
        
        let max = Swift.max(rf, Swift.max(gf, bf))
        let min = Swift.min(rf, Swift.min(gf, bf))
        let deltaMaxMin = max - min
        
        var h: Float, s: Float
        let l = (max + min) / 2

        if (max == min) {
            // Monochromatic
            h = 0; s = 0
        } else {
            if (max == rf) {
                // '%' is unavailable: Use truncatingRemainder instead
                h = ((gf - bf) / deltaMaxMin).truncatingRemainder(dividingBy: 6)
            } else if (max == gf) {
                h = ((bf - rf) / deltaMaxMin) + 2
            } else {
                h = ((rf - gf) / deltaMaxMin) + 4
            }
            s = deltaMaxMin / (1 - abs(2 * l - 1))
        }
        // '%' is unavailable: Use truncatingRemainder instead
        h = (h * 60).truncatingRemainder(dividingBy: 360)
        if (h < 0) {
            h += 360
        }

        outHsl[0] = constrain(h, low: 0, high: 360)
        outHsl[1] = constrain(s, low: 0, high: 1)
        outHsl[2] = constrain(l, low: 0, high: 1)
    }

    /// Convert the ARGB color to its HSL (hue-saturation-lightness) components.
    /// <ul>
    /// <li>outHsl[0] is Hue [0 .. 360)</li>
    /// <li>outHsl[1] is Saturation [0...1]</li>
    /// <li>outHsl[2] is Lightness [0...1]</li>
    /// </ul>
    ///
    /// - Parameters:
    ///   - color: the ARGB color to convert. The alpha component is ignored
    ///   - outHsl: 3-element array which holds the resulting HSL components
    public static func colorToHSL(_ color: Int, _ outHsl: inout [Float]){
        rgbToHSL(r: Color.red(color), g: Color.green(color), b: Color.blue(color), outHsl: &outHsl)
    }
    
    /// Convert HSL (hue-saturation-lightness) components to a RGB color.
    /// <ul>
    /// <li>hsl[0] is Hue [0 .. 360)</li>
    /// <li>hsl[1] is Saturation [0...1]</li>
    /// <li>hsl[2] is Lightness [0...1]</li>
    /// </ul>
    /// If hsv values are out of range, they are pinned.
    ///
    /// - Parameter hsl: 3-element array which holds the input HSL components
    /// - Returns: the resulting RGB color
    public static func hslToColor(_ hsl: [Float]) -> Int {
        assert(hsl.count >= 3, "The number of element of hsl must be greater than 3.")
        //let xxx = Utils() <<<< (1, 2)
        let h = hsl[0]
        let s = hsl[1]
        let l = hsl[2]
        
        let c = (1 - abs(2 * l - 1)) * s
        let m = l - 0.5 * c
        let x = c * (1 - abs((h / Float(60 % 2)) - 1))
        
        let hueSegment = Int(h / 60)
        
        var r: Float = 0, g: Float = 0, b: Float = 0
        
        switch hueSegment {
        case 0:
            r = round(255 * (c + m))
            g = round(255 * (x + m))
            b = round(255 * m)
            break
        case 1:
            r = round(255 * (x + m))
            g = round(255 * (c + m))
            b = round(255 * m)
            break
        case 2:
            r = round(255 * m)
            g = round(255 * (c + m))
            b = round(255 * (x + m))
            break
        case 3:
            r = round(255 * m)
            g = round(255 * (x + m))
            b = round(255 * (c + m))
            break
        case 4:
            r = round(255 * (x + m))
            g = round(255 * m)
            b = round(255 * (c + m))
            break
        case 5:
            fallthrough
        case 6:
            r = round(255 * (c + m))
            g = round(255 * m)
            b = round(255 * (x + m))
            break
        default:
            break
        }
        
        r = constrain(r, low: 0, high: 255)
        g = constrain(g, low: 0, high: 255)
        b = constrain(b, low: 0, high: 255)
        
        return Color.rgb(Int(r), Int(g), Int(b))
    }
    
    /// Convert the ARGB color to its CIE XYZ representative components.
    ///
    /// <p>The resulting XYZ representation will use the D65 illuminant and the CIE
    /// 2° Standard Observer (1931).</p>
    ///
    /// <ul>
    /// <li>outXyz[0] is X [0 ...95.047)</li>
    /// <li>outXyz[1] is Y [0...100)</li>
    /// <li>outXyz[2] is Z [0...108.883)</li>
    /// </ul>
    ///
    /// - Parameters:
    ///   - color: the ARGB color to convert. The alpha component is ignored
    ///   - outXyz: 3-element array which holds the resulting LAB components
    public static func colorToXYZ(_ color: Int, outXyz: inout [Double]) {
        try? rgbToXYZ(r: Color.red(color), g: Color.green(color), b: Color.blue(color), outXyz: &outXyz)
    }

    /// Convert RGB components to its CIE XYZ representative components.
    ///
    /// <p>The resulting XYZ representation will use the D65 illuminant and the CIE
    /// 2° Standard Observer (1931).</p>
    ///
    /// <ul>
    /// <li>outXyz[0] is X [0 ...95.047)</li>
    /// <li>outXyz[1] is Y [0...100)</li>
    /// <li>outXyz[2] is Z [0...108.883)</li>
    /// </ul>
    ///
    /// - Parameters:
    ///   - r: red component value [0..255]
    ///   - g: green component value [0..255]
    ///   - b: blue component value [0..255]
    ///   - outXyz: 3-element array which holds the resulting XYZ components
    /// - Throws: illegalArgument
    public static func rgbToXYZ(r: Int, g: Int, b: Int, outXyz: inout [Double]) throws {
        if (outXyz.count != 3) {
            assertionFailure("outXyz must have a length of 3.")
            throw CGError.illegalArgument
        }
        var sr = Double(r) / 255.0
        sr = sr < 0.04045 ? sr / 12.92 : pow((sr + 0.055) / 1.055, 2.4)
        var sg = Double(g) / 255.0
        sg = sg < 0.04045 ? sg / 12.92 : pow((sg + 0.055) / 1.055, 2.4)
        var sb = Double(b) / 255.0
        sb = sb < 0.04045 ? sb / 12.92 : pow((sb + 0.055) / 1.055, 2.4)
    
        outXyz[0] = 100 * (sr * 0.4124 + sg * 0.3576 + sb * 0.1805)
        outXyz[1] = 100 * (sr * 0.2126 + sg * 0.7152 + sb * 0.0722)
        outXyz[2] = 100 * (sr * 0.0193 + sg * 0.1192 + sb * 0.9505)
    }
        
    /// Set the alpha component of {@code color} to be {@code alpha}.
    ///
    /// - Parameters:
    ///   - color: @ColorInt
    ///   - alpha: alpha
    /// - Returns: return
    public static func setAlphaComponent(_ color: Int, alpha: Int) throws -> Int {
        if (alpha < 0 || alpha > 255) {
            assertionFailure("alpha must be between 0 and 255.")
            throw CGError.illegalArgument
        }
        return (color & 0x00ffffff) | (alpha << 24)
    }
    
    private static func constrain(_ amount: Float, low: Float, high: Float) -> Float {
        return clamp(amount, lower: low, upper: high)
    }
    
    private static func constrain(_ amount: Int, low: Int, high: Int) -> Float {
        return Float(clamp(amount, lower: low, upper: high))
    }
    
    private static func getTempDouble3Array() -> [Double] {
        // FIXME: ThreadLocal<Array>
        let result = [Double](repeating: 0, count: 3)
        return result
    }
}

