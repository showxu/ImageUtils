//
//  ImageProc.swift
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

#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

// MARK: - Resize Image
extension Image {
    
    final public func resized(
        to size: Size,
        quality: CGInterpolationQuality = .high
    ) -> Image? {
        return Image(resize: self, to: size, quality: quality)
    }
    
    final public class func `init`(
        _ size: Size = .zero,
        color: Color = .clear,
        radius: CGFloat = 0
    ) -> Image? {
        let rect = Rect(origin: .zero, size: size)
        guard let ctx = CGContext(size, false, 1) else { return nil }
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.setFillColor(color.cgColor)
        let radius = min(size.height / 2, radius)
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.clip()
        ctx.fill(rect)
        guard let cgImage = ctx.makeImage() else { return nil }
        let image = Image(cgImage: cgImage)
        return image
    }
    
    final public class func `init`(
        resize image: Image,
        width: Int,
        height: Int,
        quality: CGInterpolationQuality = .high
    ) -> Image? {
        return `init`(
            resize: image,
            to: Size(width: width, height: height),
            quality: quality
        )
    }

    final public class func `init`(
        resize image: Image,
        to size: Size,
        quality: CGInterpolationQuality = .high
    ) -> Image? {
        let newRect = Rect(origin: .zero, size: size).integral
        #if os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #else
        guard let cgImage = image.cgImage else { return nil }
        #endif
        // Use CGContext directly instead of UIKit api UIGraphicsBeginImageContextWithOptions
        guard let ctx = CGContext(size, false, 1) else { return nil }
        // Set the quality level to use when rescaling
        ctx.interpolationQuality = .high
        #if false
        // For CGContext it's unnecessary to flip vertically.
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        #endif
        // Draw into the context; this scales the image
        ctx.draw(cgImage, in: newRect)
        guard let resized = ctx.makeImage() else { return nil }
        // Get the resized image from the context and a UIImage
        let image = Image(cgImage: resized)
        return image
    }
}

// MARK: - Alpha Channel
extension Image {
    
    // Returns true if the image has alpha layer
    final public var hasAlpha: Bool {
        guard let alpha = cgImage?.alphaInfo else { return false }
        switch alpha {
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
        alpha image: Image,
        quality: CGInterpolationQuality = .high
    ) -> Image? {
        guard let cgImage = image.cgImage, image.hasAlpha else { return image }
        // create new offscreen context
        guard let ctx = CGContext(image.size, false, image.scale) else { return nil }
        ctx.draw(cgImage, in: CGRect(origin: .zero, size: image.size * image.scale))
        ctx.interpolationQuality = quality
        let alphaImage = ctx.makeImage()!
        return Image(cgImage: alphaImage)
    }
}

// MARK: - Mask Image
extension CGImage {
    
    // Creates a mask that makes the outer edges transparent and everything else opaque
    // The size must include the entire mask (opaque part + transparent border)
    final public class func `init`(
        mask size: Size,
        border: CGFloat
    ) -> CGImage? {
        // Create a context that's the same dimensions as the new size
        guard let maskCtx = CGContext(size, false, 1) else { return nil }
        // Start with a mask that's entirely transparent
        maskCtx.setFillColor(.black)
        maskCtx.fill(Rect(origin: .zero, size: size))
        // Make the inner part (within the border) opaque
        maskCtx.setFillColor(.white)
        maskCtx.fill(CGRect(
            x: border,
            y: border,
            width: size.width - 2 * border,
            height: size.height - 2 * border
        ))
        let mask = maskCtx.makeImage()
        return mask
    }
}

// MARK: - Transparent Border
extension Image {
    
    final public func transparent(
        border: CGFloat,
        quality: CGInterpolationQuality = .high
    ) -> Image? {
        return Image(
            transparent: self,
            border: border,
            quality: quality
        )
    }
    
    // Returns a copy of the image with a transparent border of the given size added around its edges.
    final public class func `init`(
        transparent image: Image,
        border: CGFloat,
        quality: CGInterpolationQuality = .high
    ) -> Image? {
        // If the image does not have an alpha layer, add one
        let pixelsWidth = image.size.width * image.scale
        let pixelsHeight = image.size.height * image.scale
        guard let cgImage = Image(alpha: image)?.cgImage else { return nil }
        let newRect = Rect(
            x: 0,
            y: 0,
            width: pixelsWidth + CGFloat(border) * 2,
            height: pixelsHeight + CGFloat(border) * 2
        )
        // Build a context that's the same dimensions as the new size
        guard let ctx = CGContext(newRect.size, false, 1)  else { return nil }
        ctx.interpolationQuality = quality
        // Draw the image in the center of the context, leaving a gap around the edges
        let imageRect = Rect(
            x: border,
            y: border,
            width: pixelsHeight,
            height: pixelsHeight
        )
        ctx.draw(cgImage, in: imageRect)
        guard
            let imageToMask = ctx.makeImage(),
            // Create a mask to make the border transparent.
            let mask = CGImage(mask: newRect.size, border: border)
        else { return nil }
        // Mask to the image
        imageToMask.masking(mask)
        return Image(cgImage: imageToMask)
    }
}

// MARK: - Round Corner Clip
extension Image {
    
    final public func rounded(radius: CGFloat) -> Image? {
        return Image(corner: self, radius: radius)
    }
    
    final public class func `init`(
        corner image: Image,
        radius: CGFloat,
        quality: CGInterpolationQuality = .high
    ) -> Image? {
        guard let cgImage = image.cgImage, let ctx = CGContext(bitmap: cgImage) else { return nil }
        // Create a clipping path with rounded corners
        let rect = Rect(
            x: 0,
            y: 0,
            width: image.size.width,
            height: image.size.height
        )
        ctx.beginPath()
        ctx.addRoundedRectToPath(rect, ovalWidth: radius, ovalHeight: radius)
        ctx.closePath()
        ctx.clip()
        ctx.draw(cgImage, in: .init(origin: .zero, size: image.size))
        guard let rounded = ctx.makeImage() else { return nil }
        return Image(cgImage: rounded)
    }
}
extension CGContext {
    
    // Adds a rectangular path to the given context and rounds its corners by the given extents
    internal func addRoundedRectToPath(_ rect: Rect, ovalWidth: CGFloat, ovalHeight: CGFloat) {
        if ovalWidth == 0 || ovalHeight == 0 {
            addRect(rect)
            return
        }
        saveGState()
        defer {
            restoreGState()
        }
        translateBy(x: rect.minX, y: rect.minY)
        scaleBy(x: ovalWidth, y: ovalHeight)
        let fw = rect.width / ovalWidth
        let fh = rect.height / ovalHeight
        move(to: .init(x: fw, y: fh / 2))
        addArc(tangent1End: .init(x: fw, y: fh), tangent2End: .init(x: fw / 2, y: fh), radius: 1)
        addArc(tangent1End: .init(x: 0, y: fh), tangent2End: .init(x: 0, y: fh / 2), radius: 1)
        addArc(tangent1End: .init(x: 0, y: 0), tangent2End: .init(x: fw / 2, y: 0), radius: 1)
        addArc(tangent1End: .init(x: fw, y: 0), tangent2End: .init(x: fw, y: fh / 2), radius: 1)
    }
}
