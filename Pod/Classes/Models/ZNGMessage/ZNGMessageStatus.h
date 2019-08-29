//
//  ZNGMessageStatus.h
//  ZingleSDK
//
//  Created by Jason Neel on 8/23/19.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ZNGMessageStatusTypeFailed;

@interface ZNGMessageStatus : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong, nullable) NSString * type;
@property (nonatomic, strong, nullable) NSString * statusDescription;
@property (nonatomic, strong, nullable) NSDate * createdAt;

- (BOOL) isFailure;

@end

NS_ASSUME_NONNULL_END
