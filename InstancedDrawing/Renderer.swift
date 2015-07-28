//
//  Renderer.swift
//  InstancedDrawing
//
//  Created by brett on 7/23/15.
//  Copyright (c) 2015 DataMingle. All rights reserved.
//

import Foundation
import Metal
import simd
import QuartzCore.CAMetalLayer

class Renderer : NSObject {
    
    var angularVelocity: Float = 0
    var velocity: Float = 0
    var frameDuration: Float = 0
    
    let cowCount: Int = 80;
    let cowSpeed: Float = 0.75;
    let cowTurnDamping: Float = 0.95;
    
    let terrainSize: Float = 40;
    let terrainHeight: Float = 1.5;
    let terrainSmoothness: Float = 0.95;
    
    let cameraHeight: Float = 1;
    
    let Y: vector_float3 = [ 0, 1, 0 ];
    
    func random_unit_float() -> Float {
        
        return Float(arc4random()) / Float(UInt32.max);
    }
    
    var layer: CAMetalLayer?
    
    // Long-lived Metal objects
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    var renderPipeline: MTLRenderPipelineState?
    var depthState: MTLDepthStencilState?
    var depthTexture: MTLTexture?
    var sampler: MTLSamplerState?
    
    // Resources
    var terrainMesh: TerrainMesh?
    var terrainTexture: MTLTexture?
    var cowMesh: ObjectMesh?
    var cowTexture: MTLTexture?
    var sharedUniformBuffer: MTLBuffer?
    var terrainUniformBuffer: MTLBuffer?
    var cowUniformBuffer: MTLBuffer?
    
    // Parameters
    var cameraPosition: vector_float3 = []
    var cameraHeading: Float = 0
    var cameraPitch: Float = 0
    var cows: [Cow] = []
    var frameCount: Int = 0
    
    init(layer: CAMetalLayer) {
        super.init()
        self.frameDuration = 1 / 60.0
        self.layer = layer
        
        self.buildMetal()
        self.buildPipelines()
        self.buildCows()
        self.buildResources()
        
    }
    
    func buildMetal() {
        self.device = MTLCreateSystemDefaultDevice()
        self.layer!.device = self.device
        self.layer!.pixelFormat = MTLPixelFormat.BGRA8Unorm
    }
    
    func buildPipelines() {
        
        self.commandQueue = self.device!.newCommandQueue()
        
        let library: MTLLibrary = self.device!.newDefaultLibrary()!
        
        let vertexDescriptor: MTLVertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = MTLVertexFormat.Float4;
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].bufferIndex = 0;
        vertexDescriptor.attributes[1].format = MTLVertexFormat.Float4;
        vertexDescriptor.attributes[1].offset = sizeof(vector_float4);
        vertexDescriptor.attributes[1].bufferIndex = 0;
        vertexDescriptor.attributes[2].format = MTLVertexFormat.Float2;
        vertexDescriptor.attributes[2].offset = sizeof(vector_float4) * 2;
        vertexDescriptor.attributes[2].bufferIndex = 0;
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.PerVertex;
        vertexDescriptor.layouts[0].stride = sizeof(Vertex);

        let pipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.newFunctionWithName("vertex_project")
        pipelineDescriptor.fragmentFunction = library.newFunctionWithName("fragment_texture")
        pipelineDescriptor.vertexDescriptor = vertexDescriptor;
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm;
        pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float;
        
        do {
            self.renderPipeline = try self.device!.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
        } catch {
            NSLog("Failed to create render pipeline state")
        }
        
        let depthDescriptor: MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthWriteEnabled = true
        depthDescriptor.depthCompareFunction = MTLCompareFunction.Less
        self.depthState = self.device!.newDepthStencilStateWithDescriptor(depthDescriptor)
        
