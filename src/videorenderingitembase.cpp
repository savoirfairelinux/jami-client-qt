/*
 * Copyright (C) 2020 by Savoir-faire Linux
 * Author: Mingrui Zhang   <mingrui.zhang@savoirfairelinux.com>
 * Author: Yang Wang <yang.wang@savoirfairelinux.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "videorenderingitembase.h"

#include "lrcinstance.h"

struct TexturePoint2D
{
    float x, y, z, dx, dy;

    void set(float nx, float ny, float nz, float ndx, float ndy)
    {
        x = nx;
        y = ny;
        z = nz;
        dx = ndx;
        dy = ndy;
    }
};

const QSGGeometry::AttributeSet&
textureAttributeSet()
{
    static QSGGeometry::Attribute data[] = {QSGGeometry::Attribute::create(0, 3, GL_FLOAT, true),
                                            QSGGeometry::Attribute::create(1, 2, GL_FLOAT, false)};
    static QSGGeometry::AttributeSet attrs = {2, sizeof(TexturePoint2D), data};
    return attrs;
}

// TexturesBlendMaterial
TexturesBlendMaterial::TexturesBlendMaterial(AVFrame* materialFrame)
    : QSGMaterial()
    , materialFrame_(std::unique_ptr<AVFrame, void (*)(AVFrame*)>(materialFrame, [](AVFrame* frame) {
        av_frame_free(&frame);
    }))
{
    setFlag(Blending);
}

QSGMaterialShader*
TexturesBlendMaterial::createShader() const
{
    return new TexturesBlendShader();
}

QSGMaterialType*
TexturesBlendMaterial::type() const
{
    static QSGMaterialType type;
    return &type;
}

// TexturesBlendShader
TexturesBlendShader::TexturesBlendShader()
    : QSGMaterialShader()
{
    setShaderSourceFile(QOpenGLShader::Vertex, vertexShaderFile_);
    setShaderSourceFile(QOpenGLShader::Fragment, fragmentShaderFile_);
}

void
TexturesBlendShader::initialize()
{
    angleToRotateId_ = program()->uniformLocation("aAngleToRotate");
    lineSizeWidthScaleFactorsId_ = program()->uniformLocation("vTextureCoordScalingFactors");
    isNV12Id_ = program()->uniformLocation("isNV12");

    uniformTextureSampler2DIds_[0] = program()->uniformLocation("Ytex");
    uniformTextureSampler2DIds_[1] = program()->uniformLocation("Utex");
    uniformTextureSampler2DIds_[2] = program()->uniformLocation("Vtex");
    uniformTextureSampler2DIds_[3] = program()->uniformLocation("UVtex_NV12");

    program()->bind();

    QOpenGLFunctions* glFuncs = QOpenGLContext::currentContext()->functions();
    glFuncs->glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glFuncs->glGenTextures(4, textureIds_);
}

char const* const*
TexturesBlendShader::attributeNames() const
{
    static char const* const attr[] = {"aPosition", "aTextureCoord", nullptr};
    return attr;
}

void
TexturesBlendShader::updateState(const RenderState& state, QSGMaterial* newEffect, QSGMaterial*)
{
    Q_UNUSED(state)

    TexturesBlendMaterial* material = static_cast<TexturesBlendMaterial*>(newEffect);

    bool isNV12 {false};
    QVector3D lineSizeWidthScaleFactors {1.0, 1.0, 1.0};

    QOpenGLFunctions* glFuncs = QOpenGLContext::currentContext()->functions();
    // We bind the textures in inverse order so that we leave the updateState
    // function with GL_TEXTURE0 as the active texture unit. This is maintain
    // the "contract" that updateState should not mess up the GL state beyond
    // what is needed for this material.

    // glFuncs->glEnable(GL_DEPTH_TEST);
    // glFuncs->glDepthMask(true);
    // glFuncs->glClearColor(0.0f, 0.0f, 0.0f, 0.5f);
    // glFuncs->glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    auto frame = material->getMaterialFrame();

    if (frame->linesize[0] && frame->linesize[1] && frame->linesize[2]) {
        isNV12 = false;

        if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV420P
            || AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV422P
            || AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV444P) {
            // Y
            initializeTextureYUV(glFuncs,
                                 textureIds_[0],
                                 frame->linesize[0],
                                 frame->height,
                                 frame->data[0]);
            // U
            initializeTextureYUV(glFuncs,
                                 textureIds_[1],
                                 frame->linesize[1],
                                 (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV420P
                                      ? 0.5
                                      : 1)
                                     * frame->height,
                                 frame->data[1]);
            // V
            initializeTextureYUV(glFuncs,
                                 textureIds_[2],
                                 frame->linesize[2],
                                 (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV420P
                                      ? 0.5
                                      : 1)
                                     * frame->height,
                                 frame->data[2]);

            lineSizeWidthScaleFactors.setX((GLfloat) frame->width / (GLfloat) frame->linesize[0]);
            lineSizeWidthScaleFactors.setY(
                (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV444P ? 1 : 0.5)
                * ((GLfloat) frame->width / (GLfloat) frame->linesize[1]));
            lineSizeWidthScaleFactors.setZ(
                (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV444P ? 1 : 0.5)
                * ((GLfloat) frame->width / (GLfloat) frame->linesize[2]));
        }
    }

    if (frame->linesize[0] && frame->linesize[1]) {
        // the format is NV12
        if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_NV12) {
            isNV12 = true;
            initializeTextureYUV(glFuncs,
                                 textureIds_[0],
                                 frame->linesize[0],
                                 frame->height,
                                 frame->data[0]);
            initializeTextureNV12(glFuncs,
                                  textureIds_[3],
                                  frame->linesize[1],
                                  frame->height / 2,
                                  frame->data[1]);
        }
    }

    program()->setUniformValue(angleToRotateId_, material->getAngleToRotate());
    program()->setUniformValue(lineSizeWidthScaleFactorsId_, lineSizeWidthScaleFactors);
    program()->setUniformValue(isNV12Id_, isNV12);

    glFuncs->glActiveTexture(GL_TEXTURE0);
    glFuncs->glBindTexture(GL_TEXTURE_2D, textureIds_[0]);
    program()->setUniformValue(uniformTextureSampler2DIds_[0], 0);

    if (isNV12) {
        glFuncs->glActiveTexture(GL_TEXTURE0 + 1);
        glFuncs->glBindTexture(GL_TEXTURE_2D, textureIds_[3]);
        program()->setUniformValue(uniformTextureSampler2DIds_[3], 1);
    } else {
        glFuncs->glActiveTexture(GL_TEXTURE0 + 1);
        glFuncs->glBindTexture(GL_TEXTURE_2D, textureIds_[1]);
        program()->setUniformValue(uniformTextureSampler2DIds_[1], 1);

        glFuncs->glActiveTexture(GL_TEXTURE0 + 2);
        glFuncs->glBindTexture(GL_TEXTURE_2D, textureIds_[2]);
        program()->setUniformValue(uniformTextureSampler2DIds_[2], 2);
    }

    // glFuncs->glDrawArrays(GL_TRIANGLES, 0, 6);
}

void
TexturesBlendShader::deactivate()
{
    QOpenGLFunctions* glFuncs = QOpenGLContext::currentContext()->functions();
    glFuncs->glBindTexture(GL_TEXTURE_2D, 0);
    glFuncs->glDeleteTextures(4, textureIds_);
}

void
TexturesBlendShader::initializeTextureYUV(
    QOpenGLFunctions* glFuncs, GLuint textureId, int width, int height, uint8_t* data)
{
    glFuncs->glBindTexture(GL_TEXTURE_2D, textureId);
    glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glFuncs->glTexImage2D(GL_TEXTURE_2D,
                          0,
                          GL_LUMINANCE,
                          width,
                          height,
                          0,
                          GL_LUMINANCE,
                          GL_UNSIGNED_BYTE,
                          data);
}

void
TexturesBlendShader::initializeTextureNV12(
    QOpenGLFunctions* glFuncs, GLuint textureId, int width, int height, uint8_t* data)
{
    glFuncs->glBindTexture(GL_TEXTURE_2D, textureId);
    glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glFuncs->glTexImage2D(GL_TEXTURE_2D, 0, GL_RG8, width, height, 0, GL_RG, GL_UNSIGNED_BYTE, data);
}

// VideoRenderingItemBase
VideoRenderingItemBase::VideoRenderingItemBase(QQuickItem* parent)
    : QQuickItem(parent)
{
    setFlag(QQuickItem::ItemHasContents);

    connect(LRCInstance::renderer(), &RenderManager::previewAvFrameUpdated, [this]() { update(); });
    connect(LRCInstance::renderer(), &RenderManager::previewRenderingStopped, [this]() {
        update();
    });
}

VideoRenderingItemBase::~VideoRenderingItemBase() {}

QSGNode*
VideoRenderingItemBase::updatePaintNode(QSGNode* old, UpdatePaintNodeData*)
{
    QSGGeometryNode* node = 0;
    GLfloat angleToRotate {0.0};
    QSize textureSize;
    QSGGeometry* geometry;
    TexturesBlendMaterial* material;

    node = static_cast<QSGGeometryNode*>(old);

    auto frame = LRCInstance::renderer()->getPreviewAVFrame();
    if (!frame || !frame->width || !frame->height) {
        return node;
    }

    if (auto matrix = av_frame_get_side_data(frame, AV_FRAME_DATA_DISPLAYMATRIX)) {
        const int32_t* data = reinterpret_cast<int32_t*>(matrix->data);
        angleToRotate = av_display_rotation_get(data);
    }

    if (!node) {
        node = new QSGGeometryNode;
        geometry = new QSGGeometry(textureAttributeSet(), 0);
        geometry->setDrawingMode(GL_TRIANGLE_STRIP);
        material = new TexturesBlendMaterial(frame);
        material->setAngleToRotate(angleToRotate);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    } else {
        geometry = node->geometry();
        material = static_cast<TexturesBlendMaterial*>(node->material());
        material->setMaterialFrame(frame);
        material->setAngleToRotate(angleToRotate);
    }

    if ((fmod(angleToRotate, 360.0) >= 45.0 && fmod(angleToRotate, 360.0) <= 135.0)
        || (fmod(angleToRotate, 360.0) >= 225.0 && fmod(angleToRotate, 360.0) <= 315.0)) {
        textureSize.setWidth(frame->height);
        textureSize.setHeight(frame->width);
    } else {
        textureSize = QSize(frame->width, frame->height);
    }

    float dPictureAspectRatio = (float) textureSize.width() / (float) textureSize.height();
    float dAspectRatio = (float) width() / (float) height();

    if (dPictureAspectRatio > dAspectRatio) {
        setHeight(width() * textureSize.height() / textureSize.width());
    } else if (dPictureAspectRatio < dAspectRatio) {
        setWidth(height() * textureSize.width() / textureSize.height());
    }

    int vertexStride = geometry->sizeOfVertex();
    int vertexCount = 6;
    geometry->allocate(vertexCount, 0);
    TexturePoint2D* textureVertices = reinterpret_cast<TexturePoint2D*>(geometry->vertexData());
    memset(textureVertices, 0, vertexCount * vertexStride);

    // textureVertices[0].set(-1.0f, -1.0f, 0.0f, 0.0f, 1.0f);
    // textureVertices[1].set(-1.0f, 1.0f, 0.0f, 0.0f, 0.0f);
    // textureVertices[2].set(1.0f, 1.0f, 0.0f, 1.0f, 0.0f);
    // textureVertices[3].set(1.0f, 1.0f, 0.0f, 1.0f, 0.0f);
    // textureVertices[4].set(1.0f, -1.0f, 0.0f, 1.0f, 1.0f);
    // textureVertices[5].set(-1.0f, -1.0f, 0.0f, 0.0f, 1.0f);

    // auto pointGlobal = this->mapToScene(QPointF(x(), y()));
    auto pointGlobal = QPointF(x(), y());

    auto x1 = (((pointGlobal.x() * 2) / window()->width()) - 1);
    auto x_1 = ((((pointGlobal.x() + width()) * 2) / window()->width()) - 1);
    auto y1 = (-((pointGlobal.y() * 2) / window()->height()) + 1);
    auto y_1 = (-(((pointGlobal.y() + height()) * 2) / window()->height()) + 1);

    // qDebug() << "px: " << pointGlobal.x();
    // qDebug() << "py: " << pointGlobal.y();
    // qDebug() << "x1: " << x1;
    // qDebug() << "x_1: " << x_1;

    textureVertices[0].set(x_1, y_1, 0.0f, 0.0f, 1.0f);
    textureVertices[1].set(x_1, y1, 0.0f, 0.0f, 0.0f);
    textureVertices[2].set(x1, y1, 0.0f, 1.0f, 0.0f);
    textureVertices[3].set(x1, y1, 0.0f, 1.0f, 0.0f);
    textureVertices[4].set(x1, y_1, 0.0f, 1.0f, 1.0f);
    textureVertices[5].set(x_1, y_1, 0.0f, 0.0f, 1.0f);

    node->markDirty(QSGNode::DirtyGeometry);

    return node;
}
