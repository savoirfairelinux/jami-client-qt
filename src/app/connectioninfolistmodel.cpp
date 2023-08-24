#include "connectioninfolistmodel.h"

ConnectionInfoListModel::ConnectionInfoListModel(LRCInstance* instance, QObject* parent)
    : AbstractListModelBase(parent)
{
    lrcInstance_ = instance;
    connect(lrcInstance_,
            &LRCInstance::currentAccountIdChanged,
            this,
            &ConnectionInfoListModel::resetData);
}

int
ConnectionInfoListModel::rowCount(const QModelIndex& parent) const
{
    return peerIds_.size();
}

QVariant
ConnectionInfoListModel::data(const QModelIndex& index, int role) const
{
    const auto accountID = lrcInstance_->get_currentAccountId();

    if (accountID.isEmpty()) {
        qWarning() << "ConnectionInfoListModel::data: accountID or peerID is empty";
        return {};
    }
    const auto peerId = peerIds_[index.row()];
    const auto peerData = peerData_[peerId];

    switch (role) {
    case ConnectionInfoList::PeerId:
        return peerId;
    case ConnectionInfoList::DeviceId: {
        QVariantMap deviceMap;
        int i = 0;
        for (const auto& device : peerData.keys()) {
            deviceMap.insert(QString::number(i++), device);
        }
        return QVariant(deviceMap);
    }
    case ConnectionInfoList::Status: {
        QVariantMap statusMap;
        int i = 0;
        for (const auto& device : peerData.keys()) {
            statusMap.insert(QString::number(i++), peerData[device]["status"]);
        }
        return QVariantMap(statusMap);
    }
    case ConnectionInfoList::Channels: {
        QVariantMap channelsMap;
        int i = 0;
        for (const auto& device : peerData.keys()) {
            channelsMap.insert(QString::number(i++), peerData[device]["channels"]);
        }
        return QVariant(channelsMap);
    }
    case ConnectionInfoList::Count:
        return peerData.size();
    }
    return {};
}

QHash<int, QByteArray>
ConnectionInfoListModel::roleNames() const
{
    using namespace ConnectionInfoList;
    QHash<int, QByteArray> roles;
#define X(role) roles[role] = #role;
    CONNECTONINFO_ROLES
#undef X
    return roles;
}

void
ConnectionInfoListModel::update()
{
    const auto accountID = lrcInstance_->get_currentAccountId();
    if (accountID.isEmpty()) {
        return;
    }
    aggregateData();
}

template<typename T>
std::tuple<QVector<T>, QVector<T>>
getSetDiff(QVector<T> u, QVector<T> v)
{
    using namespace std;
    QVector<T> a, r;
    set_difference(v.begin(), v.end(), u.begin(), u.end(), inserter(a, a.begin()));
    set_difference(u.begin(), u.end(), v.begin(), v.end(), inserter(r, r.begin()));
    return {a, r};
}

void
ConnectionInfoListModel::aggregateData()
{
    const auto accountID = lrcInstance_->get_currentAccountId();
    if (accountID.isEmpty()) {
        return;
    }

    connectionInfoList_ = lrcInstance_->getConnectionList(accountID);
    peerData_ = {};

    QSet<QString> newPeerIds;

    for (const auto& connectionInfo : connectionInfoList_) {
        if (!connectionInfo["peer"].isEmpty()) {
            newPeerIds.insert(connectionInfo["peer"]);
        }
        peerData_[connectionInfo["peer"]][connectionInfo["device"]] = {};
        peerData_[connectionInfo["peer"]][connectionInfo["device"]]["status"]
            = connectionInfo["status"];
        peerData_[connectionInfo["peer"]][connectionInfo["device"]]["channels"] = 1;
    }

    QVector<QString> oldVector;
    for (const auto& peerId : peerIds_) {
        oldVector << peerId;
    }
    QVector<QString> newVector;
    for (const auto& peerId : newPeerIds) {
        newVector << peerId;
    }

    std::sort(oldVector.begin(), oldVector.end());
    std::sort(newVector.begin(), newVector.end());

    QVector<QString> removed, added;
    std::tie(added, removed) = getSetDiff(oldVector, newVector);
    Q_FOREACH (const auto& key, added) {
        auto index = std::distance(newVector.begin(),
                                   std::find(newVector.begin(), newVector.end(), key));
        beginInsertRows(QModelIndex(), index, index);
        peerIds_.insert(index, key);
        endInsertRows();
    }
    Q_FOREACH (const auto& key, removed) {
        auto index = std::distance(oldVector.begin(),
                                   std::find(oldVector.begin(), oldVector.end(), key));
        beginRemoveRows(QModelIndex(), index, index);
        peerIds_.remove(index);
        endRemoveRows();
    }

    // HACK: loop through all the peerIds_ and update the data for each one.
    // This is not efficient, but it works.
    Q_FOREACH (const auto& peerId, peerIds_) {
        auto index = std::distance(peerIds_.begin(),
                                   std::find(peerIds_.begin(), peerIds_.end(), peerId));
        Q_EMIT dataChanged(this->index(index), this->index(index));
    }
}

void
ConnectionInfoListModel::resetData()
{
    beginResetModel();
    peerIds_.clear();
    peerData_.clear();
    endResetModel();
}