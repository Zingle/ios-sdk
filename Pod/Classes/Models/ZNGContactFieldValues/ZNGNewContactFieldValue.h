//
//  ZNGNewContactFieldValue.h
//  Pods
//
//  Created by Ryan Farley on 3/21/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGNewContactFieldValue : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* value;
@property(nonatomic, strong) NSString* customFieldOptionId;
@property(nonatomic, strong) NSString* customFieldId;

@end
