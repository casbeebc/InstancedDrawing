//
//  TerrainMesh.swift
//  InstancedDrawing
//
//  Created by brett on 7/28/15.
//  Copyright © 2015 DataMingle. All rights reserved.
//

import UIKit
import Metal
import simd

class TerrainMesh : GeometryMesh {
    var width : Float = 0
    var depth : Float = 0
    var height: Float = 0
    var smoothness: Float = 0
    var iterations: UInt16 = 0
    
    var device: MTLDevice?
    var stride: Int = 0
    var vertexCount: Int = 0
    var indexCount: Int = 0
    
    var vertices: [Vertex] = []
    var indices: [Int] = []
    
    
    
    init?(width:Float, height:Float, iterations: UInt16, smoothness: Float, device: MTLDevice) {
        super.init()
        
        self.device = device
        self.width = width
        self.depth = width
        self.height = height
        self.smoothness = smoothness
        self.iterations = iterations
        
        self.generateTerrain()
        
    }
    
    func generateTerrain() {
        
        self.stride = Int((1 << self.iterations) + 1) // number of vertices on one side of the terrain patch
        
        self.vertexCount = self.stride * self.stride
        self.indexCount = (self.stride - 1) * (self.stride - 1) * 6
        
        
        var variance: Float = 1.0 // absolute maximum variance about mean height value
        let smoothingFactor: Float = powf(2, -self.smoothness) // factor by which to decrease variance each iteration
        
        // seed corners with 0.
        self.vertices[0].position.y = 0.0
        self.vertices[self.stride].position.y = 0.0
        self.vertices[(self.stride - 1) * self.stride].position.y = 0.0
        self.vertices[(self.stride * self.stride) - 1].position.y = 0.0
        
        for (var i = 0; i < Int(self.iterations); ++i)
        {
            let numSquares: Int = (1 << i); // squares per edge at the current subdivision level (1, 2, 4, 8)
            let squareSize: Int = Int(1 << (self.iterations - UInt16(i))); // edge length of square at current subdivision (CHECK THIS)
            
            for (var y = 0; y < numSquares; ++y)
            {
                for (var x = 0; x < numSquares; ++x)
                {
                    let row = y * squareSize;
                    let column = x * squareSize;
                    
                    self.performSquareStepWithRow(row, column: column, squareSize: squareSize, variance: variance)
                    self.performDiamondStepWithRow(row, column: column, squareSize: squareSize, variance: variance)
                }
            }
            
            variance *= smoothingFactor;
        }
        
        self.computeMeshCoordinates()
        self.computeMeshNormals()
        self.generateMeshIndices()
        
        self.vertexBuffer = self.device!.newBufferWithBytes(&self.vertices, length: sizeof(Vertex) * self.vertexCount, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.vertexBuffer!.label = "Vertices (Terrain)"
        
        self.indexBuffer = self.device!.newBufferWithBytes(&self.indices, length: sizeof(UInt16) * self.indexCount, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.indexBuffer!.label = "Indices (Terrain)"
    }
    
    func performSquareStepWithRow(row: Int, column: Int, squareSize: Int, variance: Float) {
        let r0 = row
        let c0 = column

        let r1: Int = (r0 + squareSize) % self.stride
        let c1: Int = (c0 + squareSize) % self.stride
        let cmid: Int = c0 + (squareSize / 2)
        let rmid: Int = r0 + (squareSize / 2)
        
        let y00: Float = self.vertices[r0 * self.stride + c0].position.y
        let y01: Float = self.vertices[r0 * self.stride + c1].position.y;
        let y11: Float = self.vertices[r1 * self.stride + c1].position.y;
        let y10: Float = self.vertices[r1 * self.stride + c0].position.y;
        let ymean: Float = (y00 + y01 + y11 + y10) * 0.25;
        let error: Float = ((Float(arc4random()) / Float(UInt32.max) - 0.5) * 2) * variance;
        let y: Float = ymean + error;
        
        self.vertices[rmid * self.stride + cmid].position.y = y;
    }
    
    func performDiamondStepWithRow(row: Int, column: Int, squareSize: Int, variance: Float) {
        
        let r0: Int = row;
        let c0: Int = column;
        let r1: Int = (r0 + squareSize) % self.stride;
        let c1: Int = (c0 + squareSize) % self.stride;
        let cmid: Int = c0 + (squareSize / 2);
        let rmid: Int = r0 + (squareSize / 2);
        
        let y00: Float = self.vertices[r0 * self.stride + c0].position.y;
        let y01: Float = self.vertices[r0 * self.stride + c1].position.y;
        let y11: Float = self.vertices[r1 * self.stride + c1].position.y;
        let y10: Float = self.vertices[r1 * self.stride + c0].position.y;
        var error: Float = 0;
        error = (((Float(arc4random()) / Float(UInt32.max)) - 0.5) * 2) * variance;
        self.vertices[r0 * self.stride + cmid].position.y = (y00 + y01) * 0.5 + error;
        error = (((Float(arc4random()) / Float(UInt32.max)) - 0.5) * 2) * variance;
        self.vertices[rmid * self.stride + c0].position.y = (y00 + y10) * 0.5 + error;
        error = (((Float(arc4random()) / Float(UInt32.max)) - 0.5) * 2) * variance;
        self.vertices[rmid * self.stride + c1].position.y = (y01 + y11) * 0.5 + error;
        error = (((Float(arc4random()) / Float(UInt32.max)) - 0.5) * 2) * variance;
        self.vertices[r1 * self.stride + cmid].position.y = (y01 + y11) * 0.5 + error;
    }
    
    func computeMeshCoordinates() {
        for (var r = 0; r < self.stride; ++r)
        {
            for (var c = 0; c < self.stride; ++c)
            {
                let x: Float = (Float(c) / Float(self.stride - 1) - 0.5) * self.width
                let y: Float = self.vertices[r * self.stride + c].position.y * self.height
                let z: Float = (Float(r) / Float(self.stride - 1) - 0.5) * self.depth
                
                self.vertices[r * self.stride + c].position = [ x, y, z, 1 ]
                
                let s: Float = Float(c) / Float(self.stride - 1) * 5
                let t: Float = Float(r) / Float(self.stride - 1) * 5
                self.vertices[r * self.stride + c].texCoords = [s, t]
            }
        }
    }
    
    func computeMeshNormals() {
        
        let yScale: Float = 4;
        for (var r = 0; r < self.stride; ++r)
        {
            for (var c = 0; c < self.stride; ++c)
            {
                if (r > 0 && c > 0 && r < self.stride - 1 && c < self.stride - 1) {
                    
                    let L: vector_float4 = self.vertices[r * self.stride + (c - 1)].position
                    let R: vector_float4 = self.vertices[r * self.stride + (c + 1)].position
                    let U: vector_float4 = self.vertices[(r - 1) * self.stride + c].position
                    let D: vector_float4 = self.vertices[(r + 1) * self.stride + c].position
                    let T: vector_float3 = [ R.x - L.x, (R.y - L.y) * yScale, 0 ]
                    let B: vector_float3 = [ 0, (D.y - U.y) * yScale, D.z - U.z ]
                    let N: vector_float3 = vector_cross(B, T);
                    var normal: vector_float4 = [ N.x, N.y, N.z, 0 ]
                    normal = vector_normalize(normal);
                    self.vertices[r * self.stride + c].normal = normal;
                    
                } else {
                    let N: vector_float4 = [ 0, 1, 0, 0 ]
                    self.vertices[r * self.stride + c].normal = N;
                }
            }
        }
    }
    
    func generateMeshIndices() {
        
        var i: Int = 0;
        for (var r = 0; r < self.stride - 1; ++r)
        {
            for (var c = 0; c < self.stride - 1; ++c)
            {
                self.indices[i++] = r * self.stride + c
                self.indices[i++] = (r + 1) * self.stride + c
                self.indices[i++] = (r + 1) * self.stride + (c + 1)
                self.indices[i++] = (r + 1) * self.stride + (c + 1)
                self.indices[i++] = r * self.stride + (c + 1)
                self.indices[i++] = r * self.stride + c
            }
        }
    }
    
    func heightAtPositionX(x: Float, z:Float) -> Float {
        
        let halfSize: Float = self.width / 2
        
        if (x < -halfSize || x > halfSize || z < -halfSize || z > halfSize) {
            return 0
        }
        
        // Normalize x and z between 0 and 1
        let nx: Float = (x / self.width) + 0.5
        let nz: Float = (z / self.depth) + 0.5
        
        // Compute fractional indices of nearest vertices
        let fx: Float = nx * Float(self.stride - 1)
        let fz: Float = nz * Float(self.stride - 1)
        
        // Compute index of nearest vertices that are "up" and to the left
        let ix: Float = floorf(fx)
        let iz: Float = floorf(fz)
        
        // Compute fractional offsets in the direction of next nearest vertices
        let dx: Float = fx - ix
        let dz: Float = fz - iz
        
        // Get heights of nearest vertices
        let y00: Float = self.vertices[Int(iz * Float(self.stride) + ix)].position.y
        let y01: Float = self.vertices[Int(iz * Float(self.stride) + (ix + 1))].position.y
        let y10: Float = self.vertices[Int((iz + 1) * Float(self.stride) + ix)].position.y
        let y11: Float = self.vertices[Int((iz + 1) * Float(self.stride) + (ix + 1))].position.y
        
        // Perform bilinear interpolation to get approximate height at point
        let ytop: Float = (Float(1 - dx) * y00) + (dx * y01)
        let ybot: Float = (Float(1 - dx) * y10) + (dx * y11)
        let y: Float = (Float(1 - dz) * ytop) + (dz * ybot)
        
        return y
    }

}