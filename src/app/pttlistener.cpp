
#include "calladapter.h"
#include "pttlistener.h"

#include <QCoreApplication>
#include <QVariant>
#include <QString>

#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

class PTTListener::Impl : public QObject
{
    Q_OBJECT
public:
    Impl(PTTListener* parent)
        : QObject(nullptr)
        , parent_(*parent)
        , display_(XOpenDisplay(NULL))
        , root_(DefaultRootWindow(display_))
    {}

    ~Impl()
    {
        stopListening();
        XCloseDisplay(display_);
    };

    void startListening()
    {
        thread_.reset(new QThread(this));
        moveToThread(thread_.get());
        connect(thread_.get(), &QThread::started, this, &Impl::processEvents);
        thread_->start();
        if (thread_->isRunning()) {
            qDebug() << "thread running";
        }
    }

    void stopListening()
    {
        stop_.store(true);
        // thread_->wait();
    }

    KeySym getCurrentKey() const
    {
        return currentKey_;
    }

    QString keySymToQString(KeySym ks);

    KeySym qKeyToKeySym(QKeyEvent* event);

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

        while (!stop_.load()) {
            XEvent ev;

            XNextEvent(display_, &ev);
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
                XLookupString(&ev.xkey, buf, 16, &ks, &comp);
                if (!(pressed) && ks == currentKey_) {
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
                if (!is_retriggered && ks == XK_space) {
                    Q_EMIT parent_.PTTKeyReleased();
                    pressed = false;
                }
                break;
            }
        }
    }

private:
    PTTListener& parent_;
    Display* display_;
    Window root_;
    QScopedPointer<QThread> thread_;
    std::atomic_bool stop_ {false};
    KeySym currentKey_ = XK_space;
    // QString keyString_ = QString::fromStdString(XKeysymToString(currentKey_));
};

QString
PTTListener::Impl::keySymToQString(KeySym ks)
{
    char* keyString = XKeysymToString(ks);
    if (keyString != nullptr) {
        QString keyQString = QString::fromUtf8(keyString);
    } else {
        qDebug() << "conversion failed";
    }

    return QString::fromUtf8(XKeysymToString(ks));
}

KeySym
PTTListener::Impl::qKeyToKeySym(QKeyEvent* event)
{
    return XStringToKeysym(QKeySequence(event->key()).toString().toLatin1().data());
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

QString
PTTListener::getKeyString()
{
    return pimpl_->keySymToQString(pimpl_->getCurrentKey());
}

QString
PTTListener::keyEventToString(QKeyEvent* event)
{
    KeySym ks = pimpl_->qKeyToKeySym(event);
    return pimpl_->keySymToQString(ks);
}

#include "pttlistener.moc"
