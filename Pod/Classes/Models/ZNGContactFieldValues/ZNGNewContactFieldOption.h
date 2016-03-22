//
//  ZNGNewContactFieldOption.h
//  Pods
//
//  Created by Ryan Farley on 3/22/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGNewContactFieldOption : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* selectedCustomFieldOptionId;
@property(nonatomic, strong) NSString* customFieldId;

@end
