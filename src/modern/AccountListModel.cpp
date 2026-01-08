#include "AccountListModel.h"
#include "CoreService.h"
#include <QDebug>

AccountListModel::AccountListModel(QObject* parent)
    : QAbstractListModel(parent)
{
    // Connect to CoreService signals
    connect(&CoreService::instance(), &CoreService::accountsChanged, 
            this, &AccountListModel::onAccountsChanged);
    
    // Connect to initialization to trigger first load
    connect(&CoreService::instance(), &CoreService::initializationChanged,
            this, &AccountListModel::reload);

    // If already initialized, load now
    if (CoreService::instance().isInitialized()) {
        reload();
    }
}

void AccountListModel::onAccountsChanged()
{
    qDebug() << "[AccountListModel] Detected change, reloading...";
    reload();
}

void AccountListModel::reload()
{
    auto* service = &CoreService::instance();
    if (!service->isInitialized()) return;

    beginResetModel();
    m_accounts.clear();

    QStringList ids = service->getAccountList();
    qDebug() << "[AccountListModel] Loading" << ids.size() << "accounts.";

    for (const auto& id : ids) {
        auto details = service->getAccountDetails(id);
        AccountItem item;
        item.id = id;
        item.alias = details.value("Account.alias").toString();
        item.username = details.value("Account.username").toString();
        
        // Fallback if alias is empty
        if (item.alias.isEmpty()) {
            item.alias = item.username; // Use username as alias if no alias set
        }
        if (item.alias.isEmpty()) {
            item.alias = "Unnamed Account";
        }

        item.enabled = details.value("Account.enable", "true").toString() == "true";
        
        m_accounts.append(item);
    }

    endResetModel();
}

int AccountListModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) return 0;
    return m_accounts.size();
}

QVariant AccountListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= m_accounts.size())
        return QVariant();

    const auto& account = m_accounts[index.row()];

    switch (role) {
    case IdRole:
        return account.id;
    case AliasRole:
        return account.alias;
    case UsernameRole:
        return account.username;
    case EnabledRole:
        return account.enabled;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> AccountListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "accountId";
    roles[AliasRole] = "alias";
    roles[UsernameRole] = "username";
    roles[EnabledRole] = "enabled";
    return roles;
}
