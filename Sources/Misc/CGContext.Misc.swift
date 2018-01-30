//
//  CGContext.Misc.swift
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

extension CGBitmapInfo {
    
    public init(
        _ space: @autoclosure () -> CGColorSpace = CGColorSpaceCreateDeviceRGB(),
        _ isOpaque: Bool = false
    ) {
        switch space().model {
        case .monochrome where isOpaque:
            self.init(rawValue: CGImageAlphaInfo.none.rawValue)
        case .rgb where isOpaque:
            self.init(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        case .rgb:
            self.init(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        default:
            self.init(rawValue: CGBitmapInfo.byteOrderMask.rawValue)
        }
    }
}

extension CGContext {
    
    final public class func `init`(
        _ size: CGSize,
        _ isOpaque: Bool = false,
        _ scale: CGFloat,
        _ space: @autoclosure () -> CGColorSpace = CGColorSpaceCreateDeviceRGB()
    ) -> CGContext? {
        let space = space()
        let ctx = CGContext(
            data: nil,
            width: Int(size.width * scale),
            height: Int(size.height * scale),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: space,
            bitmapInfo: CGBitmapInfo(space, isOpaque).rawValue
        )
        return ctx
    }
    
    final public class func `init`(_ image: CGImage) -> CGContext? {
        let ctx = CGContext(bitmap: image)
        ctx?.draw(image, in: CGRect(origin: .zero, size: image.size))
        return ctx
    }
    
    final public class func `init`(
        bitmap image: CGImage,
        buffer: @autoclosure () -> UnsafeMutablePointer<CChar>? = nil,
        bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedFirst.rawValue
    ) -> CGContext? {
        guard let space = image.colorSpace else { return nil }
        let ctx = CGContext(
            data: buffer()?.deinitialize(),
            width: image.width,
            height: image.height,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: image.bytesPerRow,
            space: space,
            bitmapInfo: bitmapInfo,
            releaseCallback: nil,
            releaseInfo: nil
        )
        return ctx
    }
}

// MARK: - Path
extension CGContext {
    
    // Adds a rectangular path to the given context and rounds its corners by the given extents
    public func addArc(to rect: CGRect, semiMajorAxis: CGFloat, semiMinorAxis: CGFloat) {
        if semiMajorAxis == 0 || semiMinorAxis == 0 {
            addRect(rect)
            return
        }
        saveGState()
        defer {
            restoreGState()
        }
        translateBy(x: rect.minX, y: rect.minY)
        scaleBy(x: semiMajorAxis, y: semiMinorAxis)
        let fw = rect.width / semiMajorAxis
        let fh = rect.height / semiMinorAxis
        move(to: .init(x: fw, y: fh / 2))
        addArc(tangent1End: .init(x: fw, y: fh), tangent2End: .init(x: fw / 2, y: fh), radius: 1)
        addArc(tangent1End: .init(x: 0, y: fh), tangent2End: .init(x: 0, y: fh / 2), radius: 1)
        addArc(tangent1End: .init(x: 0, y: 0), tangent2End: .init(x: fw / 2, y: 0), radius: 1)
        addArc(tangent1End: .init(x: fw, y: 0), tangent2End: .init(x: fw, y: fh / 2), radius: 1)
    }
}

extension CGContext {
    
    @_inlineable
    final public var size: CGSize {
        return CGSize(width: width, height: height)
    }
    
    @_inlineable
    final public var bytes: Int {
        return bytesPerRow * height
    }
    
    @_inlineable
    final public var bytesPerPixel: Int {
        return bitsPerPixel / max(1, bitsPerComponent) // Usaully one component has 8-bit width, safe for zero pixel.
    }
    
    /// .bytesPerRow is wrong? We use bytesPerPixel * width to compute it.
    @_inlineable
    final public var bytesPerRow: Int {
        return bytesPerPixel * width
    }
}

// MARK: - macOS compatible
extension CGContext {
    
    #if !os(macOS)
    @available(iOS 2.0, *)
    public func setFillColor(_ color: Color) {
        setFillColor(color.cgColor)
    }
    #endif
}
