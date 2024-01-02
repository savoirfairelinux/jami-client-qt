/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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

#include <Windows.h>

class PTTListener::Impl : public QObject
{
    Q_OBJECT
public:
    Impl(PTTListener* parent)
        : QObject(nullptr)
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

        quint32 key = qtKeyToVKey(pThis->getCurrentKey());
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

    static quint32 qtKeyToVKey(Qt::Key key);
};

PTTListener::PTTListener(AppSettingsManager* settingsManager, QObject* parent)
    : QObject(parent)
    , pimpl_(std::make_unique<Impl>(this))
    , settingsManager_(settingsManager)
{}

PTTListener::~PTTListener() = default;

#ifdef HAVE_GLOBAL_PTT
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
#endif

quint32
PTTListener::Impl::qtKeyToVKey(Qt::Key key)
{
    switch (key) {
    case Qt::Key_Escape:
        return VK_ESCAPE;
    case Qt::Key_Tab:
    case Qt::Key_Backtab:
        return VK_TAB;
    case Qt::Key_Backspace:
        return VK_BACK;
    case Qt::Key_Return:
    case Qt::Key_Enter:
        return VK_RETURN;
    case Qt::Key_Insert:
        return VK_INSERT;
    case Qt::Key_Delete:
        return VK_DELETE;
    case Qt::Key_Pause:
        return VK_PAUSE;
    case Qt::Key_Print:
        return VK_PRINT;
    case Qt::Key_Clear:
        return VK_CLEAR;
    case Qt::Key_Home:
        return VK_HOME;
    case Qt::Key_End:
        return VK_END;
    case Qt::Key_Left:
        return VK_LEFT;
    case Qt::Key_Up:
        return VK_UP;
    case Qt::Key_Right:
        return VK_RIGHT;
    case Qt::Key_Down:
        return VK_DOWN;
    case Qt::Key_PageUp:
        return VK_PRIOR;
    case Qt::Key_PageDown:
        return VK_NEXT;
    case Qt::Key_F1:
        return VK_F1;
    case Qt::Key_F2:
        return VK_F2;
    case Qt::Key_F3:
        return VK_F3;
    case Qt::Key_F4:
        return VK_F4;
    case Qt::Key_F5:
        return VK_F5;
    case Qt::Key_F6:
        return VK_F6;
    case Qt::Key_F7:
        return VK_F7;
    case Qt::Key_F8:
        return VK_F8;
    case Qt::Key_F9:
        return VK_F9;
    case Qt::Key_F10:
        return VK_F10;
    case Qt::Key_F11:
        return VK_F11;
    case Qt::Key_F12:
        return VK_F12;
    case Qt::Key_F13:
        return VK_F13;
    case Qt::Key_F14:
        return VK_F14;
    case Qt::Key_F15:
        return VK_F15;
    case Qt::Key_F16:
        return VK_F16;
    case Qt::Key_F17:
        return VK_F17;
    case Qt::Key_F18:
        return VK_F18;
    case Qt::Key_F19:
        return VK_F19;
    case Qt::Key_F20:
        return VK_F20;
    case Qt::Key_F21:
        return VK_F21;
    case Qt::Key_F22:
        return VK_F22;
    case Qt::Key_F23:
        return VK_F23;
    case Qt::Key_F24:
        return VK_F24;
    case Qt::Key_Space:
        return VK_SPACE;
    case Qt::Key_Asterisk:
        return VK_MULTIPLY;
    case Qt::Key_Plus:
        return VK_ADD;
    case Qt::Key_Minus:
        return VK_SUBTRACT;
    case Qt::Key_Slash:
        return VK_DIVIDE;
    case Qt::Key_MediaNext:
        return VK_MEDIA_NEXT_TRACK;
    case Qt::Key_MediaPrevious:
        return VK_MEDIA_PREV_TRACK;
    case Qt::Key_MediaPlay:
        return VK_MEDIA_PLAY_PAUSE;
    case Qt::Key_MediaStop:
        return VK_MEDIA_STOP;
        // couldn't find those in VK_*
        // case Qt::Key_MediaLast:
        // case Qt::Key_MediaRecord:
    case Qt::Key_VolumeDown:
        return VK_VOLUME_DOWN;
    case Qt::Key_VolumeUp:
        return VK_VOLUME_UP;
    case Qt::Key_VolumeMute:
        return VK_VOLUME_MUTE;
    case Qt::Key_0:
        return VK_NUMPAD0;
    case Qt::Key_1:
        return VK_NUMPAD1;
    case Qt::Key_2:
        return VK_NUMPAD2;
    case Qt::Key_3:
        return VK_NUMPAD3;
    case Qt::Key_4:
        return VK_NUMPAD4;
    case Qt::Key_5:
        return VK_NUMPAD5;
    case Qt::Key_6:
        return VK_NUMPAD6;
    case Qt::Key_7:
        return VK_NUMPAD7;
    case Qt::Key_8:
        return VK_NUMPAD8;
    case Qt::Key_9:
        return VK_NUMPAD9;
    case Qt::Key_A:
        return 'A';
    case Qt::Key_B:
        return 'B';
    case Qt::Key_C:
        return 'C';
    case Qt::Key_D:
        return 'D';
    case Qt::Key_E:
        return 'E';
    case Qt::Key_F:
        return 'F';
    case Qt::Key_G:
        return 'G';
    case Qt::Key_H:
        return 'H';
    case Qt::Key_I:
        return 'I';
    case Qt::Key_J:
        return 'J';
    case Qt::Key_K:
        return 'K';
    case Qt::Key_L:
        return 'L';
    case Qt::Key_M:
        return 'M';
    case Qt::Key_N:
        return 'N';
    case Qt::Key_O:
        return 'O';
    case Qt::Key_P:
        return 'P';
    case Qt::Key_Q:
        return 'Q';
    case Qt::Key_R:
        return 'R';
    case Qt::Key_S:
        return 'S';
    case Qt::Key_T:
        return 'T';
    case Qt::Key_U:
        return 'U';
    case Qt::Key_V:
        return 'V';
    case Qt::Key_W:
        return 'W';
    case Qt::Key_X:
        return 'X';
    case Qt::Key_Y:
        return 'Y';
    case Qt::Key_Z:
        return 'Z';

    default:
        // Try to get virtual key from current keyboard layout or US.
        const HKL layout = GetKeyboardLayout(0);
        int vk = VkKeyScanEx(key, layout);
        if (vk == -1) {
            const HKL layoutUs = GetKeyboardLayout(0x409);
            vk = VkKeyScanEx(key, layoutUs);
        }
        return vk == -1 ? 0 : vk;
    }
}

#include "pttlistener.moc"
