/*
 * Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

#include "avadapter.h"
#include "qtutils.h"

#include "api/codecmodel.h"
#include "api/devicemodel.h"

#ifdef Q_OS_LINUX
#include "screencastportal.h"
#include "xrectsel.h"
#ifndef ENABLE_LIBWRAP
#include <sys/prctl.h>
#endif
#endif

#include <QtConcurrent/QtConcurrent>
#include <QApplication>
#include <QPainter>
#include <QScreen>

#include <media_const.h>

AvAdapter::AvAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
    , rendererInformationListModel_(std::make_unique<RendererInformationListModel>())
{
    set_renderersInfoList(QVariant::fromValue(rendererInformationListModel_.get()));

    set_muteScreenshareAudio(true);

    connect(&lrcInstance_->avModel(), &lrc::api::AVModel::audioDeviceEvent, this, &AvAdapter::onAudioDeviceEvent);
    // QueuedConnection mandatory to avoid deadlock
    connect(&lrcInstance_->avModel(),
            &lrc::api::AVModel::rendererStarted,
            this,
            &AvAdapter::onRendererStarted,
            Qt::QueuedConnection);
    connect(&lrcInstance_->avModel(), &lrc::api::AVModel::rendererStopped, this, &AvAdapter::onRendererStopped);
    connect(&lrcInstance_->avModel(), &lrc::api::AVModel::onRendererFpsChange, this, &AvAdapter::updateRenderersFPSInfo);
#ifdef Q_OS_LINUX
    connect(&lrcInstance_->behaviorController(),
            &BehaviorController::callStatusChanged,
            this,
            &AvAdapter::onCallStatusChanged);
#endif
}

// The top left corner of primary screen is (0, 0).
// For Qt, QScreen geometry contains x, y location relative to primary screen.
// The purpose of the function is to use calculate a boundingRect for virtual desktop
// to help screen sharing.
const QRect
AvAdapter::getAllScreensBoundingRect()
{
    auto screens = QGuiApplication::screens();

    // p0 is for x axis, p1 is for y axis,
    // points contain values that are the maximum positive and negative domain value
    QPoint p0(0, 0), p1(0, 0);

    for (auto scr : screens) {
        auto devicePixelRatio = scr->devicePixelRatio();
        auto screenRect = scr->geometry();

        if (screenRect.y() < 0 && p1.y() < abs(screenRect.y()))
            p1.setY(abs(screenRect.y()));
        else if (screenRect.y() >= 0 && p1.x() < screenRect.y() + screenRect.height() * devicePixelRatio)
            p1.setX(screenRect.y() + screenRect.height() * devicePixelRatio);

        if (screenRect.x() < 0 && p0.y() < abs(screenRect.x()))
            p0.setY(abs(screenRect.x()));
        else if (screenRect.x() >= 0 && p0.x() < screenRect.x() + screenRect.width() * devicePixelRatio)
            p0.setX(screenRect.x() + screenRect.width() * devicePixelRatio);
    }

    return QRect(-p0.y(), -p1.y(), p0.y() + p0.x(), p1.y() + p1.x());
}

void
AvAdapter::shareEntireScreen(int screenNumber, bool muteAudio)
{
    QScreen* screen = QGuiApplication::screens().at(screenNumber);
    if (!screen)
        return;
    QRect rect = screen->geometry();
#ifdef WIN32
    rect.moveRight(rect.right() - rect.left() + 1);
    rect.moveLeft(0);
    rect.moveBottom(rect.bottom() - rect.top() + 1);
    rect.moveTop(0);
#endif

    auto resource = lrcInstance_->getCurrentCallModel()->getDisplay(getScreenNumber(screenNumber),
                                                                    rect.x(),
                                                                    rect.y(),
                                                                    rect.width() * screen->devicePixelRatio(),
                                                                    rect.height() * screen->devicePixelRatio());
    auto callId = lrcInstance_->getCurrentCallId();
    muteCamera_ = !isCapturing();
    lrcInstance_->getCurrentCallModel()->addMedia(callId,
                                                  resource,
                                                  lrc::api::CallModel::MediaRequestType::SCREENSHARING,
                                                  muteAudio);
}

#ifdef Q_OS_LINUX
static std::map<QString, std::unique_ptr<ScreenCastPortal>> callPortal;

void
AvAdapter::onCallStatusChanged(const QString& accountId, const QString& callId)
{
    auto& accInfo = lrcInstance_->accountModel().getAccountInfo(accountId);
    auto& callModel = accInfo.callModel;
    const auto call = callModel->getCall(callId);

    if (call.status == lrc::api::call::Status::ENDED) {
        closePortal(callId);
    }
}

void
AvAdapter::closePortal(const QString& callId)
{
    if (callPortal.count(callId)) {
        lrcInstance_->avModel().stopPreview(callPortal[callId]->videoInputId);
        callPortal.erase(callId);
    }
}

void
AvAdapter::shareWayland(bool entireScreen, bool muteAudio)
{
    QString callId = lrcInstance_->getCurrentCallId();
    closePortal(callId);

    PortalCaptureType captureType = entireScreen ? PortalCaptureType::SCREEN : PortalCaptureType::WINDOW;
    auto portal = std::make_unique<ScreenCastPortal>(captureType);

    int err = portal->getPipewireFd();
    if (err == EACCES) {
        qInfo() << "Unable to share screen: permission denied";
        return;
    } else if (err != 0) {
        qWarning() << "Failed to get PipeWire fd. Error code:" << err;
        return;
    }
    QString resource = QString("%1%2pipewire pid:%3 fd:%4 node:%5")
                           .arg(libjami::Media::VideoProtocolPrefix::DISPLAY)
                           .arg(libjami::Media::VideoProtocolPrefix::SEPARATOR)
                           .arg(getpid())
                           .arg(portal->pipewireFd)
                           .arg(portal->pipewireNode);
#ifndef ENABLE_LIBWRAP
    // If the daemon is running as a separate process, then it is unable to directly use the
    // PipeWire file descriptor opened by the client, so it will attempt to duplicate
    // it using the pidfd_getfd system call. This requires the daemon process to have
    // ptrace permission on the client process. On some systems, this will be true by
    // default (as long as the client and daemon processes have the same uid), but it
    // may not be if the Yama Linux Security Module is used. The call to prctl below
    // will grant permission if the Yama LSM is enabled and set to mode 1.
    //
    // References:
    // https://man7.org/linux/man-pages/man2/pidfd_getfd.2.html
    // https://man7.org/linux/man-pages/man2/prctl.2.html
    // https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/LSM/Yama.rst
    prctl(PR_SET_PTRACER, PR_SET_PTRACER_ANY);
#endif
    // We open the video input here (instead of letting the daemon do it) to ensure
    // that the daemon doesn't try to restart it while we still need it, since this
    // would require getting a new file descriptor for PipeWire.
    portal->videoInputId = lrcInstance_->avModel().startPreview(resource);

    callPortal[callId] = std::move(portal);
    muteCamera_ = !isCapturing();
    lrcInstance_->getCurrentCallModel()->addMedia(callId,
                                                  resource,
                                                  lrc::api::CallModel::MediaRequestType::SCREENSHARING,
                                                  muteAudio);
}

void
AvAdapter::shareEntireScreenWayland(bool muteAudio)
{
    shareWayland(true, muteAudio);
}

void
AvAdapter::shareWindowWayland(bool muteAudio)
{
    shareWayland(false, muteAudio);
}
#endif // Q_OS_LINUX

void
AvAdapter::shareAllScreens(bool muteAudio)
{
    const auto arrangementRect = getAllScreensBoundingRect();

    auto resource = lrcInstance_->getCurrentCallModel()->getDisplay(getScreenNumber(),
                                                                    arrangementRect.x(),
                                                                    arrangementRect.y(),
                                                                    arrangementRect.width(),
                                                                    arrangementRect.height());
    auto callId = lrcInstance_->getCurrentCallId();
    muteCamera_ = !isCapturing();
    lrcInstance_->getCurrentCallModel()->addMedia(callId,
                                                  resource,
                                                  lrc::api::CallModel::MediaRequestType::SCREENSHARING,
                                                  muteAudio);
}

void
AvAdapter::captureScreen(int screenNumber)
{
    std::ignore = QtConcurrent::run([this, screenNumber]() {
        QScreen* screen = QGuiApplication::screens().at(screenNumber);
        if (!screen)
            return;
        /*
         * The screen window id is always 0.
         */
        auto pixmap = screen->grabWindow(0);

        QBuffer buffer;
        buffer.open(QIODevice::WriteOnly);
        pixmap.save(&buffer, "PNG");

        Q_EMIT screenCaptured(screenNumber, Utils::byteArrayToBase64String(buffer.data()));
    });
}

