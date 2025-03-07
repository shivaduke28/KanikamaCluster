﻿#ifndef KANIKAMA_CLUSTER_INCLUDED
#define KANIKAMA_CLUSTER_INCLUDED

#include <UnityCG.cginc>
#include <HLSLSupport.cginc>

UNITY_DECLARE_TEX2DARRAY(_Udon_LightmapArray);
static const int KANIKAMA_MAX_LIGHTMAP_COUNT = 64;
half3 _Udon_LightmapColors[KANIKAMA_MAX_LIGHTMAP_COUNT];
int _Udon_LightmapCount; // 0~16

// w=16, h=1
sampler2D _KanikamaClusterColorTex;

inline half3 KanikamaGISampleLightmapArray(float2 lightmapUV)
{
    half3 col = 0;
    float lightCountInv = 1.0 / 16;
    for (int i = 0; i < _Udon_LightmapCount; i++)
    {
        col += DecodeLightmap(UNITY_SAMPLE_TEX2DARRAY(
                _Udon_LightmapArray,
                float3(lightmapUV.x, lightmapUV.y, i))
        ) * tex2Dlod(_KanikamaClusterColorTex, float4((i * lightCountInv) + 0.5 * lightCountInv , 0.5, 0, 0)).rgb;
    }
    return col;
}

#if defined(_KANIKAMA_MODE_DIRECTIONAL)

UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_Udon_LightmapIndArray);

#if defined(_KANIKAMA_DIRECTIONAL_SPECULAR)
#include "UnityStandardBRDF.cginc"
#endif

inline void KanikamaSampleDirectional(float2 lightmapUV, half3 normalWorld, half3 viewDir, half roughness,
                                      out half3 diffuse, out half3 specular)
{
    diffuse = 0;
    specular = 0;
    for (int i = 0; i < _Udon_LightmapCount; i++)
    {
        half3 bakedColor = DecodeLightmap(
                UNITY_SAMPLE_TEX2DARRAY(_Udon_LightmapArray, float3(lightmapUV.x, lightmapUV.y, i)))
            * _Udon_LightmapColors[i];
        half4 bakedDirTex = UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Udon_LightmapIndArray, _Udon_LightmapArray,
                                                            float3(lightmapUV.x, lightmapUV.y, i));
        diffuse += DecodeDirectionalLightmap(bakedColor, bakedDirTex, normalWorld);

        half3 dominantDir = bakedDirTex.xyz - 0.5;
        half halfLambert = dot(normalWorld, dominantDir) + 0.5;
        half3 diff = bakedColor * halfLambert / max(1e-4h, bakedDirTex.w);
        diffuse += diff;

        // Directional lightmap specular based on BakeryDirectionalLightmapSpecular in Bakery.cginc by Mr F
        // https://geom.io/bakery/wiki/
#if defined(_KANIKAMA_DIRECTIONAL_SPECULAR)
        half3 halfDir = Unity_SafeNormalize(normalize(dominantDir) + viewDir);
        half nh = saturate(dot(normalWorld, halfDir));
        half spec = GGXTerm(nh, roughness);
        specular += spec * bakedColor;
#endif
    }
}

inline void KanikamaSampleDirectional(float2 lightmapUV, half3 normalWorld, inout half3 diffuse)
{
    diffuse = 0;
    for (int i = 0; i < _Udon_LightmapCount; i++)
    {
        half3 bakedColor = DecodeLightmap(
                UNITY_SAMPLE_TEX2DARRAY(_Udon_LightmapArray, float3(lightmapUV.x, lightmapUV.y, i)))
            * _Udon_LightmapColors[i];
        half4 bakedDirTex = UNITY_SAMPLE_TEX2DARRAY_SAMPLER(_Udon_LightmapIndArray, _Udon_LightmapArray,
                                                            float3(lightmapUV.x, lightmapUV.y, i));
        diffuse += DecodeDirectionalLightmap(bakedColor, bakedDirTex, normalWorld);

        half3 dominantDir = bakedDirTex.xyz - 0.5;
        half halfLambert = dot(normalWorld, dominantDir) + 0.5;
        half3 diff = bakedColor * halfLambert / max(1e-4h, bakedDirTex.w);
        diffuse += diff;
    }
}

#endif // _KANIKAMA_MODE_DIRECTIONAL

void KanikamaGI(float2 lightmapUV, half3 normalWorld, half occlusion, out half3 diffuse)
{
    #if defined(_KANIKAMA_MODE_DIRECTIONAL)
    KanikamaSampleDirectional(lightmapUV, normalWorld, diffuse);
    #else
    diffuse = KanikamaGISampleLightmapArray(lightmapUV);
    #endif
    diffuse *= occlusion;
} 

void KanikamaGI(float2 lightmapUV, half3 normalWorld, half3 viewDir, half roughness, half occlusion,
                    out half3 diffuse, out half3 specular)
{
    #if defined(_KANIKAMA_MODE_DIRECTIONAL)
    KanikamaSampleDirectional(lightmapUV, normalWorld, viewDir, roughness, diffuse, specular);
    #else
    diffuse = KanikamaGISampleLightmapArray(lightmapUV);
    specular = 0;
    #endif

    diffuse *= occlusion;
    specular *= occlusion;
}

#endif // KANIKAMA_CLUSTER_INCLUDED
