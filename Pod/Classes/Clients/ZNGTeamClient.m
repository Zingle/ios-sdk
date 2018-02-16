//
//  ZNGTeamClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/23/18.
//

#import "ZNGTeamClient.h"
#import "ZNGTeamV2.h"
#import "ZingleSession.h"
#import <AFNetworking/AFHTTPSessionManager.h>

@implementation ZNGTeamClient

- (void)teamListWithSuccess:(void (^ _Nullable)(NSArray<ZNGTeamV2 *> * _Nullable teams))success
                    failure:(void (^ _Nullable)(ZNGError * _Nullable error))failure
{
    NSString * path = [NSString stringWithFormat:@"services/%@/teams", self.serviceId];
    
    [self.session.v2SessionManager GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(self->jsonProcessingQueue, ^{
            NSError * error = nil;
            NSArray<ZNGTeamV2 *> * teams = [MTLJSONAdapter modelsOfClass:[ZNGTeamV2 class] fromJSONArray:responseObject error:&error];
            
            if (teams != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(teams);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure([[ZNGError alloc] initWithAPIError:error]);
                });
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure([[ZNGError alloc] initWithAPIError:error]);
    }];
}

@end
