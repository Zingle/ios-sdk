//
//  ZNGNewMessageResponse.h
//  Pods
//
//  Created by Jason Neel on 6/21/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGNewMessageResponse : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSArray<NSString *> * messageIds;

@end
