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
    
    var width: CGFloat {
        return size.width
    }
    
    var height: CGFloat {
        return size.height
    }
}

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
        return resize(image, to: Size.init(width: dstWidth, height: dstHeight), filter: filter)
    }

    final public class func resize(_ image: Image, to dstSize: Size, filter: Bool = false) -> Image? {
        let newRect = Rect(origin: .zero, size: dstSize).integral
        guard let cgImage = image.cgImage else { return nil }
    
        UIGraphicsBeginImageContextWithOptions(dstSize, false, Screen.main.scale)
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
        let newImage = UIImage(cgImage: cgImageNew)

        return newImage
    }
    #endif
}

