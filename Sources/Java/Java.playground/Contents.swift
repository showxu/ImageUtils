
import UIKit.UIColor
import Foundation

/**
 * A class which allows custom selection of colors in a {@link Palette}'s generation. Instances
 * can be created via the {@link Builder} class.
 *
 * <p>To use the target, use the {@link Palette.Builder#addTarget(Target)} API when building a
 * Palette.</p>
 */
public final class Target {
    
    private static let targetDarkLuma: Float = 0.26
    private static let maxDarkLuma: Float = 0.45
    
    private static let minLightLuma: Float = 0.55
    private static let targetLightLuma: Float = 0.74
    
    private static let minNormalLuma: Float = 0.3
    private static let targetNormalLuma: Float = 0.5
    private static let maxNormalLuma: Float = 0.7

    private static let targetMutedSaturation: Float = 0.3
    private static let maxMutedSaturation: Float = 0.4
    
    private static let minVibrantSaturation: Float = 0.35
    private static let targetVibrantSaturation: Float = 1
    
    private static let weightSaturation: Float = 0.24
    private static let weightLuma: Float = 0.52
    private static let weightPopulation: Float = 0.24
    
    private static let indexMin: Int = 0
    static let indexTarget: Int = 1
    static let indexMax: Int = 2
    
    static let indexWeightSat: Int = 0
    static let indexWeightLuma: Int = 1
    static let indexWeightPop: Int = 2

    /**
     * A target which has the characteristics of a vibrant color which is light in luminance.
     */
    public static let lightVibrant: Target = {
        let lightVibrant = Target()
        setDefaultLightLightnessValues(lightVibrant)
        setDefaultVibrantSaturationValues(lightVibrant)
        return lightVibrant
    }()

    /**
     * A target which has the characteristics of a vibrant color which is neither light or dark.
     */
    public static let vibrant: Target = {
        let vibrant = Target()
        setDefaultNormalLightnessValues(vibrant)
        setDefaultVibrantSaturationValues(vibrant)
        return vibrant
    }()

    /**
     * A target which has the characteristics of a vibrant color which is dark in luminance.
     */
    public static let darkVibrant: Target = {
        let darkVibrant = Target()
        setDefaultDarkLightnessValues(darkVibrant)
        setDefaultVibrantSaturationValues(darkVibrant)
        return darkVibrant
    }()

    /**
     * A target which has the characteristics of a muted color which is light in luminance.
     */
    public static let lightMuted: Target = {
        let lightMuted = Target()
        setDefaultLightLightnessValues(lightMuted)
        setDefaultMutedSaturationValues(lightMuted)
        return lightMuted
    }()

    /**
     * A target which has the characteristics of a muted color which is neither light or dark.
     */
    public static let muted: Target = {
        let muted = Target()
        setDefaultNormalLightnessValues(muted)
        setDefaultMutedSaturationValues(muted)
        return muted
    }()

    /**
     * A target which has the characteristics of a muted color which is dark in luminance.
     */
    public static let darkMuted: Target = {
        let darkMuted = Target()
        setDefaultDarkLightnessValues(darkMuted)
        setDefaultMutedSaturationValues(darkMuted)
        return darkMuted
    }()

    final var saturationTargets: [Float] = Array(repeating: 0, count: 3)
    final var lightnessTargets: [Float] = Array(repeating: 0, count: 3)
    final var weights: [Float] = Array(repeating: 0, count: 3)
    final var isExclusive: Bool = true // default to true
    
    init() {
        Target.setTargetDefaultValues(&saturationTargets)
        Target.setTargetDefaultValues(&lightnessTargets)
        setDefaultWeights()
    }

    init(_ from: Target) {
        saturationTargets = from.saturationTargets
        lightnessTargets = from.lightnessTargets
        weights = from.weights
    }

    /**
     * The minimum saturation value for this target.
     * @FloatRange(from = 0, to = 1)
     */
    public func getMinimumSaturation() -> Float {
        return saturationTargets[Target.indexMin]
    }

    /**
     * The target saturation value for this target.
     * @FloatRange(from = 0, to = 1)
     */
    public func getTargetSaturation() -> Float {
        return saturationTargets[Target.indexTarget]
    }

