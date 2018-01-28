//
//  Abstract: This extension inspired from
//  Apple UIImageEffects (https://developer.apple.com/library/content/samplecode/UIImageEffects/Introduction/Intro.html)
//  --------------------------------------------------------------------------------
//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 0xxd0 (https://github.com/0xxd0).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//  --------------------------------------------------------------------------------
//
//  Abstract: This class contains methods to apply blur and tint effects to an image.
//  This is the code you’ll want to look out to find out how to use vImage to
//  efficiently calculate a blur.
//  Version: 1.1
//
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//  Inc. ("Apple") in consideration of your agreement to the following
//  terms, and your use, installation, modification or redistribution of
//  this Apple software constitutes acceptance of these terms.  If you do
//  not agree with these terms, please do not use, install, modify or
//  redistribute this Apple software.
//
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software.
//  Neither the name, trademarks, service marks or logos of Apple Inc. may
//  be used to endorse or promote products derived from the Apple Software
//  without specific prior written permission from Apple.  Except as
//  expressly stated in this notice, no other rights or licenses, express or
//  implied, are granted by Apple herein, including but not limited to any
//  patent rights that may be infringed by your derivative works or by other
//  works in which the Apple Software may be incorporated.
//
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//  Copyright (C) 2014 Apple Inc. All Rights Reserved.
//

#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

import Accelerate

extension Image {
    
    #if !(os(watchOS) || os(macOS))
    //| ----------------------------------------------------------------------------
    public final class func blur(light input: Image) -> Image? {
        let tint = Color(white: 1, alpha: 0.3)
        return blur(input, blurRadius: 60, tint: tint, saturation: 1.8, mask: nil)
    }

    //| ----------------------------------------------------------------------------
    public final class func blur(extraLight input: Image) -> Image? {
        let tint = Color(white: 0.97, alpha: 0.82)
        return blur(input, blurRadius: 40, tint: tint, saturation: 1.8, mask: nil)
    }
    
    //| ----------------------------------------------------------------------------
    public final class func blur(dark input: Image) -> Image? {
        let tint = Color(white: 0.11, alpha: 0.73)
        return blur(input, blurRadius: 40, tint: tint, saturation: 1.8, mask: nil)
    }
    
    //| ----------------------------------------------------------------------------
    public final class func blur(tint input: Image, _ tint: Color) -> Image? {
        let effectColorAlpha = CGFloat(0.6)
        var effectColor = tint
        let count = effectColor.cgColor.numberOfComponents
        if count == 2 {
            var b: CGFloat = 0
            if tint.getWhite(&b, alpha: nil) {
                effectColor = Color.init(white: b, alpha: effectColorAlpha)
            }
        } else {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0;
            if tint.getRed(&r, green: &g, blue: &b, alpha: nil) {
                effectColor = Color.init(red: r, green: g, blue: b, alpha: effectColorAlpha)
            }
        }
        return blur(input, blurRadius: 20, tint: tint, saturation: -1, mask: nil)
    }
    
