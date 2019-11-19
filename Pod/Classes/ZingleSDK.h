//
//  ZingleSDK.h
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import <Foundation/Foundation.h>
#import "ZNGConversation.h"
#import "ZNGContact.h"
#import "ZNGService.h"
#import "ZNGContactService.h"

/**
 *  The NSNotification name to be posted along with the appropriate userInfo dictionary for the SDK to update its data and UI
 *   to reflect incoming push notification info.
 */
FOUNDATION_EXPORT NSString * _Nonnull const ZNGPushNotificationReceived;

@class ZingleAccountSession;
@class ZingleContactSession;

NS_ASSUME_NONNULL_BEGIN

typedef ZNGAccount * _Nullable (^ZNGAccountChooser)(NSArray<ZNGAccount *> * availableAccounts);
typedef ZNGService * _Nullable (^ZNGServiceChooser)(NSArray<ZNGService *> * availableServices);
typedef void (^ZNGAccountSessionCallback)(ZNGService * _Nullable service, ZNGError * _Nullable error);

typedef ZNGContactService * _Nullable (^ZNGContactServiceChooser)(NSArray<ZNGContactService *> * availableContactServices);
typedef void (^ZNGContactSessionCallback)(ZNGContactService * _Nullable contactService, ZNGService * _Nullable service, ZNGError * _Nullable error);

typedef void (^ZNGErrorHandler)(ZNGError * _Nonnull error);

@interface ZingleSDK : NSObject

#pragma mark - Push notifications
/**
 *  Static setter for the push notification device token.  This allows apps to register this push notification token for later use before a ZingleSession has been initialized.
 */
+ (void) setPushNotificationDeviceToken:(nonnull NSData *)token
__attribute__((deprecated("Notifications via normal APNS has been deprecated in favor of Firebase.  Use `setFirebaseToken:` instead.")));

/**
 *  Static setter for a Firebase FCM token.  This allows apps to register this push notification token for later use before a ZingleSession has been initialized.
 */
+ (void) setFirebaseToken:(nonnull NSString *)token;

#pragma mark - Contact access

/**
 *  The initializer for a Zingle session of the Contact type.  This includes both authentication information for the API user (i.e. the develoepr) and a set of identifying
 *   information for the contact to be sending messages (channel value and channel type ID.)
 *
 *  Once a list of available, matching contact services has been returned by the server, the availableContactServices array will be populated.
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 *  @param channelTypeId An identifier for the channel type, e.g. the identifier for Big Hotel Messaging System
 *  @param channelValue The channel value for the current user, e.g. joeSchmoe97 for the user name in Big Hotel Messaging System
 */
+ (ZingleContactSession *) contactSessionWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue;

#pragma mark - Account access
/**
 *  Provides a session object with the provided API credentials.  This is an account type session that is used by a specific service.
 *
 *  Using this constructor requires the developer to observe the availableAccounts and availableServices arrays on the returned session object
 *   in order to select one.  If multiple accounts/services are available and one is not selected, most API calls will fail.
 *
 *  @param token Token for Zingle API user
 *  @param key Security key for Zingle API user
 */
+ (ZingleAccountSession *) accountSessionWithToken:(NSString *)token key:(NSString *)key;

@end
NS_ASSUME_NONNULL_END
