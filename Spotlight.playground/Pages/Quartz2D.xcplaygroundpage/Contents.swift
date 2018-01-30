//: [Previous Page](@previous)

import UIKit
import ImageUtils

//: ## Quartz2D

//: **`color image`**
let dimension: CGFloat = 200
let size = Size(width: dimension, height: dimension)
let fooImage = Image(size, color: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1), radius: dimension / 2)!

let image = Image(size, color: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))!

//: **`resize image`**
let resized = image.resized(to: size / 2)

//: **`bordered image`**
let bordered = image.bordered(20)

//: **`clipped image`**
let clipped = image.clipped(radius: dimension / 2)

//: [Next Page](@next)
