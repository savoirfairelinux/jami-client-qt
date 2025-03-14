/*
 *  Copyright (C) 2012-2025 Savoir-faire Linux Inc.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "directrenderer.h"

#include "dbus/videomanager.h"
#include "videomanager_interface.h"

#include <QMutex>

namespace lrc {
namespace video {

using namespace lrc::api::video;

struct DirectRenderer::Impl : public QObject
{
    Q_OBJECT
public:
    Impl(DirectRenderer* parent)
        : QObject(nullptr)
        , parent_(parent)
    {
        configureTarget();
        if (!VideoManager::instance().registerSinkTarget(parent_->id(), target))
            qWarning() << "Cannot register " << parent_->id();
    };
    ~Impl()
    {
        parent_->stopRendering();
        VideoManager::instance().registerSinkTarget(parent_->id(), {});
    }

    // sink target callbacks
    void configureTarget()
    {
        using namespace std::placeholders;
        target.pull = std::bind(&Impl::pullCallback, this);
        target.push = std::bind(&Impl::pushCallback, this, _1);
    };

    libjami::FrameBuffer pullCallback()
    {
        QMutexLocker lk(&mutex);
        if (!frameBufferPtr) {
            frameBufferPtr.reset(av_frame_alloc());
        }

        // A response to this signal should be used to provide client
        // allocated buffer specs via the AVFrame structure.
        // Important: Subscription to this signal MUST be synchronous(Qt::DirectConnection).
        Q_EMIT parent_->frameBufferRequested(frameBufferPtr.get());

        if (frameBufferPtr->format == AV_PIX_FMT_NONE) {
            return nullptr;
        }

        return std::move(frameBufferPtr);
    };

    void pushCallback(libjami::FrameBuffer buf)
    {
        {
            QMutexLocker lk(&mutex);
            frameBufferPtr = std::move(buf);
        }

        parent_->updateFpsTracker();
        Q_EMIT parent_->frameUpdated();
    };

private:
    DirectRenderer* parent_;

public:
    libjami::SinkTarget target;
    FpsTracker fpsTracker;
    QMutex mutex;
    libjami::FrameBuffer frameBufferPtr;
};

DirectRenderer::DirectRenderer(const QString& id, const QSize& res)
    : Renderer(id, res)
    , pimpl_(std::make_unique<DirectRenderer::Impl>(this))
{}

DirectRenderer::~DirectRenderer() {}

void
DirectRenderer::startRendering()
{
    Q_EMIT started(size());
}

void
DirectRenderer::stopRendering()
{
    Q_EMIT stopped();
}

Frame
DirectRenderer::currentFrame() const
{
    return {};
}

} // namespace video
} // namespace lrc

#include "moc_directrenderer.cpp"
#include "directrenderer.moc"
