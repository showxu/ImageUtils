//
//  Palette.swift
//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 0xxd0 (http://github.com/0xxd0)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import CoreGraphics

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
    
    static let defaultResizeBitmapArea = 112 * 112
    static let defaultCalculateNumberColors = 16
    
    static let minContrastTitleText: Float = 3.0
    static let minContrastBodyText: Float = 4.5
    
    /// Start generating a {@link Palette} with the returned {@link Builder} instance.
    ///
    /// - Parameter bitmap: bitmap
    /// - Returns: biulder
    public static func from(_ bitmap: Bitmap) -> Builder {
        return Builder(bitmap)
    }
    
    /// Generate a {@link Palette} from the pre-generated list of {@link Palette.Swatch} swatches.
    /// This is useful for testing, or if you want to resurrect a {@link Palette} instance from a
    /// list of swatches. Will return null if the {@code swatches} is null.
    ///
    /// - Parameter swatches: swatchs
    /// - Returns: Palettes
    public static func from(_ swatches: [Swatch]) -> Palette? {
        // FIXME: Error handling
        return try! Builder(swatches).generate()
    }
    
    /// @deprecated Use {@link Builder} to generate the Palette.
    ///
    /// - Parameter bitmap: bitmap
    /// - Returns: palette
    @available(*, message: "deprecated Use {@link Builder} to generate the Palette.")
    public static func generate(_ bitmap: Bitmap) -> Palette {
        return from(bitmap).generate()
    }
    
    /// @deprecated Use {@link Builder} to generate the Palette.
    ///
    /// - Parameters:
    ///   - bitmap: bitmpa
    ///   - numColors: numColors
    /// - Returns: palette
    @available(*, message: "deprecated Use {@link Builder} to generate the Palette.")
    public static func generate(_ bitmap: Bitmap, _ numColors: Int) -> Palette {
        return from(bitmap).maximumColorCount(numColors).generate()
    }
    
    /// @deprecated Use {@link Builder} to generate the Palette.
    ///
    /// - Parameter bitmap: bitmap
    @available(*, message: "deprecated Use {@link Builder} to generate the Palette.")
    public static func generate(_ bitmap: Bitmap, _ async: ((Bitmap, Palette) -> Void)?) {
        return from(bitmap).generate({ p in
            async?(bitmap, p)
        })
    }
    
    /// @deprecated Use {@link Builder} to generate the Palette.
    ///
    /// - Parameters:
    ///   - bitmap: bitmap
    ///   - numColors: numColors
    ///   - async: callback
    /// - Notes: @deprecated Use {@link Builder} to generate the Palette.
    @available(*, message: "deprecated Use {@link Builder} to generate the Palette.")
    public static func generate(_ bitmap: Bitmap, _ numColors: Int, _ async: ((Bitmap, Palette) -> Void)?) {
        return from(bitmap).maximumColorCount(numColors).generate({ (p) in
            async?(bitmap, p)
        })
    }
    
    private var swatches: [Swatch]
    private var targets: [Target]
    
    private var selectedSwatches: [Target: Swatch] = [:]
    private var usedColors: [Int: Bool] = [:]
    
    private var dominantSwatch: Swatch?
    
    init(_ swatches: [Swatch], _ targets: [Target]) {
        self.swatches = swatches
        self.targets = targets
    
        dominantSwatch = findDominantSwatch()
    }
    
    /// Returns all of the swatches which make up the palette.
    ///
    /// - Returns: all of the swatches which make up the palette.
    public func getSwatches() -> [Swatch] {
        return swatches
    }

    /// Returns the targets used to generate this palette.
    ///
    /// - Returns: the targets used to generate this palette.
    public func getTargets() -> [Target] {
        return targets
    }
    
    /// Returns the most vibrant swatch in the palette. Might be null.
    ///
    /// - Returns: the most vibrant swatch in the palette. Might be null.
    /// - Notes: see Target#VIBRANT
    public func getVibrantSwatch() -> Swatch? {
        return getSwatchForTarget(Target.vibrant)
    }
    
    /// Returns a light and vibrant swatch from the palette. Might be null.
    ///
    /// - Returns: a light and vibrant swatch from the palette. Might be null.
    /// - Notes: see Target#LIGHT_VIBRANT
    public func getLightVibrantSwatch() -> Swatch? {
        return getSwatchForTarget(Target.lightVibrant)
    }
    
    /// Returns a dark and vibrant swatch from the palette. Might be null.
    ///
    /// - Returns: a dark and vibrant swatch from the palette. Might be null.
    /// - Notes: see Target#DARK_VIBRANT
    public func getDarkVibrantSwatch() -> Swatch? {
        return getSwatchForTarget(Target.darkVibrant)
    }
    
    /// Returns a muted swatch from the palette. Might be null.
    ///
    /// - Returns: a muted swatch from the palette. Might be null.
    /// - Notes: see Target#MUTED
    public func getMutedSwatch() -> Swatch? {
        return getSwatchForTarget(Target.muted)
    }
    
    /// Returns a muted and light swatch from the palette. Might be null.
    ///
    /// - Returns: a muted and light swatch from the palette. Might be null.
    /// - Notes: see Target#LIGHT_MUTED
    public func getLightMutedSwatch() -> Swatch? {
        return getSwatchForTarget(Target.lightMuted)
    }
    
    /// Returns a muted and dark swatch from the palette. Might be null.
    ///
    /// - Returns: a muted and dark swatch from the palette. Might be null.
    /// - Notes: see Target#DARK_MUTED
    public func getDarkMutedSwatch() -> Swatch? {
        return getSwatchForTarget(Target.darkMuted)
    }
    
    /// Returns the most vibrant color in the palette as an RGB packed int.
    ///
    /// - Parameter defaultColor: value to return if the swatch isn't available
    /// - Returns: the most vibrant color in the palette as an RGB packed int.
    /// - Notes: see #getVibrantSwatch()
    public func getVibrantColor(_ defaultColor: Int) -> Int {
        return getColorForTarget(Target.vibrant, defaultColor)
    }
    
    /// Returns a light and vibrant color from the palette as an RGB packed int.
    ///
    /// - Parameter defaultColor: value to return if the swatch isn't available
    /// - Returns: a light and vibrant color from the palette as an RGB packed int.
    /// - Notes: see #getLightVibrantSwatch()
    public func getLightVibrantColor(_ defaultColor: Int) -> Int {
        return getColorForTarget(Target.lightVibrant, defaultColor)
    }
    
    /// Returns a dark and vibrant color from the palette as an RGB packed int.
    ///
    /// - Parameter defaultColor: defaultColor value to return if the swatch isn't available
    /// - Returns: a dark and vibrant color from the palette as an RGB packed int.
    /// - Notes: see #getDarkVibrantSwatch()
    public func getDarkVibrantColor(_ defaultColor: Int) -> Int {
        return getColorForTarget(Target.darkVibrant, defaultColor)
    }
    
    /// Returns a muted color from the palette as an RGB packed int.
    ///
    /// - Parameter defaultColor: value to return if the swatch isn't available
    /// - Returns:  a muted color from the palette as an RGB packed int.
    /// - Notes: see #getMutedSwatch()
    public func getMutedColor(_ defaultColor: Int) -> Int {
        return getColorForTarget(Target.muted, defaultColor)
    }

    /// Returns a muted and light color from the palette as an RGB packed int.
    ///
    /// - Parameter defaultColor: value to return if the swatch isn't available
    /// - Returns: a muted and light color from the palette as an RGB packed int.
    /// - Notes: see #getLightMutedSwatch()
    public func getLightMutedColor(_ defaultColor: Int) -> Int {
        return getColorForTarget(Target.lightMuted, defaultColor)
    }

    /// Returns a muted and dark color from the palette as an RGB packed int.
    ///
    /// - Parameter defaultColor: value to return if the swatch isn't available
    /// - Returns: a muted and dark color from the palette as an RGB packed int.
    /// - Notes: see #getDarkMutedSwatch()
    public func getDarkMutedColor(_ defaultColor: Int) -> Int {
        return getColorForTarget(Target.darkMuted, defaultColor)
    }

    /// Returns the selected swatch for the given target from the palette, or {@code null} if one
    /// could not be found.
    ///
    /// - Parameter target: given target
    /// - Returns: selected swatch
    public func getSwatchForTarget(_ target: Target) -> Swatch? {
        return selectedSwatches[target]
    }

    /// Returns the selected color for the given target from the palette as an RGB packed int.
    ///
    /// - Parameters:
    ///   - target: given target
    ///   - defaultColor: value to return if the swatch isn't available
    /// - Returns: the selected color for the given target from the palette as an RGB packed int.
    public func getColorForTarget(_ target: Target, _ defaultColor: Int) -> Int {
        let swatch = getSwatchForTarget(target)
        return swatch?.getRgb() ?? defaultColor
    }
    
    /// Returns the dominant swatch from the palette.
    /// <p>The dominant swatch is defined as the swatch with the greatest population (frequency)
    /// within the palette.</p>
    ///
    /// - Returns: Returns the dominant swatch from the palette.
    public func getDominantSwatch() -> Swatch? {
        return dominantSwatch
    }
    
    /// Returns the color of the dominant swatch from the palette, as an RGB packed int.
    ///
    /// - Parameter defaultColor: defaultColor value to return if the swatch isn't available
    /// - Returns: the color of the dominant swatch from the palette, as an RGB packed int.
    /// - Notes: #getDominantSwatch()
    public func getDominantColor(_ defaultColor: Int) -> Int {
        return dominantSwatch?.getRgb() ?? defaultColor
    }
    
    func generate() {
        // We need to make sure that the scored targets are generated first. This is so that
        // inherited targets have something to inherit from
        for target in targets {
            target.normalizeWeights()
            selectedSwatches[target] = generateScoredTarget(target)
        }
        // We now clear out the used colors
        usedColors.removeAll()
    }
    
    private func generateScoredTarget(_ target: Target) -> Swatch? {
        let maxScoreSwatch = getMaxScoredSwatchForTarget(target)
        if maxScoreSwatch != nil, target.isExclusive {
            // If we have a swatch, and the target is exclusive, add the color to the used list
            usedColors[maxScoreSwatch!.getRgb()] = true
        }
        return maxScoreSwatch
    }
    
    private func getMaxScoredSwatchForTarget(_ target: Target) -> Swatch? {
        var maxScore = Float(0)
        var maxScoreSwatch: Swatch?
        for swatch in swatches {
            if (shouldBeScoredForTarget(swatch, target)) {
                let score = generateScore(swatch, target)
                if (maxScoreSwatch == nil || score > maxScore) {
                    maxScoreSwatch = swatch
                    maxScore = score
                }
            }
        }
        return maxScoreSwatch
    }
    
    private func shouldBeScoredForTarget(_ swatch: Swatch, _ target: Target) -> Bool {
        // Check whether the HSL values are within the correct ranges, and this color hasn't
        // been used yet.
        var hsl = swatch.getHsl()
        return hsl[1] >= target.getMinimumSaturation() && hsl[1] <= target.getMaximumSaturation()
            && hsl[2] >= target.getMinimumLightness() && hsl[2] <= target.getMaximumLightness()
            && !(usedColors[swatch.getRgb()] ?? false)
    }
    
    private func generateScore(_ swatch: Swatch, _ target: Target) -> Float {
        let hsl = swatch.getHsl()
        var saturationScore: Float = 0
        var luminanceScore: Float = 0
        var populationScore: Float = 0

        let maxPopulation = dominantSwatch?.getPopulation() ?? 1
    
        if target.getSaturationWeight() > 0 {
            saturationScore = target.getSaturationWeight() * (1 - abs(hsl[1] - target.getTargetSaturation()))
        }
        if target.getLightnessWeight() > 0 {
            luminanceScore = target.getLightnessWeight() * (1 - abs(hsl[2] - target.getTargetLightness()))
        }
        if target.getPopulationWeight() > 0 {
            populationScore = target.getPopulationWeight() * (Float(swatch.getPopulation()) / Float(maxPopulation))
        }
        return saturationScore + luminanceScore + populationScore
    }

    private func findDominantSwatch() -> Swatch? {
        var maxPop = Int.min
        var maxSwatch: Swatch?
        for swatch in swatches where swatch.getPopulation() > maxPop {
            maxSwatch = swatch
            maxPop = swatch.getPopulation()
        }
        return maxSwatch
    }
    
    private static func copyHslValues(_ color: Swatch) -> [Float] {
        let newHsl = color.getHsl()
        return newHsl
    }
}

