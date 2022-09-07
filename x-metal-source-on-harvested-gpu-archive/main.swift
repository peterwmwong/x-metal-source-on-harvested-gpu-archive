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
    print("Command stdout/stderr:\n\(result)");
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
/* See shaders.metal */
let lib = device.makeDefaultLibrary()!
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
let descriptorsPath = NSTemporaryDirectory().appending("descriptors.mtlp-json")

try shell("rm -rf \(descriptorsPath) # Remove any existing")
try shell("xcrun metal-source -flatbuffers=json \(archivePath) -o \(descriptorsPath)")

print("""

-------------------------------------------------
Display descriptor... directory? not a JSON file?
-------------------------------------------------
""")
try shell("find \(descriptorsPath)")
