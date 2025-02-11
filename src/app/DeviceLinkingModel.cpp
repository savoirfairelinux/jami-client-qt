#include "devicelinkingmodel.h"
#include "lrcinstance.h"
#include "api/accountmodel.h"
#include "global.h"
#include "qtutils.h"

DeviceLinkingModel::DeviceLinkingModel(LRCInstance* lrcInstance, QObject* parent)
    : QObject(parent)
    , lrcInstance_(lrcInstance)
{
    connect(&lrcInstance_->accountModel(),
            &AccountModel::addDeviceStateChanged,
            this,
            [this](const QString& accountID,
                   uint32_t operationId,
                   int state,
                   const MapStringString& details) {
                if (operationId != operationId_)
                    return;

                currentState_ = state;
                //                if (state == DeviceAuthState::Error) {
                //                    errorMsg_ = details.value("error", "Unknown error occurred");
                //                } else if (state == DeviceAuthState::TokenAvailable) {
                //                    pin_ = details.value("pin");
                //                }

                //                Q_EMIT deviceAuthStateChanged();
                //                Q_EMIT stateChanged();
            });
}

void
DeviceLinkingModel::addDevice(const QString& token)
{
    qWarning() << "******* add device" << token;
    //    auto result = lrcInstance_->accountModel().addDevice(lrcInstance_->getCurrentAccountInfo().id,
    //                                                         token);
    //    if (result > 0) {
    //        operationId_ = result;
    //        currentState_ = DeviceAuthState::Init;
    //        // Q_EMIT deviceAuthStateChanged();
    //    } else {
    //        //        currentState_ = DeviceAuthState::Error;
    //        //        errorMsg_ = "Failed to start device linking";
    //        //        Q_EMIT deviceAuthStateChanged();
    //    }
}

bool
DeviceLinkingModel::isPasswordRequired() const
{
    return false; // return lrcInstance_->getCurrentAccountInfo().hasArchivePassword;
}

bool
DeviceLinkingModel::isExporting() const
{
    return exporting_;
}

bool
DeviceLinkingModel::isExportSuccess() const
{
    return exportSuccess_;
}

QString
DeviceLinkingModel::exportedPIN() const
{
    return pin_;
}

QString
DeviceLinkingModel::errorMessage() const
{
    return errorMsg_;
}

void
DeviceLinkingModel::startExport(const QString& password)
{
    //    exporting_ = true;
    //    //Q_EMIT stateChanged();

    //    // TODO: Implement actual export logic here
    //    // For now just simulate success
    //    pin_ = "123456";
    //    exportSuccess_ = true;
    //    exporting_ = false;
    // Q_EMIT stateChanged();
}
