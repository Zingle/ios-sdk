//
//  ZNGCustomFieldValues.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGCustomField.h"

@interface ZNGCustomFieldValue : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* value;
@property(nonatomic, strong) NSString* selectedCustomFieldOptionId;
@property(nonatomic, strong) ZNGCustomField* customField;

@end
