//
//  ZNGCondition.h
//  Pods
//
//  Created by Jason Neel on 6/15/17.
//
//

#import <Mantle/Mantle.h>

@interface ZNGCondition : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSString * comparisonMethodCode;
@property (nonatomic, copy, nullable) NSString * comparisonSource;
@property (nonatomic, copy, nullable) NSString * comparisonValue;

@end
