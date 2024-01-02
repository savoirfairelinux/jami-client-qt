/*
 *  Copyright (C) 2018-2024 Savoir-faire Linux Inc.
 *  Author: Hugo Lefeuvre <hugo.lefeuvre@savoirfairelinux.com>
 *  Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

#include "api/avmodel.h"

#include "api/video.h"
#include "api/lrc.h"
#ifdef ENABLE_LIBWRAP
#include "directrenderer.h"
#else
#include "shmrenderer.h"
#endif
#include "callbackshandler.h"
#include "dbus/callmanager.h"
#include "dbus/configurationmanager.h"
#include "dbus/videomanager.h"
#include "authority/storagehelper.h"

#include <media_const.h>

#include <QtCore/QStandardPaths>
#include <QtCore/QDir>
#include <QUrl>
#include <QSize>
#include <QReadWriteLock>

#include <algorithm> // std::sort
#include <chrono>
#include <csignal>
#include <iomanip> // for std::put_time
#include <fstream>
#include <mutex>
#include <thread>
#include <string>
#include <sstream>

#if defined(Q_OS_UNIX) && !defined(__APPLE__)
#include <xcb/xcb.h>
#endif
#ifdef WIN32
#include "Windows.h"
#include <tchar.h>
#include <dwmapi.h>
#endif

namespace lrc {

using namespace api;
using namespace api::video;
using namespace lrc::video;

class AVModelPimpl : public QObject
{
    Q_OBJECT
public:
    AVModelPimpl(AVModel& linked, const CallbacksHandler& callbacksHandler);

    const CallbacksHandler& callbacksHandler;
    QString getRecordingPath() const;
    static const QString recorderSavesSubdir;
    AVModel& linked_;

    QReadWriteLock renderersMutex_;
    std::map<QString, std::unique_ptr<Renderer>> renderers_;
    QString currentVideoCaptureDevice_ {};

#ifndef ENABLE_LIBWRAP
    // TODO: Init Video Renderers from daemon (see:
    // https://git.jami.net/savoirfairelinux/ring-daemon/issues/59)
    static void stopCameraAndQuit(int);
    static uint32_t SIZE_RENDERER;
#endif

    /**
     * Get device via its type
     * @param type
     * @return the device name
     */
    QString getDevice(int type) const;

    /**
     * Add video::Renderer to renderers_ and start it
     * @param id
     * @param size
     * @param shmPath
     */
    void addRenderer(const QString& id, const QSize& res, const QString& shmPath = {});

    /**
     * Remove renderer from renderers_. If the returned renderer is ignored, it
     * will be deleted.
     * @param id
     * @return the renderer
     */
    std::unique_ptr<Renderer> removeRenderer(const QString& id);

    bool hasRenderer(const QString& id);
    QSize getRendererSize(const QString& id);
    Frame getRendererFrame(const QString& id);

public Q_SLOTS:
    /**
     * Listen from CallbacksHandler when a renderer starts
     * @param id
     * @param shmPath
     * @param width
     * @param height
     */
    void onDecodingStarted(const QString& id, const QString& shmPath, int width, int height);
    /**
     * Listen from CallbacksHandler when a renderer stops
     * @param id
     * @param shmPath
     */
    void onDecodingStopped(const QString& id, const QString& shmPath);
    /**
     * Detect when a video device is plugged or unplugged
     */
    void slotDeviceEvent();
    /**
     * Detect when an audio device is plugged or unplugged
     */
    void slotAudioDeviceEvent();
    /**
     * Audio volume level
     * @param id Ringbuffer id
     * @param level Volume in range [0, 1]
     */
    void slotAudioMeter(const QString& id, float level);
    /**
     * Listen from CallbacksHandler when a recorder stopped notice is incoming
     * @param filePath
     */
    void slotRecordPlaybackStopped(const QString& filePath);
};

const QString AVModelPimpl::recorderSavesSubdir = "sent_data";
#ifndef ENABLE_LIBWRAP
uint32_t AVModelPimpl::SIZE_RENDERER = 0;
#endif

