//
//  ZingleContactSession.h
//  Pods
//
//  Created by Jason Neel on 6/15/16.
//
//
#import "ZingleSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZingleContactSession : ZingleSession

@property (nonatomic, readonly, nonnull) NSString * channelTypeID;
@property (nonatomic, readonly, nonnull) NSString * channelValue;


- (instancetype) initWithToken:(NSString *)token key:(NSString *)key channelTypeId:(NSString *)channelTypeId channelValue:(NSString *)channelValue;

@end

NS_ASSUME_NONNULL_END