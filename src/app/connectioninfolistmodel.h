#pragma once

#include "abstractlistmodelbase.h"

#define CONNECTONINFO_ROLES \
    X(ConnectionDatas) \
    X(ChannelsMap) \
    X(PeerName) \
    X(PeerId) \
    X(DeviceId) \
    X(Status) \
    X(Channels) \
    X(Count) // this is the number of connections (convenience)

namespace ConnectionInfoList {
Q_NAMESPACE
enum Role {
    DummyRole = Qt::UserRole + 1,
#define X(role) role,
    CONNECTONINFO_ROLES
#undef X
};
Q_ENUM_NS(Role)
} // namespace ConnectionInfoList

class ConnectionInfoListModel : public AbstractListModelBase
{
public:
    explicit ConnectionInfoListModel(LRCInstance* instance, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // get data from backend
    Q_INVOKABLE void update();

private:
    using Role = ConnectionInfoList::Role;

    VectorMapStringString connectionInfoList_;

    // Transformed data.
    // peerIds_ will be used to generate to granularize the data changes.
    // Example (NOTE: Avatar and PeerName are synthesized from peerData_):
    // Also, we want to remove the peerId from peerData_.
    // peerData_ = {
    //     "peerId1": {
    //         "deviceId1": {
    //             "status": "online",
    //             "channels": ["channel1", "channel2"]
    //         },
    //         "deviceId2": {
    //             "status": "offline",
    //             "channels": ["channel3"]
    //         }
    //     },
    //     "peerId2": {
    //         "deviceId3": {
    //             "status": "online",
    //             "channels": ["channel4"]
    //         }
    //     }
    // }
    QVector<QString> peerIds_;
    QMap<QString, QMap<QString, QMap<QString, QVariant>>> peerData_;
    void aggregateData();
    void resetData();
};
