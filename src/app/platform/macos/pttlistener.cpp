/*
 * Copyright (C) 2020-2023 Savoir-faire Linux Inc.
 * Author: Capucine Berthet <capucine.berthet@savoirfairelinux.com>
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
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

PTTListener::PTTListener(QObject* parent)
    : QObject(parent)
{
    qApp->setProperty("PTTListener", QVariant::fromValue(this));
    moveToThread(&workerThread);
    workerThread.start();
}

PTTListener::~PTTListener()
{
    stopListening();
    workerThread.quit();
    workerThread.wait();
}

void
PTTListener::startListening()
{
    keyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, GlobalKeyboardProc, NULL, 0);
}

void
PTTListener::stopListening()
{
    UnhookWindowsHookEx(keyboardHook);
}

LRESULT CALLBACK
PTTListener::GlobalKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    auto* pThis = qApp->property("PTTListener").value<PTTListener*>();
    if (pThis == nullptr) {
        qWarning() << "PTTListener not found";
        return CallNextHookEx(keyboardHook, nCode, wParam, lParam);
    }
    if (nCode == HC_ACTION) {
        if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
            Q_EMIT pThis->PTTKeyPressed();
        } else if (wParam == WM_KEYUP || wParam == WM_SYSKEYUP) {
            Q_EMIT pThis->PTTKeyReleased();
        }
    }

    return CallNextHookEx(keyboardHook, nCode, wParam, lParam);
}

HHOOK PTTListener::keyboardHook = nullptr;
