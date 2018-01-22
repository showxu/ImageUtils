//
//  Math.Utils.swift
//
//

public func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T {
    return max(min(value, upper), lower)
}
