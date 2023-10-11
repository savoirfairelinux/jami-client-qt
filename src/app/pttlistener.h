#pragma once

#include <QObject>
#include <QThread>
#include <QKeyEvent>

class PTTListener : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(PTTListener)

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

    Q_INVOKABLE Qt::Key getCurrentKey()
    {
        return currentKey_;
    }

    Q_INVOKABLE QString keyToString(Qt::Key key)
    {
        return QKeySequence(key).toString();
    }

    Q_INVOKABLE QString keyEventToString(QKeyEvent* event);
    Q_INVOKABLE void setPttKey(Qt::Key key)
    {
        currentKey_ = key;
    }

Q_SIGNALS:
    void PTTKeyPressed();
    void PTTKeyReleased();

public Q_SLOTS:
    void startListening();
    void stopListening();

private:
    PTTListener(QObject* parent = nullptr);
    ~PTTListener();
    class Impl;
    std::unique_ptr<Impl> pimpl_;
    bool pttOn_ = true;
    Qt::Key currentKey_ = Qt::Key_Space;
};
