//
//  CGImage.Misc.swift
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

import CoreGraphics.CGImage
#if os(macOS)
import OpenGL
#elseif !os(watchOS)
import OpenGLES
#endif

extension CGImage {
    
    final public class func `init`(
        _ data: @autoclosure () -> UnsafeMutableRawPointer,
        bitmapContext: @autoclosure () -> CGContext,
        release: ((UnsafeMutableRawPointer?) -> Void)? = nil
    ) -> CGImage? {
        let releaseCallback = Unmanaged<AnyObject>.passRetained(release as AnyObject).toOpaque()
        let data = data()
        let ctx = bitmapContext()
        guard
            let space = ctx.colorSpace,
            let dataProvider = CGDataProvider(dataInfo: releaseCallback, data: data, size: ctx.bytes, releaseData: { info, rawData, size in
                let releaseCallback = Unmanaged<AnyObject>.fromOpaque(info!)
                let release = releaseCallback.takeRetainedValue() as? (UnsafeMutableRawPointer?) -> Void
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

extension CGImage {
    
    #if !os(watchOS)
    final public func readPixels() {
        glReadPixels(GLint(0), GLint(0), GLsizei(width), GLsizei(height), GLenum(GL_RGB), GLenum(GL_UNSIGNED_BYTE),         context?.data)
    }
    #endif
}

extension CGImage {
    
    final public var pixels: [Int] {
        guard
            width != 0 && height != 0,
            // Context should live in memory for auto managing underlying data.
            let ctx = context,
            // FIMEX: (dataProvider?.data) is more faster
            let data = ctx.data?.assumingMemoryBound(to: UInt8.self)
        else { return [] }
        var pixels: [Int] = []
        pixels.reserveCapacity(width * height)

        for i in 0..<width * height {
            let offset = i * 4
            let b = data[offset]
            let g = data[offset + 1]
            let r = data[offset + 2]
            let a = data[offset + 3]
            let argb = Color.argb(Int(a), Int(r), Int(g), Int(b))
            pixels.append(argb)
        }
        return pixels
    }
}

extension CGImage {
    
    final public var context: CGContext? {
        return CGContext(self)
    }
    
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
        return bitsPerPixel / max(1, bitsPerComponent) // Safe for zero pixel.
    }
    
    /// .bytesPerRow is wrong? We use bytesPerPixel * width to compute it.
    @_inlineable
    final public var bytesPerRow: Int {
        return bytesPerPixel * width
    }
}

