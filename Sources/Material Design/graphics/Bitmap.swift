//
//  Bitmap.swift
// 
//

import UIKit

public typealias Bitmap = Image

extension Bitmap {
    
    static let createScaledBitmap: (
        _ src: Bitmap,
        _ dstWidth: Int,
        _ dstHeight: Int,
        _ filter: Bool) -> Bitmap? = Bitmap.resize

    public func getPixels(_ pixels: inout [Int],
                          _ offset: Int,
                          _ stride: Int,
                          _ x: Int,
                          _ y: Int,
                          _ width: Int,
                          _ height: Int) {
        // unnecessary for Swift
        // checkRecycled("Can't call getPixels() on a recycled bitmap");
        // FIXME: check
        // checkHardware("unable to getPixels(), " + "pixel access is not supported on Config#HARDWARE bitmaps");
        if (width == 0 || height == 0) {
            return // nothing to do
        }
        // FIXME: check
        // checkPixelsAccess(x, y, width, height, offset, stride, pixels);
        let ctx = CGImage.getContext(cgImage)
        let data = ctx?.data?.assumingMemoryBound(to: UInt8.self)
        for i in 0..<width * height where data != nil {
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

