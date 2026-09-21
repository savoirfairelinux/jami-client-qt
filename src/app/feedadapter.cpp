/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include "feedadapter.h"
#include "dbus/configurationmanager.h"
#include "api/contactmodel.h"
#include "api/conversationmodel.h"

#include <QBuffer>
#include <QImage>
#include <QImageReader>

FeedAdapter::FeedAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
{
    refreshTimer_.setSingleShot(true);
    refreshTimer_.setInterval(0);
    connect(&refreshTimer_, &QTimer::timeout, this, &FeedAdapter::reload);
    connect(instance, &LRCInstance::currentAccountIdChanged, this, [this] {
        feeds_.clear();
        clearError();
        Q_EMIT feedsChanged();
        refreshTimer_.start();
    });
    auto schedule = [this](const QString& accountId) {
        if (accountId == lrcInstance_->get_currentAccountId())
            refreshTimer_.start();
    };
    auto& manager = ConfigurationManager::instance();
    connect(&manager, &ConfigurationManagerInterface::feedsChanged, this, schedule);
    connect(&manager,
            &ConfigurationManagerInterface::conversationReady,
            this,
            [schedule](const QString& accountId, const QString&) { schedule(accountId); });
    connect(&manager,
            &ConfigurationManagerInterface::conversationRemoved,
            this,
            [schedule](const QString& accountId, const QString&) { schedule(accountId); });
    connect(&manager,
            &ConfigurationManagerInterface::conversationProfileUpdated,
            this,
            [schedule](const QString& accountId, const QString&, const MapStringString&) { schedule(accountId); });
    connect(&manager,
            &ConfigurationManagerInterface::onConversationError,
            this,
            [this](const QString& accountId, const QString& id, int, const QString& message) {
                if (accountId == lrcInstance_->get_currentAccountId() && (id.isEmpty() || !details(id).isEmpty()))
                    fail(message);
            });
    connect(&instance->behaviorController(),
            &lrc::api::BehaviorController::newUnreadInteraction,
            this,
            [schedule](const QString& accountId, const QString&, const QString&, const lrc::api::interaction::Info&) {
                schedule(accountId);
            });
    connect(&instance->behaviorController(),
            &lrc::api::BehaviorController::newReadInteraction,
            this,
            [schedule](const QString& accountId, const QString&, const QString&) { schedule(accountId); });
    refreshTimer_.start();
}

void
FeedAdapter::fail(const QString& error)
{
    qWarning() << "Feed operation:" << error;
    error_ = error;
    Q_EMIT errorChanged();
}

void
FeedAdapter::clearError()
{
    error_.clear();
    Q_EMIT errorChanged();
}

void
FeedAdapter::reload()
{
    const auto account = lrcInstance_->get_currentAccountId();
    if (account.isEmpty())
        return;
    auto reply = ConfigurationManager::instance().getFeeds(account);
#ifndef ENABLE_LIBWRAP
    reply.waitForFinished();
    if (reply.isError()) {
        fail(reply.error().message());
        return;
    }
#endif
    const VectorMapStringString entries = reply;
    feeds_.clear();
    for (const auto& entry : entries) {
        QVariantMap item;
        for (auto it = entry.begin(); it != entry.end(); ++it)
            item.insert(it.key(), it.value());
        for (const auto* flag : {"owned", "subscribed", "available", "requested", "feedReplies", "feedClosed"})
            item[QLatin1String(flag)] = entry.value(QLatin1String(flag)) == QStringLiteral("true");
        const auto id = entry.value("id");
        item["ownerName"] = lrcInstance_->getCurrentAccountInfo().contactModel->bestNameForContact(
            entry.value("feedOwner"));
        auto model = lrcInstance_->getCurrentConversationModel();
        auto conv = model ? model->getConversationForUid(id) : std::nullopt;
        item["unread"] = conv ? conv->get().unreadMessages : 0;
        feeds_.push_back(item);
    }
    Q_EMIT feedsChanged();
}

