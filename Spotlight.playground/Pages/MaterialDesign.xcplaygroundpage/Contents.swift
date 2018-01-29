//: [Previous Page](@previous)

//: ## Material Design
import UIKit
import ImageUtils

//: ### Android Palette
/*:
 With the relase of Android Lollipop, several new support libraries have been created. One of the new libraries is the Palette.
 
 Palette is a cool way to pull out theme colors from images, which is useful if you want to make view components to match color pattern from the image.
 
 Now, we can use it on the Apple platform.
 */

//: We need to generate the color palette for the image.
let thumb = UIImage(named: "viva-la-vida.jpg")!
let palette = Palette.from(thumb).generate()

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

//: To learn more detail about Palette, see [Android Developers](https://developer.android.com/reference/android/support/v7/graphics/Palette.html)

//: [Next Page](@next)
