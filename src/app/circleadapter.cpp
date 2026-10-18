/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include "circleadapter.h"
#include "dbus/configurationmanager.h"
#include "api/contactmodel.h"
#include "api/conversationmodel.h"

#include <QByteArray>
#include <QRegularExpression>
#include <QSet>
#include <QUuid>
#include <algorithm>

namespace {
const QString PREFIX = QStringLiteral("jami.channels.v1/");

struct DefaultCircle
{
    QString id;
    QString name;
};

const QList<DefaultCircle> DEFAULTS = {
    {QStringLiteral("default-friends"), QStringLiteral("Amis")},
    {QStringLiteral("default-real-friends"), QStringLiteral("Amis proches")},
    {QStringLiteral("default-family"), QStringLiteral("Famille")},
    {QStringLiteral("default-colleague"), QStringLiteral("Collègues")},
};

QString
migrateDefaultName(const QString& raw)
{
    if (raw == QLatin1String("Friends") || raw == QLatin1String("Friend"))
        return QStringLiteral("Amis");
    if (raw == QLatin1String("Real Friends") || raw == QLatin1String("Real friend"))
        return QStringLiteral("Amis proches");
    if (raw == QLatin1String("Family"))
        return QStringLiteral("Famille");
    if (raw == QLatin1String("Colleague") || raw == QLatin1String("Colleagues"))
        return QStringLiteral("Collègues");
    return raw;
}

QString
encodeUri(const QString& uri)
{
    return QString::fromLatin1(uri.toUtf8().toBase64(QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals));
}

QString
decodeUri(const QString& encoded)
{
    return QString::fromUtf8(QByteArray::fromBase64(encoded.toLatin1(), QByteArray::Base64UrlEncoding));
}
} // namespace

CircleAdapter::CircleAdapter(LRCInstance* instance, QObject* parent)
    : QmlAdapterBase(instance, parent)
{
    reloadTimer_.setSingleShot(true);
    reloadTimer_.setInterval(0);
    connect(&reloadTimer_, &QTimer::timeout, this, &CircleAdapter::reload);
    connect(instance, &LRCInstance::currentAccountIdChanged, this, [this] {
        circles_.clear();
        clearError();
        Q_EMIT circlesChanged();
        reloadTimer_.start();
    });
    auto& manager = ConfigurationManager::instance();
#ifdef ENABLE_LIBWRAP
    connect(&manager,
            &ConfigurationManagerInterface::accountMetadataChanged,
            this,
            [this](const QString& accountId, const MapStringString&) {
                if (accountId == lrcInstance_->get_currentAccountId())
                    reloadTimer_.start();
            });
#endif
    reloadTimer_.start();
}

void
CircleAdapter::fail(const QString& err)
{
    qWarning() << "Circle operation:" << err;
    error_ = err;
    Q_EMIT errorChanged();
}

void
CircleAdapter::clearError()
{
    if (error_.isEmpty())
        return;
    error_.clear();
    Q_EMIT errorChanged();
}

