//
//  ZNGCorrespondent.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGChannel.h"

@interface ZNGCorrespondent : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* correspondentId;
@property(nonatomic, strong) ZNGChannel* channel;

@end
