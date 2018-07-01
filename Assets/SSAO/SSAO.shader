Shader "Hidden/SSAO"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_OcclusionTexture ("OcclusionTexture", 2D) = "white" {}
		_KernelSize ("Kernel Size", float) = 0.02
		_BIAS ("BIAS", float) = 0.3
		_Intensity ("Intensity", float) = 0.5
		_BlurOffset ("_BlurOffset", float) = 1
		[MaterialToggle] _Debug("Debug", Float) = 0
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
			sampler2D _CameraDepthNormalsTexture;
			
			float4 _MainTex_TexelSize;
            
            float _KernelSize;
            const float _BIAS;
            float _Intensity; 
            float _Debug;
            float3 _Samples[256];
            float _SampleCount; 
            
            float random(float min, float max, float3 myVector){
                 float rand = frac(sin(myVector.x * dot(myVector ,float3(12.9898,78.233,45.5432))) * 43758.5453);
                 return (max - min) * rand + min;
            }
        
            float3 RotateAroundZInDegrees (float3 vertex, float degrees){
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                //return float3(mul(m, vertex.xz), vertex.y).xzy;
                return float3(mul(m, vertex.xy), vertex.z).zxy;
            }


            fixed4 frag(v2f i) : SV_Target{
			    float3 normal = DecodeViewNormalStereo( tex2D(_CameraDepthNormalsTexture, i.uv.xy) );
			    float depth01 = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, i.uv.xy).zw);
                const float FARPLANE = _ProjectionParams.z;
                
                float scale = _KernelSize / (depth01 * FARPLANE);
                
                float ao = 0.0;
                for(int j = 0; j < _SampleCount; ++j){
                    
                    float3 sample = _Samples[j]; // PickSamplePoint(i.uv, j); // 
			        sample = RotateAroundZInDegrees(sample, random(0.0f, 360.0f, float3(j, i.uv))); 
			        
                    if( dot(normal, sample) < 0.0f) sample *= -1.0f;			    
			    
			        float2 off = sample.xy * scale;
			        float s_depth01 = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, i.uv.xy + off).zw);
			        
                    float depth_delta = (depth01 - s_depth01) * FARPLANE;
                    //return saturate(depth_delta);
                    
                    float3 sampleDir = float3(sample.xy * _KernelSize, depth_delta);
                    
                    
                    float occ = max(0.0, dot(normal, normalize(sampleDir)) - _BIAS) * (1.0 / (1.0+length(sampleDir)) * _Intensity);
                    ao += 1.0f - occ;
                    
                    // if(depth_delta < _BIAS) ao += 1.0; 
                }
                
                ao /= _SampleCount;
                ao *= ao;
                return saturate(ao);
            }
			ENDCG
		}
		
		
        Pass{
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
            float _Debug;
            float _BlurOffset;
            
            fixed4 frag (v2f i) : SV_Target{
                 fixed4 col = tex2D(_MainTex, i.uv);
                 fixed4 col1 = tex2D(_MainTex, i.uv + fixed2(0, _BlurOffset * _MainTex_TexelSize.y));
                 fixed4 col2 = tex2D(_MainTex, i.uv - fixed2(0, _BlurOffset * _MainTex_TexelSize.y));
                 fixed4 col3 = tex2D(_MainTex, i.uv + fixed2(_BlurOffset * _MainTex_TexelSize.x, 0));
                 fixed4 col4 = tex2D(_MainTex, i.uv - fixed2(_BlurOffset * _MainTex_TexelSize.x, 0));
                 
                 // fixed4 col5 = tex2D(_MainTex, i.uv + fixed2(  _BlurOffset * _MainTex_TexelSize.x,   _BlurOffset * _MainTex_TexelSize.y));
                 // fixed4 col6 = tex2D(_MainTex, i.uv + fixed2(  _BlurOffset * _MainTex_TexelSize.x, - _BlurOffset * _MainTex_TexelSize.y));
                 // fixed4 col7 = tex2D(_MainTex, i.uv + fixed2(- _BlurOffset * _MainTex_TexelSize.x, - _BlurOffset * _MainTex_TexelSize.y));
                 // fixed4 col8 = tex2D(_MainTex, i.uv + fixed2(- _BlurOffset * _MainTex_TexelSize.x,   _BlurOffset * _MainTex_TexelSize.y));
                 // return (4 * (col1 + col2 + col3 + col4)  + (col5 + col6 + col7 + col8)) / (4 * 4 + 4);
                 
                 return (col + col1 + col2 + col3 + col4) / 5.0;
                 
            }
            ENDCG
        }
        
        
        Pass{
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
            sampler2D _OcclusionTexture;
            float _Debug;
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 hemisphericalVisibility = tex2D(_OcclusionTexture, i.uv);
                
                if(_Debug == 1)  return hemisphericalVisibility;
                
                return col * (hemisphericalVisibility.x);
            }
            ENDCG
        }        
                
	}
}