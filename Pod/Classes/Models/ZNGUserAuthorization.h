//
//  ZNGUserAuthorization.h
//  Pods
//
//  Created by Robert Harrison on 5/24/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGUser.h"

@interface ZNGUserAuthorization : ZNGUser

@property (nonatomic, strong, nullable) NSString * authorizationClass;

- (NSString * _Nullable) displayName;

@end
