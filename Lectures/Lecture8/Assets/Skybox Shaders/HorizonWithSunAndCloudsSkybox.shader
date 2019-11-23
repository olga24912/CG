// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

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

        _SampleCount("Sample Count", int) = 64 //64 - 128 depends on angle
        _FarDist("Far Dist", float) = 30000
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

    int _SampleCount;
    float _FarDist;
    
    v2f vert(appdata v)
    {
        v2f o;
        o.position = UnityObjectToClipPos(v.position);
        o.texcoord = v.texcoord;
        return o;
    }

    float get_height_gradient(float y) {
         if (y <= 0.5 && y >= 0.25) {
             return 1;
         }
         return 0;
    }

    float get_density_reduce_coeff(float y) {
        return 1; 
    }

    float getHighDetailNoise(float3 pos) {
        return 1; 
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
        
        if (rayDir.y < 0.0001 || dist0 >= _FarDist) {
            return half4(skyLight, 0);
        }
        
        float step = (dist1 - dist0)/samples;
        float scatter = 0.008; 
        float3 pos = _WorldSpaceCameraPos + rayDir*dist0;
        float3 cloudLight = 0;
        float alpha = 0;
        for (int s = 0; s < samples; ++s) {
             float noise = getHighDetailNoise(pos);         
             if (noise > 0.0000001) {
                 float density = noise * step;
                 alpha += (1.0 - alpha) * density; 
             }

             if (alpha >= 0.99) {
                 break;
             }
             pos += rayDir * step;
        }

        half3 res = lerp(half3(1, 1, 1), skyLight, 1 - alpha);
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
    CustomEditor "HorizonWithSunSkyboxInspector"
}
