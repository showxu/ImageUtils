//
//  Bitmap.swift
// 
//

public typealias Bitmap = Image

extension Bitmap {
    
    static let createScaledBitmap: (
        _ src: Bitmap,
        _ dstWidth: Int,
        _ dstHeight: Int,
        _ filter: Bool) -> Bitmap? = Bitmap.resize
}

