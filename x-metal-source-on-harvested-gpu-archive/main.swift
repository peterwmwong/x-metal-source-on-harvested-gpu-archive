import Foundation
import Metal
import MetalKit

let IS_GENERATING_PIPELINE_SCRIPT = false

func shell(_ command: String) throws {
    let task = Process()
    let pipe = Pipe()
    
    print("\nCommand: \(command)");
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.standardInput = nil
    try task.run()
    let result = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
    print("Command stdout/stderr:\n\(result)");
}

if IS_GENERATING_PIPELINE_SCRIPT {
    print("""

-----------
Environment
-----------
""")
    try shell("xcrun --show-sdk-path")
    try shell("xcrun xcodebuild -version")
}


print("""

------------------------
Creating Render Pipeline
------------------------
""")
let device = MTLCreateSystemDefaultDevice()!
/* See shaders.metal */
var lib;
if IS_GENERATING_PIPELINE_SCRIPT {
    lib = device.makeDefaultLibrary()!
} else {
    lib = try! device.makeLibrary(URL: URL(filePath: "/Users/pwong/projects/x-metal-source-on-harvested-gpu-archive/x-metal-source-on-harvested-gpu-archive/shaders-applegpu_13g.metallib"))
}
let pipelineDesc = MTLRenderPipelineDescriptor()
if !IS_GENERATING_PIPELINE_SCRIPT {
    let desc = MTLBinaryArchiveDescriptor()
    desc.url = URL(filePath: "/Users/pwong/projects/x-metal-source-on-harvested-gpu-archive/x-metal-source-on-harvested-gpu-archive/shaders-applegpu_13g.metallib")
    let bin = try! device.makeBinaryArchive(descriptor: desc)
    pipelineDesc.binaryArchives = [bin]
}
pipelineDesc.vertexFunction = lib.makeFunction(name: "main_vertex")
pipelineDesc.fragmentFunction = lib.makeFunction(name: "main_fragment")
pipelineDesc.colorAttachments[0]?.pixelFormat = .rgba8Unorm


if !IS_GENERATING_PIPELINE_SCRIPT {
    let WIDTH = 4
    let HEIGHT = 4
    
    // let pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDesc, options: .failOnBinaryArchiveMiss).0
    let pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
    
    let textureBuf = device.makeBuffer(length: 4 /* 4-bytes (rgba) */ * WIDTH * HEIGHT)!
    let textureDesc = MTLTextureDescriptor()
    textureDesc.storageMode = .shared
    textureDesc.depth = 1
    textureDesc.pixelFormat = .rgba8Unorm
    textureDesc.usage = .renderTarget
    textureDesc.width = WIDTH
    textureDesc.height = HEIGHT
    let output = textureBuf.makeTexture(descriptor: textureDesc, offset: 0, bytesPerRow: 4 * WIDTH)
    
    let queue = device.makeCommandQueue()!
    let command = queue.makeCommandBuffer()!
    
    let renderDesc = MTLRenderPassDescriptor()
    let color = renderDesc.colorAttachments[0]!
    color.texture = output
    color.loadAction = .clear
    color.storeAction = .store
    color.clearColor = MTLClearColorMake(0, 0, 0, 0)
    
    let r = command.makeRenderCommandEncoder(descriptor: renderDesc)!
    r.setRenderPipelineState(pipeline)
    r.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1)
    r.endEncoding()
    
    command.commit()
    command.waitUntilCompleted()
    
    let outputPixels = Array(textureBuf.contents().withMemoryRebound(to: (UInt8, UInt8, UInt8, UInt8).self, capacity: WIDTH * HEIGHT) {
        UnsafeBufferPointer(start: $0, count: WIDTH * HEIGHT)
    })
    
    func printOutputPixels(_ arr: Array<(UInt8, UInt8, UInt8, UInt8)>) {
        for y in 0..<HEIGHT {
            var r: [UInt8] = []
            for x in 0..<WIDTH {
                r.append(arr[y * WIDTH + x].1)
            }
            print(r)
        }
        
    }
    printOutputPixels(outputPixels)
}

if IS_GENERATING_PIPELINE_SCRIPT {
    print("""

----------------------
Harvesting GPU Archive
----------------------

""")
    let archivePath = NSTemporaryDirectory().appending("harvested-archive.metallib")
    let archiveDesc = MTLBinaryArchiveDescriptor()
    let archive = try device.makeBinaryArchive(descriptor: archiveDesc)
    try archive.addRenderPipelineFunctions(descriptor: pipelineDesc)
    try archive.serialize(to: NSURL.fileURL(withPath: archivePath))
    print("Created archive: \(archivePath)")
    
    print("""

--------------------------------------------
Verify/Display Information about GPU Archive
--------------------------------------------
""")
    
    try shell("xcrun metal-readobj \(archivePath)")
    
    print("""

---------------------------------------------
Using metal-source to get pipeline descriptor
---------------------------------------------
""")
    let descriptorsPath = NSTemporaryDirectory().appending("descriptors.mtlp-json")
    
    try shell("rm -rf \(descriptorsPath) # Remove any existing")
    try shell("xcrun metal-source -flatbuffers=json \(archivePath) -o \(descriptorsPath)")
    
    print("""

-------------------------------------------------
Display descriptor... directory? not a JSON file?
-------------------------------------------------
""")
    try shell("find \(descriptorsPath)")
}