AVModel::AVModel(const CallbacksHandler& callbacksHandler)
    : QObject(nullptr)
    , pimpl_(std::make_unique<AVModelPimpl>(*this, callbacksHandler))
{
#ifndef ENABLE_LIBWRAP
    // Because the client uses DBUS, if a crash occurs, the daemon will not
    // be able to know it. So, stop the camera if the user was just previewing.
    std::signal(SIGSEGV, AVModelPimpl::stopCameraAndQuit);
    std::signal(SIGINT, AVModelPimpl::stopCameraAndQuit);
#endif
}

AVModel::~AVModel()
{
    QWriteLocker lk(&pimpl_->renderersMutex_);
    for (auto r = pimpl_->renderers_.begin(); r != pimpl_->renderers_.end(); ++r) {
        (*r).second.reset();
    }
}

QList<MapStringString>
AVModel::getRenderersInfo(QString id)
{
    QList<MapStringString> infoList;
    QReadLocker lk(&pimpl_->renderersMutex_);
    for (auto r = pimpl_->renderers_.begin(); r != pimpl_->renderers_.end(); r++) {
        MapStringString qmap;
        auto& rend = r->second;
        MapStringString mapInfo = rend->getInfos();
        if (id.isEmpty() || mapInfo["RENDERER_ID"] == id) {
            qmap.insert(rend->RES, mapInfo["RES"]);
            qmap.insert(rend->RENDERER_ID, mapInfo["RENDERER_ID"]);
            qmap.insert(rend->FPS, mapInfo["FPS"]);
            infoList.append(qmap);
        }
    }
    return infoList;
    return {};
}

void
AVModel::updateRenderersFPSInfo(QString rendererId)
{
    QReadLocker lk(&pimpl_->renderersMutex_);
    auto it = std::find_if(pimpl_->renderers_.begin(),
                           pimpl_->renderers_.end(),
                           [&rendererId](const auto& c) {
                               return rendererId == c.second->getInfos()["RENDERER_ID"];
                           });
    if (it != pimpl_->renderers_.end()) {
        auto fpsInfo = qMakePair(rendererId, it->second->getInfos()["FPS"]);
        lk.unlock();
        Q_EMIT onRendererFpsChange(fpsInfo);
    }
}

bool
AVModel::getDecodingAccelerated() const
{
    bool result = VideoManager::instance().getDecodingAccelerated();
    return result;
}

void
AVModel::setDecodingAccelerated(bool accelerate)
{
    VideoManager::instance().setDecodingAccelerated(accelerate);
}

bool
AVModel::getEncodingAccelerated() const
{
    bool result = VideoManager::instance().getEncodingAccelerated();
    return result;
}

void
AVModel::setEncodingAccelerated(bool accelerate)
{
    VideoManager::instance().setEncodingAccelerated(accelerate);
}

bool
AVModel::getHardwareAcceleration() const
{
    bool result = getDecodingAccelerated() && getEncodingAccelerated();
    return result;
}
void
AVModel::setHardwareAcceleration(bool accelerate)
{
    setDecodingAccelerated(accelerate);
    setEncodingAccelerated(accelerate);
}

QVector<QString>
AVModel::getDevices() const
{
    QStringList devices = VideoManager::instance().getDeviceList();
    VectorString result;
    for (const auto& device : devices) {
        result.push_back(device);
    }
    return (QVector<QString>) result;
}

QString
AVModel::getDefaultDevice() const
{
    return VideoManager::instance().getDefaultDevice();
}

void
AVModel::setDefaultDevice(const QString& deviceId)
{
    VideoManager::instance().setDefaultDevice(deviceId);
}

Settings
AVModel::getDeviceSettings(const QString& deviceId) const
{
    if (deviceId.isEmpty()) {
        return video::Settings();
    }
    MapStringString settings = VideoManager::instance().getSettings(deviceId);
    if (settings["id"] != deviceId) {
        throw std::out_of_range("Device '" + deviceId.toStdString() + "' not found");
    }
    video::Settings result;
    result.name = settings["name"];
    result.id = settings["id"];
    result.channel = settings["channel"];
    result.size = settings["size"];
    result.rate = settings["rate"].toFloat();
    return result;
}

