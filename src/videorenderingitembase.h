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

class LRCInstance;

extern "C" {
struct AVFrame;
}

struct VideoRenderingItemBaseRenderConnections
{
    QMetaObject::Connection stopped, updated;
};

class VideoRenderingItemBase : public QQuickFramebufferObject
{
    Q_OBJECT

public:
    enum class Type { PREVIEW, DISTANT, PHOTO };
    Q_ENUM(Type)

    Q_PROPERTY(LRCInstance* lrcInstance MEMBER lrcInstance_ NOTIFY lrcInstanceChanged)
    Q_PROPERTY(
        VideoRenderingItemBase::Type renderingType READ getRenderingType WRITE setRenderingType)
    Q_PROPERTY(QString distantRenderId READ getDistantRenderId WRITE setDistantRenderId NOTIFY
                   distantRenderIdChanged)
    Q_PROPERTY(
        QSize expectedSize READ getExpectedSize WRITE setExpectedSize NOTIFY expectedSizeChanged)

public:
    explicit VideoRenderingItemBase(QQuickItem* parent = 0);
    Renderer* createRenderer() const override;

    Q_INVOKABLE void takePhoto();

    // Setters
    void setRenderingType(VideoRenderingItemBase::Type type);
    void setNeedToUpdateFrame(bool update);
    void setDistantRenderId(QString distantRenderId);
    void setExpectedSize(QSize newSize);
    void setCurrentTextureSize(const QSize& size);
    void setRenderingFinished(bool finished);
    void setAngleRotated(double angle);

    // Getters
    bool getNeedToUpdateFrame();
    VideoRenderingItemBase::Type getRenderingType();
    QString getDistantRenderId();
    QSize getExpectedSize();
    bool getRenderingFinished();
    LRCInstance* getLrcInstance();

    // Get scale factor to map frame size to actual item size
    // used by conference layout
    Q_INVOKABLE float getWidthScaleFactor();
    Q_INVOKABLE float getHeightScaleFactor();

signals:
    void distantRenderIdChanged();
    void expectedSizeChanged();
    void currentTextureSizeChanged();
    void updateParticipantsInfoRequest();
    void photoIsReady(QString photoBase64);
    void lrcInstanceChanged();

private:
    // Recalculate different size according to the changes of parameters
    void recalculateItemSize();

    // Connect to RenderManager
    void connectRenderManager();

    // Disconnect from RenderManager
    void disconnectRenderManager();

private:
    VideoRenderingItemBase::Type renderingType_ {VideoRenderingItemBase::Type::PREVIEW};

    QString distantRenderId_ {""};

    QSharedPointer<QQuickItemGrabResult> photo_ {nullptr};

    bool needToUpdateFrame_ {false};
    bool renderingFinished_ {false};
    double angleRotated_ {0.0};
    QSize currentTextureSize_ {0, 0};
    QSize expectedSize_ {0, 0};

    // LRCInstance pointer
    LRCInstance* lrcInstance_ {nullptr};

    VideoRenderingItemBaseRenderConnections connections_;
};

class TexturesRenderer : public QObject, protected QOpenGLFunctions
{
    Q_OBJECT
public:
    explicit TexturesRenderer(VideoRenderingItemBase::Type type);
    ~TexturesRenderer();

    // Setter
    void setWindow(QQuickWindow* window)
    {
        window_ = window;
    }

    void setDistantRenderId(const QString& id)
    {
        distantRenderId_ = id;
    }

    // Getter
    QSize getTextureSize()
    {
        return textureSize_;
    }

    double getAngleRotated()
    {
        return angleToRotateZ_;
    }

    void initialize();

    void updateFrame(LRCInstance* lrcInstance);
    void clearFrame();
    bool frameIsEmpty();

public slots:
    // Main drawing function
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

    QSize textureSize_;
    QString distantRenderId_ {""};

    // Moved current frame
    std::unique_ptr<AVFrame, void (*)(AVFrame*)> frame_;

    // Uniform values ids
    int isNV12Id_ {0};
    int angleToRotateYId_ {0};
    int angleToRotateZId_ {0};
    int lineSizeWidthScaleFactorsId_ {0};
    int scaleFactorId_ {0};
    GLuint uniformTextureSampler2DIds_[4] = {0};

    // Attribute values ids
    int vertsLocation_ {0};
    int textureLocation_ {0};

    // Uniform values to set into the shader
    bool isNV12_ {false};
    QVector2D scaleFactor_ {1.0, 1.0};
    QVector3D lineSizeWidthScaleFactors_ {1.0, 1.0, 1.0};
    double angleToRotateZ_ {0.0};
    double angleToRotateY_ {0.0};

    // OpenGLTexture storage
    std::unique_ptr<QOpenGLTexture> Ytex_ = nullptr;
    std::unique_ptr<QOpenGLTexture> Utex_ = nullptr;
    std::unique_ptr<QOpenGLTexture> Vtex_ = nullptr;
    std::unique_ptr<QOpenGLTexture> UVtex_NV12_ = nullptr;

    // Item window pointer
    QQuickWindow* window_ = nullptr;

    // Current frame image
    std::unique_ptr<QImage> frameImage_;
};
