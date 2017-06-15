//
//  ZNGContactGroup.h
//  Pods
//
//  Created by Jason Neel on 6/15/17.
//
//

#import <Mantle/Mantle.h>

@class ZNGCondition;

@interface ZNGContactGroup : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nonnull) NSString * groupId;
@property (nonatomic, copy, nullable) NSString * displayName;
@property (nonatomic, copy, nullable) NSString * conditionBooleanOperator;
@property (nonatomic, strong, nullable) NSArray<ZNGCondition *> * conditions;

@end
