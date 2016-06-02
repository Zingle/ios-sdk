//
//  ZNGUserAuthorization.h
//  Pods
//
//  Created by Robert Harrison on 5/24/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGUserAuthorization : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* authorizationClass;

@end
