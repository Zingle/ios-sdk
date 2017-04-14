//
//  ZNGBaseClientAccount.h
//  Pods
//
//  Created by Jason Neel on 4/6/17.
//
//

#import <ZingleSDK/ZingleSDK.h>

/**
 *  A Zingle SDK client that requires both an active account
 */
@interface ZNGBaseClientAccount : ZNGBaseClient

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, readonly, nonnull) NSString * accountId;

- (instancetype) initWithSession:(__weak ZingleSession *)session accountId:(NSString *)accountId;

- (instancetype) initWithSession:(__weak ZingleSession *)session NS_UNAVAILABLE;

NS_ASSUME_NONNULL_END

@end
