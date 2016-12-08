//
//  ZNGHotsosClient.h
//  Pods
//
//  Created by Jason Neel on 12/7/16.
//
//

#import <Foundation/Foundation.h>

@class ZNGService;

NS_ASSUME_NONNULL_BEGIN

@interface ZNGHotsosClient : NSObject

- (id) init NS_UNAVAILABLE;
- (id) initWithService:(ZNGService *)service;

- (void) getIssuesLike:(NSString *)term completion:(void (^)(NSArray<NSString *> * _Nullable matchingIssueNames, NSError * _Nullable error))completion;

@property (nonatomic, strong) ZNGService * service;

NS_ASSUME_NONNULL_END

@end
