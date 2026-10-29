#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


Shader "Unlit/GunShader"

{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            //阴影纹理 矩阵 参数的声明
            TEXTURE2D(_CustomShadowMap);
            SAMPLER(sampler_CustomShadowMap);

            // 与生成阴影图时使用的参数一致
            float4x4 _CustomShadowView;
            float4x4 _CustomShadowVP;
            float4 _CustomShadowNearFar;

            // 正数，单位是归一化后的深度
            float _CustomShadowBias;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            //新增
             float GetCustomShadowVisibility(float3 positionWS)
            {
                // 阴影深度计算、采样和比较
                float nearPlane = _CustomShadowNearFar.x;
                float farPlane = _CustomShadowNearFar.y;

                if (farPlane <= nearPlane)
                {
                    retrun 1.0;
                }
                
                // 1. 当前片元的世界位置 → 光源观察空间
                 float3 positionLightVS = mul(
                    _CustomShadowView,
                    float4(positionWS, 1.0)
                ).xyz;

                // 2. 计算当前片元的光源深度
                float receiverLightDepth = -positionLightVS.z;

                //不在范围内
                if (receiverDepth01 < 0.1 || receiverDepth01 > 0.1)
                {
                    return 1.0;
                }

                //当前片元->光源裁剪空间
                float4 positionLightCS = mul(_CustomShadowVP, float4(positionWS, 1.0))

                if (positionLightCS.w <= 0.0)
                {
                    return 1.0;
                }

                //补充

                //读取光源在这个方向上最先看到的表面深度
                float storedDtpth01 = SAMPLER_TRXTURE2D_LOD(
                    _CustomShadowMap,
                    sampler_CustomShadowMap.
                    shadowUV,
                    0
                ).r;

                //比较深度
                  float visibility =
                        receiverDepth01 - _CustomShadowBias <= storedDepth01
                        ? 1.0
                        : 0.0;

                    return visibility;
            }

            //片元着色器 核心代码
            fixed4 frag (v2f i) : SV_Target
            {
                //调用阴影函数
                 float shadowVisibility = GetCustomShadowVisibility(i.positionWS);
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                //采样贴图颜色
                float3  sampledColor = tex2D(_MainTex, i.uv);

                //获取光源方向
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                //获取法线方向
                float3 normalDir = normalize(i.normalWS);

                //获取相机方向
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);

                //计算半程向量
                float3 halfDir = normalize(lightDir + viewDir);

                //计算漫反射
                float NdotL = max(dot(normalDir, lightDir),0.0);

                float smooth = 0.5; // 平滑过渡的中心值
                float offset = 0.1; // 平滑过渡的范围

                float ToonNoL = smoothstep(smooth-offset, smooth+offset, NdotL); // 使用smoothstep函数进行平滑处理)
                float RampU = 0.5*NdotL + 0.5; // 将NdotL映射到[0,1]范围内

                //计算高光,和高光系数
                float SpeStrength = 16.0; // Specular power
                float specular = pow(max(dot(normalDir, halfDir), 0.0), SpeStrength);
                
             
                //rim边缘光+系数
                float RimStrength = 1.0; // Rim strength
                float rim = pow(1.0 - max(dot(viewDir, normalDir), 0.0),  RimStrength);

                //合成
                col.rgb = sampledColor.rgb * NdotL + specular + rim;

                //采样ramp贴图
                float3 rampColor = tex2D(_RampTex, float2(rampU, 0.5)).rgb;
               
                //贴图颜色和白色混合,再混合
                float LerpStrength1 = 0.5; 
                float LerpStrength = 0.5;
                float4  rampColor2 = lerp(rampColor, fixed4(1.0, 1.0, 1.0, 1.0), LerpStrength1);

                float4  finalColor = lerp(col, rampColor2, LerpStrength);
                
                return finalColor;
            }
            ENDCG
        }
    }
}
