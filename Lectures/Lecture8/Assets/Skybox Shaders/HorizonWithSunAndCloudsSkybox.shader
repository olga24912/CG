﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Skybox/HorizonWithSunAndCloudsSkybox"
{
    Properties
    {
        _SkyColor1("Top Color", Color) = (0.37, 0.52, 0.73, 0)
        _SkyExponent1("Top Exponent", Float) = 8.5
        _SkyColor2("Horizon Color", Color) = (0.89, 0.96, 1, 0)
        _SkyColor3("Bottom Color", Color) = (0.89, 0.89, 0.89, 0)
        _SkyExponent2("Bottom Exponent", Float) = 3.0
        _SkyIntensity("Sky Intensity", Float) = 1.0
        _SunColor("Sun Color", Color) = (1, 0.99, 0.87, 1)
        _SunIntensity("Sun Intensity", float) = 2.0
        _SunAlpha("Sun Alpha", float) = 550
        _SunBeta("Sun Beta", float) = 1
        _SunVector("Sun Vector", Vector) = (0.269, 0.615, 0.740, 0)
        _SunAzimuth("Sun Azimuth (editor only)", float) = 20
        _SunAltitude("Sun Altitude (editor only)", float) = 38

        _NoiseTex("NoiseVolume", 3D) = "white" {}
        _Weather("Weather", 2D) = "white" {}
        _SampleCount("Sample Count", int) = 128 //64 - 128 depends on angle
        _FarDist("Far Dist", float) = 30000
        _Coverage("Coverage", float) = 0.5
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    struct appdata
    {
        float4 position : POSITION;
        float3 texcoord : TEXCOORD0;
    };
    
    struct v2f
    {
        float4 position : SV_POSITION;
        float3 texcoord : TEXCOORD0;
        float3 rayDir : TEXCOORD1;
    };
    
    half3 _SkyColor1;
    half _SkyExponent1;
    half3 _SkyColor2;
    half3 _SkyColor3;
    half _SkyExponent2;
    half _SkyIntensity;
    half3 _SunColor;
    half _SunIntensity;
    half _SunAlpha;
    half _SunBeta;
    half3 _SunVector;
    


    sampler3D _NoiseTex;
    sampler2D _Weather;
    int _SampleCount;
    float _FarDist;
    float _Coverage;

    v2f vert(appdata v)
    {
        v2f o;
        o.position = UnityObjectToClipPos(v.position);
        o.texcoord = v.texcoord;
        return o;
    }

    float getHighDetailNoise(float3 pos) {
        const float scale = 3*1e-5;
        const float wscale = 1e-6;

        float4 uvw = float4(pos * scale, 0);
        float cloudSample = tex3Dlod(_NoiseTex, uvw).b; 
        float weather = tex2Dlod(_Weather, float4(pos.x * wscale, pos.z * wscale, 0, 0)).r;
        if (cloudSample * weather * _Coverage < 0.05) {
            return 0; 
        }
        return cloudSample * _Coverage * weather;
    }

    float BeerPowder(float depth) {
        const float coeff = 0.005;
        return exp(-coeff * depth) * (1 - exp(-coeff * 2 * depth));
    }
   

    float sampleConeToLight(float3 pos) {
        const int sampleCount = 6;
        float3 lightPos = normalize(_WorldSpaceLightPos0.xyz);
        float step = (float(4000) - pos.y) / (lightPos.y * sampleCount);
        float depth = 0;
        float3 curpos = pos + lightPos * step;
        for (int s = 0; s < sampleCount; ++s) {
            depth += getHighDetailNoise(curpos) * step;
            pos += lightPos * step;
        }

        return BeerPowder(depth);
    }
    
    float HenyeyGreenstein(float cosine) {
        const float hgcoeff = 0.5;
        return 0.5 * (1 - hgcoeff * hgcoeff)/pow(1 + hgcoeff * hgcoeff - 2 * hgcoeff * cosine, 1.5);
    }
                        
    half4 frag(v2f i) : COLOR
    {
        float3 v = normalize(i.texcoord);
        float p = v.y;
        float p1 = 1 - pow(min(1, 1 - p), _SkyExponent1);
        float p3 = 1 - pow(min(1, 1 + p), _SkyExponent2);
        float p2 = 1 - p1 - p3;                                            
        half3 c_sky = _SkyColor1 * p1 + _SkyColor2 * p2 + _SkyColor3 * p3;
        half3 c_sun = _SunColor * min(pow(max(0, dot(v, _SunVector)), _SunAlpha) * _SunBeta, 1);
        half3 skyLight = c_sky * _SkyIntensity + c_sun * _SunIntensity;


        int samples = _SampleCount;
        float3 rayDir = normalize(i.texcoord);
        float dist0 = float(1500)/rayDir.y;
        float dist1 = float(4000)/rayDir.y;
        
        if (rayDir.y < 0.00001) {
            return half4(skyLight, 0);
        }
        
        float step = (dist1 - dist0)/samples;
        float scatter = 0.01; 
        float3 pos = _WorldSpaceCameraPos + rayDir*dist0;
        float3 cloudLight = 0;
        float alpha = 0;
        float depth = 0;
        float hg = HenyeyGreenstein(dot(rayDir, _WorldSpaceLightPos0.xyz));
        for (int s = 0; s < samples; ++s) {
             float noise = getHighDetailNoise(pos);
             //return half4(noise, noise, noise, 0);
             float density = noise * step; 
           
             if (density > 0.0000001) {
                 alpha += (1.0 - alpha) * noise; 
             }

             if (alpha >= 0.99) {
                 break;
             }
             cloudLight += half3(1, 1, 1) * density * scatter * BeerPowder(depth) * hg * sampleConeToLight(pos);
             pos += rayDir * step;
             depth += density;
        }
      
        half3 res = cloudLight * alpha + (1 - alpha) * skyLight;
        return  half4(res, 0);
    }
                                                            
    ENDCG

    SubShader
    {
        Tags { "RenderType"="Background" "Queue"="Background" }
        Pass
        {
            ZWrite Off
            Cull Off
            Fog { Mode Off }
            CGPROGRAM
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }                                                    
}
