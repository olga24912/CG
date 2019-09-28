Shader "Custom/BrokenShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _XTex ("Albedo (RGB)", 2D) = "white" {}
        _ZTex("Albedo (RGB)", 2D) = "black" {}
        _YTex("Albedo (RGB)", 2D) = "red" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Pass
        {
            // indicate that our pass is the "base" pass in forward
            // rendering pipeline. It gets ambient and main directional
            // light data set up; light direction in _WorldSpaceLightPos0
            // and color in _LightColor0
            Tags {"LightMode"="ForwardBase"}
        
            CGPROGRAM
            #pragma enable_d3d11_debug_symbols
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc" // for UnityObjectToWorldNormal
            #include "UnityLightingCommon.cginc" // for _LightColor0

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 normal : NORMAL;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }
            
            sampler2D _XTex;
            sampler2D _YTex;
            sampler2D _ZTex;

            fixed4 frag (v2f i) : SV_Target
            {
                half nl = max(0, dot(i.normal, _WorldSpaceLightPos0.xyz));
                half3 light = nl * _LightColor0;
                light += ShadeSH9(half4(i.normal,1));

                float2 xUV = i.worldPos.zy;
                float2 yUV = i.worldPos.xz;
                float2 zUV = i.worldPos.xy;
 
                fixed4 colX = tex2D(_XTex, xUV), colY = tex2D(_YTex, yUV), colZ = tex2D(_ZTex, zUV);

                //float3 blendWeight = abs(i.normal);
                //blendWeight = blendWeight / (blendWeight.x + blendWeight.y + blendWeight.z);
                
                float3 blendWeight = 0;
                float2 xzBlend = abs(normalize(i.normal.xz));
                blendWeight.xz = max(0, xzBlend - 0.67);
                blendWeight.xz /= dot(blendWeight.xz, float2(1, 1));

                blendWeight.y = saturate((abs(i.normal.y) - 0.675) * 80.0);
                blendWeight.xz *= (1 - blendWeight.y); 
                               
                fixed4 col = colX * blendWeight.x + colY * blendWeight.y + colZ * blendWeight.z;
                col.rgb *= light;
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
