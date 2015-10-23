//
//  ZNGMessageSearch.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModelSearch.h"

@interface ZNGMessageSearch : ZingleModelSearch

@property (nonatomic, retain) NSString *contactId;
@property (nonatomic, retain) NSString *templateId;
@property (nonatomic, retain) NSString *communicationDirection;
@property (nonatomic, retain) NSDate *createdAfter, *createdBefore;

@end
