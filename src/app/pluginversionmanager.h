#pragma once

#include <memory>
#include "abstractupdatemanager.h"

class QString;
class LRCInstance;

#define PLUGIN_STATUS_ROLES \
    X(INSTALLABLE) \
    X(DOWNLOADING) \
    X(INSTALLING) \
    X(INSTALLED) \
    X(FAILED) \
    X(UPDATABLE)

namespace PluginStatus {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    PLUGIN_STATUS_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace PluginStatus

class PluginVersionManager final : public AbstractUpdateManager
{
    Q_OBJECT
public:
    explicit PluginVersionManager(LRCInstance* instance,
                                  QString& baseUrl,
                                  QObject* parent = nullptr);
    ~PluginVersionManager();

    Q_INVOKABLE bool isAutoUpdaterEnabled() override;

    Q_INVOKABLE void cancelUpdate(QString pluginId);
    unsigned int downloadFile(const QUrl& url,
                              const QString& pluginId,
                              unsigned int replyId,
                              std::function<void(bool, const QString&)> onDoneCallback,
                              const QString& filePath);
    void installRemotePlugin(const QString& pluginId);

public Q_SLOTS:
    void checkVersionStatus(const QString& pluginId);
    void setAutoUpdate(bool state);

Q_SIGNALS:
    void versionStatusChanged(QString pluginId, PluginStatus::Role status);

private:
    QString baseUrl;
    bool autoUpdateCheck = false;
    QMap<QString, unsigned int> pluginRepliesId {};
    struct Impl;
    friend struct Impl;
    std::unique_ptr<Impl> pimpl_;
};
Q_DECLARE_METATYPE(PluginVersionManager*)