/// Listener to be used with {@link #generateAsync(Bitmap, PaletteAsyncListener)} or
/// {@link #generateAsync(Bitmap, int, PaletteAsyncListener)}
public protocol PaletteAsyncListener {
    
    /// Called when the {@link Palette} has been generated.
    func onGenerated(_ palette: Palette)
}

extension Palette {

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
        public func getTitleTextColor() -> Int {
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
    }
}

extension Palette.Swatch: CustomStringConvertible {
    
    public var description: String {
        return  """
                [RGB: \(getRgb() /*.toHexString*/)]
                [HSL: \(getHsl() /*Arrays.toString()*/)])
                [Population: \(population)]
                [Title Text: \(getTitleTextColor() /*.toHexString*/)]
                [Body Text: \(getBodyTextColor() /*.toHexString*/)]
                """
    }
}

extension Palette.Swatch: CustomDebugStringConvertible {
    
    /// @Override public String toString()
    public var debugDescription: String {
        return description
    }
}

extension Palette.Swatch: Hashable {
    
    /// @Override public int hashCode() in Java
    public var hashValue: Int {
        return 31 * rgb + population
    }
}

extension Palette.Swatch: Equatable {
    
    /// @override public boolean equals(Object o) in Java
    public static func ==(lhs: Palette.Swatch, rhs: Palette.Swatch) -> Bool {
        if unsafeBitCast(lhs, to: OpaquePointer.self) == unsafeBitCast(rhs, to: OpaquePointer.self) {
            return true
        }
        return lhs.population == rhs.population && lhs.rgb == rhs.rgb
    }
}

