Shader "0_Custom/MonteCarlo"
{   
    
    Properties
    {
        _BaseColor ("Color", Color) = (0, 0, 0, 1)
        _AmbientColor ("Ambient Color", Color) = (0, 0, 0, 1)
        _Shininess ("Shininess", Float) = 1
        _Cubemap ("Cubemap", CUBE) = "" {} 
        _DiffusePower ("DiffusePower", Float) = 1
        _SpecularPower ("SpecularPower", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
            
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
           
            static const float pi = 3.141592653589793238462;
            struct appdata
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float4 clip : SV_POSITION;
                float4 pos : TEXCOORD1;
                fixed3 normal : NORMAL;
            };

            float4 _AmbientColor;
            float4 _BaseColor;
            float _Shininess;
            samplerCUBE _Cubemap;
            float _DiffusePower;
            float _SpecularPower;

            float rand(uint n) {
                n ^= 2747636419u;
                n *= 2654435769u;
                n ^= n>>16;
                n *= 2654435769u;
                n ^= n>>16;
                n *= 2654435769u;
                return float(n)/4294967295.0;
            }

            float f(float3 w, v2f i) {
                float3 normal = normalize(i.normal);
               
                //if (_DiffusePower > 0) {
                    float3 lightDir = normalize(w);
                    float NdotL = dot( normal, lightDir );
                    float intensity = saturate( NdotL );

                    float diffuse = intensity * _DiffusePower;
                    float3 viewDirection = normalize(_WorldSpaceCameraPos - i.pos.xyz);
                
                    float3 H = normalize(lightDir + viewDirection);

                    float NdotH = dot( normal, H );
                    intensity = pow(saturate(NdotH), _Shininess);
                    float specular = intensity * _SpecularPower;
                    return diffuse + specular;  
                //}
                //return 1;
           }

            v2f vert (appdata v)
            {
                v2f o;
                o.clip = UnityObjectToClipPos(v.vertex);
                o.pos = mul(UNITY_MATRIX_M, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float3 getColor(float3 w, fixed3 normal) {
               // float3 w_prime = reflect(w, normal);
                return texCUBE(_Cubemap, w).rgb;
            }

            float3 getRandomDir(fixed3 normal, int i, v2f ii) {
                 float z = rand(float(2*i));
                 float phi = rand(float(2*i+1))*2*pi;
                 
                 float3 bs1 = normalize(cross(normal, float3(rand(i*3), rand(i*3 + 1), rand(i*3 + 2))));
                 float3 bs2 = normalize(cross(bs1, normal));
                 //Debug.Log("z" + str(z) + " phi:" + str(phi));
                 return z*normal + sqrt(1.0f - z*z) * (cos(phi) * bs1 + sin(phi) * bs2);
            }

            float normalf(v2f i) {
                int n = 50000;
                float3 normal = normalize(i.normal);
                float FVal = 0;
                for (int j = 0; j < n; ++j) {
                    float3 w = normalize(getRandomDir(normal, j, i));
                    FVal += f(w, i); 
                }
                return FVal/n;
            }

            fixed4 frag (v2f i) : SV_Target {
                int n = 10000;
                float3 normal = normalize(i.normal);
                //float3 w = getRandomDir(normal, 0, i);
                //return float4(getColor(w)*f(w, i), 1.0);
                float3 color = float3(0.0, 0.0, 0.0);
                float Fnormal = 0;//normalf(i);
                for (int j = 0; j < n; ++j) {
                    float3 w = normalize(getRandomDir(normal, j/* + i.pos.x + i.pos.y*/, i));
                    float curf = f(w, i);
                    Fnormal += curf; 
                    color += curf * getColor(w, normal);
                }
                return float4(color/Fnormal, 1.0);    
            }
            ENDCG
        }
    }
}