void
AvAdapter::captureAllScreens()
{
    std::ignore = QtConcurrent::run([this]() {
        auto screens = QGuiApplication::screens();

        QList<QPixmap> scrs;
        int width = 0, height = 0, currentPoint = 0;

        for (auto scr : screens) {
            QPixmap pix = scr->grabWindow(0);
            auto devicePixelRatio = scr->devicePixelRatio();
            width += scr->geometry().width() * devicePixelRatio;
            if (height < scr->geometry().height() * devicePixelRatio)
                height = scr->geometry().height() * devicePixelRatio;
            scrs << pix;
        }

        QPixmap final(width, height);
        QPainter painter(&final);
        final.fill(Qt::black);

        for (const auto& scr : scrs) {
            painter.drawPixmap(currentPoint, 0, scr.width(), scr.height(), scr);
            currentPoint += scr.width();
        }

        QBuffer buffer;
        buffer.open(QIODevice::WriteOnly);
        final.save(&buffer, "PNG");
        Q_EMIT screenCaptured(-1, Utils::byteArrayToBase64String(buffer.data()));
    });
}

void
AvAdapter::shareFile(const QString& filePath)
{
    auto callId = lrcInstance_->getCurrentCallId();
    if (!callId.isEmpty()) {
        muteCamera_ = !isCapturing();
        auto resource = QString("%1%2%3")
                            .arg(libjami::Media::VideoProtocolPrefix::FILE)
                            .arg(libjami::Media::VideoProtocolPrefix::SEPARATOR)
                            .arg(QUrl(filePath).toLocalFile());

        Utils::oneShotConnect(&lrcInstance_->avModel(),
                              &lrc::api::AVModel::fileOpened,
                              this,
                              [this, callId, filePath, resource](bool hasAudio, bool hasVideo) {
                                  lrcInstance_->avModel().setAutoRestart(resource, true);
                                  lrcInstance_->getCurrentCallModel()
                                      ->addMedia(callId,
                                                 filePath,
                                                 lrc::api::CallModel::MediaRequestType::FILESHARING,
                                                 false,
                                                 hasAudio);
                                  lrcInstance_->avModel().pausePlayer(resource, false);
                              });

        lrcInstance_->avModel().createMediaPlayer(resource);
    }
}

