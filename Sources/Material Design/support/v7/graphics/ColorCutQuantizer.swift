//
//  ColorCutQuantizer.swift
//
//

import libkern

///
/// An color quantizer based on the Median-cut algorithm, but optimized for picking out distinct
/// colors rather than representation colors.
///
/// The color space is represented as a 3-dimensional cube with each dimension being an RGB
/// component. The cube is then repeatedly divided until we have reduced the color space to the
/// requested number of colors. An average color is then generated from each cube.
///
/// What makes this different to median-cut is that median-cut divided cubes so that all of the cubes
/// have roughly the same population, where this quantizer divides boxes based on their color volume.
/// This means that the color space is divided into distinct colors, rather than representative
/// colors.
///
final class ColorCutQuantizer {
    
    static var componentRed: Int = -3;
    static var componentGreen: Int = -2;
    static var componentBlue: Int = -1;
    
    private static var quantizeWordWidth = 5
    private static var quantizeWordMask = (1 << quantizeWordWidth) - 1
    
    var colors: [Int] = []
    var histogram: [Int] = []
    var quantizedColors: [Palette.Swatch] = []

    var filters: [PaletteFilter]
    
    private var tempHsl: [Float] = [Float](repeating: 0, count: 3)
    
    /// Constructor.
    ///
    /// - Parameters:
    ///   - pixels: pixels histogram representing an image's pixel data
    ///   - maxColors: maxColors The maximum number of colors that should be in the result palette.
    ///   - filters: filters Set of filters to use in the quantization stage
    init(_ pixels: [Int], _ maxColors: Int, _ filters: [PaletteFilter]) {
        self.filters = filters
        var pixels = pixels
        var hist = [Int](repeating: 0, count: 1 << (ColorCutQuantizer.quantizeWordWidth * 3))
        
        for (i, pixel) in pixels.enumerated() {
            let quantizedColor = ColorCutQuantizer.quantizeFromRgb888(pixel)
            // Now update the pixel value to the quantized value
            pixels[i] = quantizedColor
            // And update the histogram
            hist[quantizedColor] += 1
        }
        // Now let's count the number of distinct colors
        var distinctColorCount = 0
        for color in hist.indices {
            if hist[color] > 0 && shouldIgnoreColor(color) {
                // If we should ignore the color, set the population to 0
                hist[color] = 0
            }
            if hist[color] > 0 {
                // If the color has population, increase the distinct color count
                distinctColorCount += 1
            }
        }
        // Now lets go through create an array consisting of only distinct colors
        var colors = [Int]()
        colors.reserveCapacity(distinctColorCount)
        for color in hist.indices where hist[color] > 0 {
            colors.append(color)
        }
        self.histogram = hist
        self.colors = colors
        
        if (distinctColorCount <= maxColors) {
            // The image has fewer colors than the maximum requested, so just return the colors
            quantizedColors = []
            for color in colors {
                quantizedColors.append(Palette.Swatch(
                    color: ColorCutQuantizer.approximateToRgb888(color),
                    population: hist[color])
                )
            }
        } else {
            // We need use quantization to reduce the number of colors
            quantizedColors = quantizePixels(maxColors)
        }
    }
    
    /// Return the list of quantized colors
    ///
    /// - Returns: the list of quantized colors
    func getQuantizedColors() -> [Palette.Swatch] {
        return quantizedColors
    }
    
    private func quantizePixels(_ maxColors: Int) -> [Palette.Swatch] {
        // Create the priority queue which is sorted by volume descending. This means we always
        // split the largest box in the queue
        var pq: [Vbox] = []
        pq.reserveCapacity(maxColors)
        // To start, offer a box which contains all of the colors
        pq.append(Vbox(self, 0, max(0, colors.count - 1)))
        // Now go through the boxes, splitting them until we have reached maxColors or there are no
        // more boxes to split
        splitBoxes(&pq, maxColors, sort: >)
        // Finally, return the average colors of the color boxes
        return generateAverageColors(pq)
    }
    
    /// Iterate through the {@link java.util.Queue}, popping
    /// {@link ColorCutQuantizer.Vbox} objects from the queue
    /// and splitting them. Once split, the new box and the remaining box are offered back to the
    /// queue.
    ///
    /// - Parameters:
    ///   - queue: queue {@link java.util.PriorityQueue} to poll for boxes
    ///   - maxSize: maxSize Maximum amount of boxes to split
    private func splitBoxes(_ queue: inout [Vbox], _ maxSize: Int, sort by: ((Vbox, Vbox) -> Bool)? = nil) {
        while queue.count < maxSize, queue.count > 0 {
            var vbox = queue.removeFirst()
            
            if (vbox.canSplit()) {
                // First split the box, and offer the result
                queue.append(vbox.splitBox())
                // Then offer the box back
                queue.append(vbox)
                if let comparator = by {
                    queue.sort(by: comparator)
                }
            } else {
                // If we get here then there are no more boxes to split, so return
                return
            }
        }
    }
    
