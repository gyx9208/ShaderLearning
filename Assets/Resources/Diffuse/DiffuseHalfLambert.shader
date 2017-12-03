Shader "Custom/Diffuse/HalfLambert" {
	Properties{
		_Diffuse("Diffuse", Color) = (1,1,1,1)
	}
	SubShader{
		Pass{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "Lighting.cginc"

				fixed4 _Diffuse;
				struct a2v {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					fixed3 worldNormal : TEXCOORD0;
				};

				v2f vert(a2v v){
					v2f o;
					//注释见DiffuseVertexLevel shader
					o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
					//这里没有再归一化了，反正之后还要归一一次？
					o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

					return o;
				}
				
				fixed4 frag(v2f i) : SV_TARGET{
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
					fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * (dot(worldNormal,worldLight)*0.5+0.5);

					fixed3 color = ambient + diffuse;
					return fixed4(color,1);
				}
			ENDCG
		}
	}
	FallBack "Diffuse"
}