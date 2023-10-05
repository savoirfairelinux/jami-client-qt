#pragma once

#include <QObject>
#include <QThread>
#include <QString>
#include <QKeyEvent>

#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

class PTTListener : public QObject
{
    Q_OBJECT

public:
    static PTTListener& getInstance()
    {
        static PTTListener instance;
        return instance;
    }

    Q_INVOKABLE bool getPttState()
    {
        return pttOn_;
    }
    Q_INVOKABLE void setPttState(bool on)
    {
        pttOn_ = on;
    }
    Q_INVOKABLE QString getKeyString();
    Q_INVOKABLE QString keyEventToString(QKeyEvent* event);

Q_SIGNALS:
    void PTTKeyPressed();
    void PTTKeyReleased();

public Q_SLOTS:
    void startListening();
    void stopListening();

private:
    PTTListener(QObject* parent = nullptr);
    ~PTTListener();

    PTTListener(const PTTListener&) = delete;
    void operator=(const PTTListener&) = delete;
    class Impl;
    std::unique_ptr<Impl> pimpl_;
    bool pttOn_ = true;
};
