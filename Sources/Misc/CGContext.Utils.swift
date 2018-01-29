//
//  CGContext.Utils.swift
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

extension CGContext {
    
    // Adds a rectangular path to the given context and rounds its corners by the given extents
    public func addArc(to rect: Rect, semiMajorAxis: CGFloat, semiMinorAxis: CGFloat) {
        if semiMajorAxis == 0 || semiMinorAxis == 0 {
            addRect(rect)
            return
        }
        saveGState()
        defer {
            restoreGState()
        }
        translateBy(x: rect.minX, y: rect.minY)
        scaleBy(x: semiMajorAxis, y: semiMinorAxis)
        let fw = rect.width / semiMajorAxis
        let fh = rect.height / semiMinorAxis
        move(to: .init(x: fw, y: fh / 2))
        addArc(tangent1End: .init(x: fw, y: fh), tangent2End: .init(x: fw / 2, y: fh), radius: 1)
        addArc(tangent1End: .init(x: 0, y: fh), tangent2End: .init(x: 0, y: fh / 2), radius: 1)
        addArc(tangent1End: .init(x: 0, y: 0), tangent2End: .init(x: fw / 2, y: 0), radius: 1)
        addArc(tangent1End: .init(x: fw, y: 0), tangent2End: .init(x: fw, y: fh / 2), radius: 1)
    }
}