void
AvAdapter::shareScreenArea(unsigned x, unsigned y, unsigned width, unsigned height, bool muteAudio)
{
    muteCamera_ = !isCapturing();
#ifdef Q_OS_LINUX
    // xrectsel will freeze all displays too fast so that the call
    // context menu will not be closed even closed signal is emitted
    // use timer to wait until popup is closed
    QTimer::singleShot(100, this, [=]() mutable {
        x = y = width = height = 0;
        xrectsel(&x, &y, &width, &height);
        auto resource = lrcInstance_->getCurrentCallModel()->getDisplay(getScreenNumber(),
                                                                        x,
                                                                        y,
                                                                        width < 128 ? 128 : width,
                                                                        height < 128 ? 128 : height);
        auto callId = lrcInstance_->getCurrentCallId();
        lrcInstance_->getCurrentCallModel()->addMedia(callId,
                                                      resource,
                                                      lrc::api::CallModel::MediaRequestType::SCREENSHARING,
                                                      muteAudio);
    });
#else
    auto resource = lrcInstance_->getCurrentCallModel()->getDisplay(getScreenNumber(),
                                                                    x,
                                                                    y,
                                                                    width < 128 ? 128 : width,
                                                                    height < 128 ? 128 : height);
    auto callId = lrcInstance_->getCurrentCallId();
    lrcInstance_->getCurrentCallModel()->addMedia(callId,
                                                  resource,
                                                  lrc::api::CallModel::MediaRequestType::SCREENSHARING,
                                                  muteAudio);
#endif
}

void
AvAdapter::shareWindow(const QString& windowProcessId, const QString& windowId, const int fps, bool muteAudio)
{
    auto resource = lrcInstance_->getCurrentCallModel()->getDisplay(windowProcessId, windowId, fps);
    auto callId = lrcInstance_->getCurrentCallId();

    muteCamera_ = !isCapturing();
    lrcInstance_->getCurrentCallModel()->addMedia(callId,
                                                  resource,
                                                  lrc::api::CallModel::MediaRequestType::SCREENSHARING,
                                                  muteAudio);
}

