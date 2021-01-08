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

#include <QOpenGLFramebufferObject>

#include "lrcinstance.h"

// clang-format off
static const GLfloat vertexVertices[] = {
	-1.0f, -1.0f,
	 1.0f, -1.0f,
	 -1.0f, 1.0f,
	 1.0f, 1.0f,
};

static const GLfloat textureVertices[] = {
	0.0f,  1.0f,
	1.0f,  1.0f,
	0.0f,  0.0f,
	1.0f,  0.0f,
};
// clang-format on

// VideoRenderingItemBaseRenderer
class VideoRenderingItemBaseRenderer : public QQuickFramebufferObject::Renderer
{
public:
    VideoRenderingItemBaseRenderer() {}

    void synchronize(QQuickFramebufferObject* item) override
    {
        VideoRenderingItemBase* i = static_cast<VideoRenderingItemBase*>(item);

        // Set up TexturesRenderer
        if (!render_)
            render_ = std::make_unique<TexturesRenderer>(i->getRenderingType());

        // Clear frame when needed
        if (i->getRenderingFinished()) {
            render_->clearFrame();
            i->setRenderingFinished(false);
            return;
        }

        // Set distant rendering id
        if (!i->getDistantRenderId().isEmpty())
            render_->setDistantRenderId(i->getDistantRenderId());

        // Update frame when needed
        if (i->getNeedToUpdateFrame())
            render_->updateFrame();
        i->setNeedToUpdateFrame(false);

        // Pass window pointer
        render_->setWindow(i->window());

        // Start to initialize
        render_->initialize();

        // Pass initialized value into VideoRenderingItemBase
        i->setAngleRotated(render_->getAngleRotated());
        i->setCurrentTextureSize(render_->getTextureSize());
    }

    void render() override
    {
        render_->paint();
    }

    QOpenGLFramebufferObject* createFramebufferObject(const QSize& size) override
    {
        QOpenGLFramebufferObjectFormat format;
        format.setSamples(4);
        format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
        return new QOpenGLFramebufferObject(size, format);
    }

private:
    std::unique_ptr<TexturesRenderer> render_ = nullptr;
};

// VideoRenderingItemBase
VideoRenderingItemBase::VideoRenderingItemBase(QQuickItem* parent)
    : QQuickFramebufferObject(parent)
{
    // Only items which specify QQuickItem::ItemHasContents
    // are allowed to call QQuickItem::update().
    setFlag(QQuickItem::ItemHasContents);

    setRenderingType(renderingType_);
}

void
VideoRenderingItemBase::recalculateItemSize()
{
    if (currentTextureSize_.isEmpty()) {
        QQmlProperty::write(this, "width", expectedSize_.width());
        QQmlProperty::write(this, "height", expectedSize_.height());

        return;
    }

    if ((fmod(angleRotated_, 360.0) >= 45.0 && fmod(angleRotated_, 360.0) <= 135.0)
        || (fmod(angleRotated_, 360.0) >= 225.0 && fmod(angleRotated_, 360.0) <= 315.0)) {
        currentTextureSize_.transpose();
    }

    // Calculate the final size
    float dPictureAspectRatio = static_cast<float>(currentTextureSize_.width())
                                / static_cast<float>(currentTextureSize_.height());
    float dAspectRatio = static_cast<float>(expectedSize_.width())
                         / static_cast<float>(expectedSize_.height());

    if (dPictureAspectRatio > dAspectRatio) {
        QQmlProperty::write(this, "width", expectedSize_.width());
        QQmlProperty::write(this,
                            "height",
                            expectedSize_.width() * currentTextureSize_.height()
                                / currentTextureSize_.width());
    } else if (dPictureAspectRatio < dAspectRatio) {
        QQmlProperty::write(this,
                            "width",
                            expectedSize_.height() * currentTextureSize_.width()
                                / currentTextureSize_.height());
        QQmlProperty::write(this, "height", expectedSize_.height());
    }

    emit updateParticipantsInfoRequest();
}

QQuickFramebufferObject::Renderer*
VideoRenderingItemBase::createRenderer() const
{
    return new VideoRenderingItemBaseRenderer;
}

