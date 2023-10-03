/*
 * Copyright (C) 2023 Savoir-faire Linux Inc.
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

#include <ApplicationServices/ApplicationServices.h>

class PTTListener::Impl : public QObject
{
    Q_OBJECT
public:
    Impl(PTTListener* parent)
        : QObject(parent)
    {
        qApp->setProperty("PTTListener", QVariant::fromValue(parent));
    }

    ~Impl()
    {
        stopListening();
    };

    void startListening()
    {
        CGEventMask eventMask = (1 << kCGEventKeyDown) | (1 << kCGEventKeyUp);
        CFMachPortRef eventTap = CGEventTapCreate(kCGHIDEventTap,
                                                  kCGHeadInsertEventTap,
                                                  kCGEventTapOptionDefault,
                                                  eventMask,
                                                  CGEventCallback,
                                                  this);

        if (eventTap) {
            CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault,
                                                                             eventTap,
                                                                             0);
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
            CFRelease(runLoopSource);

            CGEventTapEnable(eventTap, true);
        } else {
            qDebug() << "Impossible to create the keyboard tap.";
        }
    }

    void stopListening()
    {
        CGEventTapEnable(eventTap, false);
        CFRelease(eventTap);
    }

    static CGEventRef CGEventCallback(CGEventTapProxy proxy,
                                      CGEventType type,
                                      CGEventRef event,
                                      void* refcon)
    {
        auto* pThis = qApp->property("PTTListener").value<PTTListener*>();
        CGKeyCode keycode = (CGKeyCode) CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        CGKeyCode pttKey = (CGKeyCode) 49;
        if (pThis == nullptr) {
            qWarning() << "PTTListener not found";
            return {};
        }
        static bool isKeyDown = false;
        if (keycode == pttkey) {
            if (type == kCGEventKeyDown) {
                Q_EMIT pThis->pttKeyPressed();
                isKeyDown = true;
            } else if (type == kCGEventKeyUp) {
                Q_EMIT pThis->pttKeyReleased();
                isKeyDown = false;
            }
        }
        return event;
    }
};

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

#include "pttlistener.moc"
