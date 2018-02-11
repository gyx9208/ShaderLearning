// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Texture/Mask Texture"{
    Properties{
         _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8,256)) = 20
        _BumpMap("Normal Map", 2D)= "bump" {}
        _BumpScale("Bump Scale", Float) = 1.0
        _SpecularMask("Specular Mask", 2D) = "white"{}
        _SpecularScale("Specular Scale",Range(8,256)) = 20
    }
    //在切线空间下计算
    SubShader{
        Pass{
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "Lighting.cginc"

                fixed4 _Color;
                fixed4 _Specular;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                float _Gloss;
                sampler2D _BumpMap;
                float4 _BumpMap_ST;
                float _BumpScale;
                sampler2D _SpecularMask;
                float _SpecularScale;

                struct a2v {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float4 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float4 uv : TEXCOORD0;
                    float3 lightDir : TEXCOORD1;
                    float3 viewDir : TEXCOORD2;
                };

                v2f vert (a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);

                    o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                    o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                    //从模型空间到切线空间的向量变换矩阵
                    fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				    fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				    fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
                    float3x3 rotation = float3x3(worldTangent, worldBinormal, worldNormal);
                    //计算方法：
                    //副切线
                    //float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                    //切线x轴，副切线y轴，法线z轴的顺序 模型空间到切线空间的变换矩阵
                    //float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                    
                    o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                    o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
                    
                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 tangentLightDir = normalize(i.lightDir);
                    fixed3 tangentViewDir = normalize(i.viewDir);

                    fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                    fixed3 tangentNormal;
                    //这个要把法线贴图格式设置成normal才能用
                    tangentNormal = UnpackNormal(packedNormal);
                    tangentNormal.xy*=_BumpScale;
                    tangentNormal.z = sqrt(1-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                    fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentLightDir));

                    fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                    fixed specularMask = tex2D(_SpecularMask,i.uv).r * _SpecularScale;
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal,halfDir)), _Gloss) * specularMask;
                    return fixed4(ambient + diffuse + specular,1.0);
                }
            ENDCG
        }
    }

    FallBack "Specular"
}