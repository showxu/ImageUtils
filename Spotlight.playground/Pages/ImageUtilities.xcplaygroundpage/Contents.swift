//: [Previous Page](@previous)

import UIKit
import ImageUtils

//: ## Image Utilities

//: **`colored image`**
let dimension: CGFloat = 200
let size = Size(width: dimension, height: dimension)
let colored = Image(size, color: .red, radius: dimension / 2)!

//: **`resize image`**
var resized = Image(resize: colored, to: size / 2, quality: .default)!

resized = resized.resized(to: Size(width: 50, height: 50))!

//: **`tranparent bordered image`**
var masked = Image(size, color: .green, radius: 0)!

masked = Image(transparent: masked, border: 30)!

masked = masked.transparent(border: 30)!

//: **`round corner image`**
var cornered = Image(size, color: .blue, radius: 0)!
cornered = cornered.rounded(radius: 100)!

//: [Next Page](@next)
