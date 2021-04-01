/*
 * Copyright (C) 2021 by Savoir-faire Linux
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

#include "systemtray.h"

#include "appsettingsmanager.h"

#ifdef USE_LIBNOTIFY
#include <libnotify/notification.h>
#include <libnotify/notify.h>
#include <memory>

struct Notification
{
    std::shared_ptr<NotifyNotification> nn;
    QString convUid;
};

using NotifyCb = NotifyActionCallback;

struct SystemTray::SystemTrayImpl
{
    std::map<QString, Notification> notifications;
    bool actions {false};
    bool append {false};
    SystemTray* parent;

    SystemTrayImpl(SystemTray* parent)
        : parent(parent)
    {}

    void addNotificationAction(Notification& n,
                               const QString& actionName,
                               NotifyCb callback,
                               const QString& prefix = {})
    {
        notify_notification_add_action(n.nn.get(),
                                       (prefix + n.convUid).toStdString().c_str(),
                                       actionName.toStdString().c_str(),
                                       callback,
                                       this->parent,
                                       nullptr);
    }
};

static void
openConversation(NotifyNotification*, const char* id, SystemTray* nm)
{
    Q_EMIT nm->openConversationActivated(id);
}

static void
acceptPending(NotifyNotification*, char* id, SystemTray* nm)
{
    Q_EMIT nm->acceptPendingActivated(QString(id).remove("ap:"));
}

static void
refusePending(NotifyNotification*, char* id, SystemTray* nm)
{
    Q_EMIT nm->refusePendingActivated(QString(id).remove("rp:"));
}

static void
answerCall(NotifyNotification*, char* id, SystemTray* nm)
{
    Q_EMIT nm->answerCallActivated(QString(id).remove("ac:"));
}

static void
declineCall(NotifyNotification*, char* id, SystemTray* nm)
{
    Q_EMIT nm->declineCallActivated(QString(id).remove("dc:"));
}
#endif // USE_LIBNOTIFY

SystemTray::SystemTray(AppSettingsManager* settingsManager, QObject* parent)
    : QSystemTrayIcon(parent)
    , settingsManager_(settingsManager)
    , pimpl_(std::make_unique<SystemTrayImpl>(this))
{
#ifdef USE_LIBNOTIFY
    notify_init("Jami");

    // get notify server info
    char* name = nullptr;
    char* vendor = nullptr;
    char* version = nullptr;
    char* spec = nullptr;

    if (notify_get_server_info(&name, &vendor, &version, &spec)) {
        qDebug() << QString("notify server name: %1, vendor: %2, version: %3, spec: %4")
                        .arg(name)
                        .arg(vendor)
                        .arg(version)
                        .arg(spec);
    }

    // check  notify server capabilities
    auto list = notify_get_server_caps();
    while (list) {
        if (g_strcmp0((const char*) list->data, "append") == 0
            || g_strcmp0((const char*) list->data, "x-canonical-append") == 0) {
            pimpl_->append = true;
        }
        if (g_strcmp0((const char*) list->data, "actions") == 0) {
            pimpl_->actions = true;
        }
        list = g_list_next(list);
    }
    g_list_free_full(list, g_free);
#endif
}

SystemTray::~SystemTray()
{
#ifdef USE_LIBNOTIFY
    notify_uninit();
#endif // USE_LIBNOTIFY
    hide();
}

#ifdef Q_OS_LINUX
void
SystemTray::showNotification(const QString& id,
                             const QString& title,
                             const QString& body,
                             NotificationType type,
                             const QString& convUid)
{
    if (!settingsManager_->getValue(Settings::Key::EnableNotifications).toBool())
        return;

#ifdef USE_LIBNOTIFY
    std::shared_ptr<NotifyNotification> notification(
        notify_notification_new(title.toStdString().c_str(), body.toStdString().c_str(), nullptr),
        g_object_unref);
    Notification n = {notification, convUid};
    pimpl_->notifications.emplace(id, n);

    // TODO: notify_notification_set_image_from_pixbuf <- GdkPixbuf

    if (type != NotificationType::CHAT) {
        notify_notification_set_urgency(notification.get(), NOTIFY_URGENCY_CRITICAL);
        notify_notification_set_timeout(notification.get(), NOTIFY_EXPIRES_DEFAULT);
    } else {
        notify_notification_set_urgency(notification.get(), NOTIFY_URGENCY_NORMAL);
    }

    if (pimpl_->actions) {
        if (type == NotificationType::CALL) {
            pimpl_->addNotificationAction(n, tr("Answer"), (NotifyCb) answerCall, "ac:");
            pimpl_->addNotificationAction(n, tr("Decline"), (NotifyCb) declineCall, "dc:");
        } else {
            pimpl_->addNotificationAction(n, tr("Open conversation"), (NotifyCb) openConversation);
            if (type != NotificationType::CHAT) {
                pimpl_->addNotificationAction(n, tr("Accept"), (NotifyCb) acceptPending, "ap:");
                pimpl_->addNotificationAction(n, tr("Refuse"), (NotifyCb) refusePending, "rp:");
            }
        }
    }

    GError* error = nullptr;
    notify_notification_show(notification.get(), &error);
    if (error) {
        qWarning("failed to show notification: %s", error->message);
        g_clear_error(&error);
    }
#else
    Q_UNUSED(id)
    Q_UNUSED(title)
    Q_UNUSED(body)
    Q_UNUSED(type)
    Q_UNUSED(convUid)
#endif // USE_LIBNOTIFY
}

#else
void
SystemTray::showNotification(const QString& message,
                             const QString& from,
                             std::function<void()> const& onClickedCb)
{
    if (!settingsManager_->getValue(Settings::Key::EnableNotifications).toBool())
        return;

    setOnClickedCallback(std::move(onClickedCb));

    if (from.isEmpty())
        showMessage(message, "", QIcon(":images/jami.png"));
    else
        showMessage(from, message, QIcon(":images/jami.png"));
}

template<typename Func>
void
SystemTray::setOnClickedCallback(Func&& onClicked)
{
    disconnect(messageClicked_);
    messageClicked_ = connect(this, &QSystemTrayIcon::messageClicked, onClicked);
}
#endif
