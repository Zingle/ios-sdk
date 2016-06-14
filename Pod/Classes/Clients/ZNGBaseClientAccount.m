//
//  ZNGBaseClientAccount.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZNGBaseClientAccount.h"
#import "ZNGAccount.h"

@implementation ZNGBaseClientAccount

- (instancetype) initWithAccount:(ZNGAccount *)account
{
    self = [super init];
    
    if (self != nil) {
        _account = account;
    }
    
    return self;
}

- (NSDictionary *) parametersByMergingIntoPassedParameters: (NSDictionary *)passedParameters;
{
    NSDictionary * accountParameters = @{@"account" : self.account.accountId};
    NSDictionary * parameters = accountParameters;
    
    if (passedParameters != nil) {
        NSMutableDictionary * mutableParameters = [passedParameters mutableCopy];
        [mutableParameters addEntriesFromDictionary:accountParameters];
        parameters = mutableParameters;
    }
    
    return parameters;
}

- (NSURLSessionDataTask *)getListWithParameters:(NSDictionary*)passedParameters
                                           path:(NSString*)path
                                  responseClass:(Class)responseClass
                                        success:(void (^)(id responseObject, ZNGStatus *status))success
                                        failure:(void (^)(ZNGError* error))failure
{
    NSDictionary * parameters = [self parametersByMergingIntoPassedParameters:passedParameters];
    
    [self getListWithParameters:parameters path:path responseClass:responseClass success:success failure:failure];
}

@end