void
CircleAdapter::reload()
{
    const auto accountId = lrcInstance_->get_currentAccountId();
    if (accountId.isEmpty())
        return;

    MapStringString metadata;
#ifdef ENABLE_LIBWRAP
    metadata = ConfigurationManager::instance().getAccountMetadata(accountId);
#endif

    QSet<QString> ids;
    for (const auto& def : DEFAULTS)
        ids.insert(def.id);

    const QRegularExpression validId(QStringLiteral("^[A-Za-z0-9-]{1,128}$"));
    for (auto it = metadata.begin(); it != metadata.end(); ++it) {
        if (!it.key().startsWith(PREFIX))
            continue;
        const auto rest = it.key().mid(PREFIX.size());
        const auto slash = rest.indexOf(QLatin1Char('/'));
        if (slash <= 0)
            continue;
        const auto id = rest.left(slash);
        if (id != QLatin1String("all") && validId.match(id).hasMatch())
            ids.insert(id);
    }

    QList<QVariantMap> items;
    for (const auto& id : ids) {
        if (metadata.value(PREFIX + id + QStringLiteral("/deleted")) == QStringLiteral("1"))
            continue;

        QString defaultName;
        bool builtIn = false;
        int defaultOrder = DEFAULTS.size();
        for (int i = 0; i < DEFAULTS.size(); ++i) {
            if (DEFAULTS[i].id == id) {
                defaultName = DEFAULTS[i].name;
                builtIn = true;
                defaultOrder = i;
                break;
            }
        }

        const auto storedName = metadata.value(PREFIX + id + QStringLiteral("/name"));
        const auto name = migrateDefaultName(storedName.isEmpty() ? defaultName : storedName).trimmed();
        if (name.isEmpty())
            continue;

        QStringList members;
        QStringList groups;
        const auto memberPrefix = PREFIX + id + QStringLiteral("/members/");
        const auto groupPrefix = PREFIX + id + QStringLiteral("/groups/");
        for (auto it = metadata.begin(); it != metadata.end(); ++it) {
            if (it.value() != QStringLiteral("1"))
                continue;
            if (it.key().startsWith(memberPrefix)) {
                const auto uri = decodeUri(it.key().mid(memberPrefix.size())).trimmed();
                if (!uri.isEmpty())
                    members.push_back(uri);
            } else if (it.key().startsWith(groupPrefix)) {
                const auto uri = decodeUri(it.key().mid(groupPrefix.size())).trimmed();
                if (!uri.isEmpty())
                    groups.push_back(uri);
            }
        }
        members.sort();
        groups.sort();

        QVariantMap item;
        item[QStringLiteral("id")] = id;
        item[QStringLiteral("name")] = name;
        item[QStringLiteral("builtIn")] = builtIn;
        item[QStringLiteral("order")] = defaultOrder;
        item[QStringLiteral("members")] = members;
        item[QStringLiteral("groups")] = groups;
        item[QStringLiteral("count")] = members.size() + groups.size();
        items.push_back(item);
    }

    std::sort(items.begin(), items.end(), [](const QVariantMap& a, const QVariantMap& b) {
        const int oa = a.value(QStringLiteral("order")).toInt();
        const int ob = b.value(QStringLiteral("order")).toInt();
        if (oa != ob)
            return oa < ob;
        const int cmp = QString::compare(a.value(QStringLiteral("name")).toString(),
                                         b.value(QStringLiteral("name")).toString(),
                                         Qt::CaseInsensitive);
        if (cmp != 0)
            return cmp < 0;
        return a.value(QStringLiteral("id")).toString() < b.value(QStringLiteral("id")).toString();
    });

    circles_.clear();
    for (const auto& item : items)
        circles_.push_back(item);
    Q_EMIT circlesChanged();
}

QVariantMap
CircleAdapter::details(const QString& circleId) const
{
    for (const auto& v : circles_) {
        const auto map = v.toMap();
        if (map.value(QStringLiteral("id")).toString() == circleId)
            return map;
    }
    return {};
}

QVariantList
CircleAdapter::contacts(const QString& accountId) const
{
    QVariantList result;
    if (!lrcInstance_->accountModel().hasAccount(accountId))
        return result;
    const auto& accInfo = lrcInstance_->getAccountInfo(accountId);
    const auto model = accInfo.contactModel.get();
    for (auto it = model->getAllContacts().begin(); it != model->getAllContacts().end(); ++it) {
        if (it->isBanned || it->profileInfo.type != lrc::api::profile::Type::JAMI || it.key() == accInfo.profileInfo.uri)
            continue;
        result.push_back(QVariantMap {
            {QStringLiteral("uri"), it.key()},
            {QStringLiteral("name"), model->bestNameForContact(it.key())},
        });
    }
    return result;
}

QVariantList
CircleAdapter::groups(const QString& accountId) const
{
    QVariantList result;
    if (!lrcInstance_->accountModel().hasAccount(accountId))
        return result;
    const auto& accInfo = lrcInstance_->getAccountInfo(accountId);
    const auto convModel = accInfo.conversationModel.get();
    if (!convModel)
        return result;
    for (const auto& conv : convModel->getConversations()) {
        if (!conv.isSwarm() || conv.isCoreDialog() || conv.mode == lrc::api::conversation::Mode::FEED)
            continue;
        const QString title = convModel->title(conv.uid);
        result.push_back(QVariantMap {
            {QStringLiteral("uri"), QStringLiteral("swarm:") + conv.uid},
            {QStringLiteral("uid"), conv.uid},
            {QStringLiteral("name"), title.isEmpty() ? conv.uid : title},
        });
    }
    return result;
}

