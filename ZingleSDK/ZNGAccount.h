//
//  ZNGAccount.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModel.h"

@class ZNGServiceSearch;
@class ZNGPlanSearch;
@class ZNGService;
@class ZNGPlan;

@interface ZNGAccount : ZingleModel

@property (nonatomic, retain) NSString *displayName;
@property (nonatomic, retain) NSNumber *termMonths;
@property (nonatomic, retain) NSDate *currentTermStartDate, *currentTermEndDate;

- (ZNGService *)newService;
- (ZNGPlanSearch *)planSearch;

- (NSArray *)allServicesWithError:(NSError **)error;
- (void)allServicesWithCompletionBlock:( void (^)(NSArray *services) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock;


- (NSArray *)allPlansWithError:(NSError **)error;
- (void)allPlansWithCompletionBlock:( void (^)(NSArray *accounts) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock;

- (ZNGPlan *)findPlanByCode:(NSString *)planCode error:(NSError **)error;
- (void)findPlanByCode:(NSString *)planCode withCompletionBlock:( void (^)(ZNGPlan *plan) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock;

@end