        let samplerDescriptor: MTLSamplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = MTLSamplerMinMagFilter.Nearest
        samplerDescriptor.magFilter = MTLSamplerMinMagFilter.Linear
        samplerDescriptor.sAddressMode = MTLSamplerAddressMode.Repeat
        samplerDescriptor.tAddressMode = MTLSamplerAddressMode.Repeat
        self.sampler = self.device!.newSamplerStateWithDescriptor(samplerDescriptor)
    }
    
    func buildCows() {
        
        for (var i = 0; i < cowCount; ++i)
        {
            let cow: Cow = Cow()
            
            // Situate the cow somewhere in the internal 80% part of the terrain patch
            let x: Float = (random_unit_float() - 0.5) * terrainSize * 0.8
            let z: Float = (random_unit_float() - 0.5) * terrainSize * 0.8
            let y: Float = self.terrainMesh!.heightAtPositionX(x, z: z)
            
            cow.position = [ x, y, z ]
            cow.heading = 2 * Float(M_PI) * random_unit_float();
            cow.targetHeading = cow.heading;
            
            self.cows.append(cow)
        }

    }
    func loadMeshes() {
        
        self.terrainMesh = TerrainMesh(width: self.terrainSize, height: self.terrainHeight, iterations: 4, smoothness: terrainSmoothness, device: self.device!)
        
        let modelURL: NSURL? = NSBundle.mainBundle().URLForResource("spot", withExtension: "obj")
        let cowModel: Model = Model(fileURL: modelURL!, generateNormals: true)
        let spotGroup: Group? = cowModel.groupForName("spot")
        
        self.cowMesh = ObjectMesh(group: spotGroup!, device: self.device!)
    }
    
    func loadTextures() {
        
        self.terrainTexture = TextureLoader.texture2DWithImageNamed("grass", device: self.device!)
        self.terrainTexture!.label = "Terrain Texture"
        
        self.cowTexture = TextureLoader.texture2DWithImageNamed("spot", device: self.device!)
        self.cowTexture!.label = "Cow Texture"
    }
    
    func buildUniformBuffers() {
        
        self.sharedUniformBuffer = self.device!.newBufferWithLength(sizeof(Uniforms), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.sharedUniformBuffer!.label = "Shared Uniforms"
        
        self.terrainUniformBuffer = self.device!.newBufferWithLength(sizeof(PerInstanceUniforms), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.terrainUniformBuffer!.label = "Terrain Uniforms"
        
        self.cowUniformBuffer = self.device!.newBufferWithLength(sizeof(PerInstanceUniforms), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.cowUniformBuffer!.label = "Cow Uniforms"
        
    }
    
    func buildResources() {
        
        self.loadMeshes()
        self.loadTextures()
        self.buildUniformBuffers()
        
    }
    
    func buildDepthTexture() {
        
        let drawableSize: CGSize = self.layer!.drawableSize
        
        let descriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.Depth32Float, width: Int(drawableSize.width), height: Int(drawableSize.height), mipmapped: false)
        
        self.depthTexture = self.device!.newTextureWithDescriptor(descriptor)
        self.depthTexture!.label = "Depth Texture"
        
    }
    
    func positionConstrainedToTerrainForPosition(position:vector_float3) -> vector_float3
    {
        var newPosition: vector_float3 = position
    
        // limit x and z extent to terrain patch boundaries
        let halfWidth = self.terrainMesh!.width * 0.5
        let halfDepth = self.terrainMesh!.depth * 0.5
        
        if (newPosition.x < -halfWidth) {
            newPosition.x = -halfWidth
        } else if (newPosition.x > halfWidth) {
            newPosition.x = halfWidth
        }
        
        if (newPosition.z < -halfDepth) {
            newPosition.z = -halfDepth
        } else if (newPosition.z > halfDepth) {
            newPosition.z = halfDepth
        }
        
        newPosition.y = self.terrainMesh!.heightAtPositionX(newPosition.x, z:newPosition.z)
        
        return newPosition
    }
    
    func updateTerrain() {
        
        var terrainUniforms: PerInstanceUniforms = PerInstanceUniforms()
        
        terrainUniforms.modelMatrix = MatrixUtilities.matrix_identity()
        terrainUniforms.normalMatrix = MatrixUtilities.matrix_upper_left3x3(terrainUniforms.modelMatrix!)

        memcpy(self.terrainUniformBuffer!.contents(), &terrainUniforms, sizeof(PerInstanceUniforms));
    }
    
    func updateCamera() {
        
        var cameraPosition: vector_float3 = self.cameraPosition
        
        self.cameraHeading += self.angularVelocity * self.frameDuration
        
        // update camera location based on current heading
        cameraPosition.x += -sin(self.cameraHeading) * self.velocity * self.frameDuration
        cameraPosition.z += -cos(self.cameraHeading) * self.velocity * self.frameDuration
        cameraPosition = self.positionConstrainedToTerrainForPosition(cameraPosition)
        cameraPosition.y += cameraHeight
        
        self.cameraPosition = cameraPosition
        
    }
    
    func updateCows() {
        
        for (var i = 0; i < cowCount; ++i) {
            
            let cow: Cow = self.cows[i]
            
            // all cows select a new heading every ~4 seconds
            if (self.frameCount % 240 == 0) {
                cow.targetHeading = 2 * Float(M_PI) * random_unit_float()
            }
            
            // smooth between the current and intended direction
            cow.heading = (cowTurnDamping * cow.heading) + ((1 - cowTurnDamping) * cow.targetHeading)
            
            // update cow position based on its orientation, constraining to terrain
            var position: vector_float3 = cow.position;
            position.x += sin(cow.heading) * cowSpeed * self.frameDuration
            position.z += cos(cow.heading) * cowSpeed * self.frameDuration
            position = self.positionConstrainedToTerrainForPosition(position)
            cow.position = position;
            
            // build model matrix for cow
            let rotation: matrix_float4x4 = MatrixUtilities.matrix_rotation(Y, angle: -cow.heading);
            let translation: matrix_float4x4 = MatrixUtilities.matrix_translation(cow.position);
            
            // copy matrices into uniform buffers
            var uniforms: PerInstanceUniforms = PerInstanceUniforms()
            uniforms.modelMatrix = matrix_multiply(translation, rotation);
            uniforms.normalMatrix = MatrixUtilities.matrix_upper_left3x3(uniforms.modelMatrix!);
            
            memcpy(self.cowUniformBuffer!.contents() + sizeof(PerInstanceUniforms) * i, &uniforms, sizeof(PerInstanceUniforms));
        }
    }
    
    func updateSharedUniforms() {
        
        let viewMatrix: matrix_float4x4 = matrix_multiply(MatrixUtilities.matrix_rotation(Y, angle: self.cameraHeading),
            MatrixUtilities.matrix_translation(-self.cameraPosition))
        
        let aspect: Float = Float(self.layer!.drawableSize.width) / Float(self.layer!.drawableSize.height);
        let fov: Float = (aspect > 1) ? (Float(M_PI) / 4) : (Float(M_PI) / 3)
        let projectionMatrix: matrix_float4x4 = MatrixUtilities.matrix_perspective_projection(aspect, fovy: fov, near: 0.1, far: 100);
        
        var uniforms: Uniforms = Uniforms()
        
        uniforms.viewProjectionMatrix = matrix_multiply(projectionMatrix, viewMatrix);
        memcpy(self.sharedUniformBuffer!.contents(), &uniforms, sizeof(Uniforms));
    }
    
    func updateUniforms() {
        
        self.updateTerrain()
        self.updateCows()
        self.updateCamera()
        self.updateSharedUniforms()
        
    }
    
    func createRenderPassWithColorAttachmentTexture(texture: MTLTexture) -> MTLRenderPassDescriptor {
    
        let renderPass: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        
        renderPass.colorAttachments[0].texture = texture
        renderPass.colorAttachments[0].loadAction = MTLLoadAction.Clear
        renderPass.colorAttachments[0].storeAction = MTLStoreAction.Store
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.5, 0.95, 1.0)
        
        renderPass.depthAttachment.texture = self.depthTexture
        renderPass.depthAttachment.loadAction = MTLLoadAction.Clear
        renderPass.depthAttachment.storeAction = MTLStoreAction.Store
        renderPass.depthAttachment.clearDepth = 1.0
        
        return renderPass
    }
    
    func drawTerrainWithCommandEncoder(commandEncoder: MTLRenderCommandEncoder) {
        
        commandEncoder.setVertexBuffer(self.terrainMesh!.vertexBuffer, offset:0, atIndex:0)
        commandEncoder.setVertexBuffer(self.sharedUniformBuffer, offset:0, atIndex:1)
        commandEncoder.setVertexBuffer(self.terrainUniformBuffer, offset:0, atIndex:2)

        commandEncoder.setFragmentTexture(self.terrainTexture, atIndex:0)
        commandEncoder.setFragmentSamplerState(self.sampler, atIndex:0)
        
        commandEncoder.drawIndexedPrimitives(MTLPrimitiveType.Triangle, indexCount:self.terrainMesh!.indexBuffer!.length / sizeof(IndexType), indexType:MTLIndexType.UInt16, indexBuffer:self.terrainMesh!.indexBuffer!, indexBufferOffset:0, instanceCount: self.cowCount)
    }
    
    func drawCowsWithCommandEncoder(commandEncoder: MTLRenderCommandEncoder) {
        commandEncoder.setVertexBuffer(self.cowMesh!.vertexBuffer, offset:0, atIndex:0)
        commandEncoder.setVertexBuffer(self.sharedUniformBuffer, offset:0, atIndex:1)
        commandEncoder.setVertexBuffer(self.cowUniformBuffer, offset:0, atIndex:2)
        commandEncoder.setFragmentTexture(self.cowTexture, atIndex:0)
        commandEncoder.setFragmentSamplerState(self.sampler, atIndex:0)
        
        commandEncoder.drawIndexedPrimitives(MTLPrimitiveType.Triangle,
            indexCount:self.cowMesh!.indexBuffer.length / sizeof(IndexType),
            indexType:MTLIndexType.UInt16,
            indexBuffer:self.cowMesh!.indexBuffer,
            indexBufferOffset:0,
            instanceCount:self.cowCount
        )
    }

    
    func draw() {
        self.updateUniforms()
        
        let drawable: CAMetalDrawable? = self.layer!.nextDrawable()
        
        if drawable != nil {
            if(CGFloat(self.depthTexture!.width) != self.layer!.drawableSize.width || CGFloat(self.depthTexture!.height) != self.layer!.drawableSize.height) {
                
                self.buildDepthTexture()
            }
        
        
            let renderPass: MTLRenderPassDescriptor = self.createRenderPassWithColorAttachmentTexture(drawable!.texture)
            
            let commandBuffer: MTLCommandBuffer = self.commandQueue!.commandBuffer()
            
            let commandEncoder: MTLRenderCommandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPass)
            commandEncoder.setRenderPipelineState(self.renderPipeline!)
            commandEncoder.setDepthStencilState(self.depthState)
            commandEncoder.setFrontFacingWinding(MTLWinding.CounterClockwise)
            commandEncoder.setCullMode(MTLCullMode.Back)
            
            self.drawTerrainWithCommandEncoder(commandEncoder)
            self.drawCowsWithCommandEncoder(commandEncoder)
            
            commandEncoder.endEncoding()
            
            commandBuffer.presentDrawable(drawable!)
            commandBuffer.commit()
            
            ++self.frameCount
        }
        
    }
    

}