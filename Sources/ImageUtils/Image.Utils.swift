//
//  Image.Utils.swift
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
