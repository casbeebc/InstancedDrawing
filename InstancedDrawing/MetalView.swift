//
//  MetalView.swift
//  InstancedDrawing
//
//  Created by brett on 7/23/15.
//  Copyright (c) 2015 DataMingle. All rights reserved.
//

import UIKit
import Metal
import QuartzCore

class MetalView: UIView {

    var metalLayer: CAMetalLayer! = nil
    var currentTouch: UITouch! = nil
    
    override init(frame aRect: CGRect) {
        super.init(frame: aRect)
        
        // During the first layout pass, we will not be in a view hierarchy, so we guess our scale
        var scale: CGFloat = UIScreen().scale
        
        
        // If we've moved to a window by the time our frame is being set, we can take its scale as our own
        if self.window != nil {
            scale = self.window!.screen.scale;
        }
        
        let drawableSize = self.bounds.size;

        // Since drawable size is in pixels, we need to multiply by the scale to move from points to pixels
        
        // NOTE: Swift doesn't allow you to multiple two CGFloats together
        let newWidth = Float(drawableSize.width) * Float(scale)
        let newHeight = Float(drawableSize.height) * Float(scale)
        
        self.metalLayer.drawableSize = CGSize(width: CGFloat(newWidth), height: CGFloat(newHeight));
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        let touches = touches as! Set<UITouch>
        
        for touch:UITouch in touches {
            currentTouch = touch
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        let touches = touches as! Set<UITouch>
        
        for touch:UITouch in touches {
            currentTouch = touch
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        currentTouch = nil
    }
    
    override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent) {
        currentTouch = nil
    }
    
}