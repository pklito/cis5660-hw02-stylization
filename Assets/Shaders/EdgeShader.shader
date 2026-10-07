Shader "Hidden/Edge Detection"
{
    Properties
    {
        _OutlineThickness ("Outline Thickness", Float) = 1
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
        }

        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass 
        {
            Name "EDGE DETECTION OUTLINE"
            
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" // needed to sample scene depth
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl" // needed to sample scene normals
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl" // needed to sample scene color/luminance

            CBUFFER_START(UnityPerMaterial)
                float _OutlineThickness;
                float4 _OutlineColor;
            CBUFFER_END

            #pragma vertex Vert // vertex shader is provided by the Blit.hlsl include
            #pragma fragment frag

            // Sobel edge detection kernel for vector samples.
            // Samples are laid out row by row (top row first):
            //   0 1 2
            //   3 4 5
            //   6 7 8
            float Sobel(float3 s[9])
            {
                // Horizontal gradient: kernel [-1 0 1; -2 0 2; -1 0 1]
                const float3 gx = (s[2] + 2.0 * s[5] + s[8]) - (s[0] + 2.0 * s[3] + s[6]);
                // Vertical gradient: kernel [-1 -2 -1; 0 0 0; 1 2 1]
                const float3 gy = (s[0] + 2.0 * s[1] + s[2]) - (s[6] + 2.0 * s[7] + s[8]);
                return sqrt(dot(gx, gx) + dot(gy, gy));
            }

            // The same kernel logic as above, but for a single-value instead of a vector3.
            float Sobel(float s[9])
            {
                const float gx = (s[2] + 2.0 * s[5] + s[8]) - (s[0] + 2.0 * s[3] + s[6]);
                const float gy = (s[0] + 2.0 * s[1] + s[2]) - (s[6] + 2.0 * s[7] + s[8]);
                return sqrt(gx * gx + gy * gy);
            }
            
            // Helper function to sample scene normals remapped from [-1, 1] range to [0, 1].
            float3 SampleSceneNormalsRemapped(float2 uv)
            {
                return SampleSceneNormals(uv) * 0.5 + 0.5;
            }

            // Helper function to sample scene luminance.
            float SampleSceneLuminance(float2 uv)
            {
                float3 color = SampleSceneColor(uv);
                return color.r * 0.3 + color.g * 0.59 + color.b * 0.11;
            }

            half4 frag(Varyings IN) : SV_TARGET
            {
                // Screen-space coordinates which we will use to sample.
                float2 uv = IN.texcoord;
                float2 texel_size = float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
                float2 offset = texel_size * _OutlineThickness;

                // Generate the 3x3 neighborhood of samples, row by row (top row first).
                float2 uvs[9];
                for (int y = 0; y < 3; y++)
                {
                    for (int x = 0; x < 3; x++)
                    {
                        uvs[y * 3 + x] = uv + offset * float2(x - 1, 1 - y);
                    }
                }
                
                float3 normal_samples[9];
                float depth_samples[9], luminance_samples[9];
                
                for (int i = 0; i < 9; i++) {
                    depth_samples[i] = SampleSceneDepth(uvs[i]);
                    normal_samples[i] = SampleSceneNormalsRemapped(uvs[i]);
                    luminance_samples[i] = SampleSceneLuminance(uvs[i]);
                }
                
                // Apply edge detection kernel on the samples to compute edges.
                float edge_depth = Sobel(depth_samples);
                float edge_normal = Sobel(normal_samples);
                float edge_luminance = Sobel(luminance_samples);
                
                // Threshold the edges (discontinuity must be above certain threshold to be counted as an edge).
                // Sobel produces larger magnitudes than Roberts Cross, so these are starting guesses: tune by eye.
                float depth_threshold = 1 / 100.0f;
                edge_depth = edge_depth > depth_threshold ? 1 : 0;
                
                float normal_threshold = 1 / 2.0f;
                edge_normal = edge_normal > normal_threshold ? 1 : 0;
                
                float luminance_threshold = 1 / 0.5f;
                edge_luminance = edge_luminance > luminance_threshold ? 1 : 0;
                
                // Combine the edges from depth/normals/luminance using the max operator.
                // Note: luminance is still not included here, same as the original shader.
                float edge = max(edge_depth, edge_normal);
                
                // Color the edge with a custom color.
                return edge * _OutlineColor;
            }
            ENDHLSL
        }
    }
}