QString
CircleAdapter::createCircle(const QString& accountId, const QString& name)
{
    clearError();
    const auto trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        fail(tr("Circle name is required"));
        return {};
    }
    for (const auto& v : circles_) {
        if (v.toMap().value(QStringLiteral("name")).toString().compare(trimmed, Qt::CaseInsensitive) == 0) {
            fail(tr("A circle with this name already exists"));
            return {};
        }
    }
    const auto id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    MapStringString updates;
    updates.insert(PREFIX + id + QStringLiteral("/name"), trimmed);
#ifdef ENABLE_LIBWRAP
    if (!ConfigurationManager::instance().setAccountMetadata(accountId, updates, false)) {
        fail(tr("Unable to create circle"));
        return {};
    }
#endif
    reload();
    return id;
}

bool
CircleAdapter::renameCircle(const QString& accountId, const QString& circleId, const QString& name)
{
    clearError();
    const auto trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        fail(tr("Circle name is required"));
        return false;
    }
    for (const auto& v : circles_) {
        const auto m = v.toMap();
        if (m.value(QStringLiteral("id")).toString() != circleId
            && m.value(QStringLiteral("name")).toString().compare(trimmed, Qt::CaseInsensitive) == 0) {
            fail(tr("A circle with this name already exists"));
            return false;
        }
    }
    MapStringString updates;
    updates.insert(PREFIX + circleId + QStringLiteral("/name"), trimmed);
#ifdef ENABLE_LIBWRAP
    if (!ConfigurationManager::instance().setAccountMetadata(accountId, updates, false)) {
        fail(tr("Unable to rename circle"));
        return false;
    }
#endif
    reload();
    return true;
}

bool
CircleAdapter::deleteCircle(const QString& accountId, const QString& circleId)
{
    clearError();
    MapStringString updates;
    updates.insert(PREFIX + circleId + QStringLiteral("/deleted"), QStringLiteral("1"));
#ifdef ENABLE_LIBWRAP
    if (!ConfigurationManager::instance().setAccountMetadata(accountId, updates, false)) {
        fail(tr("Unable to delete circle"));
        return false;
    }
#endif
    reload();
    return true;
}

bool
CircleAdapter::setMember(
    const QString& accountId, const QString& circleId, const QString& uri, bool isGroup, bool included)
{
    clearError();
    const auto trimmed = uri.trimmed();
    if (circleId.isEmpty() || trimmed.isEmpty())
        return false;
    const auto field = isGroup ? QStringLiteral("/groups/") : QStringLiteral("/members/");
    MapStringString updates;
    updates.insert(PREFIX + circleId + field + encodeUri(trimmed), included ? QStringLiteral("1") : QStringLiteral("0"));
#ifdef ENABLE_LIBWRAP
    if (!ConfigurationManager::instance().setAccountMetadata(accountId, updates, false)) {
        fail(tr("Unable to update circle members"));
        return false;
    }
#endif
    reload();
    return true;
}

int
CircleAdapter::broadcastText(const QString& accountId, const QString& circleId, const QString& text)
{
    clearError();
    const auto trimmed = text.trimmed();
    if (trimmed.isEmpty() || !lrcInstance_->accountModel().hasAccount(accountId))
        return 0;

    const auto circle = details(circleId);
    if (circle.isEmpty())
        return 0;

    const auto members = circle.value(QStringLiteral("members")).toStringList();
    const auto groups = circle.value(QStringLiteral("groups")).toStringList();
    auto* convModel = lrcInstance_->getAccountInfo(accountId).conversationModel.get();
    if (!convModel)
        return 0;

    int sent = 0;
    for (const auto& conv : convModel->getConversations()) {
        if (conv.mode == lrc::api::conversation::Mode::FEED)
            continue;
        bool match = false;
        if (conv.isSwarm() && !conv.isCoreDialog()) {
            match = groups.contains(QStringLiteral("swarm:") + conv.uid) || groups.contains(conv.uid);
        } else {
            const auto peers = convModel->peersForConversation(conv.uid);
            for (const auto& peer : peers) {
                if (members.contains(peer) || members.contains(QStringLiteral("jami:") + peer)
                    || members.contains(QStringLiteral("ring:") + peer)) {
                    match = true;
                    break;
                }
            }
        }
        if (match) {
            convModel->sendMessage(conv.uid, trimmed);
            ++sent;
        }
    }
    return sent;
}
