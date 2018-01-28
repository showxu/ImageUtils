//
//  Image+Utils.swift
//
//

#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

extension Image {
    
    #if os(iOS) || os(tvOS)
    final public class func build(_ size: CGSize = .zero,
                                  color: Color = .clear,
                                  radius: CGFloat = 0) -> Image? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, Screen.main.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.setFillColor(color.cgColor)
        UIBezierPath(roundedRect: rect, cornerRadius: min(size.height / 2, radius)).addClip()
        ctx.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
    }
    
    final public class func resize(_ image: Image, dstWidth: Int, dstHeight: Int, filter: Bool = false) -> Image? {
        return resize(image, to: Size(width: dstWidth, height: dstHeight), filter: filter)
    }

    final public class func resize(_ image: Image, to dstSize: Size, filter: Bool = false) -> Image? {
        let newRect = Rect(origin: .zero, size: dstSize).integral
        guard let cgImage = image.cgImage else { return nil }
    
        UIGraphicsBeginImageContextWithOptions(dstSize, false, image.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        let ctx = UIGraphicsGetCurrentContext()
        
        // Set the quality level to use when rescaling
        ctx?.interpolationQuality = .high
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: dstSize.height)
        ctx?.concatenate(flipVertical)
        // Draw into the context; this scales the image
        ctx?.draw(cgImage, in: newRect)
        
        guard let cgImageNew = ctx?.makeImage() else { return nil }
        // Get the resized image from the context and a UIImage
        let newImage = Image(cgImage: cgImageNew)

        return newImage
    }
    #endif
}


    
extension CGImage {
    
    var context: CGContext? {
        return CGImage.getContext(self)
    }

    public class func getContext(_ cgImage: CGImage?) -> CGContext? {
        guard
            let cgImage = cgImage,
            let ctx = getBitmapContext(cgImage)
        else { return nil }
        ctx.draw(cgImage, in: Rect(origin: .zero, size: cgImage.size))
        return ctx
    }
    
    public class func getBitmapContext(
            _ cgImage: CGImage,
            _ dataProvider: ((CGImage) -> UnsafeMutablePointer<CChar>)? = nil,
            _ bitmapInfo: (CGImage) -> UInt32 = { _ in
                return CGImageAlphaInfo.premultipliedFirst.rawValue
            }) -> CGContext? {
        guard let colorSpace = cgImage.colorSpace else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = cgImage.bitsPerComponent
        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerRow = bitsPerPixel / bitsPerComponent * width // cgImage.bytesPerRow is wrong?
        
        let ctx = CGContext(
            data: dataProvider?(cgImage).deinitialize(),
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo(cgImage),
            releaseCallback: nil,
            releaseInfo: nil
        )
        return ctx
    }
    
    public class func getCGImage(_ bitmap: UnsafeMutableRawPointer?,
                                 bitmapContext: CGContext?,
                                 release: ((UnsafeMutableRawPointer?) -> Void)?) -> CGImage? {
        let releasePtr = Unmanaged<AnyObject>.passRetained(release as AnyObject).toOpaque()
        guard
            let bitmap = bitmap,
            let bitmapContext = bitmapContext,
            let colorSpace = bitmapContext.colorSpace,
            let dataProvider = CGDataProvider(dataInfo: releasePtr, data: bitmap, size: bitmapContext.bytes, releaseData: {(info, rawData, size) in
                guard let info = info else { return }
                let releasePtr = Unmanaged<AnyObject>.fromOpaque(info)
                let release = releasePtr.takeRetainedValue() as? (UnsafeMutableRawPointer?) -> Void
                let data = UnsafeMutableRawPointer(mutating: rawData)
                release?(data)
            })
        else { return nil }
        
        let cg = CGImage(width: bitmapContext.width,
                         height: bitmapContext.height,
                         bitsPerComponent: bitmapContext.bitsPerComponent,
                         bitsPerPixel: bitmapContext.bitsPerPixel,
                         bytesPerRow: bitmapContext.bytesPerRow,
                         space: colorSpace,
                         bitmapInfo: bitmapContext.bitmapInfo,
                         provider: dataProvider,
                         decode: nil,
                         shouldInterpolate: true,
                         intent: .defaultIntent)
        return cg
    }
}

