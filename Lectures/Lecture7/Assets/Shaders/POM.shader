// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "0_Custom/POM"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _HeightMap ("Height Map", 2D) = "white" {}
        _HeightMapScale ("Height", Float) = 1
        _StepNum ("Step Number", Float) = 10
    }
    SubShader
    {
        Tags {"LightMode"="ForwardBase"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc" // for _LightColor0


            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                half3 tspace0 : TEXCOORD1;
                half3 tspace1 : TEXCOORD2;
                half3 tspace2 : TEXCOORD3;
                float2 uv : TEXCOORD4;
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                half3 wNormal = UnityObjectToWorldNormal(v.normal);
                half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 wBitangent = cross(wNormal, wTangent) * tangentSign;

                o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
                o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
                o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);
                
                o.uv = v.uv;        
                return o;
            }

            sampler2D _MainTex;
            sampler2D _BumpMap;
            sampler2D _HeightMap;
            half _HeightMapScale;
            half _StepNum;

            float2 ParallaxMapping(float2 texCoord, float3 viewDir) 
            {
                 float layerDepth = 1.0/_StepNum;
                 float currentLayerDepth = 0.0;
                 float2 p = viewDir.xy/viewDir.z * _HeightMapScale; 
                 float2 deltaP = p / _StepNum;

                 float2 currentTC = texCoord;
                 float currentH = tex2D(_HeightMap, currentTC).r;
 
                 while (currentLayerDepth < currentH) {
                     currentTC += deltaP;
                     currentH = tex2D(_HeightMap, currentTC).r;
                     currentLayerDepth += layerDepth;
                 }

                 return currentTC;
            };

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDirection = normalize(i.worldPos - _WorldSpaceCameraPos);
                float3 viewDir;
                viewDir.x = dot(float3(i.tspace0.x, i.tspace1.x, i.tspace2.x), viewDirection);
                viewDir.y = dot(float3(i.tspace0.y, i.tspace1.y, i.tspace2.y), viewDirection);
                viewDir.z = dot(float3(i.tspace0.z, i.tspace1.z, i.tspace2.z), viewDirection);
                viewDir = normalize(viewDir);
                i.uv = ParallaxMapping(i.uv, viewDir); 


                half3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                half3 worldNormal;
                worldNormal.x = dot(i.tspace0, tnormal);
                worldNormal.y = dot(i.tspace1, tnormal);
                worldNormal.z = dot(i.tspace2, tnormal);

                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                half3 light = nl * _LightColor0;
                light += ShadeSH9(half4(worldNormal,1));

                fixed4 c = 0;
                fixed3 baseColor = tex2D(_MainTex, i.uv).rgb;
                c.rgb = baseColor * light; 
                return c;
            }
            ENDCG
        }
    }
}
