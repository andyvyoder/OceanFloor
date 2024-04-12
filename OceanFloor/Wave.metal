
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

constexpr sampler textureSampler(coord::normalized, address::repeat, filter::linear);


[[visible]]
void waveSurfaceShader(realitykit::surface_parameters params)
{
    float waveRed = params.uniforms().custom_parameter()[0];
    float waveGreen = params.uniforms().custom_parameter()[1];
    float waveBlue = params.uniforms().custom_parameter()[2];
    
    half3 customColor = half3(waveRed, waveGreen, waveBlue);
    
    metal::texture2d<half> texture = params.textures().custom();
    
    // use the x/z world position as the u/v indices for the texture to get a consistent
    // texture mapping across the multiple meshes
    float x = params.geometry().world_position()[0];
    float z = params.geometry().world_position()[2];
    
    const float textureScaleFactor = 0.5;
    float u = x * textureScaleFactor;
    float v = z * textureScaleFactor;
    
    float2 uv = float2(u,v);
    half4 textureColor = texture.sample(textureSampler, uv);
    half3 textureRgb = half3(textureColor[0], textureColor[1], textureColor[2]);
    
    // Blend the texture color with the custom color
    float blendFactor = 0.5;
    half3 blendedColor = mix(customColor, textureRgb, blendFactor);
    
    
    params.surface().set_base_color(blendedColor);
}

