//
//  ZNGContactAssignment.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/16/18.
//

#import <Mantle/Mantle.h>

@interface ZNGContactAssignment : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSString * userId;
@property (nonatomic, copy, nullable) NSString * teamId;

@end
