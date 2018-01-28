
//: [Previous Page](@previous)

//: ## vImage
import UIKit
import ImageUtils

//: ### Image.Effects

//: **`vImage based blur effect`**
let preview = UIImage(named: "porsche-preview.jpg")!

Image.blur(light: preview)

Image.blur(dark: preview)

Image.blur(extraLight: preview)

//: [Next Page](@next)
