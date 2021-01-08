#ifdef GL_ES
precision mediump float;
#endif

uniform bool isNV12;
uniform sampler2D Ytex, Utex, Vtex, UVtex_NV12;
uniform vec3 vTextureCoordScalingFactors;

varying vec2 vTextureCoord;

mat3 YUVtoRGBCoeffMatrixTransposed = mat3(1.164383,  0.000000, 1.596027,
                                          1.164383, -0.391762, -0.812968,
                                          1.164383, 2.017232, 0.000000);

vec3 ConvertYUVtoRGB(vec3 yuv)
{
    yuv -= vec3(0.062745, 0.501960, 0.501960);
    yuv = yuv * YUVtoRGBCoeffMatrixTransposed;

    return clamp(yuv, 0.0, 1.0);
}

void main(void) {
    vec3 yuv;
    vec3 rgb;

    if(isNV12) {
        vec2 texCoorUV = vec2(vTextureCoord.x / 2.0, vTextureCoord.y);

        yuv.x = texture2D(Ytex, vTextureCoord).r;
        yuv.y = texture2D(UVtex_NV12,texCoorUV).r;
        yuv.z = texture2D(UVtex_NV12,texCoorUV).g;
    } else {
        yuv.x = texture2D(Ytex, vec2(vTextureCoord.x * vTextureCoordScalingFactors.x,
        vTextureCoord.y)).r;
        yuv.y = texture2D(Utex, vec2(vTextureCoord.x * vTextureCoordScalingFactors.y,
        vTextureCoord.y)).r;
        yuv.z = texture2D(Vtex, vec2(vTextureCoord.x * vTextureCoordScalingFactors.z,
        vTextureCoord.y)).r;
    }

    rgb = ConvertYUVtoRGB(yuv);

    if(rgb.r < 0.1 && rgb.b < 0.1 && yuv.x < 0.1) {
        rgb.g = 0.0;
    }

    gl_FragColor = vec4(rgb, 1.0);
}