    private func generateAverageColors(_ vboxes: [Vbox]) -> [Palette.Swatch] {
        var colors: [Palette.Swatch] = []
        for vbox in vboxes {
            let swatch = vbox.getAverageColor()
            if !shouldIgnoreColor(swatch) {
                // As we're averaging a color box, we can still get colors which we do not want, so
                // we check again here
                colors.append(swatch)
            }
        }
        return colors
    }

    /// Represents a tightly fitting box around a color space.
    fileprivate struct Vbox {
        private var colorCutQuantizer: ColorCutQuantizer
        
        // lower and upper index are inclusive
        private var lowerIndex: Int
        private var upperIndex: Int
        // Population of colors within this box
        private var population: Int
        
        private var minRed: Int = .max, maxRed: Int = .min
        private var minGreen: Int = .max, maxGreen: Int = .min
        private var minBlue: Int = .max, maxBlue: Int = .min
        
        private static var ordinal = Int32(0)
        
        let hashValue = Int(OSAtomicIncrement32(&Vbox.ordinal))
        
        init(_ quantizer: ColorCutQuantizer, _ lower: Int, _ upper: Int) {
            colorCutQuantizer = quantizer
            lowerIndex = lower
            upperIndex = upper
            population = 0
            fitBox()
        }
        
        func getVolume() -> Int {
            let r = Double(maxRed - minRed + 1)
            let g = Double(maxGreen - minGreen + 1)
            let b = Double(maxBlue - minBlue + 1)
            return Int(r * g * b)
        }
        
        func canSplit() -> Bool {
            return getColorCount() > 1
        }
        
        func getColorCount() -> Int {
            return 1 + upperIndex - lowerIndex
        }
        
        /// Recomputes the boundaries of this box to tightly fit the colors within the box.
        mutating func fitBox() {
            // Reset the min and max to opposite values
            minRed = 0xff
            minGreen = 0xff
            minBlue = 0xff
            maxRed = 0x0
            maxGreen = 0x0
            maxBlue = 0x0

            population = colorCutQuantizer.colors[lowerIndex...upperIndex].reduce(0) {
                $0 + colorCutQuantizer.histogram[$1]
            }
            
            for i in lowerIndex...upperIndex where colorCutQuantizer.colors.count != 0 {
                let color = colorCutQuantizer.colors[i]
                let r = quantizedRed(color)
                let g = quantizedGreen(color)
                let b = quantizedBlue(color)
                
                maxRed = max(maxRed, r)
                minRed = min(minRed, r)
                maxGreen = max(maxGreen, g)
                minGreen = min(minGreen, g)
                maxBlue = max(maxBlue, b)
                minBlue = min(minBlue, b)
            }
        }
        
        /// Split this color box at the mid-point along its longest dimension
        ///
        /// - Returns:  the new ColorBox
        mutating func splitBox() -> Vbox {
            if !canSplit() {
                print("Can not split a box with only 1 color")
                // FIXME: Error handling
                // throw new IllegalStateException();
            }
            // find median along the longest dimension
            let splitPoint = findSplitPoint()
            let newBox = Vbox(colorCutQuantizer, splitPoint + 1, upperIndex)
            // Now change this box's upperIndex and recompute the color boundaries
            upperIndex = splitPoint
            fitBox()
            return newBox
        }

        /// Return the dimension which this box is largest in
        ///
        /// - Returns: the dimension which this box is largest in
        func getLongestColorDimension() -> Int {
            let redLength = maxRed - minRed
            let greenLength = maxGreen - minGreen
            let blueLength = maxBlue - minBlue
        
            if (redLength >= greenLength) && (redLength >= blueLength) {
                return ColorCutQuantizer.componentRed
            } else if (greenLength >= redLength) && (greenLength >= blueLength) {
                return ColorCutQuantizer.componentGreen
            } else {
                return ColorCutQuantizer.componentBlue
            }
        }
        
        /// Finds the point within this box's lowerIndex and upperIndex index of where to split.
        ///
        /// This is calculated by finding the longest color dimension, and then sorting the
        /// sub-array based on that dimension value in each color. The colors are then iterated over
        /// until a color is found with at least the midpoint of the whole box's dimension midpoint.
        ///
        /// - Returns: the index of the colors array to split from
        func findSplitPoint() -> Int {
            // FIXME: Dimension
            let longestDimension = getLongestColorDimension()
            var colors = colorCutQuantizer.colors
            let hist = colorCutQuantizer.histogram
            
            // We need to sort the colors in this box based on the longest color dimension.
            // As we can't use a Comparator to define the sort logic, we modify each color so that
            // its most significant is the desired dimension
            ColorCutQuantizer.modifySignificantOctet(&colors, longestDimension, lowerIndex, upperIndex)
            // Now sort... Arrays.sort uses a exclusive toIndex so we need to add
            // Arrays.sort(colors, lowerIndex, upperIndex + 1)
            colors[lowerIndex...upperIndex].sort()
            // Now revert all of the colors so that they are packed as RGB again
            ColorCutQuantizer.modifySignificantOctet(&colors, longestDimension, lowerIndex, upperIndex);
            
            colorCutQuantizer.colors = colors
            
            if longestDimension == ColorCutQuantizer.componentRed {
                colors[lowerIndex...upperIndex].sort() {
                    ColorCutQuantizer.quantizedRed($0) < ColorCutQuantizer.quantizedRed($1)
                }
            } else if longestDimension == ColorCutQuantizer.componentGreen {
                colors[lowerIndex...upperIndex].sort() {
                    ColorCutQuantizer.quantizedGreen($0) < ColorCutQuantizer.quantizedGreen($1)
                }
            } else  {
                colors[lowerIndex...upperIndex].sort() {
                    ColorCutQuantizer.quantizedBlue($0) < ColorCutQuantizer.quantizedBlue($1)
                }
            }
            let midPoint = population / 2
            var count = 0
            for i in lowerIndex...upperIndex {
                count += hist[colors[i]]
                if (count >= midPoint) {
                    // we never want to split on the upperIndex, as this will result in the same
                    // box
                    return min(upperIndex - 1, i)
                }
            }
            return lowerIndex
        }

        /// Return the average color of this box.
        ///
        /// - Returns: the average color of this box.
        func getAverageColor() -> Palette.Swatch {
            let colors = colorCutQuantizer.colors
            let hist = colorCutQuantizer.histogram
            var redSum = 0
            var greenSum = 0
            var blueSum = 0
            var totalPopulation = 0
        
            for i in lowerIndex...upperIndex {
                let color = colors[i]
                let colorPopulation = hist[color]
                totalPopulation += colorPopulation
                redSum += colorPopulation * quantizedRed(color)
                greenSum += colorPopulation * quantizedGreen(color)
                blueSum += colorPopulation * quantizedBlue(color)
            }
            let redMean = Int(round(Float(redSum) / Float(totalPopulation)))
            let greenMean = Int(round(Float(greenSum) / Float(totalPopulation)))
            let blueMean = Int(round(Float(blueSum) / Float(totalPopulation)))
        
            return Palette.Swatch(
                color: ColorCutQuantizer.approximateToRgb888(redMean, greenMean, blueMean),
                population: totalPopulation
            )
        }
    }
    
