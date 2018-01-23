//
//  Palette.swift
//
//

/**
 * A helper class to extract prominent colors from an image.
 * <p>
 * A number of colors with different profiles are extracted from the image:
 * <ul>
 *     <li>Vibrant</li>
 *     <li>Vibrant Dark</li>
 *     <li>Vibrant Light</li>
 *     <li>Muted</li>
 *     <li>Muted Dark</li>
 *     <li>Muted Light</li>
 * </ul>
 * These can be retrieved from the appropriate getter method.
 *
 * <p>
 * Instances are created with a {@link Builder} which supports several options to tweak the
 * generated Palette. See that class' documentation for more information.
 * <p>
 * Generation should always be completed on a background thread, ideally the one in
 * which you load your image on. {@link Builder} supports both synchronous and asynchronous
 * generation:
 *
 * <pre>
 * // Synchronous
 * Palette p = Palette.from(bitmap).generate();
 *
 * // Asynchronous
 * Palette.from(bitmap).generate(new PaletteAsyncListener() {
 *     public void onGenerated(Palette p) {
 *         // Use generated instance
 *     }
 * });
 * </pre>
 */
public final class Palette {
}

extension Palette {
    
    static let defaultResizeBitmapArea = 112 * 112
    static let defaultCalculateNumberColors = 16
    
    static let minContrastTitleText: Float = 3.0
    static let minContrastBodyText: Float = 4.5
    
    static let logTag = "Palette"
    static let logTimings = false
    
    /// Represents a color swatch generated from an image's palette. The RGB color can be retrieved
    /// by calling {@link #getRgb()}.
    public final class Swatch {
        
        private final var red: Int
        private final var green: Int
        private final var blue: Int
        
        private final var rgb: Int
        private final var population: Int
        
        private var generatedTextColors: Bool = false
        private var titleTextColor: Int = 0
        private var bodyTextColor: Int = 0
        
        private var hsl: [Float] = .init(repeating: 0, count: 3)
        
        public init(color: Int, population: Int) {
            self.red = Color.red(color)
            self.green = Color.green(color)
            self.blue = Color.blue(color)
            self.rgb = color
            self.population = population
        }
        
        init(red: Int, green: Int, blue: Int, population: Int) {
            self.red = red
            self.green = green
            self.blue = blue
            self.rgb = Color.rgb(red, green, blue)
            self.population = population
        }
        
        convenience init(hsl: [Float], population: Int) {
            self.init(color: Color.Utils.hslToColor(hsl), population: population)
            self.hsl = hsl
        }
        
        /// Return this swatch's RGB color value
        ///
        /// - Returns: this swatch's RGB color value
        public func getRgb() -> Int {
            return rgb
        }
        
        /// Return this swatch's HSL values.
        ///     hsv[0] is Hue [0 .. 360)
        ///     hsv[1] is Saturation [0...1]
        ///     hsv[2] is Lightness [0...1]
        ///
        /// - Returns: this swatch's HSL values.
        public func getHsl() -> [Float] {
            Color.Utils.rgbToHSL(r: red, g: green, b: blue, outHsl: &hsl)
            return hsl
        }

        /// Return the number of pixels represented by this swatch
        ///
        /// - Returns: the number of pixels represented by this swatch
        public func getPopulation() -> Int {
            return population
        }

        /// Returns an appropriate color to use for any 'title' text which is displayed over this
        /// {@link Swatch}'s color. This color is guaranteed to have sufficient contrast.
        ///
        /// - Returns: an appropriate color to use for any 'title' text which is displayed over this
        /// @ColorInt
        public func getTitleTextColor() throws -> Int {
            // FIXME: Error handling
            try! ensureTextColorsGenerated()
            return titleTextColor
        }

        /// Returns an appropriate color to use for any 'body' text which is displayed over this
        /// {@link Swatch}'s color. This color is guaranteed to have sufficient contrast.
        ///
        public func getBodyTextColor() -> Int {
            // FIXME: Error handling
            try! ensureTextColorsGenerated()
            return bodyTextColor
        }
        
        private static func ensureTextColorsGenerated(_ swatch: Swatch) throws {
            do {
                try swatch.ensureTextColorsGenerated()
            } catch {
                throw error
            }
        }
        
        private func ensureTextColorsGenerated() throws {
            guard !generatedTextColors else { return }
            do {
                // First check white, as most colors will be dark
                let lightBodyAlpha = try Color.Utils.calculateMinimumAlpha(Int(Color.WHITE), rgb, Palette.minContrastBodyText)
                let lightTitleAlpha = try Color.Utils.calculateMinimumAlpha(Int(Color.WHITE), rgb, Palette.minContrastTitleText)
                
                if lightBodyAlpha != -1 && lightTitleAlpha != -1 {
                    // If we found valid light values, use them and return
                    bodyTextColor = try Color.Utils.setAlphaComponent(Int(Color.WHITE), alpha: lightBodyAlpha)
                    titleTextColor = try Color.Utils.setAlphaComponent(Int(Color.WHITE), alpha: lightTitleAlpha)
                    generatedTextColors = true
                    return
                }
                
                let darkBodyAlpha = try Color.Utils.calculateMinimumAlpha(
                    Int(Color.BLACK), rgb, Palette.minContrastBodyText)
                let darkTitleAlpha = try Color.Utils.calculateMinimumAlpha(
                    Int(Color.BLACK), rgb, Palette.minContrastTitleText)
                
                if (darkBodyAlpha != -1 && darkTitleAlpha != -1) {
                    // If we found valid dark values, use them and return
                    bodyTextColor = try Color.Utils.setAlphaComponent(Int(Color.BLACK), alpha: darkBodyAlpha)
                    titleTextColor = try Color.Utils.setAlphaComponent(Int(Color.BLACK), alpha: darkTitleAlpha)
                    generatedTextColors = true
                    return
                }
                // If we reach here then we can not find title and body values which use the same
                // lightness, we need to use mismatched values
                bodyTextColor = lightBodyAlpha != -1
                    ? try Color.Utils.setAlphaComponent(Int(Color.WHITE), alpha: lightBodyAlpha)
                    : try Color.Utils.setAlphaComponent(Int(Color.BLACK), alpha: darkBodyAlpha)
                titleTextColor = lightTitleAlpha != -1
                    ? try Color.Utils.setAlphaComponent(Int(Color.WHITE), alpha: lightTitleAlpha)
                    : try Color.Utils.setAlphaComponent(Int(Color.BLACK), alpha: darkTitleAlpha)
                generatedTextColors = true
            } catch {
                throw error
            }
        }
        //
        //        @Override
        //        public String toString() {
        //        return new StringBuilder(getClass().getSimpleName())
        //        .append(" [RGB: #").append(Integer.toHexString(getRgb())).append(']')
        //        .append(" [HSL: ").append(Arrays.toString(getHsl())).append(']')
        //        .append(" [Population: ").append(mPopulation).append(']')
        //        .append(" [Title Text: #").append(Integer.toHexString(getTitleTextColor()))
        //        .append(']')
        //        .append(" [Body Text: #").append(Integer.toHexString(getBodyTextColor()))
        //        .append(']').toString();
        //        }
        //
        //        @Override
        //        public boolean equals(Object o) {
        //        if (this == o) {
        //        return true;
        //        }
        //        if (o == null || getClass() != o.getClass()) {
        //        return false;
        //        }
        //
        //        Swatch swatch = (Swatch) o;
        //        return mPopulation == swatch.mPopulation && mRgb == swatch.mRgb;
        //        }
        //
        //        @Override
        //        public int hashCode() {
        //        return 31 * mRgb + mPopulation;
        //        }
    }
}