Capabilities
AVModel::getDeviceCapabilities(const QString& deviceId) const
{
    // Channel x Resolution x Framerate
    QMap<QString, QMap<QString, QVector<QString>>> capabilites = VideoManager::instance()
                                                                     .getCapabilities(deviceId);
    video::Capabilities result;
    for (auto& channel : capabilites.toStdMap()) {
        video::ResRateList channelCapabilities;
        for (auto& resToRates : channel.second.toStdMap()) {
            video::FrameratesList rates;
            QVectorIterator<QString> itRates(resToRates.second);
            while (itRates.hasNext()) {
                rates.push_back(itRates.next().toFloat());
            }
            std::sort(rates.begin(), rates.end(), std::greater<int>());
            channelCapabilities.push_back(qMakePair(resToRates.first, rates));
        }
        // sort by resolution widths
        std::sort(channelCapabilities.begin(),
                  channelCapabilities.end(),
                  [](const QPair<video::Resolution, video::FrameratesList>& lhs,
                     const QPair<video::Resolution, video::FrameratesList>& rhs) {
                      auto lhsWidth = lhs.first.left(lhs.first.indexOf("x")).toLongLong();
                      auto rhsWidth = rhs.first.left(rhs.first.indexOf("x")).toLongLong();
                      return lhsWidth > rhsWidth;
                  });
        result.insert(channel.first, channelCapabilities);
    }
    return result;
}

void
AVModel::setDeviceSettings(video::Settings& settings)
{
    MapStringString newSettings;
    auto rate = QString::number(settings.rate, 'f', 7);
    rate = rate.left(rate.length() - 1);
    newSettings["channel"] = settings.channel;
    newSettings["name"] = settings.name;
    newSettings["id"] = settings.id;
    newSettings["rate"] = rate;
    newSettings["size"] = settings.size;
    VideoManager::instance().applySettings(settings.id, newSettings);

    // If the preview is running, reload it
    // doing this during a call will cause re-invite, this is unwanted
    QReadLocker lk(&pimpl_->renderersMutex_);
    auto it = pimpl_->renderers_.find(video::PREVIEW_RENDERER_ID);
    if (it != pimpl_->renderers_.end() && it->second && pimpl_->renderers_.size() == 1) {
        lk.unlock();
        stopPreview(video::PREVIEW_RENDERER_ID);
        startPreview(video::PREVIEW_RENDERER_ID);
    }
}

QString
AVModel::getDeviceIdFromName(const QString& deviceName) const
{
    auto devices = getDevices();
    auto iter = std::find_if(devices.begin(), devices.end(), [this, deviceName](const QString& d) {
        auto settings = getDeviceSettings(d);
        return settings.name == deviceName;
    });
    if (iter == devices.end()) {
        qWarning() << "Couldn't find device: " << deviceName;
        return {};
    }
    return *iter;
}

VectorString
AVModel::getSupportedAudioManagers() const
{
    QStringList managers = ConfigurationManager::instance().getSupportedAudioManagers();
    VectorString result;
    for (const auto& manager : managers) {
        result.push_back(manager);
    }
    return result;
}

QString
AVModel::getAudioManager() const
{
    return ConfigurationManager::instance().getAudioManager();
}

QVector<QString>
AVModel::getAudioOutputDevices() const
{
    QStringList devices = ConfigurationManager::instance().getAudioOutputDeviceList();

    // A fix for ring-daemon#43
    if (ConfigurationManager::instance().getAudioManager() == QStringLiteral("pulseaudio")) {
        if (devices.at(0) == QStringLiteral("default")) {
            devices[0] = QObject::tr("default");
        }
    }

    VectorString result;
    for (const auto& device : devices) {
        result.push_back(device);
    }
    return (QVector<QString>) result;
}

QVector<QString>
AVModel::getAudioInputDevices() const
{
    QStringList devices = ConfigurationManager::instance().getAudioInputDeviceList();

    // A fix for ring-daemon#43
    if (ConfigurationManager::instance().getAudioManager() == QStringLiteral("pulseaudio")) {
        if (devices.at(0) == QStringLiteral("default")) {
            devices[0] = QObject::tr("default");
        }
    }

    VectorString result;
    for (const auto& device : devices) {
        result.push_back(device);
    }
    return (QVector<QString>) result;
}