    /**
     * The maximum saturation value for this target.
     * @FloatRange(from = 0, to = 1)
     */
    public func getMaximumSaturation() -> Float {
        return saturationTargets[Target.indexMax]
    }

    /**
     * The minimum lightness value for this target.
     * @FloatRange(from = 0, to = 1)
     */
    public func getMinimumLightness() -> Float {
        return lightnessTargets[Target.indexMin]
    }

    /**
     * The target lightness value for this target.
     * @FloatRange(from = 0, to = 1)
     */
    public func getTargetLightness() -> Float {
        return lightnessTargets[Target.indexTarget]
    }

    /**
     * The maximum lightness value for this target.
     * @FloatRange(from = 0, to = 1)
     */
    public func getMaximumLightness() -> Float {
        return lightnessTargets[Target.indexMax]
    }

    /**
     * Returns the weight of importance that this target places on a color's saturation within
     * the image.
     *
     * <p>The larger the weight, relative to the other weights, the more important that a color
     * being close to the target value has on selection.</p>
     *
     * @see #getTargetSaturation()
     */
    public func getSaturationWeight() -> Float {
        return weights[Target.indexWeightSat]
    }

    /**
     * Returns the weight of importance that this target places on a color's lightness within
     * the image.
     *
     * <p>The larger the weight, relative to the other weights, the more important that a color
     * being close to the target value has on selection.</p>
     *
     * @see #getTargetLightness()
     */
    public func getLightnessWeight() -> Float {
        return weights[Target.indexWeightLuma]
    }

    /**
     * Returns the weight of importance that this target places on a color's population within
     * the image.
     *
     * <p>The larger the weight, relative to the other weights, the more important that a
     * color's population being close to the most populous has on selection.</p>
     */
    public func getPopulationWeight() -> Float {
        return weights[Target.indexWeightPop]
    }

    /**
     * Returns whether any color selected for this target is exclusive for this target only.
     *
     * <p>If false, then the color can be selected for other targets.</p>
     */
    //public func isExclusive() -> Bool { return isExclusive }
    
    private static func setTargetDefaultValues(_ values: inout [Float]) {
        values[indexMin] = 0
        values[indexTarget] = 0.5
        values[indexMax] = 1
    }

    private func setDefaultWeights() {
        weights[Target.indexWeightSat] = Target.weightSaturation
        weights[Target.indexWeightLuma] = Target.weightLuma
        weights[Target.indexWeightPop] = Target.weightPopulation
    }
    
    func normalizeWeights() {
        var sum: Float = 0
        
        for weight in weights where weight > 0 {
            sum += weight
        }
        if (sum != 0) {
            for (i, _) in weights.enumerated() {
                weights[i] /= sum
            }
        }
    }
    
    private static func setDefaultDarkLightnessValues(_ target: Target) {
        target.lightnessTargets[indexTarget] = targetDarkLuma
        target.lightnessTargets[indexMax] = maxDarkLuma
    }
    
    private static func setDefaultNormalLightnessValues(_ target: Target) {
        target.lightnessTargets[indexMin] = minNormalLuma
        target.lightnessTargets[indexTarget] = targetNormalLuma
        target.lightnessTargets[indexMax] = maxNormalLuma
    }
    
    private static func setDefaultLightLightnessValues(_ target: Target) {
        target.lightnessTargets[indexMin] = minLightLuma
        target.lightnessTargets[indexTarget] = targetLightLuma
    }

    private static func setDefaultVibrantSaturationValues(_ target: Target) {
        target.saturationTargets[indexMin] = minVibrantSaturation
        target.saturationTargets[indexTarget] = targetVibrantSaturation
    }

    private static func setDefaultMutedSaturationValues(_ target: Target) {
        target.saturationTargets[indexTarget] = targetMutedSaturation
        target.saturationTargets[indexMax] = maxMutedSaturation
    }
}

extension Target {
    
    /**
     * Builder class for generating custom {@link Target} instances.
     */
    public final class Builder {
        
        private final let target: Target

        /**
         * Create a new {@link Target} builder from scratch.
         */
        public init() {
            target = Target()
        }
        
