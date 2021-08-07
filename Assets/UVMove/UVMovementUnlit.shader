Shader "Unlit/UVMovementUnlit"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Gloss ("Gloss", Float) = 1
        _MainTex ("Texture", 2D) = "white" {}
        _UVXSpeed ("UV X Speed", Float) = 0
        _UVYSpeed ("UV Y Speed", Float) = 0
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
            #include "Lighting.cginc"
            #include "UnityLightingCommon.cginc"


            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;                
            };

            struct VertexOutput
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            float4 _Color;
            float _Gloss;
            sampler2D _MainTex;
            float _UVXSpeed;
            float _UVYSpeed;

            VertexOutput vert (VertexInput v)
            {
                VertexOutput o;
                o.uv = v.uv;
                o.normal = v.normal;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float InvLerp(float a, float b, float value){
                return (value-a)/(b-a);
            }

            float3 MyLerp(float3 a, float3 b, float t){
                return t * b + (1-t)*a;
            }

            float Posterize(float value, float steps){
                return floor(value * steps) / steps;
            }

            float4 frag(VertexOutput i) : SV_Target
            {
                float2 uv = i.uv;

                uv.x += _Time.y * _UVXSpeed;
                uv.y += _Time.y * _UVYSpeed;

                float4 textured = tex2D(_MainTex, uv);

                float3 normal = normalize(i.normal);

                // Direct diffuse light
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float lightFalloff = max(0, dot(lightDir, normal));

                //lightFalloff = Posterize(lightFalloff,3);
                float3 directDiffuseLight = textured + lightColor * lightFalloff;
                //return float4(directDiffuseLight,1);    

                // Ambient light
                float3 ambientLight = float3(0.1,0.1,0.1);

                // Direct specular light
                float3 camPos = _WorldSpaceCameraPos;
                float3 fragToCam = camPos - i.worldPos;
                float3 viewDir = normalize(fragToCam);
                // Phong
                float3 viewReflect = reflect(-viewDir, normal);
                float specularFalloff = max(0,dot(viewReflect,lightDir));
                
                // Gloss
                specularFalloff = pow(specularFalloff, _Gloss);
                //specularFalloff = Posterize(specularFalloff, 3);
                float3 directSpecular = specularFalloff * lightColor;


                // Composite light
                float3 diffuseLight = ambientLight + directDiffuseLight;  

                float3 finalSurfaceColor = diffuseLight * _Color.rgb + directSpecular;

                return float4(finalSurfaceColor,0);
            }
            ENDCG
        }
    }
}
