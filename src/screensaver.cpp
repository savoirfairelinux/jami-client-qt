/*!
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Albert Babí <albert.babi@savoirfairelinux.com>
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

#include "screensaver.h"

#include <QDebug>

ScreenSaver::ScreenSaver(QObject* parent)
#ifdef Q_OS_LINUX
    : QObject(parent),
      sessionBus_(QDBusConnection::sessionBus()),
      screenSaverInterface_(nullptr)
{
    cookieRequest_ = 0u;
    createInterface();
}
#else
    : QObject(parent) {}
#endif

#ifdef Q_OS_LINUX
bool
ScreenSaver::createInterface(void)
{
    if (!sessionBus_.isConnected()) {
        qWarning() << "dbus not connected";
        return false;
    }

    for(int i = 0; i <= N_SERVICES ; i++) {
        screenSaverInterface_ = new QDBusInterface(services_[i],
                                                   paths_[i],
                                                   services_[i],
                                                   sessionBus_);
        if (screenSaverInterface_->isValid()) {
            qDebug() << "ScreenSaver dbus interface: " << services_[i];
            return true;
        }
    }
    screenSaverInterface_ = nullptr;
    return false;
}
#endif

bool
ScreenSaver::inhibit(void)
{
#ifdef Q_OS_LINUX
    if (!screenSaverInterface_) {
        if (!createInterface()) {
            qWarning() << "Error inhibiting screen saver: interface not found";
            return false;
        }
    }

    QDBusReply<uint> reply = screenSaverInterface_->call("Inhibit",
                                                         "jami-qt",
                                                         "In a call");
    if (reply.isValid()) {
        qDebug() << "Screen saver inhibited" << reply.value();
        cookieRequest_ = static_cast<uint>(reply.value());
        qDebug() << cookieRequest_;
        return true;
    } else {
        QDBusError error = reply.error();
        qDebug() << "Error inhibiting screen saver: "
                 << error.message()
                 << error.name();
    }
#endif
    return false;
}



bool
ScreenSaver::uninhibit(void)
{
#ifdef Q_OS_LINUX
    if (cookieRequest_ == 0u) {
        qWarning() << "Cannot uninhibit screen saver: request not found";
        return false;
    }

    if (!screenSaverInterface_) {
        if (!createInterface()) {
            qWarning() << "Error uninhibiting screen saver";
            return false;
        }
    }
    qDebug() << cookieRequest_;

    QDBusReply<void> reply = screenSaverInterface_->call("UnInhibit", cookieRequest_);
    if (reply.isValid()) {
        qDebug() << "Screen saveer uninhibited";
        cookieRequest_ = 0u;
        return true;
    } else {
        QDBusError error = reply.error();
        qDebug() << "Error uninhibiting screen saver: "
                 << error.message()
                 << error.name();
    }

    cookieRequest_ = 0u;
#endif
    return false;
}
