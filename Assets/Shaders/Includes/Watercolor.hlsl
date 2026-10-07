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

void ChooseColorComplex_float(float3 Highlight, float3 Midtone, float3 Shadow, float Diffuse, float2 Thresholds, float3 WorldPos, out float3 OUT)
{
    float noise = GradientNoise(WorldPos.xy) + GradientNoise(WorldPos.zz);
    Diffuse += 0.1 *GradientNoise(float2(0.4,0.4) * WorldPos.xy) + 0.1 *GradientNoise(float2(0.4,0.4) * (WorldPos.xy + float2(0.2,0.0)));;
    Diffuse = max(Diffuse, smoothstep(0.8,0.9,noise));
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