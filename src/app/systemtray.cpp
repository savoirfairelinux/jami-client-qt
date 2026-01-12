/*
 * Copyright (C) 2021-2026 Savoir-faire Linux Inc.
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
#include "global.h"

#ifdef USE_LIBNOTIFY
#include <libnotify/notification.h>
#include <libnotify/notify.h>
#include <memory>

struct Notification
{
    std::shared_ptr<NotifyNotification> nn;
    QString id;
};

static void
openConversation(NotifyNotification*, char* action, SystemTray* nm)
{
    QStringList sl = QString(action).split(";");
    Q_EMIT nm->openConversationActivated(sl.at(1), sl.at(2));
}

static void
acceptPending(NotifyNotification*, char* action, SystemTray* nm)
{
    QStringList sl = QString(action).split(";");
    Q_EMIT nm->acceptPendingActivated(sl.at(1), sl.at(2));
}

static void
declinePending(NotifyNotification*, char* action, SystemTray* nm)
{
    QStringList sl = QString(action).split(";");
    Q_EMIT nm->declinePendingActivated(sl.at(1), sl.at(2));
}

void
acceptCall(NotifyNotification*, char* action, SystemTray* nm)
{
    QStringList sl = QString(action).split(";");
    Q_EMIT nm->acceptCallActivated(sl.at(1), sl.at(2));
}

void
declineCall(NotifyNotification*, char* action, SystemTray* nm)
{
    QStringList sl = QString(action).split(";");
    Q_EMIT nm->declineCallActivated(sl.at(1), sl.at(2));
}
#endif // USE_LIBNOTIFY

struct SystemTray::SystemTrayImpl
{
    SystemTray* parent;
    SystemTrayImpl(SystemTray* parent)
        : parent(parent)
    {}

#ifdef USE_LIBNOTIFY
    std::map<QString, Notification> notifications;
    bool actions {false};
    bool append {false};

    void addNotificationAction(Notification& n, const QString& actionName, void* callback)
    {
        notify_notification_add_action(n.nn.get(),
                                       (actionName + ";" + n.id).toStdString().c_str(),
                                       actionName.toStdString().c_str(),
                                       (NotifyActionCallback) callback,
                                       this->parent,
                                       nullptr);
    }
#endif
};

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
        C_INFO << QString("notify server name: %1, vendor: %2, version: %3, spec: %4").arg(name, vendor, version, spec);
    }

    // check  notify server capabilities
    auto serverCaps = notify_get_server_caps();
    while (serverCaps) {
        if (g_strcmp0((const char*) serverCaps->data, "append") == 0
            || g_strcmp0((const char*) serverCaps->data, "x-canonical-append") == 0) {
            pimpl_->append = true;
        }
        if (g_strcmp0((const char*) serverCaps->data, "actions") == 0) {
            pimpl_->actions = true;
        }
        serverCaps = g_list_next(serverCaps);
    }
    g_list_free_full(serverCaps, g_free);
#endif
}

SystemTray::~SystemTray()
{
#ifdef USE_LIBNOTIFY
    // Clearing notifications to ensure that g_object_unref is called on every
    // NotifyNotification object *before* we call notify_uninit. This isn't strictly
    // necessary, but if we don't do it, then the destructor will call g_object_unref
    // anyway, and this will happen *after* notify_uninit, which causes GLib to
    // generate cryptic warnings when Jami shuts down, e.g.:
    // `instance '0x5627a4e236a0' has no handler with id '309'`
    pimpl_->notifications.clear();

    notify_uninit();
#endif // USE_LIBNOTIFY
    hide();
}

void
SystemTray::onNotificationCountChanged(int count)
{
    if (count == 0) {
        setIcon(QIcon(":/images/net.jami.Jami.svg"));
    } else {
        setIcon(QIcon(":/images/jami-new.svg"));
    }
    Q_EMIT countChanged();
}

#ifdef Q_OS_LINUX
bool
SystemTray::hideNotification(const QString& id)
{
#if USE_LIBNOTIFY
    // Search
    auto notification = pimpl_->notifications.find(id);
    if (notification == pimpl_->notifications.end()) {
        return false;
    }

    // Close
    GError* error = nullptr;
    if (!notify_notification_close(notification->second.nn.get(), &error)) {
        C_WARN << QString("An error occurred while closing notification: %1").arg(error->message);
        g_clear_error(&error);
        return false;
    }

    // Erase
    pimpl_->notifications.erase(id);
#endif

    return true;
}

void
SystemTray::showNotification(
    const QString& id, const QString& title, const QString& body, NotificationType type, const QByteArray& avatar)
{
    if (!settingsManager_->getValue(Settings::Key::EnableNotifications).toBool())
        return;

#ifdef USE_LIBNOTIFY
    // clear out an existing notification
    if (pimpl_->notifications.find(id) != pimpl_->notifications.end())
        hideNotification(id);

    std::shared_ptr<NotifyNotification> notification(notify_notification_new(title.toStdString().c_str(),
                                                                             body.toStdString().c_str(),
                                                                             nullptr),
                                                     g_object_unref);
    Notification n = {notification, id};

    pimpl_->notifications.emplace(id, n);

    if (!avatar.isEmpty()) {
        GError* error = nullptr;
        GdkPixbuf* pixbuf = nullptr;
        GInputStream* stream = nullptr;
        stream = g_memory_input_stream_new_from_data(avatar.constData(), avatar.size(), NULL);
        pixbuf = gdk_pixbuf_new_from_stream(stream, nullptr, &error);
        g_input_stream_close(stream, nullptr, nullptr);
        g_object_unref(stream);
        notify_notification_set_image_from_pixbuf(notification.get(), pixbuf);
    }

    if (type != NotificationType::CHAT) {
        notify_notification_set_urgency(notification.get(), NOTIFY_URGENCY_CRITICAL);
        notify_notification_set_timeout(notification.get(), NOTIFY_EXPIRES_DEFAULT);
    } else {
        notify_notification_set_urgency(notification.get(), NOTIFY_URGENCY_NORMAL);
    }

    if (pimpl_->actions) {
        if (type == NotificationType::CALL) {
            pimpl_->addNotificationAction(n, tr("Accept call"), (void*) acceptCall);
            pimpl_->addNotificationAction(n, tr("Decline call"), (void*) declineCall);
        } else {
            pimpl_->addNotificationAction(n, tr("Open conversation"), (void*) openConversation);
            if (type != NotificationType::CHAT) {
                pimpl_->addNotificationAction(n, tr("Accept invitation"), (void*) acceptPending);
                pimpl_->addNotificationAction(n, tr("Decline invitation"), (void*) declinePending);
            }
        }
    }

    GError* error = nullptr;
    notify_notification_show(notification.get(), &error);
    if (error) {
        C_WARN << QString("failed to show notification: %1").arg(error->message);
        g_clear_error(&error);
    }
#else
    Q_UNUSED(id)
    Q_UNUSED(title)
    Q_UNUSED(body)
    Q_UNUSED(type)
#endif // USE_LIBNOTIFY
}

#else
void
SystemTray::showNotification(const QString& message, const QString& from, std::function<void()> const& onClickedCb)
{
    if (!settingsManager_->getValue(Settings::Key::EnableNotifications).toBool())
        return;

    setOnClickedCallback(std::move(onClickedCb));

    if (from.isEmpty())
        showMessage(message, "", QIcon(":images/net.jami.Jami.svg"));
    else
        showMessage(from, message, QIcon(":images/net.jami.Jami.svg"));
}

template<typename Func>
void
SystemTray::setOnClickedCallback(Func&& onClicked)
{
    disconnect(messageClicked_);
    messageClicked_ = connect(this, &QSystemTrayIcon::messageClicked, onClicked);
}
#endif
