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
    #endif
}