QString
AvAdapter::getSharingResource(int screenId, const QString& windowProcessId, const QString& windowId, const int fps)
{
    if (screenId == -1) {
        const auto arrangementRect = getAllScreensBoundingRect();

        return lrcInstance_->getCurrentCallModel()->getDisplay(getScreenNumber(),
                                                               arrangementRect.x(),
                                                               arrangementRect.y(),
                                                               arrangementRect.width(),
                                                               arrangementRect.height());
    } else if (screenId > -1) {
        QScreen* screen = QGuiApplication::screens().at(screenId);
        if (!screen)
            return "";
        QRect rect = screen->geometry();

#ifdef WIN32
        rect.moveRight(rect.right() - rect.left() + 1);
        rect.moveLeft(0);
        rect.moveBottom(rect.bottom() - rect.top() + 1);
        rect.moveTop(0);
#endif

        return lrcInstance_->getCurrentCallModel()->getDisplay(getScreenNumber(screenId),
                                                               rect.x(),
                                                               rect.y(),
                                                               rect.width() * screen->devicePixelRatio(),
                                                               rect.height() * screen->devicePixelRatio());
    } else if (!windowId.isEmpty()) {
        return lrcInstance_->getCurrentCallModel()->getDisplay(windowProcessId, windowId, fps);
    }

    return "";
}

void
AvAdapter::getListWindows()
{
    auto map = lrcInstance_->avModel().getListWindows();
    set_windowsNames(map.keys());
    set_windowsIds(map.values());
}

void
AvAdapter::stopSharing(const QString& source)
{
    auto callId = lrcInstance_->getCurrentCallId();
#ifdef Q_OS_LINUX
    closePortal(callId);
#endif
    if (!source.isEmpty() && !callId.isEmpty()) {
        if (source.startsWith(libjami::Media::VideoProtocolPrefix::DISPLAY)) {
            qDebug() << "Stopping display: " << source;
            lrcInstance_->getCurrentCallModel()->removeMedia(callId,
                                                             libjami::Media::Details::MEDIA_TYPE_VIDEO,
                                                             libjami::Media::VideoProtocolPrefix::DISPLAY,
                                                             muteCamera_,
                                                             true);
        } else {
            qDebug() << "Stopping file: " << source;
            lrcInstance_->getCurrentCallModel()->removeMedia(callId,
                                                             libjami::Media::Details::MEDIA_TYPE_VIDEO,
                                                             libjami::Media::VideoProtocolPrefix::FILE,
                                                             muteCamera_,
                                                             true);
        }
    }
}

void
AvAdapter::toggleScreenshareAudio(bool mute)
{
    auto callId = lrcInstance_->getCurrentCallId();
    auto callModel = lrcInstance_->getCurrentCallModel();
    try {
        auto& call = callModel->getCall(callId);
        for (const auto& media : call.mediaList) {
            if (media[libjami::Media::MediaAttributeKey::SOURCE].startsWith("display://")
                && media[libjami::Media::MediaAttributeKey::MEDIA_TYPE] == libjami::Media::Details::MEDIA_TYPE_AUDIO) {
                QString label = media[libjami::Media::MediaAttributeKey::LABEL];
                callModel->muteMedia(callId, label, mute);
            }
        }
        set_muteScreenshareAudio(mute);

    } catch (const std::exception& e) {
        qWarning() << "Failed to toggle share audio:" << e.what();
    }
}

void
AvAdapter::startAudioMeter()
{
    lrcInstance_->startAudioMeter();
}

void
AvAdapter::stopAudioMeter()
{
    lrcInstance_->stopAudioMeter();
}

void
AvAdapter::onAudioDeviceEvent()
{
    auto& avModel = lrcInstance_->avModel();
    auto inputs = avModel.getAudioInputDevices().size();
    auto outputs = avModel.getAudioOutputDevices().size();
    Q_EMIT audioDeviceListChanged(inputs, outputs);
}

void
AvAdapter::onRendererStarted(const QString& id, const QSize& size)
{
    Q_UNUSED(size)
    auto callId = lrcInstance_->getCurrentCallId();
    if (callId.isEmpty()) {
        return;
    }

    // update renderer Information list
    auto& avModel = lrcInstance_->avModel();
    auto rendererInfoList = avModel.getRenderersInfo(id);
    if (rendererInfoList.isEmpty())
        return;
    auto rendererInfo = rendererInfoList.first();
    rendererInformationListModel_->addElement(qMakePair(id, rendererInfo));
}

void
AvAdapter::onRendererStopped(const QString& id)
{
    rendererInformationListModel_->removeElement(id);
}

