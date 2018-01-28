//
//  Graphics.swift
//  ImageUtils
//
//

import CoreGraphics

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
        return bitsPerPixel / max(1, bitsPerComponent) // Safe for zero pixel.
    }
    
    /// .bytesPerRow is wrong? We use bytesPerPixel * width to compute it.
    @_inlineable
    final public var bytesPerRow: Int {
        return bytesPerPixel * width
    }
}
