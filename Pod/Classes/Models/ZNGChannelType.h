//
//  ZNGChannelType.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGChannelType : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *channelTypeId;
@property (nonatomic, strong) NSString *typeClass;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *inboundNotificationURL;
@property (nonatomic, strong) NSString *outboundNotificationURL;
@property (nonatomic) BOOL allowCommunications;
@property (nonatomic) BOOL isGlobal;

@end
