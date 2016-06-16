//
//  ZNGContactViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/16/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGContact.h"
#import "ZNGService.h"

@class ZingleAccountSession;

@interface ZNGContactViewController : UITableViewController <UIPickerViewDataSource>

@property (nonatomic, strong, nonnull) ZingleAccountSession * session;

+ (instancetype)withContact:(ZNGContact *)contact session:(ZingleAccountSession *)aSession;

@end
