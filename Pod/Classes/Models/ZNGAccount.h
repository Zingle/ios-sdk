//
//  ZNGAccount.h
//  Pods
//
//  Created by Ryan Farley on 1/31/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGAccount : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* accountId;
@property(nonatomic, strong) NSString* displayName;
@property(nonatomic, strong) NSNumber* termMonths;
@property(nonatomic, strong) NSDate* currentTermStartDate;
@property(nonatomic, strong) NSDate* currentTermEndDate;
@property(nonatomic, strong) NSDate* createdAt;
@property(nonatomic, strong) NSDate* updatedAt;

@end