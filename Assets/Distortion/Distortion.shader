Shader "Hidden/Distortion"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _Omega ("Omega", float) = 1
        _Intensity ("Intensity", Range (0, 10)) = 1
        _Speed ("Speed", Range (0, 10)) = 4
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
			float4 _MainTex_TexelSize;
			float _Intensity;
			float _Omega;
			float _Speed;

			fixed4 frag (v2f i) : SV_Target
			{
			    float x = _MainTex_TexelSize.x;
			    float y = _MainTex_TexelSize.y;
				fixed4 col = tex2D(_MainTex, i.uv + float2(sin((2 * _Speed * _Time.x * 3.141f) * i.uv.y * _Omega)*y, 0)*_Intensity);
				return col;
			}
			ENDCG
		}
	}
}