extension Palette {
    
    public final class Builder {
        private var swatches: [Swatch]?
        private let bitmap: Bitmap?
        
        private var targets: [Target] = []
        
        private var maxColors: Int = Palette.defaultCalculateNumberColors
        private var resizeArea: Int = Palette.defaultResizeBitmapArea
        private var resizeMaxDimension: Int = -1
        
        private var filters: [PaletteFilter] = []
        private var region: Rect?
        
        /// Construct a new {@link Builder} using a source {@link Bitmap}
        public init(_ bitmap: Bitmap) {
            // Java oldman, nil check & menmory check is unnecessary in Swift.
            /* if (bitmap == null || bitmap.isRecycled()) {
                throw new IllegalArgumentException("Bitmap is not valid");
            } */
            filters.append(Palette.DefaultFilter())
            self.bitmap = bitmap
            swatches = nil
            // Add the default targets
            targets.append(Target.lightVibrant)
            targets.append(Target.vibrant)
            targets.append(Target.darkVibrant)
            targets.append(Target.lightMuted)
            targets.append(Target.muted)
            targets.append(Target.darkMuted)
        }
        
        /// Construct a new {@link Builder} using a list of {@link Swatch} instances.
        /// Typically only used for testing.
        public init(_ swatches: [Swatch]) throws {
            if /* swatches == null ||*/ swatches.isEmpty {
                // FIXME: Error handling
                print("List of Swatches is not valid")
                throw CGError.illegalArgument
            }
            filters.append(Palette.DefaultFilter())
            self.swatches = swatches
            bitmap = nil
        }
        
