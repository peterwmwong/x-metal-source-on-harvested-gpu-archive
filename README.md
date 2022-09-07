This project attempts to extract a pipeline script using `metal-source` on a harvested GPU archive.

# Background

The WWDC 2022 session [Target and optimize GPU binaries with Metal 3](https://developer.apple.com/videos/play/wwdc2022/10102/) suggests the `metal-source` tool can generate the JSON Pipeline Scripts.

Using the session's ([5:55](https://developer.apple.com/videos/play/wwdc2022/10102/?time=355)) command line directions:

```sh
> metal-source -flatbuffers=json harvested-archive.metallib -o /tmp/descriptors.mtlp-json
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
    /* See shaders.metal */
    let lib = device.makeDefaultLibrary()!
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
5. Use `metal-source` to get pipeline descriptor
    ```sh
    # Runs the following shell command
    xcrun metal-source -flatbuffers=json harvested-archive.metallib -o descriptors.mtlp-json
    ```

# Output showing no mtlp-json file is produced... but a directory instead

```
-----------
Environment
-----------

Command: xcrun --show-sdk-path
Command stdout/stderr:
/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk


Command: xcrun xcodebuild -version
Command stdout/stderr:
Xcode 14.0
Build version 14A309


------------------------
Creating Render Pipeline
------------------------
2022-09-07 16:32:24.656426-0500 x-metal-source-on-harvested-gpu-archive[6209:81985] Metal GPU Frame Capture Enabled
2022-09-07 16:32:24.656910-0500 x-metal-source-on-harvested-gpu-archive[6209:81985] Metal API Validation Enabled

----------------------
Harvesting GPU Archive
----------------------

Created archive: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/harvested-archive.metallib

--------------------------------------------
Verify/Display Information about GPU Archive
--------------------------------------------

Command: xcrun metal-readobj /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/harvested-archive.metallib
Command stdout/stderr:
2022-09-07 16:32:24.712815-0500 xcrun[6220:82490] Failed to open macho file at /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal-readobj for reading: Too many levels of symbolic links

File: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/harvested-archive.metallib
Format: MetalLib
Arch: air64
AddressSize: 64bit

File: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/harvested-archive.metallib
Format: Mach-O 64-bit Apple GPU
Arch: agx2
AddressSize: 64bit


---------------------------------------------
Using metal-source to get pipeline descriptor
---------------------------------------------

Command: rm -rf /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.mtlp-json # Remove any existing
Command stdout/stderr:


Command: xcrun metal-source -flatbuffers=json /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/harvested-archive.metallib -o /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.mtlp-json
Command stdout/stderr:


-------------------------------------------------
Display descriptor... directory? not a JSON file?
-------------------------------------------------

Command: find /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.mtlp-json
Command stdout/stderr:
/var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.mtlp-json
/var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.mtlp-json/applegpu_g13s
/var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.mtlp-json/applegpu_g13s/metallib
/var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.mtlp-json/applegpu_g13s/metallib/59738F01-C715-324F-A6B3-D5C7D147B5E9.metallib
/var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.mtlp-json/applegpu_g13s/object
/var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.mtlp-json/applegpu_g13s/object/1-0.metallib
/var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/descriptors.mtlp-json/applegpu_g13s/object/0-0.metallib
```

## Environment

- MacBook Pro 2021 M1 Max
- macOS Version 13.0 Beta 6 22A5331f
- Xcode Version 14.0 RC 14A309
