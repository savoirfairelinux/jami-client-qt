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

class VideoRenderingItemBase : public QQuickFramebufferObject
{
    Q_OBJECT

public:
    enum class Type { PREVIEW, DISTANT };

    explicit VideoRenderingItemBase(QQuickItem* parent = 0);
    Renderer* createRenderer() const Q_DECL_OVERRIDE;

    void setNeedToUpdateFrame(bool update)
    {
        needToUpdateFrame_ = update;
    }

    bool getNeedToUpdateFrame()
    {
        return needToUpdateFrame_;
    }

    VideoRenderingItemBase::Type getRenderingType()
    {
        return renderingType_;
    }

private:
    VideoRenderingItemBase::Type renderingType_ {VideoRenderingItemBase::Type::PREVIEW};
    bool needToUpdateFrame_ {false};
};

class TexturesRenderer : public QObject, protected QOpenGLFunctions
{
    Q_OBJECT
public:
    explicit TexturesRenderer(VideoRenderingItemBase::Type type);
    ~TexturesRenderer();

    // Set current Item size
    void setItemSize(QSize size)
    {
        itemSize_ = size;
    }

    // Set the window of the Item
    void setWindow(QQuickWindow* window)
    {
        window_ = window;
    }

    // Get the Item size to be expected from renderer side
    QSize getExpectedItemSize()
    {
        return expectedItemSize_;
    }

    void initialize();
    void updateFrame();

public slots:
    void paint();

private:
    void initializeShaderProgram();
    void initializeAllTextures();
    void initializeTextureYUV(QOpenGLTexture* texture, int width, int height, uint8_t* data);
    void initializeTextureNV12(QOpenGLTexture* texture, int width, int height, uint8_t* data);

    void bindTextures();
    void releaseTextures();
    void clearTextures();

    VideoRenderingItemBase::Type renderType_ {VideoRenderingItemBase::Type::PREVIEW};

    QMutex drawMutex_;
    QMutex textureMutex_;

    QString vertexShaderFile_ {":/shader/YUVConv.vert"};
    QString fragmentShaderFile_ {":/shader/YUVConv.frag"};
    std::unique_ptr<QOpenGLShaderProgram> shaderProgram_ = nullptr;

    GLuint uniformTextureSampler2DIds_[4] = {0};
    std::unique_ptr<AVFrame, void (*)(AVFrame*)> frame_;

    // uniform values ids to pass in the shader
    int isNV12Id_ {0};
    int angleToRotateId_ {0};
    int lineSizeWidthScaleFactorsId_ {0};

    // attribute values ids
    int vertsLocation_ {0};
    int textureLocation_ {0};

    // values
    QSize itemSize_ {0, 0};
    QSize expectedItemSize_ {0, 0};
    bool isNV12_ {false};
    QVector3D lineSizeWidthScaleFactors_ {1.0, 1.0, 1.0};
    double angleToRotate_ {180.0};

    std::unique_ptr<QOpenGLTexture> Ytex_ = nullptr;
    std::unique_ptr<QOpenGLTexture> Utex_ = nullptr;
    std::unique_ptr<QOpenGLTexture> Vtex_ = nullptr;
    std::unique_ptr<QOpenGLTexture> UVtex_NV12_ = nullptr;

    // item window pointer
    QQuickWindow* window_ = nullptr;
};
