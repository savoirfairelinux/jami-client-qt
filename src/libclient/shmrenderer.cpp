/*
 *  Copyright (C) 2012-2024 Savoir-faire Linux Inc.
 *  Author : Emmanuel Lepage Vallee <emmanuel.lepage@savoirfairelinux.com>
 *  Author : Guillaume Roguez <guillaume.roguez@savoirfairelinux.com>
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

#include "shmrenderer.h"

#include "dbus/videomanager.h"

#include <QDebug>
#include <QReadWriteLock>
#include <QThread>

#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/shm.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <semaphore.h>
#include <errno.h>

#ifndef CLOCK_REALTIME
#define CLOCK_REALTIME 0
#endif

namespace lrc {

using namespace api::video;

namespace video {

/* Shared memory object
 * Implementation note: double-buffering
 * Shared memory is divided in two regions, each representing one frame.
 * First byte of each frame is warranted to by aligned on 16 bytes.
 * One region is marked readable: this region can be safely read.
 * The other region is writeable: only the producer can use it.
 */

struct SHMHeader
{
    sem_t mutex;          /*!< Lock it before any operations on following fields.           */
    sem_t frameGenMutex;  /*!< unlocked by producer when frameGen modified                  */
    unsigned frameGen;    /*!< monotonically incremented when a producer changes readOffset */
    unsigned frameSize;   /*!< size in bytes of 1 frame                                     */
    unsigned mapSize;     /*!< size to map if you need to see all data                      */
    unsigned readOffset;  /*!< offset of readable frame in data                             */
    unsigned writeOffset; /*!< offset of writable frame in data                             */

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
    uint8_t data[]; /*!< the whole shared memory                                      */
#pragma GCC diagnostic pop
};

struct ShmRenderer::Impl final : public QObject
{
    Q_OBJECT
public:
    Impl(ShmRenderer* parent)
        : QObject(nullptr)
        , parent_(parent)
        , fd(-1)
        , shmArea((SHMHeader*) MAP_FAILED)
        , shmAreaLen(0)
        , frameGen(0)
    {
        VideoManager::instance().startShmSink(parent_->id(), true);

        // Continuously check for new frames on a separate thread.
        // This is necessary because the frame rate is not constant.
        // The function getNewFrame() will return false if no new frame is available.
        thread = QThread::create([this] {
            running = true;
            forever {
                if (QThread::currentThread()->isInterruptionRequested()) {
                    return;
                }

                if (!waitForNewFrame() || !running) {
                    continue;
                }

                parent_->updateFpsTracker();
                Q_EMIT parent_->frameUpdated();
            }
        });
    };
    ~Impl() {} // Thread is stopped by parent in ShmRenderer::stopShm.

    void stopThread()
    {
        // Request thread loop interruption and then unblock the sem_wait.
        thread->requestInterruption();

        // Set the frameSize to 0 and notify so that the thread loop can exit
        // without emitting the frameUpdated signal for an invalid resolution
        // (e.g. smartphone rotation).
        // This works as ShmHolder::renderFrame should reset frameSize appropriately.
        // However, the daemon may change the frameSize to 0 after we set it to 0 and
        // before the frameSize is checked in the thread loop. So we use the running
        // flag to make sure the thread loop exits without calling frameUpdated.
        running = false;

        shmLock();
        shmArea->frameSize = 0;
        shmUnlock();

        ::sem_post(&shmArea->frameGenMutex);

        thread->wait();
    }

    // Lock the memory while the copy is being made
    bool shmLock()
    {
        return ::sem_wait(&shmArea->mutex) >= 0;
    };

    // Remove the lock, allow a new frame to be drawn
    void shmUnlock()
    {
        ::sem_post(&shmArea->mutex);
    };

    // Wait for new frame data from shared memory and save pointer.
    bool waitForNewFrame()
    {
        if (!shmLock())
            return false;

        if (frameGen == shmArea->frameGen) {
            shmUnlock();

            if (::sem_wait(&shmArea->frameGenMutex) < 0)
                return false;

            if (!shmLock())
                return false;
        }

        // valid frame to render (daemon may have stopped)?
        if (!shmArea->frameSize) {
            shmUnlock();
            return false;
        }

        // map frame data
        if (!remapShm()) {
            qDebug() << "Could not resize shared memory";
            return false;
        }

        {
            QWriteLocker lk {&frameMutex};
            if (not frame)
                frame.reset(new lrc::api::video::Frame);
            frame->ptr = shmArea->data + shmArea->readOffset;
            frame->size = shmArea->frameSize;
        }

        frameGen = shmArea->frameGen;

        shmUnlock();
        return true;
    };

