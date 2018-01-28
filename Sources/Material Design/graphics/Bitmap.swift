//
//  Bitmap.swift
// 
//

import CoreGraphics

public typealias Bitmap = Image

extension Bitmap {
    
    public func getPixels(
        _ pixels: inout [Int],
        _ x: Int,
        _ y: Int,
        _ width: Int,
        _ height: Int
    ) {
        let width = min(width, Int(self.width))
        let height = min(height, Int(self.height))
        if (width == 0 || height == 0) { return }
        #if os(macOS)
            guard let ctx = cgImage(forProposedRect: nil, context: nil, hints: nil)?.context else { return }
        #else
            guard let ctx = cgImage?.context else { return }
        #endif
        let data = ctx.data?.assumingMemoryBound(to: UInt8.self)
        for i in x * y..<width * height where data != nil {
            let offset = i * 4
            let a = data![offset]
            let r = data![offset + 1]
            let g = data![offset + 2]
            let b = data![offset + 3]
            let argb = Color.argb(Int(a), Int(r), Int(g), Int(b))
            pixels[i] = argb
        }
    }
}

