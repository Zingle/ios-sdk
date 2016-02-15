//
//  ZNGConversationViewController.h
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import <UIKit/UIKit.h>

@interface ZNGConversationViewController : UIViewController

- (id)initWithServiceId:(NSString *)seriveId
    withChannelTypeName:(NSString *)channelTypeName
       fromChannelValue:(NSString *)channelValue;

- (id)initWithServiceId:(NSString *)seriveId
       fromChannelValue:(NSString *)channelValue;

@end
