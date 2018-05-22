uniform sampler2D u_atlas;

#ifdef VECTOR_TILE
uniform vec4 u_highlightColor;
#endif

varying vec2 v_textureCoordinates;
varying vec4 v_textureOffset;
varying vec2 v_depthLookupTextureCoordinate;
varying vec2 v_dimensions;

#ifdef RENDER_FOR_PICK
varying vec4 v_pickColor;
#else
varying vec4 v_color;
#endif

void main()
{

vec2 adjustedST = v_textureCoordinates - v_textureOffset.xy;
adjustedST = adjustedST / (v_textureOffset.z - v_textureOffset.x, v_textureOffset.w - v_textureOffset.y);
vec2 st = ((v_dimensions.xy * (v_depthLookupTextureCoordinate - adjustedST)) + gl_FragCoord.xy) / czm_viewport.zw;



#ifdef RENDER_FOR_PICK
    vec4 vertexColor = vec4(1.0, 1.0, 1.0, 1.0);
#else
    vec4 vertexColor = v_color;
#endif

//vertexColor = vec4(st.x, st.y, 0.0, 1.0);

    vec4 color = texture2D(u_atlas, v_textureCoordinates) * vertexColor;

// Fully transparent parts of the billboard are not pickable.
#if defined(RENDER_FOR_PICK) || (!defined(OPAQUE) && !defined(TRANSLUCENT))
    if (color.a < 0.005)   // matches 0/255 and 1/255
    {
        discard;
    }
#else
// The billboard is rendered twice. The opaque pass discards translucent fragments
// and the translucent pass discards opaque fragments.
#ifdef OPAQUE
    if (color.a < 0.995)   // matches < 254/255
    {
        discard;
    }
#else
    if (color.a >= 0.995)  // matches 254/255 and 255/255
    {
        discard;
    }
#endif
#endif

#ifdef VECTOR_TILE
    color *= u_highlightColor;
#endif

#ifdef RENDER_FOR_PICK
    gl_FragColor = v_pickColor;
#else
    gl_FragColor = color;
#endif

    czm_writeLogDepth();


    vec2 coords = gl_FragCoord.xy / czm_viewport.zw;
    float logDepth = czm_unpackDepth(texture2D(czm_globeDepthTexture, coords));
    float depth = czm_reverseLogDepth(logDepth);
    if (depth <= gl_FragDepthEXT)
    {
        discard;
    }
}
