//: [Previous Page](@previous)

import UIKit
import ImageUtils

//: ## Image Utilities

//: **`color image`**
let dimension: CGFloat = 200
let size = Size(width: dimension, height: dimension)
let fooImage = Image(size, color: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1), radius: dimension / 2)!

let image = Image(size, color: #colorLiteral(red: 0, green: 0.6650493741, blue: 0.8382979631, alpha: 1))!

//: **`resize image`**
let resized = image.resized(to: Size(width: 50, height: 50))

//: **`bordered image`**
let bordered = image.bordered(30)

//: **`clipped image`**
let clipped = image.clipped(radius: 100)

//: [Next Page](@next)
