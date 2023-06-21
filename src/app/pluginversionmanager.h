#pragma once

#include <memory>
#include "abstractupdatemanager.h"

class QString;
class LRCInstance;

class PluginVersionManager final : public AbstractUpdateManager
{
    Q_OBJECT
public:
    explicit PluginVersionManager(LRCInstance* instance, QObject* parent = nullptr);
    ~PluginVersionManager();

    Q_INVOKABLE void checkForUpdates(bool quiet = false) override;
    Q_INVOKABLE void applyUpdates(bool beta = false) override;
    Q_INVOKABLE bool isUpdaterEnabled() override;
    Q_INVOKABLE bool isAutoUpdaterEnabled() override;
    Q_INVOKABLE void setAutoUpdateCheck(bool state) override;
    Q_INVOKABLE void cancelUpdate(QString pluginId);
    QMap<QString, unsigned int> pluginRepliesId {};

Q_SIGNALS:
    // void updatable(QString pluginId);
    // void downloadProgress(QString pluginId, qint64 bytesReceived, qint64 bytesTotal);
    void downloadFinished(QString pluginId);
    void downloadStarted(QString pluginId);

private:
    struct Impl;
    std::unique_ptr<Impl> pimpl_;
};
Q_DECLARE_METATYPE(PluginVersionManager*)
