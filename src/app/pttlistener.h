#pragma once

#include <QObject>
#include <QThread>
#include <QKeyEvent>

class PTTListener : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool pttState READ getPttState WRITE setPttState NOTIFY pttStateChanged)

public:
    Q_INVOKABLE bool getPttState()
    {
        return pttState_;
    }

    Q_INVOKABLE void setPttState(bool on)
    {
        if (pttState_ != on) {
            pttState_ = on;
            Q_EMIT pttStateChanged();
        }
    }

    Q_INVOKABLE Qt::Key getCurrentKey()
    {
        return currentKey_;
    }

    Q_INVOKABLE QString keyToString(Qt::Key key)
    {
        return QKeySequence(key).toString();
    }
    Q_INVOKABLE void setPttKey(Qt::Key key)
    {
        currentKey_ = key;
    }

    PTTListener(QObject* parent = nullptr);
    ~PTTListener();

Q_SIGNALS:
    void pttKeyPressed();
    void pttKeyReleased();
    void pttStateChanged();

#ifdef HAVE_GLOBAL_PTT
public Q_SLOTS:
    void startListening();
    void stopListening();
#endif

private:
    class Impl;
    std::unique_ptr<Impl> pimpl_;

    bool pttState_ = true;
    Qt::Key currentKey_ = Qt::Key_Space;
};
