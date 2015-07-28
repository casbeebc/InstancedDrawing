//
//  TextureLoader.swift
//  InstancedDrawing
//
//  Created by brett on 7/23/15.
//  Copyright (c) 2015 DataMingle. All rights reserved.
//

import Foundation
import CoreGraphics
import Metal
import UIKit
import simd

class TextureLoader : NSObject {
    
    static func dataForImage (image: UIImage) -> UnsafeMutablePointer<Void> {
        let imageRef : CGImage = image.CGImage!
        
        let width : Int = CGImageGetWidth(imageRef)
        let height : Int = CGImageGetHeight(imageRef)
        
        let colorSpace : CGColorSpaceRef! = CGColorSpaceCreateDeviceRGB()
        
        let rawData: UnsafeMutablePointer<Void> = calloc(height * width * 4, sizeof(UInt8))
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        let context: CGContext! = CGBitmapContextCreate(rawData, width, height,bitsPerComponent, bytesPerRow, colorSpace, CGImageAlphaInfo.PremultipliedFirst.rawValue)
        
        // Releasing of memory is taken care of with Swift
        // CGColorSpaceRelease(colorSpace)
        
        CGContextTranslateCTM(context, 0, CGFloat(height))
        CGContextScaleCTM(context, 1, -1)
        
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), imageRef)

        // Releasing of memory is taken care of with Swift
        // CGContextRelease(context)
       
        return rawData
    }
    
    static func texture2DWithImageNamed(imageName: String, device: MTLDevice) -> MTLTexture {
        
        let image: UIImage = UIImage(imageLiteral: imageName)!
        let imageSize: CGSize = CGSizeMake(image.size.width, image.size.height * image.scale)
        
        let bytesPerPixel: CGFloat = 4
        let bytesPerRow: CGFloat = bytesPerPixel * imageSize.width
        
        let imageData: UnsafeMutablePointer<Void> = self.dataForImage(image)
        
        let textureDescriptor : MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: Int(imageSize.width), height: Int(imageSize.height), mipmapped: false)
        
        let texture = device.newTextureWithDescriptor(textureDescriptor)
        
        let region : MTLRegion = MTLRegionMake2D(0, 0, Int(imageSize.width), Int(imageSize.height))
        texture.replaceRegion(region, mipmapLevel: 0, withBytes: imageData, bytesPerRow: Int(bytesPerRow))
        
        return texture
    }
    
}