        /**
         * Create a new builder based on an existing {@link Target}.
         */
        public init(_ target: Target) {
            self.target = Target(target)
        }

        /**
         * Set the minimum saturation value for this target.
         * @value @FloatRange(from = 0, to = 1)
         */
        public func setMinimumSaturation(_ value: Float) -> Builder {
            target.saturationTargets[indexMin] = value
            return self
        }
        
        /**
         * Set the target/ideal saturation value for this target.
         * @value @FloatRange(from = 0, to = 1)
         */
        public func setTargetSaturation(_ value: Float) -> Builder {
            target.saturationTargets[indexTarget] = value
            return self
        }

        /**
         * Set the maximum saturation value for this target.
         * @value @FloatRange(from = 0, to = 1)
         */
        public func setMaximumSaturation(_ value: Float) -> Builder {
            target.saturationTargets[indexMax] = value
            return self
        }

        /**
         * Set the minimum lightness value for this target.
         * @value @FloatRange(from = 0, to = 1)
         */
        public func setMinimumLightness(_ value: Float) -> Builder {
            target.lightnessTargets[indexMin] = value
            return self
        }

        /**
         * Set the target/ideal lightness value for this target.
         * @value @FloatRange(from = 0, to = 1)
         */
        public func setTargetLightness(_ value: Float) -> Builder {
            target.lightnessTargets[indexTarget] = value
            return self
        }

        /**
         * Set the maximum lightness value for this target.
         * @value @FloatRange(from = 0, to = 1)
         */
        public func setMaximumLightness(_ value: Float) -> Builder{
            target.lightnessTargets[indexMax] = value
            return self
        }

        /**
         * Set the weight of importance that this target will place on saturation values.
         *
         * <p>The larger the weight, relative to the other weights, the more important that a color
         * being close to the target value has on selection.</p>
         *
         * <p>A weight of 0 means that it has no weight, and thus has no
         * bearing on the selection.</p>
         *
         * @see #setTargetSaturation(float)
         * @weight (@FloatRange(from = 0)
         */
        public func setSaturationWeight(_ weight: Float) -> Builder {
            target.weights[indexWeightSat] = weight
            return self
        }

        /**
         * Set the weight of importance that this target will place on lightness values.
         *
         * <p>The larger the weight, relative to the other weights, the more important that a color
         * being close to the target value has on selection.</p>
         *
         * <p>A weight of 0 means that it has no weight, and thus has no
         * bearing on the selection.</p>
         *
         * @see #setTargetLightness(float)
         * @weight @FloatRange(from = 0) float
         */
        public func setLightnessWeight(_ weight: Float) -> Builder {
            target.weights[indexWeightLuma] = weight
            return self
        }

        /**
         * Set the weight of importance that this target will place on a color's population within
         * the image.
         *
         * <p>The larger the weight, relative to the other weights, the more important that a
         * color's population being close to the most populous has on selection.</p>
         *
         * <p>A weight of 0 means that it has no weight, and thus has no
         * bearing on the selection.</p>
         * @weight @FloatRange(from = 0)
         */
        public func setPopulationWeight(_ weight: Float) -> Builder {
            target.weights[indexWeightPop] = weight
            return self
        }

        /**
         * Set whether any color selected for this target is exclusive to this target only.
         * Defaults to true.
         *
         * @param exclusive true if any the color is exclusive to this target, or false is the
         *                  color can be selected for other targets.
         */
        public func setExclusive(_ exclusive: Bool) -> Builder {
            target.isExclusive = exclusive
            return self
        }