QVariantList
FeedAdapter::followed() const
{
    QVariantList result;
    for (const auto& value : feeds_) {
        const auto item = value.toMap();
        if (!item.value("feedClosed").toBool() && item.value("available").toBool()
            && (item.value("owned").toBool() || item.value("subscribed").toBool()))
            result.push_back(item);
    }
    return result;
}

QVariantMap
FeedAdapter::details(const QString& id) const
{
    for (const auto& value : feeds_)
        if (value.toMap().value("id").toString() == id)
            return value.toMap();
    return {};
}

QVariantList
FeedAdapter::contacts(const QString& accountId) const
{
    QVariantList result;
    if (!lrcInstance_->accountModel().hasAccount(accountId))
        return result;
    const auto model = lrcInstance_->getAccountInfo(accountId).contactModel.get();
    for (auto it = model->getAllContacts().begin(); it != model->getAllContacts().end(); ++it) {
        if (it->isBanned || it->profileInfo.type != lrc::api::profile::Type::JAMI
            || it.key() == lrcInstance_->getAccountInfo(accountId).profileInfo.uri)
            continue;
        result.push_back(QVariantMap {{"uri", it.key()}, {"name", model->bestNameForContact(it.key())}});
    }
    return result;
}

void
FeedAdapter::refresh()
{
    clearError();
    const auto account = lrcInstance_->get_currentAccountId();
    if (!account.isEmpty())
        ConfigurationManager::instance().refreshFeeds(account);
    refreshTimer_.start();
}

QString
FeedAdapter::createFeed(const QString& accountId, const QString& title, const QString& avatar, bool replies)
{
    clearError();
    const QString id = ConfigurationManager::instance().createFeed(accountId, title.trimmed(), avatar, replies);
    if (id.isEmpty())
        fail(tr("Unable to create the Feed."));
    refreshTimer_.start();
    return id;
}

bool
FeedAdapter::update(
    const QString& accountId, const QString& id, const QString& title, const QString& avatar, bool replies)
{
    clearError();
    const bool ok = ConfigurationManager::instance().updateFeed(accountId,
                                                                id,
                                                                {{"title", title.trimmed()},
                                                                 {"avatar", avatar},
                                                                 {"feedReplies", replies ? "true" : "false"}});
    if (!ok)
        fail(tr("Unable to update the Feed."));
    refreshTimer_.start();
    return ok;
}

bool
FeedAdapter::closeFeed(const QString& accountId, const QString& id)
{
    clearError();
    const bool ok = ConfigurationManager::instance().updateFeed(accountId, id, {{"feedClosed", "true"}});
    if (!ok)
        fail(tr("Unable to close the Feed."));
    refreshTimer_.start();
    return ok;
}

bool
FeedAdapter::authorize(const QString& accountId, const QString& id, const QString& uri, bool allowed)
{
    clearError();
    const bool ok = ConfigurationManager::instance().setFeedAccess(accountId, id, uri, allowed);
    if (!ok)
        fail(tr("Unable to change this contact's Feed access."));
    return ok;
}

bool
FeedAdapter::subscribe(const QString& accountId, const QString& id, bool subscribed)
{
    clearError();
    const bool ok = ConfigurationManager::instance().subscribeFeed(accountId, id, subscribed);
    if (!ok)
        fail(tr("Unable to change the Feed subscription."));
    refreshTimer_.start();
    return ok;
}

void
FeedAdapter::open(const QString& id)
{
    lrcInstance_->selectConversation(id);
}

QString
FeedAdapter::readAvatar(const QUrl& url)
{
    QImageReader reader(url.toLocalFile());
    const auto size = reader.size();
    if (!size.isValid() || size.width() > 8192 || size.height() > 8192) {
        fail(tr("This image is invalid or too large."));
        return {};
    }
    reader.setScaledSize(size.scaled(128, 128, Qt::KeepAspectRatio));
    const auto image = reader.read();
    QByteArray bytes;
    QBuffer buffer(&bytes);
    if (image.isNull() || !buffer.open(QIODevice::WriteOnly) || !image.save(&buffer, "PNG")
        || bytes.size() > 48 * 1024) {
        fail(tr("Unable to use this Feed avatar."));
        return {};
    }
    return QString::fromLatin1(bytes.toBase64());
}