// Setters
void
VideoRenderingItemBase::setRenderingType(VideoRenderingItemBase::Type type)
{
    renderingType_ = type;

    disconnect(connections_.stopped);
    disconnect(connections_.updated);

    if (renderingType_ == VideoRenderingItemBase::Type::PREVIEW) {
        connections_.updated = connect(LRCInstance::renderer(),
                                       &RenderManager::previewAvFrameUpdated,
                                       [this]() {
                                           if (isVisible()) {
                                               setNeedToUpdateFrame(true);
                                               update();
                                           }
                                       });

        connect(LRCInstance::renderer(), &RenderManager::previewRenderingStopped, [this]() {
            setRenderingFinished(true);

            //// force redraw (can be removed)
            //// cause warnings since will not be in GUI thread
            // update();
        });
    } else {
        connections_.updated = connect(LRCInstance::renderer(),
                                       &RenderManager::avDistantFrameUpdated,
                                       [this](const QString& id) {
                                           if (distantRenderId_ == id && isVisible()) {
                                               setNeedToUpdateFrame(true);
                                               update();
                                           }
                                       });

        connect(LRCInstance::renderer(),
                &RenderManager::distantRenderingStopped,
                [this](const QString& id) {
                    if (distantRenderId_ == id) {
                        setRenderingFinished(true);

                        //// force redraw (can be removed)
                        //// cause warnings since will not be in GUI thread
                        // update();
                    }
                });
    }
}

void
VideoRenderingItemBase ::setNeedToUpdateFrame(bool update)
{
    needToUpdateFrame_ = update;
}

void
VideoRenderingItemBase::setDistantRenderId(QString distantRenderId)
{
    if (distantRenderId_ != distantRenderId) {
        distantRenderId_ = distantRenderId;

        emit distantRenderIdChanged();

        update();
    }
}

void
VideoRenderingItemBase::setExpectedSize(QSize newSize)
{
    if (expectedSize_ != newSize) {
        expectedSize_ = newSize;

        recalculateItemSize();

        emit expectedSizeChanged();
    }
}

void
VideoRenderingItemBase::setCurrentTextureSize(const QSize& size)
{
    if (currentTextureSize_ != size) {
        currentTextureSize_ = size;

        recalculateItemSize();

        emit currentTextureSizeChanged();
    }
}

void
VideoRenderingItemBase::setRenderingFinished(bool finished)
{
    renderingFinished_ = finished;
}

void
VideoRenderingItemBase::setAngleRotated(double angle)
{
    if (angleRotated_ != angle) {
        angleRotated_ = angle;

        recalculateItemSize();
    }
}

// Getters
bool
VideoRenderingItemBase::getNeedToUpdateFrame()
{
    return needToUpdateFrame_;
}

VideoRenderingItemBase::Type
VideoRenderingItemBase::getRenderingType()
{
    return renderingType_;
}

QString
VideoRenderingItemBase::getDistantRenderId()
{
    return distantRenderId_;
}

QSize
VideoRenderingItemBase::getExpectedSize()
{
    return expectedSize_;
}

bool
VideoRenderingItemBase::getRenderingFinished()
{
    return renderingFinished_;
}

Q_INVOKABLE float
VideoRenderingItemBase::getWidthScaleFactor()
{
    return static_cast<float>(width()) / static_cast<float>(currentTextureSize_.width());
}

Q_INVOKABLE float
VideoRenderingItemBase::getHeightScaleFactor()
{
    return static_cast<float>(height()) / static_cast<float>(currentTextureSize_.height());
}

// TexturesRenderer
TexturesRenderer::TexturesRenderer(VideoRenderingItemBase::Type type)
    : renderType_(type)
    , frame_ {nullptr,
              [](AVFrame* frame) {
                  av_frame_free(&frame);
              }}
    , Ytex_(std::make_unique<QOpenGLTexture>(QOpenGLTexture::Target::Target2D))
    , Utex_(std::make_unique<QOpenGLTexture>(QOpenGLTexture::Target::Target2D))
    , Vtex_(std::make_unique<QOpenGLTexture>(QOpenGLTexture::Target::Target2D))
    , UVtex_NV12_(std::make_unique<QOpenGLTexture>(QOpenGLTexture::Target::Target2D))
{}