        /**
         * Builds and returns the resulting {@link Target}.
         */
        public func build() -> Target {
            return target
        }
    }
}

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
    
    /**
     * Represents a color swatch generated from an image's palette. The RGB color can be retrieved
     * by calling {@link #getRgb()}.
     */
    public final class Swatch {
        
        private final var red: Int
        private final var green: Int
        private final var blue: Int

        private final var rgb: Int
        private final var population: Int

        private var generatedTextColors: Bool = false
        private var titleTextColor: Int = 0
        private var bodyTextColor: Int = 0

        private var hsl: [Float]?
        
        /**
         * @ColorInt
         */
        public init(_ color: Int, population: Int) {
            self.red = UIColor.red(color)
            self.green = UIColor.green(color)
            self.blue = UIColor.blue(color)
            self.rgb = color
            self.population = population
        }

        init(red: Int, green: Int, blue: Int, population: Int) {
            self.red = red
            self.green = green
            self.blue = blue
            self.rgb = UIColor.rgb(red: red, green: green, blue: blue)
            self.population = population
        }

        convenience init(hsl: [Float], population: Int) {
            self.init(UIColor.Utils.hslToColor(hsl), population: population)
            self.hsl = hsl
        }

        /**
         * @return this swatch's RGB color value
         * @ColorInt
         */
        public func getRgb() -> Int {
            return rgb
        }

        /**
         * Return this swatch's HSL values.
         *     hsv[0] is Hue [0 .. 360)
         *     hsv[1] is Saturation [0...1]
         *     hsv[2] is Lightness [0...1]
         */
        public func getHsl() -> [Float] {
            if hsl == nil {
                hsl = [Float](repeating: 0, count: 3)
            }
            //UIColor.Utils.rgbToHSL(red, green, blue, hsl)
            return hsl!
        }
//
//        /**
//         * @return the number of pixels represented by this swatch
//         */
//        public int getPopulation() {
//        return mPopulation;
//        }
//
//        /**
//         * Returns an appropriate color to use for any 'title' text which is displayed over this
//         * {@link Swatch}'s color. This color is guaranteed to have sufficient contrast.
//         */
//        @ColorInt
//        public int getTitleTextColor() {
//        ensureTextColorsGenerated();
//        return mTitleTextColor;
//        }
//
//        /**
//         * Returns an appropriate color to use for any 'body' text which is displayed over this
//         * {@link Swatch}'s color. This color is guaranteed to have sufficient contrast.
//         */
//        @ColorInt
//        public int getBodyTextColor() {
//        ensureTextColorsGenerated();
//        return mBodyTextColor;
//        }
//
//        private void ensureTextColorsGenerated() {
//        if (!mGeneratedTextColors) {
//        // First check white, as most colors will be dark
//        final int lightBodyAlpha = ColorUtils.calculateMinimumAlpha(
//        Color.WHITE, mRgb, MIN_CONTRAST_BODY_TEXT);
//        final int lightTitleAlpha = ColorUtils.calculateMinimumAlpha(
//        Color.WHITE, mRgb, MIN_CONTRAST_TITLE_TEXT);
//
//        if (lightBodyAlpha != -1 && lightTitleAlpha != -1) {
//        // If we found valid light values, use them and return
//        mBodyTextColor = ColorUtils.setAlphaComponent(Color.WHITE, lightBodyAlpha);
//        mTitleTextColor = ColorUtils.setAlphaComponent(Color.WHITE, lightTitleAlpha);
//        mGeneratedTextColors = true;
//        return;
//        }
//
//        final int darkBodyAlpha = ColorUtils.calculateMinimumAlpha(
//        Color.BLACK, mRgb, MIN_CONTRAST_BODY_TEXT);
//        final int darkTitleAlpha = ColorUtils.calculateMinimumAlpha(
//        Color.BLACK, mRgb, MIN_CONTRAST_TITLE_TEXT);
//
//        if (darkBodyAlpha != -1 && darkBodyAlpha != -1) {
//        // If we found valid dark values, use them and return
//        mBodyTextColor = ColorUtils.setAlphaComponent(Color.BLACK, darkBodyAlpha);
//        mTitleTextColor = ColorUtils.setAlphaComponent(Color.BLACK, darkTitleAlpha);
//        mGeneratedTextColors = true;
//        return;
//        }
//
//        // If we reach here then we can not find title and body values which use the same
//        // lightness, we need to use mismatched values
//        mBodyTextColor = lightBodyAlpha != -1
//        ? ColorUtils.setAlphaComponent(Color.WHITE, lightBodyAlpha)
//        : ColorUtils.setAlphaComponent(Color.BLACK, darkBodyAlpha);
//        mTitleTextColor = lightTitleAlpha != -1
//        ? ColorUtils.setAlphaComponent(Color.WHITE, lightTitleAlpha)
//        : ColorUtils.setAlphaComponent(Color.BLACK, darkTitleAlpha);
//        mGeneratedTextColors = true;
//        }
//        }
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

extension UIColor {
    
    /**
     * @ColorInt
     */
    public final class func red(_ rgb: Int) -> Int {
        let red = (rgb >> 16) & 0xFF;
        return red
    }
    
    public final class func green(_ rgb: Int) -> Int {
        let green = (rgb >> 8) & 0xFF
        return green
    }
    
    public final class func blue(_ rgb: Int) -> Int {
        let blue = rgb & 0xFF;
        return blue
    }
    
    public final class func rgb(red: Int, green: Int, blue: Int) -> Int {
        let r = (red << 16) & 0x00FF0000 // Shift red 16-bits and mask out other stuff
        let g = (green << 8) & 0x0000FF00 // Shift Green 8-bits and mask out other stuff
        let b = blue & 0x000000FF // Mask out anything not blue.
        let rgb = 0xFF000000 | r | g | b // 0xFF000000 for 100% Alpha. Bitwise OR everything together.
        return rgb
    }
}

infix operator <<<< : AdditionPrecedence

extension UIColor {
    
    public struct Utils {
        
        /**
         * Convert RGB components to HSL (hue-saturation-lightness).
         * <ul>
         * <li>outHsl[0] is Hue [0 .. 360)</li>
         * <li>outHsl[1] is Saturation [0...1]</li>
         * <li>outHsl[2] is Lightness [0...1]</li>
         * </ul>
         *
         * @param r      red component value [0..255]
         * @param g      green component value [0..255]
         * @param b      blue component value [0..255]
         * @param outHsl 3-element array which holds the resulting HSL components
         */
//        public static func rgbToHSL(@IntRange(from = 0x0, to = 0xFF) int r,
//        @IntRange(from = 0x0, to = 0xFF) int g, @IntRange(from = 0x0, to = 0xFF) int b,
//        @NonNull float[] outHsl) {
//        final float rf = r / 255f;
//        final float gf = g / 255f;
//        final float bf = b / 255f;
//
//        final float max = Math.max(rf, Math.max(gf, bf));
//        final float min = Math.min(rf, Math.min(gf, bf));
//        final float deltaMaxMin = max - min;
//
//        float h, s;
//        float l = (max + min) / 2f;
//
//        if (max == min) {
//        // Monochromatic
//        h = s = 0f;
//        } else {
//        if (max == rf) {
//        h = ((gf - bf) / deltaMaxMin) % 6f;
//        } else if (max == gf) {
//        h = ((bf - rf) / deltaMaxMin) + 2f;
//        } else {
//        h = ((rf - gf) / deltaMaxMin) + 4f;
//        }
//
//        s = deltaMaxMin / (1f - Math.abs(2f * l - 1f));
//        }
//
//        h = (h * 60f) % 360f;
//        if (h < 0) {
//        h += 360f;
//        }
//
//        outHsl[0] = constrain(h, 0f, 360f);
//        outHsl[1] = constrain(s, 0f, 1f);
//        outHsl[2] = constrain(l, 0f, 1f);
//        }
//
        /**
         * Convert HSL (hue-saturation-lightness) components to a RGB color.
         * <ul>
         * <li>hsl[0] is Hue [0 .. 360)</li>
         * <li>hsl[1] is Saturation [0...1]</li>
         * <li>hsl[2] is Lightness [0...1]</li>
         * </ul>
         * If hsv values are out of range, they are pinned.
         *
         * @param hsl 3-element array which holds the input HSL components
         * @return the resulting RGB color
         * @ColorInt
         */
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

            r = constrain(amount: r, low: 0, high: 255)
            g = constrain(amount: g, low: 0, high: 255)
            b = constrain(amount: b, low: 0, high: 255)

            return UIColor.rgb(red: Int(r), green: Int(g), blue: Int(b))
        }
        
        private static func constrain(amount: Float, low: Float, high: Float) -> Float {
            return amount < low ? low : (amount > high ? high : amount)
        }
        
        private static func constrain(amount: Int, low: Int, high: Int) -> Float {
            return Float(amount < low ? low : (amount > high ? high : amount))
        }
    }
}
