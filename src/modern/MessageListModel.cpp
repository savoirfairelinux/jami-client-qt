#include "MessageListModel.h"
#include "CoreService.h"
#include <QDebug>
#include "../libclient/qtwrapper/configurationmanager_wrap.h"

MessageListModel::MessageListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    auto* config = CoreService::instance().configurationManager();
    if (config) {
        connect(config, &ConfigurationManagerInterface::swarmLoaded, 
                this, &MessageListModel::onSwarmLoaded);
        connect(config, &ConfigurationManagerInterface::conversationLoaded,
                this, &MessageListModel::onConversationLoaded);
        connect(config, &ConfigurationManagerInterface::messagesFound,
                this, &MessageListModel::onConversationLoaded);
        connect(config, &ConfigurationManagerInterface::swarmMessageReceived, 
                this, &MessageListModel::onSwarmMessageReceived);
    }
}

int MessageListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return static_cast<int>(m_messages.size());
}

QVariant MessageListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= static_cast<int>(m_messages.size()))
        return QVariant();

    const auto &item = m_messages[index.row()];

    switch (role) {
    case IdRole:
        return item.id;
    case BodyRole:
        return item.info.body;
    case TypeRole:
        return lrc::api::interaction::to_string(item.info.type);
    case SenderRole:
        return item.info.authorUri;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> MessageListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[BodyRole] = "body";
    roles[TypeRole] = "type";
    roles[SenderRole] = "sender";
    return roles;
}

QString MessageListModel::accountId() const
{
    return m_accountId;
}

void MessageListModel::setAccountId(const QString &accountId)
{
    if (m_accountId == accountId)
        return;
    m_accountId = accountId;
    Q_EMIT accountIdChanged();
    loadMessages();
}

QString MessageListModel::conversationId() const
{
    return m_conversationId;
}

void MessageListModel::setConversationId(const QString &conversationId)
{
    if (m_conversationId == conversationId)
        return;
    m_conversationId = conversationId;
    Q_EMIT conversationIdChanged();
    loadMessages();
}

void MessageListModel::loadMessages()
{
    beginResetModel();
    m_messages.clear();
    endResetModel();

    if (m_accountId.isEmpty() || m_conversationId.isEmpty())
        return;

    qDebug() << "[MessageListModel] Loading messages for conversation" << m_conversationId << "Account:" << m_accountId;

    auto* config = CoreService::instance().configurationManager();
    if (config) {
        // Load last 20 messages
        uint32_t reqId = config->loadConversation(m_accountId, m_conversationId, "", 20);
        qDebug() << "[MessageListModel] Request sent. ID:" << reqId;
    } else {
        qDebug() << "[MessageListModel] ERROR: Config manager is NULL";
    }
}

void MessageListModel::onConversationLoaded(uint32_t requestId, const QString &accountId, const QString &conversationId, const VectorMapStringString &messages)
{
    qDebug() << "[MessageListModel] RCV ConversationLoaded. Acc:" << accountId << "Conv:" << conversationId << "Count:" << messages.size();

    if (accountId != m_accountId || conversationId != m_conversationId) {
        qDebug() << "[MessageListModel] Ignore mismatch. Expected Acc:" << m_accountId << "Conv:" << m_conversationId;
        return;
    }

    beginResetModel();
    m_messages.clear();
    m_messages.reserve(messages.size());
    for(const auto& map : messages) {
        lrc::api::interaction::Info info(map, m_accountId, m_accountId, m_conversationId);
        MessageItem item;
        item.id = map.value("id");
        item.info = std::move(info);
        m_messages.push_back(std::move(item));
    }
    endResetModel();
}

void MessageListModel::onSwarmLoaded(uint32_t requestId, const QString &accountId, const QString &conversationId, const VectorSwarmMessage &messages)
{
    qDebug() << "[MessageListModel] RCV SwarmLoaded. Acc:" << accountId << "Conv:" << conversationId << "Count:" << messages.size();

    if (accountId != m_accountId || conversationId != m_conversationId) {
        qDebug() << "[MessageListModel] Ignore mismatch.";
        return;
    }

    beginResetModel();
    m_messages.clear();
    m_messages.reserve(messages.size());
    for(const auto& msg : messages) {
        lrc::api::interaction::Info info(msg, m_accountId, m_accountId, m_conversationId);
        MessageItem item;
        item.id = msg.id;
        item.info = std::move(info);
        m_messages.push_back(std::move(item));
        
        qDebug() << "[MessageListModel] Parsed Msg:" << item.id << " Body:" << item.info.body << " Type:" << lrc::api::interaction::to_string(item.info.type);
    }
    endResetModel();
}

void MessageListModel::onSwarmMessageReceived(const QString &accountId, const QString &conversationId, const SwarmMessage &message)
{
    if (accountId != m_accountId || conversationId != m_conversationId)
        return;

    lrc::api::interaction::Info info(message, m_accountId, m_accountId, m_conversationId);
    MessageItem item;
    item.id = message.id;
    item.info = std::move(info);

    beginInsertRows(QModelIndex(), m_messages.size(), m_messages.size());
    m_messages.push_back(std::move(item));
    endInsertRows();
}
