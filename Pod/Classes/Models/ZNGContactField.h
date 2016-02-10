//
//  ZNGContactField.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGContactField : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* contactFieldId;
@property(nonatomic, strong) NSString* displayName;
@property(nonatomic, strong) NSString* dataType;
@property(nonatomic) BOOL isGlobal;
@property(nonatomic, strong) NSArray* options;// Array of ZNGFieldOption

@end