    // Remap the shared memory.
    // Shared memory is in an unlocked state if returns false (resize failed).
    bool remapShm()
    {
        // This loop handles case where daemon resize shared memory
        // during time we unlock it for remapping.
        while (shmAreaLen != shmArea->mapSize) {
            auto mapSize = shmArea->mapSize;
            shmUnlock();

            if (::munmap(shmArea, shmAreaLen)) {
                qDebug() << "Could not unmap shared area: " << strerror(errno);
                return false;
            }

            shmArea
                = (SHMHeader*) ::mmap(nullptr, mapSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

            if (shmArea == MAP_FAILED) {
                qDebug() << "Could not remap shared area: " << strerror(errno);
                return false;
            }

            if (!shmLock())
                return false;

            shmAreaLen = mapSize;
        }

        return true;
    };

private:
    ShmRenderer* parent_;

public:
    QString path;
    int fd;
    SHMHeader* shmArea;
    unsigned shmAreaLen;
    uint frameGen;

    QReadWriteLock frameMutex;
    QThread* thread;
    std::atomic<bool> running {false};
    std::shared_ptr<lrc::api::video::Frame> frame;
};

ShmRenderer::ShmRenderer(const QString& id, const QSize& res, const QString& shmPath)
    : Renderer(id, res)
    , pimpl_(std::make_unique<ShmRenderer::Impl>(this))
{
    pimpl_->path = shmPath;
}

ShmRenderer::~ShmRenderer()
{
    stopShm();
    VideoManager::instance().startShmSink(id(), false);
}

Frame
ShmRenderer::currentFrame() const
{
    QReadLocker lk {&pimpl_->frameMutex};
    if (auto frame_ptr = pimpl_->frame)
        return std::move(*frame_ptr);
    return {};
}

bool
ShmRenderer::startShm()
{
    if (pimpl_->fd != -1) {
        qWarning() << "fd must be -1";
        return false;
    }

    pimpl_->fd = ::shm_open(pimpl_->path.toLatin1(), O_RDWR, 0);

    if (pimpl_->fd < 0) {
        qWarning() << "could not open shm area" << pimpl_->path
                   << ", shm_open failed:" << strerror(errno);
        return false;
    }

    // Map only header data
    const auto mapSize = sizeof(SHMHeader);
    pimpl_->shmArea
        = (SHMHeader*) ::mmap(nullptr, mapSize, PROT_READ | PROT_WRITE, MAP_SHARED, pimpl_->fd, 0);

    if (pimpl_->shmArea == MAP_FAILED) {
        qWarning() << "Could not remap shared area";
        return false;
    }

    pimpl_->shmAreaLen = mapSize;
    pimpl_->thread->start();
    return true;
}

void
ShmRenderer::stopShm()
{
    if (pimpl_->fd < 0)
        return;

    pimpl_->stopThread();

    // Emit the signal before closing the file, this lower the risk of invalid
    // memory access
    Q_EMIT stopped();

    {
        QWriteLocker lk(&pimpl_->frameMutex);
        // reset the frame so it doesn't point to an old value
        pimpl_->frame.reset();
    }

    ::close(pimpl_->fd);
    pimpl_->fd = -1;

    if (pimpl_->shmArea == MAP_FAILED)
        return;

    ::munmap(pimpl_->shmArea, pimpl_->shmAreaLen);
    pimpl_->shmAreaLen = 0;
    pimpl_->shmArea = (SHMHeader*) MAP_FAILED;
}

void
ShmRenderer::startRendering()
{
    if (!startShm())
        return;

    Q_EMIT started(size());
}

// Done on destroy instead
void
ShmRenderer::stopRendering()
{}

} // namespace video
} // namespace lrc

#include "moc_shmrenderer.cpp"
#include "shmrenderer.moc"
