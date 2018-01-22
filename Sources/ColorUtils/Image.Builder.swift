//
//  Image.Builder.swift
//
//

#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

// FIXME: Complete Image.Builder
extension Image {
    
    public enum Size {
        case fixed(size: CGSize)
        case resizable
    }
    
    public struct Border {
        var width: CGFloat = 0
        var color: Color = .clear
    }
}

extension Image {
    
    public struct Builder {
    }
}






