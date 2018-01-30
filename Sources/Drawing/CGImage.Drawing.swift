//
//  CGImage.Utils.swift
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

// MARK: - Color Image
extension CGImage {
    
    final public class func `init`(
        _ size: CGSize,
        color: CGColor,
        radius: CGFloat = 0
    ) -> CGImage? {
        let rect = CGRect(origin: .zero, size: size)
        guard let ctx = CGContext(size, false, 1) else { return nil }
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.setFillColor(color)
        let radius = min(size.height / 2, radius)
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.clip()
        ctx.fill(rect)
        let image = ctx.makeImage()
        return image
    }
}

// MARK: - Resize
extension CGImage {
    
    final public func resized(
        to size: CGSize,
        quality: CGInterpolationQuality = .high
    ) -> CGImage? {
        return CGImage(self, to: size, quality: quality)
    }
    
    final public class func `init`(
        _ image: CGImage,
        to size: CGSize,
        quality: CGInterpolationQuality = .high
    ) -> CGImage? {
        let rect = CGRect(origin: .zero, size: size).integral
        // Use CGContext directly instead of UIKit api UIGraphicsBeginImageContextWithOptions
        guard let ctx = CGContext(size, false, 1) else { return nil }
        // Set the quality level to use when rescaling
        ctx.interpolationQuality = .high
        // Draw into the context; this scales the image
        ctx.draw(image, in: rect)
        // Get the resized image from the context and a UIImage
        let resized = ctx.makeImage()
        return resized
    }
}

// MARK: - Mask Image
extension CGImage {
    
    // Creates a mask that makes the outer edges transparent and everything else opaque
    // The size must include the entire mask (opaque part + transparent border)
    final public class func `init`(
        mask size: CGSize,
        border: CGFloat,
        color: CGColor
    ) -> CGImage? {
        // Create a context that's the same dimensions as the new size
        guard let ctx = CGContext(size, true, 1, CGColorSpaceCreateDeviceGray()) else { return nil }
        // Start with a mask that's entirely transparent
        ctx.setFillColor(.black)
        ctx.fill(CGRect(origin: .zero, size: size))
        // Make the inner part (within the border) opaque
        ctx.setFillColor(.white)
        ctx.fill(CGRect(
            x: border,
            y: border,
            width: size.width - 2 * border,
            height: size.height - 2 * border
        ))
        let mask = ctx.makeImage()
        return mask
    }
}

// MARK: - Alpha Channel
extension CGImage {
    
    final public func withAlpha() -> CGImage? {
        return CGImage(withAlpha: self)
    }
    
    // Returns true if the image has alpha layer
    final public var hasAlpha: Bool {
        switch alphaInfo {
        case .first: break
        case .last: break
        case .premultipliedFirst: break
        case .premultipliedLast: break
        default: return false
        }
        return true
    }
    
    // Returns a copy of the given image, adding an alpha channel if it doesn't already have one
    final public class func `init`(
        withAlpha image: CGImage,
        quality: CGInterpolationQuality = .high
    ) -> CGImage? {
        guard !image.hasAlpha else { return image }
        // create new offscreen context
        guard let ctx = CGContext(image.size, false, 1) else { return nil }
        ctx.draw(image, in: CGRect(origin: .zero, size: image.size))
        ctx.interpolationQuality = quality
        return ctx.makeImage()
    }
}

extension CGImage {
    
    final public func bordered(
        _ border: CGFloat,
        color: CGColor,
        quality: CGInterpolationQuality = .high
    ) -> CGImage? {
        return CGImage(self, border: border, color: color, quality: quality)
    }
    
    // Returns a copy of the image with a transparent border of the given size added around its edges.
    final public class func `init`(
        _ image: CGImage,
        border: CGFloat,
        color: CGColor,
        quality: CGInterpolationQuality = .high
    ) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        // If the image does not have an alpha layer, add one
        //guard let image = image.withAlpha() else { return nil }
        let borderedRect = Rect(
            x: 0,
            y: 0,
            width: width + border * 2,
            height: height + border * 2
        )
        // Build a context that's the same dimensions as the new size
        guard let ctx = CGContext(borderedRect.size, false, 1)  else { return nil }
        ctx.interpolationQuality = quality
        // Draw the image in the center of the context, leaving a gap around the edges
        let imageRect = CGRect(
            x: border,
            y: border,
            width: width,
            height: height
        )
        ctx.draw(image, in: imageRect)
        // Create a mask to make the border transparent.
        guard let mask = CGImage(mask: borderedRect.size, border: border, color: color) else { return nil }
        // Mask to the image
        let ret = ctx.makeImage()?.masking(mask)
        return ret
    }
}

// MARK: - Corner Clip
extension CGImage {
    
    final public func clipped(radius: CGFloat, quality: CGInterpolationQuality = .high) -> CGImage? {
        return CGImage(self, clip: radius, quality: quality)
    }
    
    final public class func `init`(
        _ image: CGImage,
        clip radius: CGFloat,
        quality: CGInterpolationQuality = .high
    ) -> CGImage? {
        guard let ctx = CGContext(bitmap: image) else { return nil }
        ctx.interpolationQuality = quality
        // Create a clipping path with rounded corners
        let rect = CGRect(
            x: 0,
            y: 0,
            width: image.size.width,
            height: image.size.height
        )
        ctx.beginPath()
        ctx.addArc(to: rect, semiMajorAxis: radius, semiMinorAxis: radius)
        ctx.closePath()
        ctx.clip()
        ctx.draw(image, in: .init(origin: .zero, size: image.size))
        let clipped = ctx.makeImage()
        return clipped
    }
}
