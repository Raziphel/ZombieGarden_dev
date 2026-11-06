// Compact 3x3 Gaussian blur compatible with GLSL 1.10.
// Nine samples instead of 25 reduce fullscreen shader work.
uniform sampler2D baseMap;
uniform float blur_strength;
uniform float screen_width;
uniform float screen_height;

void main()
{
    vec2 texel = vec2(1.0 / max(screen_width, 1.0),
                      1.0 / max(screen_height, 1.0));
    vec2 offset = texel * max(blur_strength, 0.0);
    vec2 uv = gl_TexCoord[0].xy;
    vec3 color = vec3(0.0);
    float totalWeight = 0.0;

    for (int x = -1; x <= 1; x++)
    {
        for (int y = -1; y <= 1; y++)
        {
            float wx = (x == 0) ? 2.0 : 1.0;
            float wy = (y == 0) ? 2.0 : 1.0;
            float weight = wx * wy;
            vec2 sampleUV = uv + vec2(float(x), float(y)) * offset;
            color += texture2D(baseMap, sampleUV).rgb * weight;
            totalWeight += weight;
        }
    }

    gl_FragColor = vec4(color / totalWeight, 1.0);
}