QString
AVModel::getRingtoneDevice() const
{
    const int RINGTONE_IDX = 2;
    return pimpl_->getDevice(RINGTONE_IDX);
}

QString
AVModel::getOutputDevice() const
{
    const int OUTPUT_IDX = 0;
    return pimpl_->getDevice(OUTPUT_IDX);
}

QString
AVModel::getInputDevice() const
{
    const int INPUT_IDX = 1;
    return pimpl_->getDevice(INPUT_IDX);
}

bool
AVModel::isAudioMeterActive(const QString& id) const
{
    return ConfigurationManager::instance().isAudioMeterActive(id);
}

void
AVModel::setAudioMeterState(bool active, const QString& id) const
{
    ConfigurationManager::instance().setAudioMeterState(id, active);
}

void
AVModel::startAudioDevice() const
{
    VideoManager::instance().startAudioDevice();
}

void
AVModel::stopAudioDevice() const
{
    VideoManager::instance().stopAudioDevice();
}

bool
AVModel::setAudioManager(const QString& name)
{
    return ConfigurationManager::instance().setAudioManager(name);
}

void
AVModel::setRingtoneDevice(int idx)
{
    ConfigurationManager::instance().setAudioRingtoneDevice(idx);
}

void
AVModel::setOutputDevice(int idx)
{
    ConfigurationManager::instance().setAudioOutputDevice(idx);
}

void
AVModel::setInputDevice(int idx)
{
    ConfigurationManager::instance().setAudioInputDevice(idx);
}

void
AVModel::stopLocalRecorder(const QString& path) const
{
    if (path.isEmpty()) {
        qWarning("stopLocalRecorder: can't stop non existing recording");
        return;
    }

    VideoManager::instance().stopLocalRecorder(path);
}

QString
AVModel::startLocalMediaRecorder(const QString& videoInputId) const
{
    const QString path = pimpl_->getRecordingPath();
    const QString finalPath = VideoManager::instance().startLocalMediaRecorder(videoInputId, path);
    return finalPath;
}

QString
AVModel::getRecordPath() const
{
    return ConfigurationManager::instance().getRecordPath();
}

void
AVModel::setRecordPath(const QString& path) const
{
    ConfigurationManager::instance().setRecordPath(path.toUtf8());
}

bool
AVModel::getAlwaysRecord() const
{
    return ConfigurationManager::instance().getIsAlwaysRecording();
}

void
AVModel::setAlwaysRecord(const bool& rec) const
{
    ConfigurationManager::instance().setIsAlwaysRecording(rec);
}

bool
AVModel::getRecordPreview() const
{
    return ConfigurationManager::instance().getRecordPreview();
}

void
AVModel::setRecordPreview(const bool& rec) const
{
    ConfigurationManager::instance().setRecordPreview(rec);
}

int
AVModel::getRecordQuality() const
{
    return ConfigurationManager::instance().getRecordQuality();
}

void
AVModel::setRecordQuality(const int& rec) const
{
    ConfigurationManager::instance().setRecordQuality(rec);
}

QString
AVModel::startPreview(const QString& resource)
{
    return VideoManager::instance().openVideoInput(resource);
}

void
AVModel::stopPreview(const QString& resource)
{
    VideoManager::instance().closeVideoInput(resource);
}

#ifdef WIN32
BOOL
IsAltTabWindow(HWND hwnd)
{
    auto styles = (DWORD) GetWindowLongPtr(hwnd, GWL_STYLE);
    auto ex_styles = (DWORD) GetWindowLongPtr(hwnd, GWL_EXSTYLE);

    if (ex_styles & WS_EX_TOOLWINDOW)
        return false;
    if (styles & WS_CHILD)
        return false;

    DWORD cloaked = FALSE;
    HRESULT hrTemp = DwmGetWindowAttribute(hwnd, DWMWA_CLOAKED, &cloaked, sizeof(cloaked));
    if (SUCCEEDED(hrTemp) && cloaked == DWM_CLOAKED_SHELL) {
        return false;
    }

    // Start at the root owner
    HWND hwndWalk = GetAncestor(hwnd, GA_ROOTOWNER);

    // See if we are the last active visible popup
    HWND hwndTry;
    while ((hwndTry = GetLastActivePopup(hwndWalk)) != hwndTry) {
        if (IsWindowVisible(hwndTry))
            break;
        hwndWalk = hwndTry;
    }
    return hwndWalk == hwnd;
}

