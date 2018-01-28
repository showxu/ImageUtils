//: [Previous Page](@previous)

import UIKit
import ImageUtils

//: ## Image Utilities

//: **`colored image`**
let dimension: CGFloat = 200
let size = Size(width: dimension, height: dimension)
let colored = Image(size, color: .red, radius: dimension / 2)!
//: **`resize image`**
let resized = Image(resize: colored, to: size / 2, quality: .default)!
let resized2 = resized.resized(to: Size(width: 50, height: 50))!
//: [Next Page](@next)
