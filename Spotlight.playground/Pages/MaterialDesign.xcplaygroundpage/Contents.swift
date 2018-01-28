//: [Previous Page](@previous)

//: ## Material Design
import UIKit
import ImageUtils

//: ### Android Palette
/*:
 With the relase of Android Lollipop, several new support libraries have been created. One of the new libraries is the Palette. This new class makes it easy to extract prominent colors from bitmap images, which is useful if you want to style other view components to match colors from your image, such as a background for the image or a text color with suitable contrast.
 
 And now, we can use it on the iOS platform.
 */
//: First we need to generate the color palette for the image
let vivaLaVidaAlbum = UIImage(named: "viva-la-vida.jpg")!
let palette = Palette.from(vivaLaVidaAlbum).generate()

//: **`Vibrant Color`**
let vibrant = Color(hex: palette.getVibrantColor(0))

//: **`Dark Vibrant Color`**
let vibrantDark = Color(hex: palette.getDarkVibrantColor(0))

//: **`Light Vibrant Color`**
let vibrantLight = Color(hex: (palette.getLightVibrantColor(0)))

//: **`Muted Color`**
let muted = Color(hex: palette.getMutedColor(0))

//: **`Dark Muted Color`**
let mutedDark = Color(hex: palette.getDarkMutedColor(0))

//: **`Light Muted Color`**
let mutedLight = Color(hex: palette.getLightMutedColor(0))

//: See demo project for more detail about `Palette`.

//: [Next Page](@next)
