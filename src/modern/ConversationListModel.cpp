#include "ConversationListModel.h"
#include "CoreService.h"
#include "configurationmanager_wrap.h" // For ConfigurationManagerInterface signals
#include <QDebug>

ConversationListModel::ConversationListModel(QObject* parent)
    : QAbstractListModel(parent)
{
    auto* service = &CoreService::instance();
    // Ensure service is initialized (or wait for it)
    if (!service->isInitialized()) {
        connect(service, &CoreService::initializationChanged, this, [this, service]() {
            if (service->isInitialized()) {
                // re-setup connections if needed
            }
        });
    }

    auto* config = service->configurationManager();
    if (config) {
        connect(config,
                &ConfigurationManagerInterface::conversationReady,
                this,
                &ConversationListModel::onConversationReady);
        connect(config,
                &ConfigurationManagerInterface::conversationRemoved,
                this,
                &ConversationListModel::onConversationRemoved);
        // Note: signature of signal in wrapper might differ (MapStringString vs QVariantMap)
        // I need to check the exact signature of conversationProfileUpdated in the wrapper.
        // The wrapper usually uses MapStringString.
        // For now, I will use a lambda to convert if necessary or assume implicit conversion if mapped.
        // Actually, looking at the header read previously:
        // void conversationProfileUpdated(const QString& accountId, const QString& conversationId, const
        // MapStringString& profile);

        connect(config,
                &ConfigurationManagerInterface::conversationProfileUpdated,
                this,
                [this](const QString& accId, const QString& convId, const MapStringString& profile) {
                    // Convert MapStringString to QVariantMap
                    QVariantMap vProfile;
                    for (auto it = profile.begin(); it != profile.end(); ++it) {
                        vProfile.insert(it.key(), it.value());
                    }
                    onConversationProfileUpdated(accId, convId, vProfile);
                });
    }
}

QString
ConversationListModel::accountId() const
{
    return m_accountId;
}

void
ConversationListModel::setAccountId(const QString& accountId)
{
    if (m_accountId == accountId)
        return;
    m_accountId = accountId;
    Q_EMIT accountIdChanged();
    reload();
}

void
ConversationListModel::reload()
{
    beginResetModel();
    m_conversations.clear();

    auto* config = CoreService::instance().configurationManager();
    if (config && !m_accountId.isEmpty()) {
        QStringList ids = config->getConversations(m_accountId);
        qDebug() << "[ConversationListModel] Loading" << ids.size() << "conversations for account" << m_accountId;

        for (const auto& id : ids) {
            ConversationItem item;
            item.id = id;

            auto details = config->conversationInfos(m_accountId, id);
            item.title = details.value("title");
            item.description = details.value("description");
            if (item.title.isEmpty()) {
                // Fallback to ID or peer
                item.title = id.left(8);
            }
            m_conversations.append(item);
        }
    }
    endResetModel();
}

void
ConversationListModel::onConversationReady(const QString& accountId, const QString& conversationId)
{
    if (accountId != m_accountId)
        return;
    reload(); // Naive implementation: full reload. Ideally just insert one.
}

void
ConversationListModel::onConversationRemoved(const QString& accountId, const QString& conversationId)
{
    if (accountId != m_accountId)
        return;
    reload(); // Naive implementation
}

void
ConversationListModel::onConversationProfileUpdated(const QString& accountId,
                                                    const QString& conversationId,
                                                    const QVariantMap& profile)
{
    if (accountId != m_accountId)
        return;

    for (int i = 0; i < m_conversations.size(); ++i) {
        if (m_conversations[i].id == conversationId) {
            m_conversations[i].title = profile.value("title").toString();
            m_conversations[i].description = profile.value("description").toString();
            Q_EMIT dataChanged(index(i), index(i), QVector<int> {TitleRole, DescriptionRole});
            break;
        }
    }
}

int
ConversationListModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return m_conversations.size();
}

QVariant
ConversationListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= m_conversations.size())
        return QVariant();

    const auto& item = m_conversations[index.row()];

    switch (role) {
    case IdRole:
        return item.id;
    case TitleRole:
        return item.title;
    case DescriptionRole:
        return item.description;
    case LastMessageRole:
        return item.lastMessage;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray>
ConversationListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "conversationId";
    roles[TitleRole] = "title";
    roles[DescriptionRole] = "description";
    roles[LastMessageRole] = "lastMessage";
    return roles;
}

QString
ConversationListModel::getConversationId(int row)
{
    if (row < 0 || row >= m_conversations.size())
        return QString();
    return m_conversations[row].id;
}