BOOL CALLBACK
CbEnumAltTab(HWND hwnd, LPARAM lParam)
{
    const size_t MAX_WINDOW_NAME = 256;
    TCHAR windowName[MAX_WINDOW_NAME];
    GetWindowText(hwnd, windowName, MAX_WINDOW_NAME);

    // Do not show windows that has no caption
    if (0 == windowName[0])
        return TRUE;

    std::wstring msg = std::wstring(windowName);
    auto name = QString::fromStdWString(msg);

    // Do not show invisible windows
    if (!IsWindowVisible(hwnd))
        return TRUE;

    // Alt-tab test as described by Raymond Chen
    if (!IsAltTabWindow(hwnd))
        return TRUE;

    auto isShellWindow = hwnd == GetShellWindow();

    if (isShellWindow)
        return TRUE;

    QMap<QString, QVariant>* windowList = reinterpret_cast<QMap<QString, QVariant>*>(lParam);
    auto keys = windowList->keys();
    if (keys.indexOf(name) > 0) {
        return FALSE;
    } else {
        std::stringstream ss;
        ss << hwnd;
        windowList->insert(name, QString::fromStdString(ss.str()));
    }

    return TRUE;
}
#endif

#if defined(Q_OS_UNIX) && !defined(__APPLE__)
static xcb_atom_t
getAtom(xcb_connection_t* c, const std::string& atomName)
{
    xcb_intern_atom_cookie_t atom_cookie = xcb_intern_atom(c, 0, atomName.size(), atomName.c_str());
    if (auto* rep = xcb_intern_atom_reply(c, atom_cookie, nullptr)) {
        xcb_atom_t atom = rep->atom;
        free(rep);
        return atom;
    }
    return {};
}
#endif

const QVariantMap
AVModel::getListWindows() const
{
    QMap<QString, QVariant> ret {};

#if defined(Q_OS_UNIX) && !defined(__APPLE__)
    std::unique_ptr<xcb_connection_t, void (*)(xcb_connection_t*)> c(xcb_connect(nullptr, nullptr),
                                                                     [](xcb_connection_t* ptr) {
                                                                         xcb_disconnect(ptr);
                                                                     });

    if (xcb_connection_has_error(c.get())) {
        qDebug() << "xcb connection has error";
        return ret;
    }

    auto atomNetClient = getAtom(c.get(), "_NET_CLIENT_LIST");
    auto atomWMVisibleName = getAtom(c.get(), "_NET_WM_NAME");
    if (!atomNetClient || !atomWMVisibleName)
        return ret;

    auto* screen = xcb_setup_roots_iterator(xcb_get_setup(c.get())).data;

    xcb_get_property_cookie_t propCookieList = xcb_get_property(c.get(),
                                                                0,
                                                                screen->root,
                                                                atomNetClient,
                                                                XCB_GET_PROPERTY_TYPE_ANY,
                                                                0,
                                                                100);

    using propertyPtr
        = std::unique_ptr<xcb_get_property_reply_t, void (*)(xcb_get_property_reply_t*)>;

    xcb_generic_error_t* e;
    propertyPtr replyPropList(xcb_get_property_reply(c.get(), propCookieList, &e),
                              [](auto* ptr) { free(ptr); });
    if (e) {
        qDebug() << "Error: " << e->error_code;
        free(e);
    }
    if (replyPropList.get()) {
        int valueLegth = xcb_get_property_value_length(replyPropList.get());
        if (valueLegth) {
            auto* win = static_cast<xcb_window_t*>(xcb_get_property_value(replyPropList.get()));
            for (int i = 0; i < valueLegth / 4; i++) {
                xcb_get_property_cookie_t prop_cookie = xcb_get_property(c.get(),
                                                                         0,
                                                                         win[i],
                                                                         atomWMVisibleName,
                                                                         XCB_GET_PROPERTY_TYPE_ANY,
                                                                         0,
                                                                         1000);
                propertyPtr replyProp {xcb_get_property_reply(c.get(), prop_cookie, &e),
                                       [](auto* ptr) {
                                           free(ptr);
                                       }};
                if (e) {
                    qDebug() << "Error: " << e->error_code;
                    free(e);
                }
                if (replyProp.get()) {
                    int v_size = xcb_get_property_value_length(replyProp.get());
                    if (v_size) {
                        auto v = std::string(reinterpret_cast<char*>(
                                                 xcb_get_property_value(replyProp.get())),
                                             v_size);
                        auto name = QString::fromUtf8(v.c_str());
                        if (ret.find(name) != ret.end())
                            name += QString(" - 0x%1").arg(win[i], 0, 16);
                        ret.insert(name, QVariant(QString("0x%1").arg(win[i], 0, 16)));
                    }
                }
            }
        }
    }
#endif
#ifdef WIN32
    try {
        auto newWindow = true;
        LPARAM lParam = reinterpret_cast<LPARAM>(&ret);
        while (newWindow) {
            newWindow = EnumWindows(CbEnumAltTab, lParam);
        }
        auto finishedloop = true;
    } catch (...) {
    }
#endif
    return ret;
}

