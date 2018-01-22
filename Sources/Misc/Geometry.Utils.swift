//
//  Geometry.Utils.swift
//  ImageUtils
//
//

import CoreGraphics.CGGeometry

public func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

public func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

public func *(lhs: CGFloat, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs * rhs.x, y: lhs * rhs.y)
}

public func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}

public func +=(lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs + rhs
}

public func -=(lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs - rhs
}

public func *=(lhs: inout CGPoint, rhs: CGFloat) {
    lhs = lhs * rhs
}

public func /=(lhs: inout CGPoint, rhs: CGFloat) {
    lhs = lhs / rhs
}
