//
//  ZNGSender.h
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGSender : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *senderId;
@property (nonatomic, strong) NSString *channelValue;

@end
