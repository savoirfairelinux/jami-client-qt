#ifdef GL_ES
precision mediump float;
#endif

uniform bool isNV12;
uniform sampler2D Ytex, Utex, Vtex, UVtex_NV12;

varying vec2 vTextureCoord;

mat3 YUVtoRGBCoeffMatrixTransposed = mat3(1.0, 0.000,  1.403,
                                          1.0, -0.344, -0.714,
                                          1.0, 1.770,  0.000);

vec3 ConvertYUVtoRGB(vec3 yuv)
{
    yuv -= vec3(0.0, 0.5, 0.5);
    yuv = yuv * YUVtoRGBCoeffMatrixTransposed;

    return yuv;
}

void main(void) {
    vec3 yuv;
    vec3 rgb;

    if(isNV12) {
        yuv.x = texture2D(Ytex, vTextureCoord).r;
        yuv.y = texture2D(UVtex_NV12, vTextureCoord).r;
        yuv.z = texture2D(UVtex_NV12, vTextureCoord).a;
    } else {
        yuv.x = texture2D(Ytex,
                    vec2(vTextureCoord.x, vTextureCoord.y)).r;
        yuv.y = texture2D(Utex,
                    vec2(vTextureCoord.x, vTextureCoord.y)).r;
        yuv.z = texture2D(Vtex,
                    vec2(vTextureCoord.x, vTextureCoord.y)).r;
    }

    rgb = ConvertYUVtoRGB(yuv);

    gl_FragColor = vec4(rgb, 1.0);
}