#include "Assets/Shaders/Includes/Noise.hlsl"
void ChooseColor_float(float3 Highlight, float3 Midtone, float3 Shadow, float Diffuse, float2 Thresholds, out float3 OUT)
{
    if (Diffuse < Thresholds.x)
    {
        OUT = Shadow;
    }
    else if (Diffuse < Thresholds.y)
    {
        OUT = Midtone;
    }
    else
    {
        OUT = Highlight;
    }
}

float NoiseFactory(float3 Pos, float Diffuse, float seed)
{
    float2 v2s = float2(321.41 * seed, 139.3*seed*sin(seed) + 13.1 * seed);
    float noise = GradientNoise(Pos.xy) + GradientNoise(Pos.zz);
    Diffuse += 0.1 *GradientNoise(float2(0.4,0.4) * Pos.xy + v2s) + 0.1 *GradientNoise(float2(0.4,0.4) * (Pos.xy + v2s + float2(0.2,0.0)));
    Diffuse = max(Diffuse, smoothstep(0.8, 0.9, noise));
    return Diffuse;
}

void ChooseColorComplex_float(float3 Highlight, float3 Midtone, float3 Shadow, float Diffuse, float2 Thresholds, float3 WorldPos, out float3 OUT)
{
    float DiffuseLow = NoiseFactory(WorldPos, Diffuse, 0.);
    float DiffuseHigh = NoiseFactory(WorldPos, Diffuse, 13.1);
    
    if (DiffuseLow < Thresholds.x)
    {
        OUT = Shadow * (1. - 0.07*smoothstep(0.85*Thresholds.x, Thresholds.x, DiffuseLow) * (smoothstep(0.7, 1.,GradientNoise(1.5*WorldPos.xy))));
    }
    else if (DiffuseHigh < Thresholds.y)
    {
        OUT = Midtone * (1. - 0.07*smoothstep(0.85*Thresholds.x, Thresholds.x, DiffuseHigh));;
    }
    else
    {
        OUT = Highlight;
    }
}