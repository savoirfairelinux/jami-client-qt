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

#pragma once

#include <QtQuick>
#include <QWindow>
#include <QMutex>
#include <QMutexLocker>
#include <QOpenGLFunctions>
#include <QOpenGLTexture>
#include <QOpenGLShaderProgram>
#include <QOpenGLBuffer>

extern "C" {
// FFMPEG headers
#include <libavutil/frame.h>
#include <libavutil/display.h>
#include <libavutil/hwcontext.h>
}

class TexturesBlendMaterial : public QSGMaterial
{
public:
    TexturesBlendMaterial(AVFrame* materialFrame);

    QSGMaterialType* type() const override;
    QSGMaterialShader* createShader() const override;

    struct YUVFrameTexture
    {
        QSGTexture* Ytex {nullptr};
        QSGTexture* Utex {nullptr};
        QSGTexture* Vtex {nullptr};
        QSGTexture* UVtex_NV12 {nullptr};
    } state;

    AVFrame* getMaterialFrame()
    {
        return materialFrame_.get();
    }

    void setMaterialFrame(AVFrame* frame)
    {
        materialFrame_ = std::unique_ptr<AVFrame, void (*)(AVFrame*)>(frame, [](AVFrame* frame) {
            av_frame_free(&frame);
        });
    }

    GLfloat getAngleToRotate()
    {
        return angleToRotate_;
    }

    void setAngleToRotate(GLfloat angleToRotate)
    {
        angleToRotate_ = angleToRotate;
    }

private:
    std::unique_ptr<AVFrame, void (*)(AVFrame*)> materialFrame_;
    GLfloat angleToRotate_ {0.0};
};

class TexturesBlendShader : public QSGMaterialShader
{
public:
    TexturesBlendShader();

protected:
    void initialize() override;
    char const* const* attributeNames() const override;
    void updateState(const RenderState& state,
                     QSGMaterial* newEffect,
                     QSGMaterial* oldEffect) override;
    void deactivate() override;

private:
    void initializeTextureYUV(
        QOpenGLFunctions* glFuncs, GLuint textureId, int width, int height, uint8_t* data);
    void initializeTextureNV12(
        QOpenGLFunctions* glFuncs, GLuint textureId, int width, int height, uint8_t* data);

    GLuint textureIds_[4] = {0};
    GLuint uniformTextureSampler2DIds_[4] = {0};

    QString vertexShaderFile_ {":/shader/YUVConv.vert"};
    QString fragmentShaderFile_ {":/shader/YUVConv.frag"};

    // uniform values ids to pass in the shader
    int isNV12Id_;
    int angleToRotateId_;
    int lineSizeWidthScaleFactorsId_;
};

class VideoRenderingItemBase : public QQuickItem
{
    Q_OBJECT

public:
    explicit VideoRenderingItemBase(QQuickItem* parent = 0);
    ~VideoRenderingItemBase();

protected:
    QSGNode* updatePaintNode(QSGNode*, UpdatePaintNodeData*) override;
};
