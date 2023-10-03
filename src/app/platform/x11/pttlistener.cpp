/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Edric Ladent Milaret <edric.ladent-milaret@savoirfairelinux.com>
 * Author: Anthony Léonard <anthony.leonard@savoirfairelinux.com>
 * Author: Olivier Soldano <olivier.soldano@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 * Author: Isa Nanic <isa.nanic@savoirfairelinux.com>
 * Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
 * Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

#include "pttlistener.h"

#include <QCoreApplication>
#include <QVariant>

#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include <thread>

class PTTListener::Impl : public QObject
{
    Q_OBJECT
public:
    Impl(PTTListener* parent)
        : QObject(nullptr)
        , parent_(*parent)
        , display_(XOpenDisplay(NULL))
        , root_(DefaultRootWindow(display_))
    {
        thread_.reset(new QThread());
        qDebug() << "before moveToThread";
        moveToThread(thread_.get());
    }

    ~Impl()
    {
        stopListening();
        XCloseDisplay(display_);
    };

    void startListening()
    {
        stop_.store(false);
        connect(thread_.get(), &QThread::started, this, &Impl::processEvents);
        thread_->start();
    }

    void stopListening()
    {
        stop_.store(true);
        thread_->quit();
        thread_->wait();
    }

    KeySym getKeySymFromQtKey(Qt::Key qtKey);

    QString keySymToQString(KeySym ks);


private Q_SLOTS:
    void processEvents()
    {
        Window curFocus;
        char buf[17];
        KeySym ks;
        XComposeStatus comp;
        int len;
        int revert;
        static auto flags = KeyPressMask | KeyReleaseMask | FocusChangeMask;

        XGetInputFocus(display_, &curFocus, &revert);
        XSelectInput(display_, curFocus, flags);
        bool pressed = false;
        KeySym key = getKeySymFromQtKey(parent_.currentKey_);

        while (!stop_.load()) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            while (XPending(display_)) {
                XEvent ev;

                XNextEvent(display_, &ev);
                XLookupString(&ev.xkey, buf, 16, &ks, &comp);
                switch (ev.type) {
                case FocusOut:
                    if (curFocus != root_)
                        XSelectInput(display_, curFocus, 0);
                    XGetInputFocus(display_, &curFocus, &revert);
                    if (curFocus == PointerRoot)
                        curFocus = root_;
                    XSelectInput(display_, curFocus, flags);
                    break;

                case KeyPress: {
                    if (!(pressed) && ks == key) {
                        Q_EMIT parent_.PTTKeyPressed();
                        pressed = true;
                    }
                    break;
                }

                case KeyRelease:
                    bool is_retriggered = false;
                    if (XEventsQueued(display_, QueuedAfterReading)) {
                        XEvent nev;
                        XPeekEvent(display_, &nev);
                        if (nev.type == KeyPress && nev.xkey.time == ev.xkey.time
                            && nev.xkey.keycode == ev.xkey.keycode) {
                            is_retriggered = true;
                        }
                    }
                    if (!is_retriggered && ks == key) {
                        Q_EMIT parent_.PTTKeyReleased();
                        pressed = false;
                    }
                    break;
                }
            }
        }
    }

private:
    PTTListener& parent_;
    Display* display_;
    Window root_;
    QScopedPointer<QThread> thread_;
    std::atomic_bool stop_ {false};
};

QString
PTTListener::Impl::keySymToQString(KeySym ks)
{
    char* keyString = XKeysymToString(ks);
    return QString::fromUtf8(XKeysymToString(ks));
}

PTTListener::PTTListener(QObject* parent)
    : QObject(parent)
    , pimpl_(std::make_unique<Impl>(this))
{}

PTTListener::~PTTListener() = default;

void
PTTListener::startListening()
{
    pimpl_->startListening();
}

void
PTTListener::stopListening()
{
    pimpl_->stopListening();
}
KeySym
PTTListener::Impl::getKeySymFromQtKey(Qt::Key qtKey)
{
    QString keyString = QKeySequence(qtKey).toString().toLower();
    KeySym keySym = XStringToKeysym(keyString.toUtf8().data());
    return keySym;
}

#include "pttlistener.moc"
