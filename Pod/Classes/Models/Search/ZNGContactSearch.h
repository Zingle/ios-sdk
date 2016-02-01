//
//  ZNGContactSearch.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModelSearch.h"

@class ZNGContact;

@interface ZNGContactSearch : ZingleModelSearch

@property (nonatomic, retain) NSString *channelTypeID;
@property (nonatomic, retain) NSString *channelValue;
@property (nonatomic, retain) NSString *labelID;

/*
- (ZNGContact *)findContactWithChannelTypeID:(NSString *)channelTypeID
                             andChannelValue:(NSString *)channelValue
                                       error:(NSError **)error;

- (void)findContactWithChannelTypeID:(NSString *)channelTypeID
                     andChannelValue:(NSString *)channelValue
                     completionBlock:(void (^) (ZNGContact *contact))completionBlock
                          errorBlock:(void (^) (NSError *error))errorBlock;
*/

@end
