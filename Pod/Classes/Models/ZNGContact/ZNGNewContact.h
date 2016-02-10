//
//  ZNGNewContact.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGContact.h"

@interface ZNGNewContact : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSArray *customFieldValues;
@property (nonatomic) BOOL isStarred;
@property (nonatomic) BOOL isConfirmed;

- (id)initWithContact:(ZNGContact *)contact;

@end
