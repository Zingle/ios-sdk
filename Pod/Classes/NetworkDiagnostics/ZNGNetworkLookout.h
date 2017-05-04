//
//  ZNGNetworkLookout.h
//  Pods
//
//  Created by Jason Neel on 4/18/17.
//
//

#import <Foundation/Foundation.h>

@class ZingleAccountSession;

extern NSString * _Nonnull const ZNGNetworkLookoutStatusChanged;

typedef enum {
    ZNGNetworkStatusUnknown,
    ZNGNetworkStatusInternetUnreachable,
    ZNGNetworkStatusZingleAPIUnreachable,
    ZNGNetworkStatusZingleSocketDisconnected,
    ZNGNetworkStatusConnected
} ZNGNetworkLookoutStatus;

/**
 *  The Network Lookout receives notifications for all networking events in the Zingle API and reports network status.
 */
@interface ZNGNetworkLookout : NSObject

- (void) recordLogin;
- (void) recordSocketConnected;
- (void) recordSocketDisconnected;

/**
 *  Setting this weak session reference allows better diagnostics, especially when returning from the background.
 */
@property (nonatomic, weak, nullable) ZingleAccountSession * session;

@property (nonatomic, readonly) ZNGNetworkLookoutStatus status;

@end
