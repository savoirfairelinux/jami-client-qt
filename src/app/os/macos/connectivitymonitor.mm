/*
 * Copyright (C) 2021-2024 Savoir-faire Linux Inc.
 * Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
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

#include <CoreFoundation/CoreFoundation.h>
#include <AppKit/AppKit.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <SystemConfiguration/SystemConfiguration.h>

#include "connectivitymonitor.h"
#include <QDebug>

typedef void(^SystemMonitorCallback)(void);

@interface SystemMonitor: NSObject

-(void)startWithCallBack:(SystemMonitorCallback) callback;
@property (nonatomic, copy) SystemMonitorCallback callback;

@end

@implementation SystemMonitor

-(void)startWithCallBack:(SystemMonitorCallback)callback {
    self.callback = callback;
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                                     selector: @selector(receiveWakeNotification:)
      name: NSWorkspaceDidWakeNotification object: NULL];
}

- (void)receiveWakeNotification:(NSNotification*)note
{
    _callback();
}

-(void)dealloc {
    [_callback release], _callback = nil;
    [super dealloc];
}

@end

dispatch_queue_t scNetworkQueue;
SCNetworkReachabilityRef currentReachability;
SystemMonitor* systemMonitor;

static void ReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkConnectionFlags flags, void* info)
{
     void (^callbackBlock)(SCNetworkReachabilityFlags) = (void (^)(SCNetworkReachabilityFlags))info;
     callbackBlock(flags);
}

ConnectivityMonitor::ConnectivityMonitor(QObject* parent)
    : QObject(parent)
{
    scNetworkQueue = dispatch_queue_create("scNetworkReachability", DISPATCH_QUEUE_SERIAL);
    systemMonitor = [[SystemMonitor alloc] init];
    [systemMonitor startWithCallBack: ^(void) {
        Q_EMIT connectivityChanged();
    }];
    SCNetworkReachabilityRef reachabilityRef = NULL;
       void (^callbackBlock)(SCNetworkReachabilityFlags) = ^(SCNetworkReachabilityFlags flags) {
           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
               Q_EMIT connectivityChanged();
           });
       };

      SCNetworkReachabilityContext context = {
           .version = 0,
           .info = [callbackBlock copy],
           .release = CFRelease
       };
       reachabilityRef  = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "test");
       if (SCNetworkReachabilitySetCallback(reachabilityRef , ReachabilityCallback, &context)) {
           if (!SCNetworkReachabilitySetDispatchQueue(reachabilityRef, scNetworkQueue) ) {
               SCNetworkReachabilitySetCallback(reachabilityRef, NULL, NULL);
           }
           currentReachability = reachabilityRef;
       }
}

ConnectivityMonitor::~ConnectivityMonitor()
{
    SCNetworkReachabilitySetCallback(currentReachability, NULL, NULL);
    currentReachability = NULL;
}

bool
ConnectivityMonitor::isOnline()
{
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "test");
    auto valid = SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
    bool isConnected = (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
    CFRelease(reachabilityRef);
    return valid && isConnected;
}