        /// Set the maximum number of colors to use in the quantization step when using a
        /// {@link android.graphics.Bitmap} as the source.
        /// <p>
        /// Good values for depend on the source image type. For landscapes, good values are in
        /// the range 10-16. For images which are largely made up of people's faces then this
        /// value should be increased to ~24.
        ///
        public func maximumColorCount(_ count: Int) -> Self {
            maxColors = count
            return self
        }
        
        /// Set the resize value when using a {@link android.graphics.Bitmap} as the source.
        /// If the bitmap's largest dimension is greater than the value specified, then the bitmap
        /// will be resized so that its largest dimension matches {@code maxDimension}. If the
        /// bitmap is smaller or equal, the original is used as-is.
        ///
        /// - Parameter maxDimension: maxDimension the number of pixels that the max dimension should be scaled down to,
        ///                             or any value <= 0 to disable resizing.
        /// - Returns: Builder
        /// - Notes: @deprecated Using {@link #resizeBitmapArea(int)} is preferred since it can handle
        ///             abnormal aspect ratios more gracefully.
        @available(*, message: "Using {@link #resizeBitmapArea(int)} is preferred since it can handle abnormal aspect ratios more gracefully.")
        public func resizeBitmapSize(_ maxDimension: Int) -> Builder {
            resizeMaxDimension = maxDimension
            resizeArea = -1
            return self
        }
        
