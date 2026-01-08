#pragma once

#include <QAbstractListModel>
#include <QVector>
#include <QQmlEngine>

class ConversationListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString accountId READ accountId WRITE setAccountId NOTIFY accountIdChanged)

public:
    enum Roles { IdRole = Qt::UserRole + 1, TitleRole, DescriptionRole, LastMessageRole };

    explicit ConversationListModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString accountId() const;
    void setAccountId(const QString& accountId);

    Q_INVOKABLE void reload();
    Q_INVOKABLE QString getConversationId(int row);

Q_SIGNALS:
    void accountIdChanged();

private Q_SLOTS:
    void onConversationReady(const QString& accountId, const QString& conversationId);
    void onConversationRemoved(const QString& accountId, const QString& conversationId);
    void onConversationProfileUpdated(const QString& accountId,
                                      const QString& conversationId,
                                      const QVariantMap& profile);

private:
    struct ConversationItem
    {
        QString id;
        QString title;
        QString description;
        QString lastMessage;
    };

    QString m_accountId;
    QVector<ConversationItem> m_conversations;

    void updateItemInternal(int index, const QString& conversationId);
};
