//
//  ZNGRecipient.h
//  Pods
//
//  Created by Ryan Farley on 2/9/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGRecipient : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *recipientId;
@property (nonatomic, strong) NSString *channelValue;

@end
