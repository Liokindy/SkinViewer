uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
uniform bool isCanvasEnabled;
uniform bool lighting;

varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec3 vertexNormal;
varying vec4 vertexColor;


vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
{
    vec4 texcolor = Texel(tex, texcoord);

    if (texcolor.a <= 0.0)
    {
        if (true)
        {
            vec4 pixcolor = Texel(tex, pixcoord + vec2(1, 0));
            if (pixcoord.x == 0)
            {
                return vec4(1, 1, 1, 1);
            }
        }
        discard;
    }
    
    if (!lighting)
    {
        return texcolor * color;
    }

    vec4 ambientcolor = vec4(0.5, 0.5, 0.5, 1);
    vec4 lightcolor = vec4(0.5, 0.5, 0.5, 0);

    vec3 light0direction = vec3(-0.5, -0.25, 1);
    vec3 light1direction = vec3(0.5, 0.25, 1);
    
    float light0strength = dot(normalize(vertexNormal), normalize(light0direction));
    if (light0strength < 0.0f) { light0strength = 0.0f; }
    float light1strength = dot(normalize(vertexNormal), normalize(light1direction));
    if (light1strength < 0.0f) { light1strength = 0.0f; }

    vec4 finalcolor = ambientcolor + (lightcolor * light0strength + lightcolor * light1strength) * 0.5f;

    return finalcolor * texcolor * color;
}