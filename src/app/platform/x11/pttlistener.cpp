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

<<<<<<< Updated upstream
=======
    KeySym getKeySymFromQtKey(Qt::Key qtKey);

    QString keySymToQString(KeySym ks);


>>>>>>> Stashed changes
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
<<<<<<< Updated upstream

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
                if (!(pressed) && ks == XK_space) {
                    Q_EMIT parent_.PTTKeyPressed();
                    pressed = true;
=======
        // KeySym key = XK_a;
        KeySym key = getKeySymFromQtKey(parent_.currentKey_);

        while (!stop_.load()) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
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
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                if (!is_retriggered && ks == XK_space) {
                    Q_EMIT parent_.PTTKeyReleased();
                    pressed = false;
                }
                break;
            }
            if (thread_->isFinished()) {
                qDebug() << "fini";
=======
>>>>>>> Stashed changes
            }
        }
    }

private:
    PTTListener& parent_;
    Display* display_;
    Window root_;
    QScopedPointer<QThread> thread_;
    std::atomic_bool stop_ {false};
    static const unsigned int KeyTbl_[];
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
<<<<<<< Updated upstream
=======
KeySym
PTTListener::Impl::getKeySymFromQtKey(Qt::Key qtKey)
{
    QString keyString = QKeySequence(qtKey).toString().toLower();
    KeySym keySym = XStringToKeysym(keyString.toUtf8().data());
    //    if (keySym == NoSymbol) {
    //        const int numEntries = sizeof(KeyTbl) / (2 * sizeof(unsigned int));

    //            for (int i = 0; i < numEntries; ++i) {
    //                if (KeyTbl[2 * i + 1] == static_cast<unsigned int>(qtKey)) {
    //                    return static_cast<KeySym>(KeyTbl[2 * i]);
    //                }
    //            }
    //    }
    qDebug() << "********** KeySym converti en QString : " << XKeysymToString(keySym);
    return keySym;
}
>>>>>>> Stashed changes

#include "pttlistener.moc"
