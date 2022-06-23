import Foundation
import Metal
import MetalKit

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
    print("Result: \(result)");
}

print("""

-----------
Environment
-----------

""")
try shell("xcrun --show-sdk-path")
try shell("xcrun xcodebuild -version")


print("""

------------------------
Creating Render Pipeline
------------------------

""")
let device = MTLCreateSystemDefaultDevice()!
let commandQueue = device.makeCommandQueue()!
let lib = try device.makeLibrary(
    source: """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOut {
        float4 position  [[position]];
        float point_size [[point_size]];
    };


    [[vertex]]
    VertexOut main_vertex() {
        return {
            .position = float4(0),
            .point_size = 128.0
        };
    }

    [[fragment]]
    half4 main_fragment() {
        return half4(1);
    }
    """,
    options: nil
)
let pipelineDesc = MTLRenderPipelineDescriptor()
pipelineDesc.vertexFunction = lib.makeFunction(name: "main_vertex")
pipelineDesc.fragmentFunction = lib.makeFunction(name: "main_fragment")
pipelineDesc.colorAttachments[0]?.pixelFormat = .bgra8Unorm

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
let descriptorsPath = NSTemporaryDirectory().appending("descriptors.json")
try shell("xcrun metal-source -flatbuffers=json \(archivePath) -o \(descriptorsPath)")

