//
//  Compat.swift
//  ImageUtils
//
//

#if os(macOS)
    import AppKit.NSImage
    public typealias Image = NSImage
    public typealias Screen = NSScreen
    public typealias Color = NSColor
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit.UIImage
#if os(iOS) || os(tvOS)
    public typealias Screen = UIScreen
#endif
    public typealias Image = UIImage
    public typealias Color = UIColor
#endif

