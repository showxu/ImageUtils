//
//  Palette.swift
//
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
    
    static let logTag = "Palette"
    static let logTimings = false

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
        /*
        /// Generate and return the {@link Palette} synchronously.
        public func generate() -> Palette {
            /* final TimingLogger logger = LOG_TIMINGS
                ? new TimingLogger(LOG_TAG, "Generation")
                : null; */
            var swatches: Array<Swatch>
            if (bitmap != nil) {
                // We have a Bitmap so we need to use quantization to reduce the number of colors
                // First we'll scale down the bitmap if needed
                let bitmap = scaleBitmapDown(self.bitmap!)
                // FIXME: Log
                /* if (logger != null) {
                    logger.addSplit("Processed Bitmap");
                } */
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
                    filters.isEmpty ? null : filters.toArray(new Filter[mFilters.size()]));
        
                // If created a new bitmap, recycle it
                if (bitmap != mBitmap) {
                    bitmap.recycle();
                }
        
                swatches = quantizer.getQuantizedColors();
        
                if (logger != null) {
                    logger.addSplit("Color quantization completed");
                }
            } else {
                // Else we're using the provided swatches
                swatches = mSwatches;
            }
        
            // Now create a Palette instance
            final Palette p = new Palette(swatches, mTargets);
            // And make it generate itself
            p.generate();
        
            if (logger != null) {
                logger.addSplit("Created Palette");
                logger.dumpToLog();
            }
        
            return p;
        }
        
        private int[] getPixelsFromBitmap(Bitmap bitmap) {
        final int bitmapWidth = bitmap.getWidth();
        final int bitmapHeight = bitmap.getHeight();
        final int[] pixels = new int[bitmapWidth * bitmapHeight];
        bitmap.getPixels(pixels, 0, bitmapWidth, 0, 0, bitmapWidth, bitmapHeight);
        
        if (mRegion == null) {
        // If we don't have a region, return all of the pixels
        return pixels;
        } else {
        // If we do have a region, lets create a subset array containing only the region's
        // pixels
        final int regionWidth = mRegion.width();
        final int regionHeight = mRegion.height();
        // pixels contains all of the pixels, so we need to iterate through each row and
        // copy the regions pixels into a new smaller array
        final int[] subsetPixels = new int[regionWidth * regionHeight];
        for (int row = 0; row < regionHeight; row++) {
        System.arraycopy(pixels, ((row + mRegion.top) * bitmapWidth) + mRegion.left,
        subsetPixels, row * regionWidth, regionWidth);
        }
        return subsetPixels;
        }
        }
        */
    
        /// Scale the bitmap down as needed.
        private func scaleBitmapDown(_ bitmap: Bitmap) -> Bitmap {
            var scaleRatio: Double = -1
            if resizeArea > 0 {
                let bitmapArea = Int(bitmap.width * bitmap.height)
                if bitmapArea > resizeArea {
                    scaleRatio = sqrt(Double(resizeArea / bitmapArea))
                }
            } else if resizeMaxDimension > 0{
                let maxDimension = max(bitmap.width, bitmap.height)
                if maxDimension > CGFloat(resizeMaxDimension) {
                    scaleRatio = Double(resizeMaxDimension) / Double(maxDimension)
                }
            }
            if (scaleRatio <= 0) {
                // Scaling has been disabled or not needed so just return the Bitmap
                return bitmap
            }
            return Bitmap.createScaledBitmap(bitmap,
                                             Int(ceil(Double(bitmap.width) * scaleRatio)),
                                             Int(ceil(Double(bitmap.height) * scaleRatio)),
                                             false)!
        }
    }
}
    

    
    /**

 
    

    


    



    /**
     * Generate the {@link Palette} asynchronously. The provided listener's
     * {@link PaletteAsyncListener#onGenerated} method will be called with the palette when
     * generated.
     */
    @NonNull
    public AsyncTask<Bitmap, Void, Palette> generate(final PaletteAsyncListener listener) {
    if (listener == null) {
    throw new IllegalArgumentException("listener can not be null");
    }
    
    return new AsyncTask<Bitmap, Void, Palette>() {
    @Override
    protected Palette doInBackground(Bitmap... params) {
    try {
    return generate();
    } catch (Exception e) {
    Log.e(LOG_TAG, "Exception thrown during async generate", e);
    return null;
    }
    }
    
    @Override
    protected void onPostExecute(Palette colorExtractor) {
    listener.onGenerated(colorExtractor);
    }
    }.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, mBitmap);
    }
    
    private int[] getPixelsFromBitmap(Bitmap bitmap) {
    final int bitmapWidth = bitmap.getWidth();
    final int bitmapHeight = bitmap.getHeight();
    final int[] pixels = new int[bitmapWidth * bitmapHeight];
    bitmap.getPixels(pixels, 0, bitmapWidth, 0, 0, bitmapWidth, bitmapHeight);
    
    if (mRegion == null) {
    // If we don't have a region, return all of the pixels
    return pixels;
    } else {
    // If we do have a region, lets create a subset array containing only the region's
    // pixels
    final int regionWidth = mRegion.width();
    final int regionHeight = mRegion.height();
    // pixels contains all of the pixels, so we need to iterate through each row and
    // copy the regions pixels into a new smaller array
    final int[] subsetPixels = new int[regionWidth * regionHeight];
    for (int row = 0; row < regionHeight; row++) {
    System.arraycopy(pixels, ((row + mRegion.top) * bitmapWidth) + mRegion.left,
    subsetPixels, row * regionWidth, regionWidth);
    }
    return subsetPixels;
    }
    }

}
*/

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

