This project demonstrates the `metal-source: error: unsupported binary format` error when trying to use `metal-source` on a harvested GPU archive.

# Background

The WWDC 2022 session [Target and optimize GPU binaries with Metal 3](https://developer.apple.com/videos/play/wwdc2022/10102/) suggests the `metal-source` tool can generate the JSON Pipeline Scripts.

Using the session's ([5:55](https://developer.apple.com/videos/play/wwdc2022/10102/?time=355)) command line directions:

```sh
> metal-source -flatbuffers=json harvested-binaryArchive.metallib -o /tmp/descriptors.mtlp-json
```

# Reproduction Overview

Running this project...

1. Displays XCode environment and version information
    ```sh
    # Runs the following shell commands
    xcrun --show-sdk-path
    xcrun xcodebuild -version
    ```
2. Create a simple render pipeline
    ```swift
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
    ```
3. Harvest GPU Archive
    ```swift
    let archivePath = NSTemporaryDirectory().appending("harvested-archive.metallib")
    let archiveDesc = MTLBinaryArchiveDescriptor()
    let archive = try device.makeBinaryArchive(descriptor: archiveDesc)
    try archive.addRenderPipelineFunctions(descriptor: pipelineDesc)
    try archive.serialize(to: NSURL.fileURL(withPath: archivePath))
    print("Created archive: \(archivePath)")
    ```
4. Verify/Display Information about GPU Archive
    ```sh
    # Runs the following shell command
    xcrun metal-readobj harvested-archive.metallib
    ```
5. Create Thin GPU Archive
    ```sh
    # Runs the following shell command
    xcrun air-lipo -thin applegpu_g13s harvested-archive.metallib -o thin-archive.metallib
    ```
6. Verify/Display Information about Thin GPU Archive
    ```sh
    # Runs the following shell command
    xcrun metal-readobj thin-archive.metallib
    ```
7. Use `metal-source` to get pipeline descriptor
    ```sh
    # Runs the following shell command
    xcrun metal-source -flatbuffers=json thin-archive.metallib -o descriptors.json
    ```

# Example output showing error

## Environment

- MacBook Pro 2021 M1 Max
- macOS Version 13.0 Beta 22A5266r
- Xcode Version 14.0 beta 14A5228

```

-----------
Environment
-----------


Command: xcrun --show-sdk-path
Result: /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk


Command: xcrun xcodebuild -version
Result: Xcode 14.0
Build version 14A5229c


------------------------
Creating Render Pipeline
------------------------

2022-06-23 12:36:40.169296-0500 x-metal-source-on-harvested-gpu-archive[10087:136743] Metal GPU Frame Capture Enabled
2022-06-23 12:36:40.169659-0500 x-metal-source-on-harvested-gpu-archive[10087:136743] Metal API Validation Enabled

----------------------
Harvesting GPU Archive
----------------------

Created archive: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/harvested-archive.metallib

--------------------------------------------
Verify/Display Information about GPU Archive
--------------------------------------------


Command: xcrun metal-readobj /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/harvested-archive.metallib
Result: 2022-06-23 12:36:40.230827-0500 xcrun[10092:137207] Failed to open macho file at /Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal-readobj for reading: Too many levels of symbolic links

File: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/harvested-archive.metallib
Format: MetalLib
Arch: air64
AddressSize: 64bit

File: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/harvested-archive.metallib
Format: Mach-O 64-bit Apple GPU
Arch: agx2
AddressSize: 64bit


-----------------------
Create Thin GPU Archive
-----------------------


Command: xcrun air-lipo -thin applegpu_g13s /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/harvested-archive.metallib -o /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/thin-archive.metallib
Result:

-------------------------------------------------
Verify/Display Information about Thin GPU Archive
-------------------------------------------------


Command: xcrun metal-readobj /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/thin-archive.metallib
Result: 2022-06-23 12:36:40.249596-0500 xcrun[10094:137217] Failed to open macho file at /Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal-readobj for reading: Too many levels of symbolic links

File: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/thin-archive.metallib
Format: Mach-O 64-bit Apple GPU
Arch: agx2
AddressSize: 64bit


---------------------------------------------
Using metal-source to get pipeline descriptor
---------------------------------------------


Command: xcrun metal-source -flatbuffers=json /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/thin-archive.metallib -o /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.json
Result:
Program ended with exit code: 0
```

