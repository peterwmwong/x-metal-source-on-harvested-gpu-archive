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