    ///  Modify the significant octet in a packed color int. Allows sorting based on the value of a
    ///  single color component. This relies on all components being the same word size.
    ///
    /// - Parameters:
    ///   - a:
    ///   - dimension:
    ///   - lower: lowerbound
    ///   - upper: upperbound
    static func modifySignificantOctet(_ a: inout [Int], _ dimension: Int, _ lower: Int, _ upper: Int) {
        switch (dimension) {
        case componentRed:
            // Already in RGB, no need to do anything
            break
        case componentGreen:
            // We need to do a RGB to GRB swap, or vice-versa
            for i in lower...upper {
                let color = a[i]
                a[i] = quantizedGreen(color) << (quantizeWordWidth + quantizeWordWidth)
                    | quantizedRed(color) << quantizeWordWidth
                    | quantizedBlue(color)
            }
            break
        case componentBlue:
            // We need to do a RGB to BGR swap, or vice-versa
            for i in lower...upper {
                let color = a[i]
                a[i] = quantizedBlue(color) << (quantizeWordWidth + quantizeWordWidth)
                    | quantizedGreen(color) << quantizeWordWidth
                    | quantizedRed(color)
            }
            break
        default:
            break
        }
    }
    
    private func shouldIgnoreColor(_ color565: Int) -> Bool {
        let rgb = ColorCutQuantizer.approximateToRgb888(color565)
        Color.Utils.colorToHSL(rgb, &tempHsl)
        return shouldIgnoreColor(rgb, tempHsl)
    }
    