void
AVModel::setCurrentVideoCaptureDevice(const QString& currentVideoCaptureDevice)
{
    pimpl_->currentVideoCaptureDevice_ = currentVideoCaptureDevice;
}

QString
AVModel::getCurrentVideoCaptureDevice() const
{
    return pimpl_->currentVideoCaptureDevice_;
}

void
AVModel::clearCurrentVideoCaptureDevice()
{
    pimpl_->currentVideoCaptureDevice_.clear();
}

void
AVModel::addRenderer(const QString& id, const QSize& res, const QString& shmPath)
{
    pimpl_->addRenderer(id, res, shmPath);
}

bool
AVModel::hasRenderer(const QString& id)
{
    return pimpl_->hasRenderer(id);
}

QSize
AVModel::getRendererSize(const QString& id)
{
    return pimpl_->getRendererSize(id);
}

Frame
AVModel::getRendererFrame(const QString& id)
{
    return pimpl_->getRendererFrame(id);
}

bool
AVModel::useDirectRenderer() const
{
#ifdef ENABLE_LIBWRAP
    return true;
#else
    return false;
#endif
}

QString AVModel::createMediaPlayer(const QString& resource)
{
    return VideoManager::instance().createMediaPlayer(resource);
}

void AVModel::closeMediaPlayer(const QString& resource)
{
    VideoManager::instance().closeMediaPlayer(resource);
}

bool AVModel::pausePlayer(const QString& id, bool pause)
{
    return VideoManager::instance().pausePlayer(id, pause);
}

bool AVModel::mutePlayerAudio(const QString& id, bool mute)
{
    return VideoManager::instance().mutePlayerAudio(id, mute);
}

bool AVModel::playerSeekToTime(const QString& id, int time)
{
    return VideoManager::instance().playerSeekToTime(id, time);
}

qint64 AVModel::getPlayerPosition(const QString& id)
{
    return VideoManager::instance().getPlayerPosition(id);
}

qint64 AVModel::getPlayerDuration(const QString& id)
{
    return VideoManager::instance().getPlayerDuration(id);
}

void AVModel::setAutoRestart(const QString& id, bool restart)
{
    VideoManager::instance().setAutoRestart(id, restart);
}

