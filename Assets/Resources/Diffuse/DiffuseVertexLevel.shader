// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// 抄完一遍，发现光照是反的…………
// 灵异事件，重启Unity就好了
// 发现原因了。LightMode打成LightModel了。LightMode定义了_WorldSpaceLightPos0的值是什么
Shader "Custom/Diffuse/VertexLevel" {
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
					fixed3 color : COLOR;
				};

				v2f vert(a2v v){
					v2f o;
					//计算下SV_POSITION，都要算的，没啥屌用
					o.pos = UnityObjectToClipPos(v.vertex);
					//环境光
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
					//将法线从模型空间变换到世界空间，使用顶点变换矩阵的逆转置矩阵变换法线
					//unity_WorldToObject是定点变换矩阵unity_ObjectToWorld的逆矩阵
					//交换矩阵在mul函数中的位置，得到和转置矩阵相同的计算
					//法线是向量，只取3*3
					//这里虽然用的normalize函数来归一化，但是我发现去掉normalize结果也一样，下面平行光同样
					fixed3 worldNormal= normalize(mul(v.normal, (float3x3)unity_WorldToObject));
					//平行光
					fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
					//dot取了点积，点积是投影，归一化的点积就是cos了。saturate是截取[0,1]的函数
					fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));
					//计算出顶点的颜色是 漫反射+环境光
					o.color = diffuse + ambient;

					return o;
				}
				
				fixed4 frag(v2f i) : SV_TARGET{
					return fixed4(i.color,1.0);
				}
			ENDCG
		}
	}
	FallBack "Diffuse"
}