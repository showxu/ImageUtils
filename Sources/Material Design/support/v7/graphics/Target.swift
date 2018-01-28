//
//  Target.swift
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
            for i in weights.indices {
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
        public func setMaximumLightness(_ value: Float) -> Builder {
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

extension Target: Equatable {
    
    public static func ==(lhs: Target, rhs: Target) -> Bool {
        let lh = unsafeBitCast(lhs, to: UnsafePointer<Target>.self)
        let rh = unsafeBitCast(rhs, to: UnsafePointer<Target>.self)
        return lh == rh
    }
}

extension Target: Hashable {
    
    public var hashValue: Int {
        let ptr = unsafeBitCast(self, to: UnsafePointer<Target>.self)
        let hashValue = ptr.hashValue
        return hashValue
    }
}
