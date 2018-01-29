//
//  ZNGTeamClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/23/18.
//

#import <ZingleSDK/ZingleSDK.h>

@class ZNGTeamV2;

@interface ZNGTeamClient : ZNGBaseClientService

- (void)teamListWithSuccess:(void (^ _Nullable)(NSArray<ZNGTeamV2 *> * _Nullable teams))success
                    failure:(void (^ _Nullable)(ZNGError * _Nullable error))failure;

@end
