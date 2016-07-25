//
//  ZNGEventClient.h
//  Pods
//
//  Created by Jason Neel on 7/11/16.
//
//

#import <ZingleSDK/ZingleSDK.h>

@interface ZNGEventClient : ZNGBaseClientService

- (void)eventListWithParameters:(NSDictionary*)parameters
                        success:(void (^)(NSArray<ZNGEvent *> * events, ZNGStatus* status))success
                        failure:(void (^)(ZNGError* error))failure;

- (void)eventWithId:(NSString*)eventId
            success:(void (^)(ZNGEvent * event, ZNGStatus* status))success
            failure:(void (^)(ZNGError* error))failure;

- (void)postInternalNote:(NSString *)note
               toContact:(ZNGContact *)contact
                 success:(void (^)(ZNGEvent * note, ZNGStatus * status))success
                 failure:(void (^)(ZNGError * error))failure;

@end
