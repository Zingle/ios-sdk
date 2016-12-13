//
//  ZNGPrinter.h
//  Pods
//
//  Created by Jason Neel on 12/12/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGPrinter : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong, nonnull) NSString * printerId;
@property (nonatomic, strong, nullable) NSString * displayName;

@end