TexturesRenderer::~TexturesRenderer() {}

void
TexturesRenderer::initialize()
{
    initializeShaderProgram();
    initializeAllTextures();
}

void
TexturesRenderer::initializeShaderProgram()
{
    if (!shaderProgram_) {
        // Init shader
        initializeOpenGLFunctions();
        shaderProgram_ = std::make_unique<QOpenGLShaderProgram>();
        bool vertexShaderFileLoaded = shaderProgram_->addShaderFromSourceFile(QOpenGLShader::Vertex,
                                                                              vertexShaderFile_);
        bool fragmentShaderFileLoaded
            = shaderProgram_->addShaderFromSourceFile(QOpenGLShader::Fragment, fragmentShaderFile_);

        if (!vertexShaderFileLoaded || !fragmentShaderFileLoaded) {
            qDebug() << "Shader loaded failed!";
            return;
        }

        shaderProgram_->link();

        // Bind shader
        shaderProgram_->bind();

        // Set up shader variable ids
        angleToRotateId_ = shaderProgram_->uniformLocation("aAngleToRotate");
        lineSizeWidthScaleFactorsId_ = shaderProgram_->uniformLocation(
            "vTextureCoordScalingFactors");
        isNV12Id_ = shaderProgram_->uniformLocation("isNV12");

        uniformTextureSampler2DIds_[0] = shaderProgram_->uniformLocation("Ytex");
        uniformTextureSampler2DIds_[1] = shaderProgram_->uniformLocation("Utex");
        uniformTextureSampler2DIds_[2] = shaderProgram_->uniformLocation("Vtex");
        uniformTextureSampler2DIds_[3] = shaderProgram_->uniformLocation("UVtex_NV12");

        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[0], 0);
        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[1], 1);
        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[2], 2);
        shaderProgram_->setUniformValue(uniformTextureSampler2DIds_[3], 3);

        vertsLocation_ = shaderProgram_->attributeLocation("aPosition");
        textureLocation_ = shaderProgram_->attributeLocation("aTextureCoord");

        // Unbind shader
        shaderProgram_->release();
    }
}

void
TexturesRenderer::initializeAllTextures()
{
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_DEPTH_TEST);

    if (frameIsEmpty()) {
        return;
    }

    clearTextures();

    angleToRotate_ = 180.0;
    textureSize_ = QSize(frame_->width, frame_->height);
    if (auto matrix = av_frame_get_side_data(frame_.get(), AV_FRAME_DATA_DISPLAYMATRIX)) {
        const int32_t* data = reinterpret_cast<int32_t*>(matrix->data);
        auto angle = av_display_rotation_get(data);
        angleToRotate_ = angle != 0 ? angle : angleToRotate_;
    }

    if (frame_->linesize[0] && frame_->linesize[1] && frame_->linesize[2]) {
        isNV12_ = false;

        if (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV420P
            || AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV422P
            || AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV444P) {
            // Y
            initializeTextureYUV(Ytex_.get(), frame_->linesize[0], frame_->height, frame_->data[0]);
            // U
            initializeTextureYUV(Utex_.get(),
                                 frame_->linesize[1],
                                 (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV420P
                                      ? 0.5
                                      : 1)
                                     * frame_->height,
                                 frame_->data[1]);
            // V
            initializeTextureYUV(Vtex_.get(),
                                 frame_->linesize[2],
                                 (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV420P
                                      ? 0.5
                                      : 1)
                                     * frame_->height,
                                 frame_->data[2]);

            lineSizeWidthScaleFactors_.setX((GLfloat) frame_->width / (GLfloat) frame_->linesize[0]);
            lineSizeWidthScaleFactors_.setY(
                (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV444P ? 1 : 0.5)
                * ((GLfloat) frame_->width / (GLfloat) frame_->linesize[1]));
            lineSizeWidthScaleFactors_.setZ(
                (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_YUV444P ? 1 : 0.5)
                * ((GLfloat) frame_->width / (GLfloat) frame_->linesize[2]));
        }
    }

    if (frame_->linesize[0] && frame_->linesize[1]) {
        // the format is NV12
        if (AVPixelFormat(frame_->format) == AVPixelFormat::AV_PIX_FMT_NV12) {
            isNV12_ = true;
            initializeTextureYUV(Ytex_.get(), frame_->linesize[0], frame_->height, frame_->data[0]);

            initializeTextureNV12(UVtex_NV12_.get(),
                                  frame_->linesize[1],
                                  frame_->height / 2,
                                  frame_->data[1]);
        }
    }
}

