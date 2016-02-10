//
//  ZNGContact.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGMessage.h"

@interface ZNGContact : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* contactId;
@property(nonatomic) BOOL isConfirmed;
@property(nonatomic) BOOL isStarred;
@property(nonatomic, strong) ZNGMessage* lastMessage;
@property(nonatomic, strong) NSArray* channels; // Array of ZNGChannel
@property(nonatomic, strong) NSArray* customFieldValues; // Array of ZNGContactFieldValue
@property(nonatomic, strong) NSArray* labels; // Array of ZNGLabel
@property(nonatomic, strong) NSDate* createdAt;
@property(nonatomic, strong) NSDate* updatedAt;

@end
