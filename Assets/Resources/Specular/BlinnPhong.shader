Shader "Custom/Specular/BlinnPhong"{
    Properties{
        _Diffuse ("Diffuse", Color) = (1,1,1,1)
        _Specular ("Specular",Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0,256)) = 20
    }
    SubShader{
        Pass{
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "Lighting.cginc"

                fixed4 _Diffuse;
                fixed4 _Specular;
                float _Gloss;

                struct a2v{
                    float4 vertex:POSITION;
                    float3 normal:NORMAL;
                };
                struct v2f{
                    float4 pos:SV_POSITION;
                    float3 worldNormal: TEXCOORD0;
                    float3 worldPos:TEXCOORD1;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                    //UnityObjectToWorldNormal(v.normal) = mul(v.normal, (float3x3)unity_WorldToObject);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                    return o;
                }

                fixed4 frag(v2f i):SV_TARGET{
                    float3 worldNormal = normalize(i.worldNormal);
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                    //在平行光下，_WorldSpaceLightPos0.xyz是光照，否则用函数UnityWorldSpaceLightDir实现
                    fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));

                    fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));
                    //WorldSpaceViewDir(i.worldPos) = _WorldSpaceCameraPos.xyz-i.worldPos
                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                    fixed3 halfDir = normalize(worldLight + viewDir);
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)), _Gloss);
                    fixed3 color = ambient + diffuse + specular;
                    return fixed4(color,1);
                }
            ENDCG
        }
    }
    FallBack "Specular"
}
