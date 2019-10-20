Shader "0_Custom/SH"
{
    Properties
    {
        _BaseColor ("Color", Color) = (0, 0, 0, 1)
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

            float4 _BaseColor;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.clip = UnityObjectToClipPos(v.vertex);
                o.pos = mul(UNITY_MATRIX_M, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }
            
            // (L=1; M=1), (L=1; M=0), (L=1; M=-1), (L=0, M=0)
            uniform half4 SH_0_1_r;
            uniform half4 SH_0_1_g;
            uniform half4 SH_0_1_b;
            
            // (L=2; M=-2), (L=2; M=-1), (L=2; M=1), (L=2, M=0)
            uniform half4 SH_2_r;
            uniform half4 SH_2_g;
            uniform half4 SH_2_b;
            
            // (L=2; M=2)
            uniform half4 SH_2_rgb;
            
            half pow2(half f)
            {
                return f * f;
            }
            
            float sqrt(float x) {
               return pow(x, 0.5);
            }

            float3 f(float4 direction) { 
                 float PI = 3.14159; 
                 float coeff1 = sqrt(3)/(2*sqrt(PI));
                 float coeff2 = sqrt(15)/(2*sqrt(PI));
                 float res[9] = {-coeff1 * direction.y, 
                   coeff1 * direction.z, 
                   -coeff1 * direction.x,  
                   1/(2*sqrt(PI)), 
                   coeff2*direction.y*direction.x, 
                   -coeff2*direction.y*direction.z, 
                   -coeff2*direction.x*direction.z, 
                   sqrt(5)*(3*direction.z*direction.z - 1)/(4*sqrt(PI)), 
                   sqrt(15)*(direction.x*direction.x - direction.y*direction.y)/(4*sqrt(PI))};
                  float3 res_color;
                  res_color.r = SH_0_1_r[0]*res[0] + SH_0_1_r[1]*res[1] + SH_0_1_r[2]*res[2] + SH_0_1_r[3]*res[3] +
                                SH_2_r[0]*res[4] + SH_2_r[1]*res[5] + SH_2_r[2]*res[6] + SH_2_r[3]*res[7] + SH_2_rgb[0]*res[8];  
                  res_color.g = SH_0_1_g[0]*res[0] + SH_0_1_g[1]*res[1] + SH_0_1_g[2]*res[2] + SH_0_1_g[3]*res[3] +
                                SH_2_g[0]*res[4] + SH_2_g[1]*res[5] + SH_2_g[2]*res[6] + SH_2_g[3]*res[7] + SH_2_rgb[1]*res[8];
                  res_color.b = SH_0_1_b[0]*res[0] + SH_0_1_b[1]*res[1] + SH_0_1_b[2]*res[2] + SH_0_1_b[3]*res[3] +
                                SH_2_b[0]*res[4] + SH_2_b[1]*res[5] + SH_2_b[2]*res[6] + SH_2_b[3]*res[7] + SH_2_rgb[2]*res[8];
                  return res_color;   
            }

            
            // normal.w is expected to be 1
            half3 SH_3_Order(half4 normal)
            {
                //return f(normal);
                half3 res;
                res.r = dot(SH_0_1_r, normal);
                res.g = dot(SH_0_1_g, normal);
                res.b = dot(SH_0_1_b, normal);
                
                half4 vB = normal.xyzz * normal.yzxz;
                res.r += dot(SH_2_r, vB);
                res.g += dot(SH_2_g, vB);
                res.b += dot(SH_2_b, vB);
                
                half vC = pow2(normal.x) - pow2(normal.y);
                res += SH_2_rgb.rgb * vC;
                
                return res;
            }
            
            half3 maprg(half3 sh)
            {
                if (sh.r > 0)
                {
                    return half3(sh.r, 0, 0);
                }
                else
                {
                    return half3(0, 0, -sh.r);
                }
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                
                return half4(SH_3_Order(float4(normal, 1)), 1);
            }
            ENDCG
        }
    }
}
