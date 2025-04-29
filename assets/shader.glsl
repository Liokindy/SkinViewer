uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
uniform mat4 modelMatrixInverse;
uniform bool lighting;

uniform vec3 lightColor;
uniform vec3 ambientColor;

varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec3 vertexNormal;
varying vec4 vertexColor;

varying vec3 normal;

#ifdef VERTEX
	attribute vec4 VertexNormal;

	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		normal = vec3(vec4(modelMatrixInverse*VertexNormal));
		return projectionMatrix * viewMatrix * modelMatrix * vertex_position;
	}
#endif

#ifdef PIXEL
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

    vec3 light0direction = vec3(-0.5, -0.25, 1);
    vec3 light1direction = vec3(0.5, 0.25, 1);

    float light0strength = dot(normal, light0direction);
    if (light0strength < 0.0f) { light0strength = 0.0f; }
    float light1strength = dot(normal, light1direction);
    if (light1strength < 0.0f) { light1strength = 0.0f; }

    vec4 finalcolor = vec4(ambientColor + (lightColor - ambientColor) * max(light0strength, light1strength), 1);

    return finalcolor * texcolor * color;
}
#endif