//
//  Graphics.swift
//  ImageUtils
//
//

import CoreGraphics

extension Image {
    
    #if os(macOS)
    public convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: .zero)
    }
    #endif
}

extension CGImage {
    
    final public class func `init`(
        _ data: @autoclosure () -> UnsafeMutableRawPointer,
        bitmapContext: @autoclosure () -> CGContext,
        release: ((UnsafeMutableRawPointer?) -> Void)? = nil
    ) -> CGImage? {
        let function = Unmanaged<AnyObject>.passRetained(release as AnyObject).toOpaque()
        let data = data()
        let ctx = bitmapContext()
        guard
            let space = ctx.colorSpace,
            let dataProvider = CGDataProvider(dataInfo: function, data: data, size: ctx.bytes, releaseData: { info, rawData, size in
                let function = Unmanaged<AnyObject>.fromOpaque(info!)
                let release = function.takeRetainedValue() as? (UnsafeMutableRawPointer?) -> Void
                let data = UnsafeMutableRawPointer(mutating: rawData)
                release?(data)
            })
            else { return nil }
        
        let cgImage = CGImage(
            width: ctx.width,
            height: ctx.height,
            bitsPerComponent: ctx.bitsPerComponent,
            bitsPerPixel: ctx.bitsPerPixel,
            bytesPerRow: ctx.bytesPerRow,
            space: space,
            bitmapInfo: ctx.bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
        return cgImage
    }
}

extension CGContext {
    
    final public class func `init`(
        _ size: Size,
        _ isOpaque: Bool,
        _ scale: CGFloat) -> CGContext? {
        let bitmapInfo = isOpaque ?
            CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue:
            CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let ctx = CGContext(
            data: nil,
            width: Int(size.width * scale),
            height: Int(size.height * scale),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        )
        return ctx
    }
    
    final public class func `init`(_ image: CGImage) -> CGContext? {
        guard let ctx = CGContext(bitmap: image) else {
            return nil
        }
        ctx.draw(image, in: Rect(origin: .zero, size: image.size))
        return ctx
    }
    
    final public class func `init`(
        bitmap cgImage: CGImage,
        buffer: ((CGImage) -> UnsafeMutablePointer<CChar>)? = nil,
        bitmapInfo: (CGImage) -> UInt32 = { _ in return CGImageAlphaInfo.premultipliedFirst.rawValue }
    ) -> CGContext? {
        guard let space = cgImage.colorSpace else { return nil }
        let ctx = CGContext(
            data: buffer?(cgImage).deinitialize(),
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: cgImage.bytesPerRow,
            space: space,
            bitmapInfo: bitmapInfo(cgImage),
            releaseCallback: nil,
            releaseInfo: nil
        )
        return ctx
    }
}

extension Image {
    
    @_inlineable
    final public var width: CGFloat {
        return size.width
    }
    
    @_inlineable
    final public var height: CGFloat {
        return size.height
    }
}

extension CGImage {
    
    final public var context: CGContext? {
        return CGContext(self)
    }
    
    @_inlineable
    final public var size: Size {
        return Size(width: width, height: height)
    }
    
    @_inlineable
    final public var bytes: Int {
        return bytesPerRow * height
    }
    
    @_inlineable
    final public var bytesPerPixel: Int {
        return bitsPerPixel / max(1, bitsPerComponent) // Safe for zero pixel.
    }
    
    /// .bytesPerRow is wrong? We use bytesPerPixel * width to compute it.
    @_inlineable
    final public var bytesPerRow: Int {
        return bytesPerPixel * width
    }
}

extension CGContext {
    
    @_inlineable
    final public var size: Size {
        return Size(width: width, height: height)
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