void
TexturesRenderer::paint()
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Make sure that textures are initialized when rendering
    if (!Ytex_->isCreated()) {
        window_->resetOpenGLState();
        return;
    }

    shaderProgram_->bind();

    shaderProgram_->setUniformValue(angleToRotateId_, static_cast<float>(angleToRotate_));
    shaderProgram_->setUniformValue(lineSizeWidthScaleFactorsId_, lineSizeWidthScaleFactors_);
    shaderProgram_->setUniformValue(isNV12Id_, isNV12_);

    shaderProgram_->enableAttributeArray(vertsLocation_);
    shaderProgram_->enableAttributeArray(textureLocation_);

    shaderProgram_->setAttributeArray(vertsLocation_, GL_FLOAT, vertexVertices, 2);
    shaderProgram_->setAttributeArray(textureLocation_, GL_FLOAT, textureVertices, 2);

    bindTextures();

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    releaseTextures();

    shaderProgram_->disableAttributeArray(textureLocation_);
    shaderProgram_->disableAttributeArray(vertsLocation_);

    shaderProgram_->release();

    window_->resetOpenGLState();
}

void
TexturesRenderer::updateFrame()
{
    if (renderType_ == VideoRenderingItemBase::Type::PREVIEW)
        frame_.reset(LRCInstance::renderer()->getPreviewAVFrame());
    else
        frame_.reset(LRCInstance::renderer()->getAVFrame(distantRenderId_));
}

void
TexturesRenderer::clearFrame()
{
    frame_.reset(nullptr);
    clearTextures();
}

void
TexturesRenderer::initializeTextureYUV(QOpenGLTexture* texture, int width, int height, uint8_t* data)
{
    texture->setMagnificationFilter(QOpenGLTexture::Linear);
    texture->setMinificationFilter(QOpenGLTexture::Nearest);
    texture->setWrapMode(QOpenGLTexture::ClampToEdge);
    texture->setSize(width, height);
    texture->setFormat(QOpenGLTexture::LuminanceFormat);
    texture->create();
    texture->allocateStorage();

    texture->setData(0, 0, QOpenGLTexture::Luminance, QOpenGLTexture::PixelType::UInt8, data);
}

void
TexturesRenderer::initializeTextureNV12(QOpenGLTexture* texture,
                                        int width,
                                        int height,
                                        uint8_t* data)
{
    texture->setMagnificationFilter(QOpenGLTexture::Linear);
    texture->setMinificationFilter(QOpenGLTexture::Nearest);
    texture->setWrapMode(QOpenGLTexture::ClampToEdge);
    texture->setSize(width, height);
    texture->setFormat(QOpenGLTexture::RG8_UNorm);
    texture->create();
    texture->allocateStorage();

    texture->setData(0, 0, QOpenGLTexture::RG, QOpenGLTexture::PixelType::UInt8, data);
}

void
TexturesRenderer::bindTextures()
{
    Ytex_->bind(0);

    if (isNV12_) {
        UVtex_NV12_->bind(3);
    } else {
        Utex_->bind(1);

        Vtex_->bind(2);
    }
}

void
TexturesRenderer::releaseTextures()
{
    Ytex_->release();

    if (isNV12_) {
        UVtex_NV12_->release();
    } else {
        Utex_->release();

        Vtex_->release();
    }
}

void
TexturesRenderer::clearTextures()
{
    if (Ytex_ && Ytex_->isCreated()) {
        Ytex_->destroy();
    }
    if (Utex_ && Utex_->isCreated()) {
        Utex_->destroy();
    }
    if (Vtex_ && Vtex_->isCreated()) {
        Vtex_->destroy();
    }
    if (UVtex_NV12_ && UVtex_NV12_->isCreated()) {
        UVtex_NV12_->destroy();
    }
}

bool
TexturesRenderer::frameIsEmpty()
{
    return (!frame_ || !frame_->width || !frame_->height);
}
