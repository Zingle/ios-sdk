//
//  ZNGTemplate.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGTemplate : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *body;
@property (nonatomic) BOOL isGlobal;

@end
