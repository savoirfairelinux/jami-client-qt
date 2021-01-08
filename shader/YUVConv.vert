#ifdef GL_ES
precision mediump float;
#endif

uniform float yawAngle;
uniform float pitchAngle;
uniform vec2  aScaleFactor;

attribute vec4 aPosition;
attribute vec2 aTextureCoord;

varying vec2 vTextureCoord;

void main() {
    vec3 pos = mat3(cos(radians(yawAngle)), -sin(radians(yawAngle)), 0,
                    sin(radians(yawAngle)),  cos(radians(yawAngle)), 0,
                                         0,                       0, 1) * aPosition.xyz;

    pos = mat3( cos(radians(pitchAngle)),  0, sin(radians(pitchAngle)),
                                       0,  1,                        0,
               -sin(radians(pitchAngle)),  0, cos(radians(pitchAngle))) * pos;

    pos = mat3(aScaleFactor.x,              0, 0,
                            0, aScaleFactor.y, 0,
                            0,              0, 1) * pos;

    gl_Position = vec4(pos, aPosition.w);
    vTextureCoord = aTextureCoord;
}