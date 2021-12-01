/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <Foundation/Foundation.h>
#include <UserNotifications/UserNotifications.h>
#include <AppKit/AppKit.h>
#include "systemtray.h"
#include "appsettingsmanager.h"

@interface NotificationDelegate: NSObject <NSUserNotificationCenterDelegate, UNUserNotificationCenterDelegate>
- (void) sendNotificationWithId:(NSString*) notificationId title:(NSString*)
  title body:(NSString*) body avatar:(const QByteArray&)avatar type:(NotificationType)type;
- (void) sendUserNotificationWithId:(NSString*) notificationId title:(NSString*) title body:(NSString*) body;

@end

@implementation NotificationDelegate

- (void) sendNotificationWithId:(NSString*) notificationId title:(NSString*) title body:(NSString*) body avatar:(const QByteArray&)avatar type:(NotificationType)type {
//    if (@available(macOS 11.0, *)) {
//        //check autorization.
//        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
//        UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
//        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
//            if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
//                // Notifications not allowed. Request autorization
//                [center requestAuthorizationWithOptions:options
//                                                        completionHandler:^(BOOL granted, NSError * _Nullable error) {
//                    if (!granted) {
//                        NSLog(@"Request notification permission error");
//                    } else {
//                        [self sendUserNotification];
//                    }
//                }];
//            } else {
//                [self sendUserNotification];
//            }
//        }];
//    } else {
        NSUserNotification* notification = [[NSUserNotification alloc] init];
        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
        [notification setIdentifier: notificationId];
        [notification setTitle: title];
        [notification setSoundName:NSUserNotificationDefaultSoundName];
        [notification setSubtitle: body];
        [notification setUserInfo:userInfo];
        if(!avatar.isEmpty()) {
            NSData *data = [NSData dataWithBytes:avatar.constData() length:avatar.count()];
            NSImage *image = [[NSImage alloc] initWithData:data];
            [notification setContentImage: image];
        }
        if (type == NotificationType::CALL) {
            [notification setOtherButtonTitle:@"Refuse"];
            [notification setActionButtonTitle:@"Accept"];
        }
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
   // }
}

- (void) sendUserNotificationWithId:(NSString*) notificationId title:(NSString*) title body:(NSString*) body {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = @"Don't forget";
    content.body = @"Buy some milk";
    content.sound = [UNNotificationSound defaultSound];
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger
            triggerWithTimeInterval:1 repeats:NO];
    NSString *identifier = @"UYLLocalNotification";
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
            content: content trigger:trigger];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Notification request error");
        }
    }];
}

//to handle notifications actions on macOS after 11.0
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {

}

//to handle notifications actions on macOS prior to 11.0
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDismissAlert:(NSUserNotification *)alert {
    // check if user click refuse on incoming call notifications
    if(alert.activationType != NSUserNotificationActivationTypeNone) {
        return;
    }
    auto identifier = alert.identifier;
    qDebug() << identifier;
    qDebug() << "3333333333";

}

- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    auto identifier = notification.identifier;
    qDebug() << identifier;
    qDebug() << "444444444444";
}
@end

struct SystemTray::SystemTrayImpl
{
    SystemTray* parent;
    SystemTrayImpl(SystemTray* parent)
        : parent(parent)
    {}
};

NotificationDelegate* notificationDelegate;

SystemTray::SystemTray(AppSettingsManager* settingsManager, QObject* parent)
    : QSystemTrayIcon(parent)
    , settingsManager_(settingsManager)
    , pimpl_(std::make_unique<SystemTrayImpl>(this))
{
    notificationDelegate = [[NotificationDelegate alloc] init];
    if (@available(macOS 11.0, *)) {
        UNUserNotificationCenter.currentNotificationCenter.delegate = notificationDelegate;
    } else {
        NSUserNotificationCenter.defaultUserNotificationCenter.delegate = notificationDelegate;
    }

}

SystemTray::~SystemTray()
{

}

void
SystemTray::setCount(int count)
{
    if (count == 0) {
        setIcon(QIcon(":/images/jami.svg"));
    } else {
        setIcon(QIcon(":/images/jami-new.svg"));
    }
}

void
SystemTray::showNotification(const QString& id,
                             const QString& title,
                             const QString& body,
                             NotificationType type,
                             const QByteArray& avatar)
{
    [notificationDelegate sendNotificationWithId: id.toNSString() title:title.toNSString() body: body.toNSString() avatar: avatar type: type];
}
