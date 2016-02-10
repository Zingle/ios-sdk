//
//  ZNGCustomField.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGCustomField : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *customFieldId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic) BOOL isGlobal;
@property (nonatomic, strong) NSArray *options;

@end