    public final class func blur(
        _ input: Image,
        blurRadius: Float,
        tint: Color?,
        saturation delta: Float,
        mask: Image? = nil) -> Image? {
        // Check pre-conditions.
        precondition(input.width >= 1 && input.height >= 1, "*** error: invalid size: (\(input.width) x \(input.height)). Both dimensions must be >= 1: \(input)")
        assert(input.cgImage != nil, "*** error: inputImage must be backed by a CGImage: \(input)")
        //assert(mask?.cgImage != nil, "*** error: effectMaskImage must be backed by a CGImage: \(String(describing: mask))")
        let hasBlur = blurRadius > Float.ulpOfOne
        let hasSaturationChange = fabs(delta - 1.0) > Float.ulpOfOne
        let inputCgImage = input.cgImage!
        let inputScale = input.scale
        let inputImageBitmapInfo = inputCgImage.bitmapInfo
        let inputImageAlphaInfo = inputCgImage.alphaInfo
        
        let outputSize = input.size
        let outputRect = CGRect(origin: .zero, size: outputSize)
        
        // Set up output context.
        var useOpaqueContext = false
        if inputImageAlphaInfo == .none || inputImageAlphaInfo == .noneSkipLast || inputImageAlphaInfo == .noneSkipFirst {
            useOpaqueContext = true;
        }
        UIGraphicsBeginImageContextWithOptions(outputRect.size, useOpaqueContext, inputScale)
        defer {
            UIGraphicsEndImageContext()
        }
        let optCtx = UIGraphicsGetCurrentContext()
        optCtx?.scaleBy(x: 1, y: -1)
        optCtx?.translateBy(x: 0, y: -outputRect.height)
        
        if hasBlur || hasSaturationChange {
            var effectInBuffer = vImage_Buffer()
            var scratchBuffer1 = vImage_Buffer()
            
            var format = vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                colorSpace: nil,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
                version: 0,
                decode: nil,
                renderingIntent: .defaultIntent
            )
            
            let vError = vImageBuffer_InitWithCGImage(
                &effectInBuffer,
                &format,
                nil,
                inputCgImage,
                vImage_Flags(kvImagePrintDiagnosticsToConsole)
            )
            guard vError == kvImageNoError else {
                print("*** error: vImageBuffer_InitWithCGImage returned error code \(vError) for inputImage: \(input)")
                return nil
            }
            vImageBuffer_Init(&scratchBuffer1, effectInBuffer.height, effectInBuffer.width, format.bitsPerPixel, vImage_Flags(kvImageNoFlags))
            
            var inputBuffer = UnsafeMutablePointer(&effectInBuffer)
            var outputBuffer = UnsafeMutablePointer(&scratchBuffer1)

            #if true // ENABLE_BLUR
                if hasBlur {
                    // A description of how to compute the box kernel width from the Gaussian
                    // radius (aka standard deviation) appears in the SVG spec:
                    // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
                    //
                    // For larger values of 's' (s >= 2.0), an approximation can be used: Three
                    // successive box-blurs build a piece-wise quadratic convolution kernel, which
                    // approximates the Gaussian kernel to within roughly 3%.
                    //
                    // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
                    //
                    // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
                    //
                    var inputRadius = blurRadius * Float(inputScale)
                    if inputRadius - 2 < Float.ulpOfOne {
                        inputRadius = 2
                    }
                    // too complex to be solved in reasonable time for Swift compiler. 🤫
                    // var radius = floor((inputRadius * 3 * sqrt(2 * .pi) / 4 + 0.5) / 2)
                    inputRadius *= 3
                    inputRadius *= sqrt(2 * .pi)
                    inputRadius /= 4
                    inputRadius += 0.5
                    inputRadius /= 2
                    var radius = UInt32(inputRadius)

                    radius |= 1// force radius to be odd so that the three box-blur methodology works.
                    let tempBufferSize = vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, nil, 0, 0, radius, radius, nil,  vImage_Flags(kvImageGetTempBufferSize | kvImageEdgeExtend))
                    let tempBuffer = malloc(tempBufferSize)
                    defer {
                        free(tempBuffer)
                    }
                    vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, tempBuffer, 0, 0, radius, radius, nil,  vImage_Flags(kvImageEdgeExtend))
                    vImageBoxConvolve_ARGB8888(outputBuffer, inputBuffer, tempBuffer, 0, 0, radius, radius, nil, vImage_Flags(kvImageEdgeExtend));
                    vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, tempBuffer, 0, 0, radius, radius, nil, vImage_Flags(kvImageEdgeExtend));
                    
                    swap(&inputBuffer, &outputBuffer)
                }
            #endif
            
            #if true// ENABLE_SATURATION_ADJUSTMENT
                if hasSaturationChange {
                    let s = delta
                    // These values appear in the W3C Filter Effects spec:
                    // https://dvcs.w3.org/hg/FXTF/raw-file/default/filters/index.html#grayscaleEquivalent
                    //
                    let floatingPointSaturationMatrix = ContiguousArray<Float>([
                        0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                        0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                        0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                        0,                    0,                    0,                    1,
                    ])
                    let divisor = Int32(256)
                    let maxtrixSize = floatingPointSaturationMatrix.count
                    var saturationMatrix = ContiguousArray<Int16>(repeating: 0, count: maxtrixSize)
                    for i in floatingPointSaturationMatrix.indices {
                        saturationMatrix[i] = Int16(roundf(floatingPointSaturationMatrix[i] * Float(divisor)))
                    }
                    vImageMatrixMultiply_ARGB8888(
                        inputBuffer,
                        outputBuffer,
                        saturationMatrix.withUnsafeBufferPointer{ $0.baseAddress! },
                        divisor,
                        nil,
                        nil,
                        vImage_Flags(kvImageNoFlags)
                    );
                    swap(&inputBuffer, &outputBuffer)
                }
            #endif
            
            var effect_cgImage: CGImage?
            
            effect_cgImage = vImageCreateCGImageFromBuffer(inputBuffer, &format, cleanupBuffer, nil, vImage_Flags(kvImageNoAllocate), nil)?.takeRetainedValue()
            if effect_cgImage == nil {
                effect_cgImage = vImageCreateCGImageFromBuffer(inputBuffer, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil).takeRetainedValue()
                free(inputBuffer.pointee.data);
            }
        
            if mask != nil {
                // Only need to draw the base image if the effect image will be masked.
                optCtx?.draw(inputCgImage, in: outputRect)
            }
            // draw effect image
            optCtx?.saveGState()

            if mask != nil {
                optCtx?.clip(to: outputRect, mask: mask!.cgImage!)
            }
            optCtx?.draw(effect_cgImage!, in: outputRect)
            optCtx?.restoreGState()
            // Cleanup
            free(outputBuffer.pointee.data)
        } else {
            optCtx?.draw(inputCgImage, in: outputRect)
        }
        
        #if true //ENABLE_TINT
            // Add in color tint.
            if let cgColor = tint?.cgColor {
                optCtx?.saveGState()
                optCtx?.setFillColor(cgColor)
                optCtx?.fill(outputRect)
                optCtx?.restoreGState()
            }
        #endif
        // Output image is ready.
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        return outputImage
    }
    #endif
}

func cleanupBuffer(_ userData: UnsafeMutableRawPointer?, _ bufData: UnsafeMutableRawPointer?) -> Void {
    free(bufData)
}
