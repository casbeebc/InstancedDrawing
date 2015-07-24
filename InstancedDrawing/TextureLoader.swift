//
//  TextureLoader.swift
//  InstancedDrawing
//
//  Created by brett on 7/23/15.
//  Copyright (c) 2015 DataMingle. All rights reserved.
//

import Foundation
import CoreGraphics

class TextureLoader : NSobject {
    
    func dataForImage (image: UIImage) -> uint8_t {
        var imageRef : CGImage;
        
        let width : Int = CGImageGetWidth(imageRef)
        let height : Int = CGImageGetHeight(imageRef)
        
        colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let rawData : uint8_t = calloc(height * width * 4, sizeof(uint8_t))
        
        /*
        CGImageRef imageRef = [image CGImage];
        
        // Create a suitable bitmap context for extracting the bits of the image
        const NSUInteger width = CGImageGetWidth(imageRef);
        const NSUInteger height = CGImageGetHeight(imageRef);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
        const NSUInteger bytesPerPixel = 4;
        const NSUInteger bytesPerRow = bytesPerPixel * width;
        const NSUInteger bitsPerComponent = 8;
        CGContextRef context = CGBitmapContextCreate(rawData, width, height,
        bitsPerComponent, bytesPerRow, colorSpace,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        
        CGContextTranslateCTM(context, 0, height);
        CGContextScaleCTM(context, 1, -1);
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGContextRelease(context);
        
        return rawData;
        */
    }
}