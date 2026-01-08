#pragma once

#include <QAbstractListModel>
#include <QVector>
#include <QQmlEngine>

class CoreService;

struct AccountItem
{
    QString id;
    QString alias;
    QString username;
    bool enabled;
};

class AccountListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles { IdRole = Qt::UserRole + 1, AliasRole, UsernameRole, EnabledRole };

    explicit AccountListModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reload();

private:
    void onAccountsChanged();

    QVector<AccountItem> m_accounts;
};