        /// Set the resize value when using a {@link android.graphics.Bitmap} as the source.
        /// If the bitmap's area is greater than the value specified, then the bitmap
        /// will be resized so that its area matches {@code area}. If the
        ///  bitmap is smaller or equal, the original is used as-is.
        /// <p>
        /// This value has a large effect on the processing time. The larger the resized image is,
        /// the greater time it will take to generate the palette. The smaller the image is, the
        /// more detail is lost in the resulting image and thus less precision for color selection.
        ///
        /// @param area the number of pixels that the intermediary scaled down Bitmap should cover,
        ///             or any value <= 0 to disable resizing.
        ///
        public func resizeBitmapArea(_ area: Int) -> Builder {
            resizeArea = area
            resizeMaxDimension = -1
            return self
        }
        
        /// Clear all added filters. This includes any default filters added automatically by
        /// {@link Palette}.
        ///
        public func clearFilters() -> Builder {
            filters.removeAll()
            return self
        }
        
        /// Add a filter to be able to have fine grained control over which colors are
        /// allowed in the resulting palette.
        ///
        /// - Returns: filter filter to add.
        public func addFilter(_ filter: PaletteFilter) -> Builder {
            filters.append(filter)
            return self
        }
        
        /// Set a region of the bitmap to be used exclusively when calculating the palette.
        /// <p>This only works when the original input is a {@link Bitmap}.</p>
        ///
        /// - Parameters:
        ///   - left: left The left side of the rectangle used for the region.
        ///   - top: The top of the rectangle used for the region.
        ///   - right: right The right side of the rectangle used for the region.
        ///   - bottom: bottom The bottom of the rectangle used for the region.
        /// - Returns: Builder
        public func setRegion(left: Int, top: Int, right: Int, bottom: Int) -> Builder {
            if bitmap != nil {
                if region == nil { region = Rect() }
                // Set the Rect to be initially the whole Bitmap
                region = Rect(origin: .zero, size: bitmap!.size)
                // Now just get the intersection with the region
                if region?.intersects(Rect(left: left, top: top, right: right, bottom: bottom)) == false {
                    print("The given region must intersect with the Bitmap's dimensions.")
                    // IllegalArgumentException()
                }
            }
            return self
        }
        
        /// Clear any previously region set via {@link #setRegion(int, int, int, int)}.
        public func clearRegion() -> Builder {
            region = nil
            return self
        }
        
        /// Add a target profile to be generated in the palette.
        ///
        /// <p>You can retrieve the result via {@link Palette#getSwatchForTarget(Target)}.</p>
        public func addTarget(_ target: Target) -> Builder {
            if !targets.contains(target) {
                targets.append(target)
            }
            return self
        }
        
        /// Clear all added targets. This includes any default targets added automatically by
        /// {@link Palette}.
        ///
        public func clearTargets() -> Builder {
            targets.removeAll()
            return self
        }
        
        /// Generate and return the {@link Palette} synchronously.
        public func generate() -> Palette {
            var swatches: Array<Swatch>
            if (bitmap != nil) {
                // We have a Bitmap so we need to use quantization to reduce the number of colors
                // First we'll scale down the bitmap if needed
                let bitmap = scaleBitmapDown(self.bitmap!)
                var region = self.region
                if (bitmap != self.bitmap && region != nil) {
                    // If we have a scaled bitmap and a selected region, we need to scale down the
                    // region to match the new scale
                    let scale = Double(bitmap.width / self.bitmap!.width)
                    region!.left = Int(floor(Double(region!.left) * scale))
                    region!.top = Int(floor(Double(region!.top) * scale))
                    region!.right = Int(min(Int(ceil(Double(region!.right) * scale)), Int(bitmap.width)))
                    region!.bottom = min(Int(ceil(Double(region!.bottom) * scale)), Int(bitmap.height))
                }
                // Now generate a quantizer from the Bitmap
                let quantizer = ColorCutQuantizer(
                    getPixelsFromBitmap(bitmap),
                    maxColors,
                    filters)
                // If created a new bitmap, recycle it
                swatches = quantizer.getQuantizedColors()
            } else {
                // Else we're using the provided swatches
                swatches = self.swatches!
            }
            // Now create a Palette instance
            let p = Palette(swatches, targets)
            // And make it generate itself
            p.generate()
            return p
        }
        
