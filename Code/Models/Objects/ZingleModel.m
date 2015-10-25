//
//  ZingleModel.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModel.h"
#import "ZingleSDK.h"
#import "ZingleDAO.h"
#import "ZingleModelSearch.h"
#import "NSMutableDictionary+json.h"
#import "ZingleDAOResponse.h"

@implementation ZingleModel

- (id)init
{
    if( self = [super init] )
    {
        self.DAO = [[ZingleDAO alloc] init];
    }
    
    return self;
}

- (NSString *)baseURIWithID:(BOOL)withID
{
    return @"";
}

- (NSMutableDictionary *)asDictionary
{
    return [NSMutableDictionary dictionary];
}

- (void)hydrate:(NSMutableDictionary *)data
{
    // purposefully left blank, descendants to implement
}

- (void)hydrateDates:(NSMutableDictionary *)data
{
    NSNumber *created = [data objectAtPath:@"created_at" expectedClass:[NSNumber class] default:nil];
    NSNumber *updated = [data objectAtPath:@"updated_at" expectedClass:[NSNumber class] default:nil];
    
    self.created = nil;
    if( created != nil )
    {
        self.created = [[NSDate alloc] initWithTimeIntervalSince1970:[created intValue]];
    }
    
    self.updated = nil;
    if( updated != nil )
    {
        self.updated = [[NSDate alloc] initWithTimeIntervalSince1970:[updated intValue]];
    }
}

- (BOOL)isNew
{
    return (self.ID == nil || [self.ID isEqualToString:@""]);
}

- (NSError *)preRefreshValidation
{
    return [[ZingleSDK sharedSDK] genericError:@"Refresh is not supported for this Object." code:0];
}

- (BOOL)refreshWithError:(NSError **)error
{
    NSError *validationError = [self preRefreshValidation];
    if( validationError ) {
        *error = validationError;
        return NO;
    }
    
    [self.DAO resetDefaults];
    [self.DAO setRequestMethod:ZINGLE_REQUEST_METHOD_GET];
    ZingleDAOResponse *response = [self.DAO sendSynchronousRequestTo:[self baseURIWithID:YES] error:error];
    
    if( [response successful] ) {
        [self hydrate:[response result]];
        return YES;
    } else {
        return NO;
    }
}

- (void)refreshWithCompletionBlock:(void (^) (void))completionBlock
                        errorBlock:(void (^) (NSError *error))errorBlock
{
    NSError *validationError = [self preRefreshValidation];
    if( validationError ) {
        errorBlock(validationError);
        return;
    }
    
    [self.DAO resetDefaults];
    [self.DAO setRequestMethod:ZINGLE_REQUEST_METHOD_GET];
    
    [self.DAO sendAsynchronousRequestTo:[self baseURIWithID:YES]
                        completionBlock:^(ZingleDAOResponse *response) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self hydrate:[response result]];
                                completionBlock();
                            });
                        } errorBlock:^(ZingleDAOResponse *response, NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                errorBlock(error);
                            });
                        }];
}

- (NSString *)saveToRequestURI
{
    return [self baseURIWithID:![self isNew]];
}

- (NSString *)saveRequestMethod
{
    return ([self isNew] ? ZINGLE_REQUEST_METHOD_POST : ZINGLE_REQUEST_METHOD_PUT);
}

- (NSError *)preSaveValidation
{
    return [[ZingleSDK sharedSDK] genericError:@"Save is not supported for this Object." code:0];
}

- (BOOL)saveWithError:(NSError **)error
{
    NSError *validationError = [self preSaveValidation];
    if( validationError ) {
        *error = validationError;
        return NO;
    }
    
    [self prepareSaveDAO];
    
    ZingleDAOResponse *response = [self.DAO sendSynchronousRequestTo:[self saveToRequestURI] error:error];
    
    if( [response successful] ) {
        [self hydrate:[response result]];
        return YES;
    } else {
        return NO;
    }
}

- (void)saveWithCompletionBlock:(void (^) (void))completionBlock
                     errorBlock:(void (^) (NSError *error))errorBlock
{
    NSError *validationError = [self preSaveValidation];
    if( validationError ) {
        errorBlock(validationError);
        return;
    }
    
    [self prepareSaveDAO];
    
    [self.DAO sendAsynchronousRequestTo:[self saveToRequestURI]
                        completionBlock:^(ZingleDAOResponse *response) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if( [response successful] ) {
                                    [self hydrate:[response result]];
                                    completionBlock();
                                } else {
                                    // Error
                                }
                            });
                        } errorBlock:^(ZingleDAOResponse *response, NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                errorBlock(error);
                            });
                        }];
}

- (void)prepareSaveDAO
{
    [self.DAO resetDefaults];
    [self.DAO setPostVars:[self asDictionary]];
    [self.DAO setRequestMethod:[self saveRequestMethod]];
}

- (NSError *)preDestroyValidation
{
    if( self.ID == nil || [self.ID isEqualToString:@""] ) {
        return [[ZingleSDK sharedSDK] genericError:@"Cannot delete object without an ID" code:0];
    }
    
    return [[ZingleSDK sharedSDK] genericError:@"Delete is not supported for this Object." code:0];
}

- (BOOL)destroyWithError:(NSError **)error
{
    NSError *validationError = [self preDestroyValidation];
    if( validationError ) {
        *error = validationError;
        return NO;
    }
    
    [self prepareDestroyDAO];
    
    ZingleDAOResponse *response = [self.DAO sendSynchronousRequestTo:[self baseURIWithID:YES] error:error];
    
    if( [response successful] ) {
        return YES;
    } else {
        return NO;
    }
}

- (void)destroyWithCompletionBlock:(void (^) (void))completionBlock
                        errorBlock:(void (^) (NSError *error))errorBlock
{
    NSError *validationError = [self preDestroyValidation];
    if( validationError ) {
        errorBlock(validationError);
        return;
    }
    
    [self prepareDestroyDAO];
    
    [self.DAO sendAsynchronousRequestTo:[self baseURIWithID:YES]
                        completionBlock:^(ZingleDAOResponse *response) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                completionBlock();
                            });
                        } errorBlock:^(ZingleDAOResponse *response, NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                errorBlock(error);
                            });
                        }];
}

- (void)prepareDestroyDAO
{
    [self.DAO resetDefaults];
    [self.DAO setRequestMethod:ZINGLE_REQUEST_METHOD_DELETE];
}

- (int)logLevel
{
    return [self.DAO logLevel];
}

- (void)setLogLevel:(int)logLevel
{
    [self.DAO setLogLevel:logLevel];
}

@end