    private func shouldIgnoreColor(_ color: Palette.Swatch) -> Bool {
        return shouldIgnoreColor(color.getRgb(), color.getHsl())
    }
    
    private func shouldIgnoreColor(_ rgb: Int, _ hsl: [Float]) -> Bool {
        for filter in filters where filters.count > 0 {
            if !filter.isAllowed(rgb, hsl) {
                return true
            }
        }
        return false
    }
    
    /// Quantized a RGB888 value to have a word width of {@value #QUANTIZE_WORD_WIDTH}.
    ///
    /// - Parameter color: @ColorInt
    /// - Returns: value that have a word width of {@value #QUANTIZE_WORD_WIDTH}.
    private static func quantizeFromRgb888(_ color: Int) -> Int {
        let r = modifyWordWidth(Color.red(color), 8, quantizeWordWidth)
        let g = modifyWordWidth(Color.green(color), 8, quantizeWordWidth)
        let b = modifyWordWidth(Color.blue(color), 8, quantizeWordWidth)
        return r << (quantizeWordWidth + quantizeWordWidth) | g << quantizeWordWidth | b
    }

    /// Quantized RGB888 values to have a word width of {@value #QUANTIZE_WORD_WIDTH}.
    ///
    /// - Parameters:
    ///   - r: @ColorInt r
    ///   - g: @ColorInt g
    ///   - b: @ColorInt b
    /// - Returns: values that have a word width of {@value #QUANTIZE_WORD_WIDTH}.
    static func approximateToRgb888(_ r: Int, _ g: Int, _ b: Int) -> Int {
        return Color.rgb(
            modifyWordWidth(r, quantizeWordWidth, 8),
            modifyWordWidth(g, quantizeWordWidth, 8),
            modifyWordWidth(b, quantizeWordWidth, 8)
        )
    }
    
    private static func approximateToRgb888(_ color: Int) -> Int {
        return approximateToRgb888(quantizedRed(color), quantizedGreen(color), quantizedBlue(color));
    }
    
    /// Return red component of the quantized color
    ///
    /// - Parameter color: @ColorInt
    /// - Returns: red component of the quantized color
    static func quantizedRed(_ color: Int) -> Int {
        return (color >> (quantizeWordWidth + quantizeWordWidth)) & quantizeWordMask
    }
    
    /// @return green component of a quantized color
    ///
    /// - Parameter color: @ColorInt
    /// - Returns: green component of a quantized color
    static func quantizedGreen(_ color: Int) -> Int {
        return (color >> quantizeWordWidth) & quantizeWordMask
    }
    
    /// Eeturn blue component of a quantized color
    ///
    /// - Parameter color: @ColorInt
    /// - Returns: blue component of a quantized color
    static func quantizedBlue(_ color: Int) -> Int {
        return color & quantizeWordMask
    }
    
    private static func modifyWordWidth(_ value: Int, _ currentWidth: Int, _ targetWidth: Int) -> Int {
        var newValue: Int
        if (targetWidth > currentWidth) {
            // If we're approximating up in word width, we'll shift up
            newValue = value << (targetWidth - currentWidth)
        } else {
            // Else, we will just shift and keep the MSB
            newValue = value >> (currentWidth - targetWidth)
        }
        return newValue & ((1 << targetWidth) - 1)
    }
}

extension ColorCutQuantizer.Vbox: Comparable {
    
    /// Comparator which sorts {@link Vbox} instances based on their volume, in descending order
//    static func <(lhs: ColorCutQuantizer.Vbox, rhs: ColorCutQuantizer.Vbox) -> Bool {
//        return lhs.getVolume() < rhs.getVolume()
//    }
//
//    static func ==(lhs: ColorCutQuantizer.Vbox, rhs: ColorCutQuantizer.Vbox) -> Bool {
//        return rhs.getVolume() - lhs.getVolume() == 0
//    }
}

private func ==(lhs: ColorCutQuantizer.Vbox, rhs: ColorCutQuantizer.Vbox) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

private func <(lhs: ColorCutQuantizer.Vbox, rhs: ColorCutQuantizer.Vbox) -> Bool {
    return lhs.getVolume() < rhs.getVolume()
}
