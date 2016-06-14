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

@interface ZNGContactViewController : UITableViewController <UIPickerViewDataSource>

+ (instancetype)withContact:(ZNGContact *)contact withService:(ZNGService *)service;

@end
