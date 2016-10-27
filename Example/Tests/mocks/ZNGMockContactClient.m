//
//  ZNGMockContactClient.m
//  ZingleSDK
//
//  Created by Jason Neel on 10/19/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import "ZNGMockContactClient.h"
#import "ZingleSDK/ZNGInboxDataSet.h"
#import "ZingleSDK/ZNGLabel.h"

@implementation ZNGMockContactClient

- (id) init
{
    return [super init];
}

- (void)contactWithId:(NSString*)contactId
              success:(void (^)(ZNGContact* contact, ZNGStatus* status))success
              failure:(void (^)(ZNGError* error))failure
{
    __block ZNGContact * contact = nil;
    
    [self.contacts enumerateObjectsUsingBlock:^(ZNGContact * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqual:contact]) {
            contact = obj;
            *stop = YES;
        }
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:0.1];
        
        ZNGStatus * status = [[ZNGStatus alloc] init];
        status.statusCode = 200;
        status.totalPages = (contact != nil) ? 1 : 0;
        status.totalRecords = status.totalPages;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            success(contact, status);
        });
    });
}

/**
 *  Creates a status object with a code of 200 and the correct data and page count
 */
- (ZNGStatus *) statusForContacts:(NSArray<ZNGContact *> *)contacts pageSize:(int)pageSize
{
    ZNGStatus * status = [[ZNGStatus alloc] init];
    status.statusCode = 200;
    status.pageSize = pageSize;
    status.totalRecords = [contacts count];
    status.totalPages = (pageSize > 0) ? (status.totalRecords / pageSize) + 1 : 0;
    return status;
}

- (NSArray<ZNGContact *> *)contactsMatchingParameters:(NSDictionary *)parameters
{
    NSNumber * confirmed = parameters[ParameterKeyIsConfirmed];
    NSNumber * closed = parameters[ParameterKeyIsClosed];
    NSString * labelId = parameters[ParameterKeyLabelId];
    
    NSMutableArray<ZNGContact *> * matches = [[NSMutableArray alloc] initWithCapacity:[self.contacts count]];
    
    for (ZNGContact * contact in self.contacts) {
        if ((confirmed != nil) && (contact.isConfirmed != [confirmed boolValue])) {
            continue;
        }
        
        if ((closed != nil) && (contact.isClosed != [closed boolValue])) {
            continue;
        }
        
        if (labelId != nil) {
            __block BOOL labelFound = NO;
            
            [contact.labels enumerateObjectsUsingBlock:^(ZNGLabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([label.labelId isEqualToString:labelId]) {
                    labelFound = YES;
                    *stop = YES;
                }
            }];
            
            if (!labelFound) {
                continue;
            }
        }
        
        [matches addObject:contact];
    }
    
    return matches;
}

- (void)contactListWithParameters:(NSDictionary*)parameters
                          success:(void (^)(NSArray* contacts, ZNGStatus* status))success
                          failure:(void (^)(ZNGError* error))failure
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int pageSize = [parameters[ParameterKeyPageSize] intValue];
        int pageIndex = [parameters[ParameterKeyPageIndex] intValue];
        NSArray<ZNGContact *> * matchingData = [self contactsMatchingParameters:parameters];
        ZNGStatus * status = [self statusForContacts:matchingData pageSize:pageSize];
        NSArray<ZNGContact *> * result = nil;

        if (pageSize > 0) {
            NSUInteger startingIndexForPage = (pageIndex - 1) * pageSize;
            NSUInteger totalContactCount = [matchingData count];
            
            if (startingIndexForPage < totalContactCount) {
                NSUInteger remainingContacts = totalContactCount - startingIndexForPage;
                NSUInteger count = MIN(remainingContacts, pageSize);
                status.page = pageIndex;
                
                result = [matchingData subarrayWithRange:NSMakeRange(startingIndexForPage, count)];
            }
        }
        
        [NSThread sleepForTimeInterval:0.1];
        dispatch_async(dispatch_get_main_queue(), ^{
            success(result, status);
        });
    });
}

@end
