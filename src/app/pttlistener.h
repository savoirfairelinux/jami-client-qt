#pragma once

#include <QObject>
#include <QThread>

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
    Q_INVOKABLE QString getQKey();

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
};
