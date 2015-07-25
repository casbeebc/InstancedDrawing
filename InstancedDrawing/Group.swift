//
//  Group.swift
//  InstancedDrawing
//
//  Created by brett on 7/24/15.
//  Copyright © 2015 DataMingle. All rights reserved.
//

import Foundation

class Group : NSObject {
    
    var name: String
    var vertexData: NSData? = nil
    var indexData: NSData? = nil
    
    init(name: String) {
        
        self.name = name
        
    }
}