/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once

#include "lrcinstance.h"
#include "qtutils.h"

#include <QObject>
#include <QString>

class CurrentCall final : public QObject
{
    Q_OBJECT

    QML_RO_PROPERTY(QString, id)
    QML_RO_PROPERTY(QStringList, uris)
    QML_RO_PROPERTY(bool, isAudioOnly)
    QML_RO_PROPERTY(bool, isSIP)
    QML_RO_PROPERTY(bool, isGrid)
    QML_RO_PROPERTY(call::Status, status)
    QML_RO_PROPERTY(bool, isActive)
    QML_RO_PROPERTY(bool, isPaused)
    QML_RO_PROPERTY(bool, isAudioMuted)
    QML_RO_PROPERTY(bool, isVideoMuted)
    QML_RO_PROPERTY(QString, previewId)
    QML_RO_PROPERTY(bool, isRecordingLocally)
    QML_RO_PROPERTY(bool, isRecordingRemotely)
    QML_RO_PROPERTY(QStringList, remoteRecorderNameList)
    QML_RO_PROPERTY(bool, isSharing)
    QML_RO_PROPERTY(bool, isHandRaised)
    QML_RO_PROPERTY(bool, isConference)
    QML_RO_PROPERTY(bool, isModerator)

public:
    explicit CurrentCall(LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~CurrentCall() = default;

private:
    void updateId(QString callId = {});
    void updateCallStatus();
    void updateParticipants();
    void updateCallInfo();
    void updateRemoteRecorders(const QStringList& recorders);
    void updateRecordingState(bool state);
    void connectModel();

private Q_SLOTS:
    void onCurrentConvIdChanged();
    void onCurrentAccountIdChanged();
    void onCallStatusChanged(const QString& callId, int code);
    void onCallInfosChanged(const QString& accountId, const QString& callId);
    void onParticipantsChanged(const QString& callId);
    void onRemoteRecordersChanged(const QString& callId, const QStringList& recorders);
    void onRecordingStateChanged(const QString& callId, bool state);

private:
    LRCInstance* lrcInstance_;
};
