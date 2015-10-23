//
//  ZNGMessageCorrespondent.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZNGMessageCorrespondent.h"
#import "ZingleModel.h"
#import "ZNGService.h"
#import "ZNGContact.h"
#import "ZNGLabel.h"

NSString * const ZINGLE_CORRESPONDENT_TYPE_SERVICE = @"service";
NSString * const ZINGLE_CORRESPONDENT_TYPE_CONTACT = @"contact";
NSString * const ZINGLE_CORRESPONDENT_TYPE_LABEL = @"label";

@implementation ZNGMessageCorrespondent

- (void)setCorrespondent:(ZingleModel *)correspondent
{
    if( ![correspondent isKindOfClass:[ZNGService class]] &&
        ![correspondent isKindOfClass:[ZNGContact class]] &&
        ![correspondent isKindOfClass:[ZNGLabel class]] )
    {
        [NSException raise:@"ZINGLE_INVALID_CORRESPONDENT" format:@"Invalid correspondent. Accepted objects are ZNGService, ZNGContact and ZNGLabel."];
    }
    
    _correspondent = correspondent;
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if( ![self.correspondent isNew] )
    {
        [dictionary setObject:self.correspondent.ID forKey:@"id"];
    }
    
    if( ![self.correspondent isKindOfClass:[ZNGLabel class]] )
    {
        [dictionary setObject:self.channelValue forKey:@"channel_value"];
    }
    
    return dictionary;
}

- (NSString *)correspondentType
{
    NSString *correspondentType = @"";
    
    if( [self.correspondent isKindOfClass:[ZNGService class]] )
    {
        correspondentType = ZINGLE_CORRESPONDENT_TYPE_SERVICE;
    }
    else if( [self.correspondent isKindOfClass:[ZNGContact class]] )
    {
        correspondentType = ZINGLE_CORRESPONDENT_TYPE_CONTACT;
    }
    else if( [self.correspondent isKindOfClass:[ZNGLabel class]] )
    {
        correspondentType = ZINGLE_CORRESPONDENT_TYPE_LABEL;
    }
    else
    {
        correspondentType = _correspondentType;
    }
    
    if( ![correspondentType isEqualToString:ZINGLE_CORRESPONDENT_TYPE_SERVICE] &&
        ![correspondentType isEqualToString:ZINGLE_CORRESPONDENT_TYPE_CONTACT] &&
        ![correspondentType isEqualToString:ZINGLE_CORRESPONDENT_TYPE_LABEL] )
    {
        [NSException raise:@"ZINGLE_INVALID_CORRESPONDENT_TYPE" format:@"Invalid correspondent type."];
    }
    
    return correspondentType;
}

- (NSString *)description
{
    NSString *description = @"<ZNGMessageCorrespondent> {\r";
    description = [description stringByAppendingFormat:@"    correspondent: %@\r", self.correspondent];
    description = [description stringByAppendingFormat:@"    correspondentType: %@\r", [self correspondentType]];
    description = [description stringByAppendingFormat:@"    channelType: %@\r", self.channelType];
    description = [description stringByAppendingFormat:@"    channelValue: %@\r", self.channelValue];
    description = [description stringByAppendingFormat:@"    formattedChannelValue: %@\r", self.formattedChannelValue];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}

@end
