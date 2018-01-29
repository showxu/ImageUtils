//: [Previous Page](@previous)

import UIKit
import ImageUtils

//: ## Image Utilities

//: **`color image`**
let dimension: CGFloat = 200
let size = Size(width: dimension, height: dimension)
var image = Image(size, color: .red, radius: dimension / 2)!

image = Image(size, color: .red)!

//: **`resize image`**
let resized = image.resized(to: Size(width: 50, height: 50))

//: **`bordered image`**
let bordered = image.bordered(30)

//: **`clipped image`**
let clipped = image.clipped(radius: 100)

//: [Next Page](@next)
