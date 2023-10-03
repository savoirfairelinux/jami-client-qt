/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

#include "lrcinstance.h"
#include "qmladapterbase.h"
#include "screensaver.h"
#include "calloverlaymodel.h"
#include "pttlistener.h"

#include <QObject>
#include <QString>
#include <QVariant>
#include <QSystemTrayIcon>

#include "callInformationListModel.h"

class SystemTray;

class CallAdapter final : public QmlAdapterBase
{
    Q_OBJECT
    QML_PROPERTY(bool, hasCall)
    QML_RO_PROPERTY(QVariant, callInformationList)

public:
    QTimer* timer;
    enum MuteStates { UNMUTED, LOCAL_MUTED, MODERATOR_MUTED, BOTH_MUTED };
    Q_ENUM(MuteStates)

    explicit CallAdapter(SystemTray* systemTray, LRCInstance* instance, QObject* parent = nullptr);
    ~CallAdapter() = default;

public:
    Q_INVOKABLE void startTimerInformation();
    Q_INVOKABLE void stopTimerInformation();
    Q_INVOKABLE void placeAudioOnlyCall();
    Q_INVOKABLE void placeCall();
    Q_INVOKABLE void hangUpACall(const QString& accountId, const QString& convUid);
    Q_INVOKABLE void setCallMedia(const QString& accountId, const QString& convUid, bool video);
    Q_INVOKABLE void acceptACall(const QString& accountId, const QString& convUid);

    Q_INVOKABLE void connectCallModel(const QString& accountId);
    Q_INVOKABLE void sipInputPanelPlayDTMF(const QString& key);

    // For Call Overlay
    Q_INVOKABLE void hangUpCall(const QString& callId);
    Q_INVOKABLE void setActiveStream(const QString& uri,
                                     const QString& deviceId,
                                     const QString& streamId);
    Q_INVOKABLE void minimizeParticipant(const QString& uri);
    Q_INVOKABLE void showGridConferenceLayout();
    Q_INVOKABLE void hangUpThisCall();
    Q_INVOKABLE bool isCurrentHost() const;
    Q_INVOKABLE bool participantIsHost(const QString& uri) const;
    Q_INVOKABLE void setModerator(const QString& uri, const bool state);
    Q_INVOKABLE bool isHandRaised(const QString& uri = {}) const;
    Q_INVOKABLE void raiseHand(const QString& uri, const QString& deviceId, bool state);
    Q_INVOKABLE void holdThisCallToggle();
    Q_INVOKABLE void recordThisCallToggle();
    Q_INVOKABLE void muteAudioToggle();
    Q_INVOKABLE bool isMuted();
    Q_INVOKABLE void muteCameraToggle();
    Q_INVOKABLE bool isRecordingThisCall();
    Q_INVOKABLE void muteParticipant(const QString& accountUri,
                                     const QString& deviceId,
                                     const QString& sinkId,
                                     const bool state);
    Q_INVOKABLE MuteStates getMuteState(const QString& uri) const;
    Q_INVOKABLE void hangupParticipant(const QString& uri, const QString& deviceId);
    Q_INVOKABLE void updateCall(const QString& convUid = {},
                                const QString& accountId = {},
                                bool forceCallOnly = false);
    Q_INVOKABLE QString getCallDurationTime(const QString& accountId, const QString& convUid);
    Q_INVOKABLE void resetCallInfo();
    Q_INVOKABLE void setCallInfo();
    Q_INVOKABLE void updateAdvancedInformation();

    Q_INVOKABLE bool takeScreenshot(const QImage& image, const QString& path);

Q_SIGNALS:
    void callStatusChanged(int index, const QString& accountId, const QString& convUid);

    // For Call Overlay
    void updateTimeText(const QString& time);

public Q_SLOTS:
    void onShowIncomingCallView(const QString& accountId, const QString& convUid);
    void onShowCallView(const QString& accountId, const QString& convUid);
    void onAccountChanged();
    void onCallStatusChanged(const QString& accountId, const QString& callId);
    void onCallStatusChanged(const QString& callId, int code);
    void onCallAddedToConference(const QString& callId, const QString& confId);
    void onCallStarted(const QString& callId);
    void onCallEnded(const QString& callId);

private:
    void showNotification(const QString& accountId, const QString& convUid);
    void preventScreenSaver(bool state);
    void saveConferenceSubcalls();

    QString accountId_;

    ScreenSaver screenSaver;
    SystemTray* systemTray_;
    QScopedPointer<CallOverlayModel> overlayModel_;
    VectorString currentConfSubcalls_;
    PTTListener listener_;
    bool isMicrophoneMuted_ = true;

    std::unique_ptr<CallInformationListModel> callInformationListModel_;
};
