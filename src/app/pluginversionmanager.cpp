#include "pluginversionmanager.h"
#include "networkmanager.h"
#include "lrcinstance.h"

#include <QMap>
#include <QTimer>
#include <QDir>

struct PluginVersionManager::Impl : public QObject
{
    Impl(LRCInstance* instance, PluginVersionManager& parent)
        : QObject(nullptr)
        , parent_(parent)
        , lrcInstance_(instance)
        , tempPath_(QDir::tempPath())
        , updateTimer_(new QTimer(this))
    {
        connect(updateTimer_, &QTimer::timeout, this, [this] {
            // Quiet period update check.
            parent_.checkForUpdates(true);
        });

        connect(&parent_, &NetworkManager::downloadFinished, this, [this](int replyId) {
            auto pluginsId = parent_.pluginRepliesId.keys(replyId);
            if (pluginsId.size() == 0) {
                return;
            }
            for (auto pluginId : pluginsId) {
                Q_EMIT parent_.downloadFinished(pluginId);
                parent_.pluginRepliesId.remove(pluginId);
            }
        });
    }

    ~Impl() = default;

    void checkForUpdates(bool quiet)
    {
        // TODO: should download the last version of all plugins and check version
    }

    void applyUpdates(bool beta = false)
    {
        // TODO: should download the last version of all plugins and install
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
        // TODO: should be trigger when the user enable the auto update
        return false;
    }

    bool isUpdaterEnabled()
    {
        // TODO: should check state of the updater
        return false;
    }

    void setAutoUpdateCheck(bool state)
    {
        // TODO: should call the api to fetch the new version of all plugins
    }
    PluginVersionManager& parent_;

    LRCInstance* lrcInstance_ {nullptr};
    QString tempPath_;
    QTimer* updateTimer_;
};

PluginVersionManager::PluginVersionManager(LRCInstance* instance, QObject* parent)
    : AbstractUpdateManager(NULL, parent)
    , pimpl_(std::make_unique<Impl>(instance, *this))
{}

PluginVersionManager::~PluginVersionManager()
{
    for (auto pluginReplyId : pluginRepliesId) {
        cancelDownload(pluginReplyId);
    }
    pluginRepliesId.clear();
}

void
PluginVersionManager::checkForUpdates(bool quiet)
{
    pimpl_->checkForUpdates(quiet);
}

void
PluginVersionManager::applyUpdates(bool beta)
{
    pimpl_->applyUpdates(beta);
}

void
PluginVersionManager::cancelUpdate(QString pluginId)
{
    pimpl_->cancelUpdate(pluginId);
}

bool
PluginVersionManager::isUpdaterEnabled()
{
    return pimpl_->isAutoUpdaterEnabled();
}

bool
PluginVersionManager::isAutoUpdaterEnabled()
{
    return pimpl_->isAutoUpdaterEnabled();
}

void
PluginVersionManager::setAutoUpdateCheck(bool state)
{
    pimpl_->setAutoUpdateCheck(state);
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