bool
AvAdapter::isSharing() const
{
    try {
        auto callId = lrcInstance_->getCurrentCallId();
        auto callModel = lrcInstance_->getCurrentCallModel();
        auto call = callModel->getCall(callId);
        // TODO enum
        return call.hasMediaWithType(libjami::Media::VideoProtocolPrefix::DISPLAY,
                                     libjami::Media::Details::MEDIA_TYPE_VIDEO)
               || call.hasMediaWithType("file:", libjami::Media::Details::MEDIA_TYPE_VIDEO);
    } catch (...) {
    }
    return false;
}

bool
AvAdapter::isSharingScreenOrWindow() const
{
    try {
        auto callId = lrcInstance_->getCurrentCallId();
        auto callModel = lrcInstance_->getCurrentCallModel();
        auto call = callModel->getCall(callId);
        return call.hasMediaWithType(libjami::Media::VideoProtocolPrefix::DISPLAY,
                                     libjami::Media::Details::MEDIA_TYPE_VIDEO);
    } catch (...) {
    }
    return false;
}

bool
AvAdapter::isCapturing() const
{
    try {
        auto callId = lrcInstance_->getCurrentCallId();
        auto callModel = lrcInstance_->getCurrentCallModel();
        auto call = callModel->getCall(callId);
        for (const auto& m : call.mediaList) {
            if (m[libjami::Media::MediaAttributeKey::SOURCE].startsWith(libjami::Media::VideoProtocolPrefix::CAMERA)
                && m[libjami::Media::MediaAttributeKey::MEDIA_TYPE] == libjami::Media::Details::MEDIA_TYPE_VIDEO)
                return m[libjami::Media::MediaAttributeKey::MUTED] == FALSE_STR;
        }
        return false;
    } catch (...) {
    }
    return false;
}

bool
AvAdapter::hasCamera() const
{
    try {
        auto callId = lrcInstance_->getCurrentCallId();
        auto callModel = lrcInstance_->getCurrentCallModel();
        auto call = callModel->getCall(callId);
        // TODO enum
        for (const auto& m : call.mediaList) {
            if (m[libjami::Media::MediaAttributeKey::SOURCE].startsWith(libjami::Media::VideoProtocolPrefix::CAMERA)
                && m[libjami::Media::MediaAttributeKey::MEDIA_TYPE] == libjami::Media::Details::MEDIA_TYPE_VIDEO)
                return true;
        }
        return false;
    } catch (...) {
    }
    return false;
}

int
AvAdapter::getScreenNumber(int screenId) const
{
    int display = 0;

#ifdef Q_OS_LINUX
    // Get display
    QString display_env {getenv("DISPLAY")};
    if (!display_env.isEmpty()) {
        auto list = display_env.split(':', Qt::SkipEmptyParts);
        // Should only be one display, so get the first one
        if (list.size() > 0) {
            display = list.at(0).toInt();
        }
    }
#else
#ifdef WIN32
    display = screenId;
#endif
#endif
    return display;
}

void
AvAdapter::setDeviceName(const QString& deviceName)
{
    lrcInstance_->getCurrentAccountInfo().deviceModel->setCurrentDeviceName(deviceName);
}

void
AvAdapter::enableCodec(unsigned int id, bool isToEnable)
{
    lrcInstance_->getCurrentAccountInfo().codecModel->enable(id, isToEnable);
}

void
AvAdapter::increaseCodecPriority(unsigned int id, bool isVideo)
{
    lrcInstance_->getCurrentAccountInfo().codecModel->increasePriority(id, isVideo);
}

void
AvAdapter::decreaseCodecPriority(unsigned int id, bool isVideo)
{
    lrcInstance_->getCurrentAccountInfo().codecModel->decreasePriority(id, isVideo);
}

bool
AvAdapter::getHardwareAcceleration()
{
    return lrcInstance_->avModel().getHardwareAcceleration();
}

void
AvAdapter::setHardwareAcceleration(bool accelerate)
{
    lrcInstance_->avModel().setHardwareAcceleration(accelerate);
}

void
AvAdapter::resetRendererInfo()
{
    rendererInformationListModel_->reset();
}

void
AvAdapter::setRendererInfo()
{
    auto& avModel = lrcInstance_->avModel();
    for (auto rendererInfo : avModel.getRenderersInfo()) {
        rendererInformationListModel_->addElement(qMakePair(rendererInfo["RENDERER_ID"], rendererInfo));
    }
}

void
AvAdapter::updateRenderersFPSInfo(QPair<QString, QString> fpsInfo)
{
    rendererInformationListModel_->updateFps(fpsInfo.first, fpsInfo.second);
}