AVModelPimpl::AVModelPimpl(AVModel& linked, const CallbacksHandler& callbacksHandler)
    : callbacksHandler(callbacksHandler)
    , linked_(linked)
{
    std::srand(std::time(nullptr));
#ifndef ENABLE_LIBWRAP
    SIZE_RENDERER = renderers_.size();
#endif
    connect(&callbacksHandler, &CallbacksHandler::deviceEvent, this, &AVModelPimpl::slotDeviceEvent);
    connect(&callbacksHandler,
            &CallbacksHandler::audioDeviceEvent,
            this,
            &AVModelPimpl::slotAudioDeviceEvent);
    connect(&callbacksHandler, &CallbacksHandler::audioMeter, this, &AVModelPimpl::slotAudioMeter);
    connect(&callbacksHandler,
            &CallbacksHandler::recordPlaybackStopped,
            this,
            &AVModelPimpl::slotRecordPlaybackStopped);

    // render connections
    connect(&callbacksHandler,
            &CallbacksHandler::decodingStarted,
            this,
            &AVModelPimpl::onDecodingStarted,
            Qt::DirectConnection);
    connect(&callbacksHandler,
            &CallbacksHandler::decodingStopped,
            this,
            &AVModelPimpl::onDecodingStopped,
            Qt::DirectConnection);

    // Media player connection
    connect(&callbacksHandler,
            &CallbacksHandler::fileOpened,
            this,
            [this](const QString& path, MapStringString info) {
                Q_UNUSED(path);
                bool hasAudio = info["audio_stream"].toInt() >= 0;
                bool hasVideo = info["video_stream"].toInt() >= 0;
                Q_EMIT linked_.fileOpened(hasAudio, hasVideo);
            });

    auto startedPreview = false;
    auto restartRenderers = [&](const QStringList& callList) {
        for (const auto& callId : callList) {
            MapStringString rendererInfos = VideoManager::instance().getRenderer(callId);
            auto shmPath = rendererInfos[libjami::Media::Details::SHM_PATH];
            auto width = rendererInfos[libjami::Media::Details::WIDTH].toInt();
            auto height = rendererInfos[libjami::Media::Details::HEIGHT].toInt();
            if (width > 0 && height > 0) {
                startedPreview = true;
                onDecodingStarted(callId, shmPath, width, height);
            }
        }
    };
    restartRenderers(CallManager::instance().getCallList(""));
    auto confIds = lrc::api::Lrc::getConferences();
    QStringList list;
    Q_FOREACH (QString confId, confIds) {
        list << confId;
    }
    restartRenderers(list);
    if (startedPreview)
        restartRenderers({"local"});
    currentVideoCaptureDevice_ = VideoManager::instance().getDefaultDevice();
}

QString
AVModelPimpl::getRecordingPath() const
{
    const QDir dir = authority::storage::getPath() + "/" + recorderSavesSubdir;
    dir.mkpath(".");

    std::chrono::time_point<std::chrono::system_clock> time_now = std::chrono::system_clock::now();
    std::time_t time_now_t = std::chrono::system_clock::to_time_t(time_now);
    std::tm now_tm = *std::localtime(&time_now_t);

    std::stringstream ss;
    ss << dir.path().toStdString();
    ss << "/";
    ss << std::put_time(&now_tm, "%Y%m%d-%H%M%S");
    ss << "-";
    ss << std::rand();

    QDir file_path(ss.str().c_str());

    return file_path.path();
}

void
AVModelPimpl::onDecodingStarted(const QString& id, const QString& shmPath, int width, int height)
{
    addRenderer(id, QSize(width, height), shmPath);
}

void
AVModelPimpl::onDecodingStopped(const QString& id, const QString& shmPath)
{
    Q_UNUSED(shmPath)
    removeRenderer(id);
}

