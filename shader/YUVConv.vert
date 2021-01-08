#ifdef GL_ES
precision mediump float;
#endif

uniform float aAngleToRotateZ;
uniform float aAngleToRotateY;
uniform vec2  aScaleFactor;

attribute vec4 aPosition;
attribute vec2 aTextureCoord;

varying vec2 vTextureCoord;

void main() {
    vec3 postionAfterRotateZ = mat3(cos(radians(aAngleToRotateZ)), -sin(radians(aAngleToRotateZ)), 0,
                                    sin(radians(aAngleToRotateZ)),  cos(radians(aAngleToRotateZ)), 0,
                                                                0,                              0, 1) * aPosition.xyz;

    vec3 postionAfterRotateY = mat3( cos(radians(aAngleToRotateY)),  0, sin(radians(aAngleToRotateY)),
                                                                 0,  1,                             0,
                                    -sin(radians(aAngleToRotateY)),  0, cos(radians(aAngleToRotateY))) * postionAfterRotateZ;

    vec3 postionAfterScaled = mat3(aScaleFactor.x,              0, 0,
                                                0, aScaleFactor.y, 0,
                                                0,              0, 1) * postionAfterRotateY;

    gl_Position = vec4(postionAfterScaled, aPosition.w);
    vTextureCoord = aTextureCoord;
}