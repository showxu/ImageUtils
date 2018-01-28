//
//  Rect.swift
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

extension Rect {
    
    public var left: Int {
        get {
            return Int(origin.x)
        } set {
            origin.x = CGFloat(newValue)
        }
    }
    
    public var top: Int {
        get {
            return Int(origin.y)
        } set {
            origin.y = CGFloat(newValue)
        }
    }
    
    public var right: Int {
        get {
            return left + Int(width)
        } set {
            size.width = CGFloat(newValue - left)
        }
    }
    
    public var bottom: Int {
        get {
            return top + Int(height)
        } set {
            size.height = CGFloat(newValue - top)
        }
    }
    
    public init(left: Int, top: Int, right: Int, bottom: Int) {
        self.init()
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }
}
