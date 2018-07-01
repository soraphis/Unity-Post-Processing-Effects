Shader "Hidden/DistortionMap"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DistortionMap ("DistortionMap", 2D) = "white" {}
		
        _Omega ("Omega", float) = 0
        _Intensity ("Intensity", Range (0, 10)) = 0
        _Speed ("Speed", Range (0, 10)) = 0
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			
			sampler2D _DistortionMap;
			uniform float4 _DistortionMap_TexelSize;
			
			float _Intensity;
			float _Omega;
			float _Speed;

			fixed4 frag (v2f i) : SV_Target{
			
			    float2 disp = tex2D(_DistortionMap, i.uv - float2(0, 0.1f)*(_Time.x*_Speed) ).xy;
			    disp = ((disp * 2) - 1) * _Intensity * 0.001f; // -Intensity to +Intensity
                
                // disp.y += (_Time.x * 10) % _DistortionMap_TexelSize.y;
			
				fixed4 col = tex2D(_MainTex, i.uv + disp);
				
				return col;
			}
			ENDCG
		}
	}
}
