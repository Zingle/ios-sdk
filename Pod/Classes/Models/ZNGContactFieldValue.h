//
//  ZNGContactFieldValue.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGContactField.h"

@interface ZNGContactFieldValue : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* value;
@property(nonatomic, strong) NSString* selectedCustomFieldOptionId;
@property(nonatomic, strong) ZNGContactField* customField;


@end
