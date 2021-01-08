#ifdef GL_ES
precision mediump float;
#endif

uniform float aAngleToRotate;

attribute vec4 aPosition;
attribute vec2 aTextureCoord;

varying vec2 vTextureCoord;

void main() {
    vec3 postionAfterRotate = mat3(cos(radians(aAngleToRotate)),  sin(radians(aAngleToRotate)), 0,
                                   -sin(radians(aAngleToRotate)), cos(radians(aAngleToRotate)), 0,
                                   0,                             0,                            1) * aPosition.xyz;

    gl_Position = vec4(postionAfterRotate, aPosition.w);
    vTextureCoord = aTextureCoord;
}