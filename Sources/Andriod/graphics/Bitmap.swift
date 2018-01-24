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
            return; // nothing to do
        }
        // FIXME: check
        // checkPixelsAccess(x, y, width, height, offset, stride, pixels);
        let data = CGImage.getContext(cgImage)?.data?.assumingMemoryBound(to: Int8.self)
        for i in 0..<width * height where data != nil {
            pixels[i] = Int(data![i])
        }
    }
}

