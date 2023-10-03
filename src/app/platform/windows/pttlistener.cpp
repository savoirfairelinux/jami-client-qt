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

#include <windows.h>

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
        keyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, GlobalKeyboardProc, NULL, 0);
    }

    void stopListening()
    {
        UnhookWindowsHookEx(keyboardHook);
    }

    static LRESULT CALLBACK GlobalKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam)
    {
        auto* pThis = qApp->property("PTTListener").value<PTTListener*>();
        if (pThis == nullptr) {
            qWarning() << "PTTListener not found";
            return {};
        }
        auto* keyboardHook = pThis->pimpl_->keyboardHook;
        DWORD key = VK_SPACE;
        static bool isKeyDown = false;
        if (nCode == HC_ACTION) {
            if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
                KBDLLHOOKSTRUCT* keyInfo = reinterpret_cast<KBDLLHOOKSTRUCT*>(lParam);
                if (keyInfo->vkCode == key && !isKeyDown) {
                    Q_EMIT pThis->pttKeyPressed();
                    isKeyDown = true;
                }
            } else if (wParam == WM_KEYUP || wParam == WM_SYSKEYUP) {
                KBDLLHOOKSTRUCT* keyInfo = reinterpret_cast<KBDLLHOOKSTRUCT*>(lParam);
                if (keyInfo->vkCode == key) {
                    Q_EMIT pThis->pttKeyReleased();
                    isKeyDown = false;
                }
            }
        }

        return CallNextHookEx(keyboardHook, nCode, wParam, lParam);
    }

    HHOOK keyboardHook;
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
