//
//  Drawing.swift
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

// MARK: - Color Image
extension Image {
    
    final public class func `init`(
        _ size: Size,
        color: Color,
        radius: CGFloat = 0
    ) -> Image? {
        return Image(CGImage(size, color: color.cgColor, radius: radius))
    }
}

// MARK: - Resize Image
extension Image {
    
    final public func resized(
        to size: Size
    ) -> Image? {
        return Image(cgImage?.resized(to: size))
    }
}

// MARK: - Alpha Channel
extension Image {
    
    // Returns true if the image has alpha layer
    final public var hasAlpha: Bool {
        return cgImage?.hasAlpha ?? false
    }
    
    final public func withAlpha() -> Image? {
        return Image(cgImage?.withAlpha())
    }
}

// MARK: - Transparent Border
extension Image {
    
    final public func bordered(
        _ border: CGFloat
    ) -> Image? {
        return Image(cgImage?.bordered(border, color: Color.black.cgColor))
    }
}

// MARK: - Corner Clip
extension Image {
    
    final public func clipped(radius: CGFloat) -> Image? {
        return Image(cgImage?.clipped(radius: radius))
    }
}
