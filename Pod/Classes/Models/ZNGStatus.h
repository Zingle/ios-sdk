//
//  ZNGStatus.h
//  Pods
//
//  Created by Ryan Farley on 2/19/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGStatus : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *text;
@property (nonatomic) NSInteger statusCode;
@property (nonatomic, strong) NSString *statusDescription;
@property (nonatomic, strong) NSString *sortField;
@property (nonatomic, strong) NSString *sortDirection;
@property (nonatomic) NSInteger page;
@property (nonatomic) NSInteger pageSize;
@property (nonatomic) NSInteger totalPages;
@property (nonatomic) NSInteger totalRecords;

@end
