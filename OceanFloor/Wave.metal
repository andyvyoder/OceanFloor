
#include <metal_stdlib>
#include <RealityKit/RealityKit.h>

using namespace metal;

[[visible]]
void waveGeometryModifier(realitykit::geometry_parameters params)
{
    // to control wave height extremes
    const float minAmplitude = 0.0;
    const float maxAmplitude = 0.75;

    // to control wave length and frequency
    const float waveLengthScale = 0.5;
    const float timeScale = 1.0;

    // wave height scale, a value between 0 and 1
    float waveHeightScale = params.uniforms().custom_parameter()[3];

    float targetAmplitude = mix(minAmplitude, maxAmplitude, waveHeightScale);

    float3 worldPos = params.geometry().world_position();
    float time = params.uniforms().time();
    
    
    float amplitude = targetAmplitude * sin((worldPos.x + (timeScale * time))/waveLengthScale);

    // Only offset verticly
    float3 offset = float3(0.0, amplitude, 0.0);

    params.geometry().set_model_position_offset(offset);
}


[[visible]]
void waveSurfaceShader(realitykit::surface_parameters params)
{
    float waveRed = params.uniforms().custom_parameter()[0];
    float waveGreen = params.uniforms().custom_parameter()[1];
    float waveBlue = params.uniforms().custom_parameter()[2];
    
    float3 customColor = float3(waveRed, waveGreen, waveBlue);
    
    params.surface().set_base_color(half3(customColor));
}

