//
//  ZNGMessageRead.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGMessageRead : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSDate* readAt;

@end
