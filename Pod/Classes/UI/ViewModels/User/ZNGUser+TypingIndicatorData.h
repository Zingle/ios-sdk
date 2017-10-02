//
//  ZNGUser+TypingIndicatorData.h
//  Pods
//
//  Created by Jason Neel on 8/30/17.
//
//

#import <ZingleSDK/ZingleSDK.h>
#import "ZingleSDK/ZNGMessageData.h"

/**
 *  Category on ZNGUser to allow a user to be used to populate a typing indicator message bubble
 */
@interface ZNGUser (TypingIndicatorData) <ZNGMessageData>

@end
