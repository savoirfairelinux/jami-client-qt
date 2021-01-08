#ifdef GL_ES
precision mediump float;
#endif

uniform float aAngleToRotate;
uniform vec2 aViewPortWidthAndHeight;
uniform vec2 aWidthAndHeight;

attribute vec3 aPosition;
attribute vec2 aTextureCoord;

varying vec2 vTextureCoord;
bool notInTheRoundedArea;

void main() {
    vec3 postionAfterRotate = mat3(cos(radians(aAngleToRotate)),sin(radians(aAngleToRotate)), 0,
                                   -sin(radians(aAngleToRotate)),cos(radians(aAngleToRotate)), 0,
                                   0,                 0,                    1) * aPosition;
    vec2 imageTrueSizeVector;
    if((mod(aAngleToRotate, 360.0) >= 45.0 && mod(aAngleToRotate, 360.0) <= 135.0) ||
      (mod(aAngleToRotate, 360.0) >= 225.0 && mod(aAngleToRotate, 360.0) <= 315.0)) {
        imageTrueSizeVector.x = aWidthAndHeight.y;
        imageTrueSizeVector.y = aWidthAndHeight.x;
    } else {
        imageTrueSizeVector = aWidthAndHeight;
    }
    float dPictureAspectRatio = imageTrueSizeVector.x / imageTrueSizeVector.y;
    float dAspectRatio = aViewPortWidthAndHeight.x / aViewPortWidthAndHeight.y;

    if(dPictureAspectRatio > dAspectRatio) {
        float newHeight = aViewPortWidthAndHeight.x * imageTrueSizeVector.y /
        imageTrueSizeVector.x ;
        float heightRatio = newHeight / aViewPortWidthAndHeight.y;
        postionAfterRotate.y *= heightRatio;
    } else if(dPictureAspectRatio < dAspectRatio) {
        float newWidth = aViewPortWidthAndHeight.y * imageTrueSizeVector.x/
        imageTrueSizeVector.y;
        float widthRatio = newWidth / aViewPortWidthAndHeight.x;
        postionAfterRotate.x *= widthRatio;
    }
    gl_Position = vec4(postionAfterRotate,1);
    vTextureCoord = aTextureCoord;
}