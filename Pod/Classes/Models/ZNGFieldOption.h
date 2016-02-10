//
//  ZNGOption.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGFieldOption : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* optionId;
@property(nonatomic, strong) NSString* displayName;
@property(nonatomic, strong) NSString* value;
@property(nonatomic, strong) NSNumber* sortOrder;

@end
