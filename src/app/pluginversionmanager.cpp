#include "pluginversionmanager.h"
#include "networkmanager.h"
#include "appsettingsmanager.h"
#include "lrcinstance.h"
#include "api/pluginmodel.h"

#include <QMap>
#include <QTimer>
#include <QDir>

static constexpr int updatePeriod = 1000 * 60 * 60 * 24; // one day in millis

struct PluginVersionManager::Impl : public QObject
{
public:
    Impl(LRCInstance* instance, PluginVersionManager& parent)
        : QObject(nullptr)
        , parent_(parent)
        , lrcInstance_(instance)
        , tempPath_(QDir::tempPath())
        , updateTimer_(new QTimer(this))
        , appSettingsManager_(new AppSettingsManager(this))
    {
        connect(updateTimer_, &QTimer::timeout, this, [this] { checkForUpdates(); });
        connect(&parent_, &NetworkManager::downloadFinished, this, [this](int replyId) {
            auto pluginsId = parent_.pluginRepliesId.keys(replyId);
            if (pluginsId.size() == 0) {
                return;
            }
            for (auto pluginId : pluginsId) {
                Q_EMIT parent_.versionStatusChanged(pluginId, PluginStatus::Role::INSTALLING);
                parent_.pluginRepliesId.remove(pluginId);
            }
        });
        checkForUpdates();
        setAutoUpdateCheck(true);
    }

    ~Impl()
    {
        setAutoUpdateCheck(false);
    }

    void checkForUpdates()
    {
        if (!lrcInstance_) {
            return;
        }
        for (const auto& plugin : lrcInstance_->pluginModel().getInstalledPlugins()) {
            checkVersionStatusFromPath(plugin);
        }
    }

    void cancelUpdate(QString pluginId)
    {
        if (!parent_.pluginRepliesId.contains(pluginId)) {
            return;
        }
        parent_.cancelDownload(parent_.pluginRepliesId[pluginId]);
    };

    bool isAutoUpdaterEnabled()
    {
        return appSettingsManager_->getValue(Settings::Key::PluginAutoUpdate).toBool();
    }

    void setAutoUpdate(bool state)
    {
        appSettingsManager_->setValue(Settings::Key::PluginAutoUpdate, state);
    }

    void checkVersionStatus(const QString& pluginId)
    {
        checkVersionStatusFromPath(lrcInstance_->pluginModel().getPluginPath(pluginId));
    }

    void checkVersionStatusFromPath(const QString& pluginPath)
    {
        if (!lrcInstance_) {
            return;
        }

        auto plugin = lrcInstance_->pluginModel().getPluginDetails(pluginPath);
        if (plugin.version == "" || plugin.id == "") {
            parent_.versionStatusChanged(plugin.id, PluginStatus::Role::FAILED);
            return;
        }

        parent_.sendGetRequest(QUrl(parent_.baseUrl + "/versions/" + plugin.id),
                               [this, plugin](const QByteArray& data) {
                                   const auto version = data;
                                   if (plugin.version < version) {
                                       if (isAutoUpdaterEnabled()) {
                                           installRemotePlugin(plugin.name);
                                           return;
                                       }
                                   }
                                   parent_.versionStatusChanged(plugin.id,
                                                                PluginStatus::Role::UPDATABLE);
                               });
    }

    void installRemotePlugin(const QString& pluginId)
    {
        parent_.downloadFile(
            QUrl(parent_.baseUrl + "/download/" + Utils::getPlatformString() + "/" + pluginId),
            pluginId,
            0,
            [this, pluginId](bool success, const QString& error) {
                if (!success) {
                    qDebug() << "Download Plugin error: " << error;
                    parent_.versionStatusChanged(pluginId, PluginStatus::Role::FAILED);
                    return;
                }
                auto res = lrcInstance_->pluginModel().installPlugin(tempPath_ + '/' + pluginId
                                                                         + ".jpl",
                                                                     true);
                if (res) {
                    parent_.versionStatusChanged(pluginId, PluginStatus::Role::INSTALLED);
                } else {
                    parent_.versionStatusChanged(pluginId, PluginStatus::Role::FAILED);
                }
            },
            tempPath_ + '/');
        parent_.versionStatusChanged(pluginId, PluginStatus::Role::DOWNLOADING);
    }

    void setAutoUpdateCheck(bool state)
    {
        // Quiet check for updates periodically, if set to.
        if (!state) {
            updateTimer_->stop();
            return;
        }
        updateTimer_->start(updatePeriod);
    };

    PluginVersionManager& parent_;
    AppSettingsManager* appSettingsManager_ {nullptr};
    LRCInstance* lrcInstance_ {nullptr};
    QString tempPath_;
    QTimer* updateTimer_;
};

PluginVersionManager::PluginVersionManager(LRCInstance* instance, QString& baseUrl, QObject* parent)
    : NetworkManager(NULL, parent)
    , pimpl_(std::make_unique<Impl>(instance, *this))
    , baseUrl(baseUrl)
{}

PluginVersionManager::~PluginVersionManager()
{
    for (auto pluginReplyId : pluginRepliesId) {
        cancelDownload(pluginReplyId);
    }
    pluginRepliesId.clear();
}

void
PluginVersionManager::cancelUpdate(QString pluginId)
{
    pimpl_->cancelUpdate(pluginId);
}

bool
PluginVersionManager::isAutoUpdaterEnabled()
{
    return pimpl_->isAutoUpdaterEnabled();
}

void
PluginVersionManager::setAutoUpdate(bool state)
{
    pimpl_->setAutoUpdate(state);
}

unsigned int
PluginVersionManager::downloadFile(const QUrl& url,
                                   const QString& pluginId,
                                   unsigned int replyId,
                                   std::function<void(bool, const QString&)> onDoneCallback,
                                   const QString& filePath)
{
    auto reply = NetworkManager::downloadFile(url, replyId, onDoneCallback, filePath);
    pluginRepliesId[pluginId] = reply;
    return reply;
}

void
PluginVersionManager::checkVersionStatus(const QString& pluginId)
{
    pimpl_->checkVersionStatus(pluginId);
}

void
PluginVersionManager::installRemotePlugin(const QString& pluginId)
{
    pimpl_->installRemotePlugin(pluginId);
}
