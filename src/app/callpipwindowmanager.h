/*
 * Copyright (C) 2024-2026 Savoir-faire Linux Inc.
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

#include <QObject>
#include <QPointer>
#include <QString>
#include <QQmlEngine>

#include "lrcinstance.h"

class LRCInstance;
class QQmlEngine;
class QQuickWindow;

// QML singleton that manages the Picture-in-Picture (PiP) call window.
//
// When the user navigates away from a conversation with an active call
// (e.g. switches conversations), the call view is automatically "popped out"
// into a small, resizable PiP window. At most one PiP window exists at a time
// since Jami supports a single active call.
//
// The PiP window can be reabsorbed into the main window via reabsorb(), which
// selects the call's conversation in the main window and closes the PiP.
class CallPipWindowManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool isPipActive READ isPipActive NOTIFY isPipActiveChanged)
    Q_PROPERTY(QString pipConvId READ pipConvId NOTIFY pipConvIdChanged)
    Q_PROPERTY(QString pipCallId READ pipCallId NOTIFY pipCallIdChanged)
    Q_PROPERTY(QString pipAccountId READ pipAccountId NOTIFY pipAccountIdChanged)
    Q_PROPERTY(QString pipPreviewId READ pipPreviewId NOTIFY pipPreviewIdChanged)
    Q_PROPERTY(bool pipIsAudioMuted READ pipIsAudioMuted NOTIFY pipIsAudioMutedChanged)
    Q_PROPERTY(bool pipIsCapturing READ pipIsCapturing NOTIFY pipIsCapturingChanged)
    Q_PROPERTY(bool pipPeerVideoMuted READ pipPeerVideoMuted NOTIFY pipPeerVideoMutedChanged)
    Q_PROPERTY(QString pipPeerUri READ pipPeerUri NOTIFY pipPeerUriChanged)
    Q_PROPERTY(QString pipActiveSpeakerUri READ pipActiveSpeakerUri NOTIFY pipActiveSpeakerUriChanged)
    Q_PROPERTY(QString pipActiveSpeakerSinkId READ pipActiveSpeakerSinkId NOTIFY pipActiveSpeakerSinkIdChanged)
    Q_PROPERTY(bool pipIsEmptyConference READ pipIsEmptyConference NOTIFY pipIsEmptyConferenceChanged)
    Q_PROPERTY(bool pipIsConference READ pipIsConference NOTIFY pipIsConferenceChanged)

public:
    explicit CallPipWindowManager(QQmlEngine* engine, LRCInstance* lrcInstance, QObject* parent = nullptr);
    ~CallPipWindowManager() = default;

    static CallPipWindowManager* create(QQmlEngine*, QJSEngine*);

    bool isPipActive() const
    {
#ifdef BUILD_TESTING
        if (testPipActive_)
            return !pipConvId_.isEmpty();
#endif
        return !pipConvId_.isEmpty() && !window_.isNull();
    }
    QString pipConvId() const
    {
        return pipConvId_;
    }
    QString pipCallId() const
    {
        return pipCallId_;
    }
    QString pipAccountId() const
    {
        return pipAccountId_;
    }
    QString pipPreviewId() const;
    bool pipIsAudioMuted() const
    {
        return pipIsAudioMuted_;
    }
    bool pipIsCapturing() const
    {
        return pipIsCapturing_;
    }
    bool pipPeerVideoMuted() const
    {
        return pipPeerVideoMuted_;
    }
    QString pipPeerUri() const
    {
        return pipPeerUri_;
    }
    QString pipActiveSpeakerUri() const
    {
        return pipActiveSpeakerUri_;
    }
    QString pipActiveSpeakerSinkId() const
    {
        return pipActiveSpeakerSinkId_;
    }
    bool pipIsEmptyConference() const
    {
        return pipIsEmptyConference_;
    }
    bool pipIsConference() const
    {
        return pipIsConference_;
    }

    // Pop the call view for (convId, accountId) out into the PiP window.
    // Raises the existing window if the same call is already in PiP.
    Q_INVOKABLE void popOutCall(const QString& convId, const QString& accountId);

    // Find the first active call across all accounts and pop it out into PiP.
    // No-op if no active call exists or PiP is already active.
    Q_INVOKABLE void popOutFirstActiveCall();

    // Returns true if the given conversation has an active call.
    Q_INVOKABLE bool convHasActiveCall(const QString& convId, const QString& accountId) const;

    // Close the PiP window and select the call's conversation in the main window,
    // effectively "reabsorbing" the call view back into the main window.
    Q_INVOKABLE void reabsorb();

    // Close the PiP window without selecting any conversation.
    Q_INVOKABLE void closeAll();

    // Close the PiP window if it belongs to the given account (used on account switch).
    Q_INVOKABLE void closeForAccount(const QString& accountId);

#ifdef BUILD_TESTING
    // Test backdoor: simulate an active PiP without a real window.
    // Only available in test builds (BUILD_TESTING defined).
    Q_INVOKABLE void setTestPipState(const QString& convId,
                                     const QString& accountId,
                                     const QString& callId);
#endif

Q_SIGNALS:
    void isPipActiveChanged();
    void pipConvIdChanged();
    void pipCallIdChanged();
    void pipAccountIdChanged();
    void pipPreviewIdChanged();
    void pipIsAudioMutedChanged();
    void pipIsCapturingChanged();
    void pipPeerVideoMutedChanged();
    void pipPeerUriChanged();
    void pipActiveSpeakerUriChanged();
    void pipActiveSpeakerSinkIdChanged();
    void pipIsEmptyConferenceChanged();
    void pipIsConferenceChanged();

private Q_SLOTS:
    void onCallStatusChanged(const QString& accountId, const QString& callId, int code);
    void onCallInfosChanged(const QString& accountId, const QString& callId);
    void onParticipantUpdated(const QString& callId);
    void onConferenceInfosUpdated(const QString& confId);

private:
    void closePip();
    void connectCallModel(const QString& accountId);
    void disconnectCallModel();
    void updateMuteState();
    void updatePeerVideoState();
    void updateConferenceVideoState();
    // void checkDeadActiveSpeaker(const QList<ParticipantInfos>& conferenceParticipants);

    QQmlEngine* engine_;
    LRCInstance* lrcInstance_;
    QPointer<QQuickWindow> window_;

    QString pipConvId_;
    QString pipAccountId_;
    QString pipCallId_;
    bool pipIsAudioMuted_ {false};
    bool pipIsCapturing_ {false};
    bool pipPeerVideoMuted_ {true};
    QString pipPeerUri_;
    // For conferences
    QString pipActiveSpeakerUri_;
    QString pipActiveSpeakerSinkId_;
    bool pipIsEmptyConference_ {false};
    bool pipIsConference_ {false};

#ifdef BUILD_TESTING
    // Set by setTestPipState() to simulate an active PiP without a real window.
    bool testPipActive_ {false};
#endif

    // Connection handles for the active call model, so we can disconnect on cleanup.
    QMetaObject::Connection callModelConnection_;
    QMetaObject::Connection callInfosConnection_;
    QMetaObject::Connection participantsConnection_;
    QMetaObject::Connection conferenceInfosUpdatedConnection_;
};