#ifndef ENABLE_LIBWRAP
void
AVModelPimpl::stopCameraAndQuit(int)
{
    if (SIZE_RENDERER == 1) {
        // This will stop the preview if needed (not in a call).
        VideoManager::instance().closeVideoInput(PREVIEW_RENDERER_ID);
        // HACK: this sleep is just here to let the camera stop and
        // avoid immediate raise
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    std::raise(SIGTERM);
}

#endif
QString
AVModelPimpl::getDevice(int type) const
{
    if (type < 0 || type > 2)
        return {}; // No device
    QString result;
    VectorString devices;
    switch (type) {
    case 1: // INPUT
        devices = linked_.getAudioInputDevices();
        break;
    case 0: // OUTPUT
    case 2: // RINGTONE
        devices = linked_.getAudioOutputDevices();
        break;
    default:
        break;
    }
    QStringList currentDevicesIdx = ConfigurationManager::instance().getCurrentAudioDevicesIndex();
    try {
        // Should not happen, but cannot retrieve current ringtone device
        if (currentDevicesIdx.size() < 3)
            return "";
        auto deviceIdx = currentDevicesIdx[type].toInt();
        if (deviceIdx < devices.size())
            result = devices.at(deviceIdx);
    } catch (std::bad_alloc& ba) {
        qWarning() << "bad_alloc caught: " << ba.what();
        return "";
    }
    return result;
}

static std::unique_ptr<Renderer>
createRenderer(const QString& id, const QSize& res, const QString& shmPath = {})
{
#ifdef ENABLE_LIBWRAP
    Q_UNUSED(shmPath)
    return std::make_unique<DirectRenderer>(id, res);
#else
    return std::make_unique<ShmRenderer>(id, res, shmPath);
#endif
}

void
AVModelPimpl::addRenderer(const QString& id, const QSize& res, const QString& shmPath)
{
    // Remove the renderer if it already exists.
    std::ignore = removeRenderer(id);

    {
        QWriteLocker lk(&renderersMutex_);
        renderers_[id] = createRenderer(id, res, shmPath);
    }

    QReadLocker lk(&renderersMutex_);
    if (auto* renderer = renderers_.find(id)->second.get()) {
        connect(
            renderer,
            &Renderer::fpsChanged,
            this,
            [this, id](void) { linked_.updateRenderersFPSInfo(id); },
            Qt::QueuedConnection);
        connect(
            renderer,
            &Renderer::started,
            this,
            [this, id](const QSize& size) { Q_EMIT linked_.rendererStarted(id, size); },
            Qt::DirectConnection);
#ifdef ENABLE_LIBWRAP
        connect(
            renderer,
            &Renderer::frameBufferRequested,
            this,
            [this, id](AVFrame* frame) { Q_EMIT linked_.frameBufferRequested(id, frame); },
            Qt::DirectConnection);
#endif
        connect(
            renderer,
            &Renderer::frameUpdated,
            this,
            [this, id] { Q_EMIT linked_.frameUpdated(id); },
            Qt::DirectConnection);
        connect(
            renderer,
            &Renderer::stopped,
            this,
            [this, id] { Q_EMIT linked_.rendererStopped(id); },
            Qt::DirectConnection);

        renderer->startRendering();
    }
}

std::unique_ptr<Renderer>
AVModelPimpl::removeRenderer(const QString& id)
{
    QWriteLocker lk(&renderersMutex_);
    auto it = renderers_.find(id);
    if (it == renderers_.end()) {
        qWarning() << "Cannot remove renderer. " << id << "not found";
        return {};
    }
    auto removed = std::move(it->second);
    renderers_.erase(it);
    return removed;
}

bool
AVModelPimpl::hasRenderer(const QString& id)
{
    QReadLocker lk(&renderersMutex_);
    return renderers_.find(id) != renderers_.end();
}

QSize
AVModelPimpl::getRendererSize(const QString& id)
{
    QReadLocker lk(&renderersMutex_);
    auto it = renderers_.find(id);
    if (it != renderers_.end()) {
        return it->second->size();
    }
    return {};
}

Frame
AVModelPimpl::getRendererFrame(const QString& id)
{
    QReadLocker lk(&renderersMutex_);
    auto it = renderers_.find(id);
    if (it != renderers_.end()) {
        return it->second->currentFrame();
    }
    return {};
}

void
AVModelPimpl::slotDeviceEvent()
{
    Q_EMIT linked_.deviceEvent();
}

void
AVModelPimpl::slotAudioDeviceEvent()
{
    Q_EMIT linked_.audioDeviceEvent();
}

void
AVModelPimpl::slotAudioMeter(const QString& id, float level)
{
    Q_EMIT linked_.audioMeter(id, level);
}

void
AVModelPimpl::slotRecordPlaybackStopped(const QString& filePath)
{
    Q_EMIT linked_.recordPlaybackStopped(filePath);
}

} // namespace lrc

#include "api/moc_avmodel.cpp"
#include "avmodel.moc"
