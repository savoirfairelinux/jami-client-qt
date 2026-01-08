#pragma once

#include <QAbstractListModel>
#include <vector>
#include "../libclient/qtwrapper/configurationmanager_wrap.h"
#include "../libclient/typedefs.h"
#include "../libclient/api/interaction.h"

// Ensure MetaType declarations for queued definitions
Q_DECLARE_METATYPE(SwarmMessage)
Q_DECLARE_METATYPE(VectorSwarmMessage)
Q_DECLARE_METATYPE(MapStringString)
Q_DECLARE_METATYPE(VectorMapStringString)

class MessageListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString accountId READ accountId WRITE setAccountId NOTIFY accountIdChanged)
    Q_PROPERTY(QString conversationId READ conversationId WRITE setConversationId NOTIFY conversationIdChanged)

public:
    enum MessageRoles {
        IdRole = Qt::UserRole + 1,
        BodyRole,
        TypeRole,
        SenderRole,
        TimestampRole
    };

    explicit MessageListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString accountId() const;
    void setAccountId(const QString &accountId);

    QString conversationId() const;
    void setConversationId(const QString &conversationId);

public Q_SLOTS:
    void loadMessages();

private Q_SLOTS:
    void onSwarmLoaded(uint32_t requestId, const QString &accountId, const QString &conversationId, const VectorSwarmMessage &messages);
    void onConversationLoaded(uint32_t requestId, const QString &accountId, const QString &conversationId, const VectorMapStringString &messages);
    void onSwarmMessageReceived(const QString &accountId, const QString &conversationId, const SwarmMessage &message);

Q_SIGNALS:
    void accountIdChanged();
    void conversationIdChanged();

private:
    struct MessageItem {
        QString id;
        lrc::api::interaction::Info info;
    };

    QString m_accountId;
    QString m_conversationId;
    std::vector<MessageItem> m_messages;
};
