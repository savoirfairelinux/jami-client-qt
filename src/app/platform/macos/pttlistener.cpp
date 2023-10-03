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
