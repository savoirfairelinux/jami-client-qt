#include "pttlistener.h"

#include <QCoreApplication>
#include <QVariant>

#include <windows.h>

class
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
        if (nCode == HC_ACTION) {
            if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
                Q_EMIT pThis->PTTKeyPressed();
            } else if (wParam == WM_KEYUP || wParam == WM_SYSKEYUP) {
                Q_EMIT pThis->PTTKeyReleased();
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
