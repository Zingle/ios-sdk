//
//  ZNGAutomation.h
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGAutomation : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *automationId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *status;
@property (nonatomic) BOOL isGlobal;

@end
