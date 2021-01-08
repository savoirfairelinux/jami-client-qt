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
TexturesBlendMaterial::TexturesBlendMaterial()
    : QSGMaterial()
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

int
TexturesBlendMaterial::compare(const QSGMaterial* o) const
{
    Q_ASSERT(o && type() == o->type());
    const TexturesBlendMaterial* other = static_cast<const TexturesBlendMaterial*>(o);

    if (!state.Ytex || !other->state.Ytex)
        return state.Ytex ? 1 : -1;

    if (!state.Utex || !other->state.Utex)
        return state.Utex ? -1 : 1;

    if (!state.Vtex || !other->state.Vtex)
        return state.Vtex ? -1 : 1;

    if (!state.UVtex_NV12 || !other->state.UVtex_NV12)
        return state.UVtex_NV12 ? -1 : 1;

    if (int diff = state.Ytex->comparisonKey() - other->state.Ytex->comparisonKey())
        return diff;

    if (int diff = state.Utex->comparisonKey() - other->state.Utex->comparisonKey())
        return diff;

    if (int diff = state.Vtex->comparisonKey() - other->state.Vtex->comparisonKey())
        return diff;

    if (int diff = state.UVtex_NV12->comparisonKey() - other->state.UVtex_NV12->comparisonKey())
        return diff;

    return 0;
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
    sizeTextureId_ = program()->uniformLocation("aWidthAndHeight");
    viewportSizeId_ = program()->uniformLocation("aViewPortWidthAndHeight");
    lineSizeWidthScaleFactorsId_ = program()->uniformLocation("vTextureCoordScalingFactors");
    isNV12Id_ = program()->uniformLocation("isNV12");

    uni_[0] = program()->uniformLocation("Ytex");
    uni_[1] = program()->uniformLocation("Utex");
    uni_[2] = program()->uniformLocation("Vtex");
    uni_[3] = program()->uniformLocation("UVtex_NV12");

    program()->bind();

    QOpenGLFunctions* glFuncs = QOpenGLContext::currentContext()->functions();
    glFuncs->glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glFuncs->glGenTextures(4, texs_);
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
    TexturesBlendMaterial* material = static_cast<TexturesBlendMaterial*>(newEffect);

    QRect viewportGeo;
    bool isNV12;
    GLfloat angleToRotate;
    QVector2D sizeTexture;
    QVector3D lineSizeWidthScaleFactors;

    QOpenGLFunctions* glFuncs = QOpenGLContext::currentContext()->functions();
    // We bind the textures in inverse order so that we leave the updateState
    // function with GL_TEXTURE0 as the active texture unit. This is maintain
    // the "contract" that updateState should not mess up the GL state beyond
    // what is needed for this material.

    auto frame = LRCInstance::renderer()->getPreviewAVFrame();

    if (!frame || !frame->width || !frame->height) {
        return;
    }

    double rotation = 0;
    if (auto matrix = av_frame_get_side_data(frame, AV_FRAME_DATA_DISPLAYMATRIX)) {
        const int32_t* data = reinterpret_cast<int32_t*>(matrix->data);
        rotation = av_display_rotation_get(data);
    }

    angleToRotate = rotation;
    sizeTexture = QVector2D(frame->width, frame->height);

    if (frame->linesize[0] && frame->linesize[1] && frame->linesize[2]) {
        isNV12 = false;

        if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV420P) {
            // Y
            glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[0]);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glFuncs->glTexImage2D(GL_TEXTURE_2D,
                                  0,
                                  GL_LUMINANCE,
                                  frame->linesize[0],
                                  frame->height,
                                  0,
                                  GL_LUMINANCE,
                                  GL_UNSIGNED_BYTE,
                                  frame->data[0]);
            // U
            glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[1]);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glFuncs->glTexImage2D(GL_TEXTURE_2D,
                                  0,
                                  GL_LUMINANCE,
                                  frame->linesize[1],
                                  frame->height / 2,
                                  0,
                                  GL_LUMINANCE,
                                  GL_UNSIGNED_BYTE,
                                  frame->data[1]);

            // V
            glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[2]);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glFuncs->glTexImage2D(GL_TEXTURE_2D,
                                  0,
                                  GL_LUMINANCE,
                                  frame->linesize[2],
                                  frame->height / 2,
                                  0,
                                  GL_LUMINANCE,
                                  GL_UNSIGNED_BYTE,
                                  frame->data[2]);

            lineSizeWidthScaleFactors.setX((GLfloat) frame->width / (GLfloat) frame->linesize[0]);
            lineSizeWidthScaleFactors.setY((GLfloat) frame->width / 2
                                           / (GLfloat) frame->linesize[1]);
            lineSizeWidthScaleFactors.setZ((GLfloat) frame->width / 2
                                           / (GLfloat) frame->linesize[2]);
        } else if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV422P) {
            // Y
            glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[0]);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glFuncs->glTexImage2D(GL_TEXTURE_2D,
                                  0,
                                  GL_LUMINANCE,
                                  frame->linesize[0],
                                  frame->height,
                                  0,
                                  GL_LUMINANCE,
                                  GL_UNSIGNED_BYTE,
                                  frame->data[0]);

            // U
            glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[1]);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glFuncs->glTexImage2D(GL_TEXTURE_2D,
                                  0,
                                  GL_LUMINANCE,
                                  frame->linesize[1],
                                  frame->height,
                                  0,
                                  GL_LUMINANCE,
                                  GL_UNSIGNED_BYTE,
                                  frame->data[1]);

            // V
            glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[2]);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glFuncs->glTexImage2D(GL_TEXTURE_2D,
                                  0,
                                  GL_LUMINANCE,
                                  frame->linesize[2],
                                  frame->height,
                                  0,
                                  GL_LUMINANCE,
                                  GL_UNSIGNED_BYTE,
                                  frame->data[2]);

            lineSizeWidthScaleFactors.setX((GLfloat) frame->width / (GLfloat) frame->linesize[0]);
            lineSizeWidthScaleFactors.setY((GLfloat) frame->width / 2
                                           / (GLfloat) frame->linesize[1]);
            lineSizeWidthScaleFactors.setZ((GLfloat) frame->width / 2
                                           / (GLfloat) frame->linesize[2]);
        } else if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_YUV444P) {
            // Y
            glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[0]);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glFuncs->glTexImage2D(GL_TEXTURE_2D,
                                  0,
                                  GL_LUMINANCE,
                                  frame->linesize[0],
                                  frame->height,
                                  0,
                                  GL_LUMINANCE,
                                  GL_UNSIGNED_BYTE,
                                  frame->data[0]);

            // U
            glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[1]);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glFuncs->glTexImage2D(GL_TEXTURE_2D,
                                  0,
                                  GL_LUMINANCE,
                                  frame->linesize[1],
                                  frame->height,
                                  0,
                                  GL_LUMINANCE,
                                  GL_UNSIGNED_BYTE,
                                  frame->data[1]);

            // V
            glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[2]);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glFuncs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glFuncs->glTexImage2D(GL_TEXTURE_2D,
                                  0,
                                  GL_LUMINANCE,
                                  frame->linesize[2],
                                  frame->height,
                                  0,
                                  GL_LUMINANCE,
                                  GL_UNSIGNED_BYTE,
                                  frame->data[2]);

            lineSizeWidthScaleFactors.setX((GLfloat) frame->width / (GLfloat) frame->linesize[0]);
            lineSizeWidthScaleFactors.setY((GLfloat) frame->width / (GLfloat) frame->linesize[1]);
            lineSizeWidthScaleFactors.setZ((GLfloat) frame->width / (GLfloat) frame->linesize[2]);
        }

        program()->setUniformValue(angleToRotateId_, angleToRotate);
        program()->setUniformValue(sizeTextureId_, sizeTexture);
        program()->setUniformValue(viewportSizeId_,
                                   QVector2D((GLfloat) material->getViewportGeo().width(),
                                             (GLfloat) material->getViewportGeo().height()));
        program()->setUniformValue(lineSizeWidthScaleFactorsId_, lineSizeWidthScaleFactors);
        program()->setUniformValue(isNV12Id_, isNV12);

        glFuncs->glActiveTexture(GL_TEXTURE0);
        glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[0]);
        program()->setUniformValue(uni_[0], 0);

        glFuncs->glActiveTexture(GL_TEXTURE0 + 1);
        glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[1]);
        program()->setUniformValue(uni_[1], 1);

        glFuncs->glActiveTexture(GL_TEXTURE0 + 2);
        glFuncs->glBindTexture(GL_TEXTURE_2D, texs_[2]);
        program()->setUniformValue(uni_[2], 2);

        glFuncs->glDrawArrays(GL_TRIANGLES, 0, 6);
    }

    // if (frame->linesize[0] && frame->linesize[1]) {
    //    // the format is NV12
    //    if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_NV12) {
    //        initializeTexture(frameTex_.Ytex,
    //                          QOpenGLTexture::LuminanceFormat,
    //                          QOpenGLTexture::Luminance,
    //                          frame->linesize[0],
    //                          frame->height,
    //                          frame->data[0]);
    //        initializeTexture(frameTex_.UVtex_NV12,
    //                          QOpenGLTexture::RG8_UNorm,
    //                          QOpenGLTexture::RG,
    //                          frame->linesize[1],
    //                          frame->height / 2,
    //                          frame->data[1]);
    //        setIsNV12(true);
    //        result = true;
    //    }
    //}
    // if (frame->linesize[0] && frame->linesize[1]) {
    //    // all hardware accelerated formats are NV12
    //    if (AVPixelFormat(frame->format) == AVPixelFormat::AV_PIX_FMT_CUDA) {
    //        // support the CUDA hardware accel frame
    //        result = updateTextureFromCUDA(frame);
    //    } else {
    //        result = false;
    //    }
    //}
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

    QSGGeometry* geometry;
    TexturesBlendMaterial* material;
    node = static_cast<QSGGeometryNode*>(old);
    if (!node) {
        node = new QSGGeometryNode;
        geometry = new QSGGeometry(textureAttributeSet(), 0);
        geometry->setDrawingMode(GL_TRIANGLE_STRIP);
        material = new TexturesBlendMaterial();
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    } else {
        geometry = node->geometry();
        material = static_cast<TexturesBlendMaterial*>(node->material());
    }

    material->setViewportGeo(QRect(x(), y(), width(), height()));

    int vertexStride = geometry->sizeOfVertex();
    int vertexCount = 6;

    geometry->allocate(vertexCount, 0);
    TexturePoint2D* textureVertices = reinterpret_cast<TexturePoint2D*>(geometry->vertexData());
    memset(textureVertices, 0, vertexCount * vertexStride);

    textureVertices[0].set(-1.0f * (width() / window()->width()),
                           -1.0f * (height() / window()->height()),
                           0.0f,
                           0.0f,
                           1.0f);
    textureVertices[1].set(-1.0f * (width() / window()->width()),
                           1.0f * (height() / window()->height()),
                           0.0f,
                           0.0f,
                           0.0f);
    textureVertices[2].set(1.0f * (width() / window()->width()),
                           1.0f * (height() / window()->height()),
                           0.0f,
                           1.0f,
                           0.0f);
    textureVertices[3].set(1.0f * (width() / window()->width()),
                           1.0f * (height() / window()->height()),
                           0.0f,
                           1.0f,
                           0.0f);
    textureVertices[4].set(1.0f * (width() / window()->width()),
                           -1.0f * (height() / window()->height()),
                           0.0f,
                           1.0f,
                           1.0f);
    textureVertices[5].set(-1.0f * (width() / window()->width()),
                           -1.0f * (height() / window()->height()),
                           0.0f,
                           0.0f,
                           1.0f);

    node->markDirty(QSGNode::DirtyGeometry);

    return node;
}
