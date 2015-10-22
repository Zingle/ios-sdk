//
//  ZNGAccount.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGAccount.h"
#import "ZNGServiceSearch.h"
#import "ZNGPlanSearch.h"
#import "ZNGService.h"
#import "NSMutableDictionary+json.h"
#import "ZingleDAO.h"
#import "ZingleError.h"
#import "ZingleSDK.h"
#import "ZingleDAOResponse.h"

@implementation ZNGAccount

- (NSString *)baseURIWithID:(BOOL)withID
{
    if( withID ) {
        return [NSString stringWithFormat:@"accounts/%@", self.ID];
    } else {
        return @"accounts";
    }
}

- (void)hydrate:(NSMutableDictionary *)data
{
    [self hydrateDates:data];
    
    self.ID = [data objectAtPath:@"id" expectedClass:[NSString class] default:nil];
    self.displayName = [data objectAtPath:@"display_name" expectedClass:[NSString class] default:@""];
    NSNumber *currentTermStartDate = [data objectAtPath:@"current_term_start_date" expectedClass:[NSNumber class] default:nil];
    NSNumber *currentTermEndDate = [data objectAtPath:@"current_term_end_date" expectedClass:[NSNumber class] default:nil];
    
    self.currentTermStartDate = nil;
    self.currentTermEndDate = nil;
    
    if( currentTermStartDate ) {
        self.currentTermStartDate = [[NSDate alloc] initWithTimeIntervalSince1970:[currentTermStartDate intValue]];
    }
    
    if( currentTermEndDate ) {
        self.currentTermEndDate = [[NSDate alloc] initWithTimeIntervalSince1970:[currentTermEndDate intValue]];
    }
    
    self.termMonths = [data objectAtPath:@"term_months" expectedClass:[NSNumber class] default:nil];
}

- (NSError *)preRefreshValidation
{
    return nil;
}

- (ZNGService *)newService
{
    ZNGService *service = [[ZNGService alloc] init];
    service.account = self;
    return service;
}

- (ZNGPlanSearch *)planSearch
{
    return [[ZNGPlanSearch alloc] initWithAccount:self];
}

- (NSArray *)allServicesWithError:(NSError **)error
{
    ZNGServiceSearch *serviceSearch = [[ZNGServiceSearch alloc] initWithAccount:self];
    return [serviceSearch searchWithError:error];
}

- (void)allServicesWithCompletionBlock:( void (^)(NSArray *services) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock
{
    ZNGServiceSearch *serviceSearch = [[ZNGServiceSearch alloc] initWithAccount:self];
    return [serviceSearch searchWithCompletionBlock:^(NSArray *results) {
        completionBlock(results);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (NSArray *)allPlansWithError:(NSError **)error
{
    ZNGPlanSearch *planSearch = [[ZNGPlanSearch alloc] initWithAccount:self];
    return [planSearch searchWithError:error];
}

- (void)allPlansWithCompletionBlock:( void (^)(NSArray *accounts) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock
{
    ZNGPlanSearch *planSearch = [[ZNGPlanSearch alloc] initWithAccount:self];
    [planSearch searchWithCompletionBlock:^(NSArray *results) {
        completionBlock(results);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (ZNGPlan *)findPlanByCode:(NSString *)planCode error:(NSError **)error
{
    ZNGPlanSearch *planSearch = [[ZNGPlanSearch alloc] initWithAccount:self];
    planSearch.code = planCode;
    NSArray *searchResults = [planSearch searchWithError:error];
    
    if( searchResults && [searchResults count] == 1 ) {
        ZNGPlan *plan = (ZNGPlan *)[searchResults objectAtIndex:0];
        return plan;
    }
    
    NSString *errorMessage = @"Could not find plan.";
    ZingleError *zingleError = [[ZingleError alloc] initWithDomain:ZINGLE_ERROR_DOMAIN code:ZINGLE_HTTP_STATUS_NOT_FOUND userInfo:[NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey]];
    zingleError.zingleErrorCode     = ZINGLE_HTTP_STATUS_NOT_FOUND;
    zingleError.httpStatusCode      = ZINGLE_HTTP_STATUS_NOT_FOUND;
    zingleError.errorText           = errorMessage;
    zingleError.errorDescription    = errorMessage;
    
    *error = zingleError;
    
    return nil;
}

- (void)findPlanByCode:(NSString *)planCode withCompletionBlock:( void (^)(ZNGPlan *plan) )completionBlock errorBlock:( void (^)(NSError *error) )errorBlock

{
    ZNGPlanSearch *planSearch = [[ZNGPlanSearch alloc] initWithAccount:self];
    planSearch.code = planCode;
    [planSearch searchWithCompletionBlock:^(NSArray *results) {
        if( results && [results count] == 1 ) {
            ZNGPlan *plan = (ZNGPlan *)[results objectAtIndex:0];
            completionBlock(plan);
        } else {
            NSString *errorMessage = @"Could not find plan.";
            ZingleError *error = [[ZingleError alloc] initWithDomain:ZINGLE_ERROR_DOMAIN code:ZINGLE_HTTP_STATUS_NOT_FOUND userInfo:[NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey]];
            error.zingleErrorCode     = ZINGLE_HTTP_STATUS_NOT_FOUND;
            error.httpStatusCode      = ZINGLE_HTTP_STATUS_NOT_FOUND;
            error.errorText           = errorMessage;
            error.errorDescription    = errorMessage;
            
            errorBlock(error);
        }
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (NSString *)description
{
    NSString *description = @"<ZNGAccount> {\r";
    description = [description stringByAppendingFormat:@"    ID: %@\r", self.ID];
    description = [description stringByAppendingFormat:@"    displayName: %@\r", self.displayName];
    description = [description stringByAppendingFormat:@"    termMonths: %i\r", [self.termMonths intValue]];
    description = [description stringByAppendingFormat:@"    currentTermStartDate: %@\r", self.currentTermStartDate];
    description = [description stringByAppendingFormat:@"    currentTermEndDate: %@\r", self.currentTermEndDate];
    description = [description stringByAppendingFormat:@"    created: %@\r", self.created];
    description = [description stringByAppendingFormat:@"    updated: %@\r", self.updated];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
