//
//  ZNGUser.h
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGUser : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* userId;
@property(nonatomic, strong) NSString* username;
@property(nonatomic, strong) NSString *email;
@property(nonatomic, strong) NSString *firstName;
@property(nonatomic, strong) NSString *lastName;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSArray* serviceIds;

@end
