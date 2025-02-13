// input: Monitor Texture (256x256)
// output: 4 x 1  texture

Shader "KanikamaCluster/LightTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 col;
                // 分割は2x2に限定する
                int index = floor(i.uv.x * 4); // [0,3]
                float2 uv;
                if (index == 0)
                {
                    uv = float2(0.25, 0.25);
                }
                else if (index == 1)
                {
                    uv = float2(0.75, 0.25);
                }
                else if (index == 2)
                {
                    uv = float2(0.25, 0.75);
                }
                else
                {
                    uv = float2(0.75, 0.75);
                }

                // 256x256->2x2なのでmipmap levelは7
                col.rgb = tex2Dlod(_MainTex, float4(uv, 0, 7)).rgb;
                return col;
            }
            ENDCG
        }
    }
}