        /// Generate the {@link Palette} asynchronously.
        ///
        /// - Parameter callBack: callBack
        public func generate(_ async: ((Palette) -> Void)?) {
            DispatchQueue.global(qos: .default).async {
                let p = self.generate()
                DispatchQueue.main.async {
                    async?(p)
                }
            }
        }
        
        private func getPixelsFromBitmap(_ bitmap: Bitmap)-> [Int] {
            let width = Int(bitmap.width)
            let height = Int(bitmap.height)
            
            var pixels = Array(repeating: 0, count: width * height)
            bitmap.getPixels(&pixels, 0, 0, width, height)
         
            if (region == nil) {
                // If we don't have a region, return all of the pixels
                return pixels
            } else {
                // If we do have a region, lets create a subset array containing only the region's
                // pixels
                let regionWidth = Int(region!.width)
                let regionHeight = Int(region!.height)
                // pixels contains all of the pixels, so we need to iterate through each row and
                // copy the regions pixels into a new smaller array
                var subsetPixels = Array(repeating: 0, count: regionWidth * regionHeight)
                for row in 0..<regionHeight {
                    let startIndex = row * regionWidth
                    let endIndex = startIndex + regionWidth
                    subsetPixels[startIndex..<endIndex] = pixels[startIndex..<endIndex]
                }
                return subsetPixels
            }
        }
 
        /// Scale the bitmap down as needed.
        private func scaleBitmapDown(_ bitmap: Bitmap) -> Bitmap {
            var scaleRatio: Double = -1
            if resizeArea > 0 {
                let bitmapArea = Int(bitmap.width * bitmap.height)
                if bitmapArea > resizeArea {
                    scaleRatio = sqrt(Double(resizeArea) / Double(bitmapArea))
                }
            } else if resizeMaxDimension > 0 {
                let maxDimension = max(bitmap.width, bitmap.height)
                if maxDimension > CGFloat(resizeMaxDimension) {
                    scaleRatio = Double(resizeMaxDimension) / Double(maxDimension)
                }
            }
            if (scaleRatio <= 0) {
                // Scaling has been disabled or not needed so just return the Bitmap
                return bitmap
            }
            return bitmap.resized(to: CGSize(
                width: Int(ceil(Double(bitmap.width) * scaleRatio)),
                height: Int(ceil(Double(bitmap.height) * scaleRatio))
            )) ?? bitmap
        }
    }
}

/// A Filter provides a mechanism for exercising fine-grained control over which colors
/// are valid within a resulting {@link Palette}.
public protocol PaletteFilter {

    /// Hook to allow clients to be able filter colors from resulting palette.
    ///
    /// - Parameters:
    ///   - rgb: the color in RGB888.
    ///   - hsl: HSL representation of the color.
    /// - Returns: true if the color is allowed, false if not.
    /// - Notes: see Builder#addFilter(Filter)
    func isAllowed(_ rgb: Int, _ hsl: [Float]) -> Bool
}

extension Palette {
    
    /// The default filter
    struct DefaultFilter: PaletteFilter {
        let blackMaxLightness: Float = 0.05
        let whiteMinLightness: Float = 0.95
        
        func isAllowed(_ rgb: Int, _ hsl: [Float]) -> Bool {
            return !isWhite(hsl) && !isBlack(hsl) && !isNearRedILine(hsl)
        }
        
        /// Return true if the color represents a color which is close to black.
        ///
        /// - Parameter hslColor: hslColor
        /// - Returns: true if the color represents a color which is close to black.
        private func isBlack(_ hslColor: [Float]) -> Bool {
            return hslColor[2] <= blackMaxLightness
        }
        
        /// Return true if the color represents a color which is close to white.
        ///
        /// - Parameter hslColor: hslColor
        /// - Returns: true if the color represents a color which is close to white.
        private func isWhite(_ hslColor: [Float]) -> Bool {
            return hslColor[2] >= whiteMinLightness
        }
        
        /**
         * @return true if the color lies close to the red side of the I line.
         */
        private func isNearRedILine(_ hslColor: [Float]) -> Bool {
            return hslColor[0] >= 10 && hslColor[0] <= 37 && hslColor[1] <= 0.82
        }
    }
}

