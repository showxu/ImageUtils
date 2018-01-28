//
//  Bitmap.swift
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

