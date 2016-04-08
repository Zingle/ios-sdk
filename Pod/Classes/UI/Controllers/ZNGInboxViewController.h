//
//  ZNGInboxViewController.h
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import <UIKit/UIKit.h>
#import "ZNGConversationViewController.h"
@class ZNGService;

@interface ZNGInboxViewController : UIViewController <ZNGConversationDetailDelegate>

+ (instancetype)inboxViewController;

+ (instancetype)withServiceId:(NSString *)serviceId;

- (void)refresh;

- (NSArray *)contacts;

@property (strong, nonatomic) ZNGService *service;
@property (strong, nonatomic) NSString *serviceId;

@property (nonatomic, strong) NSMutableDictionary *currentFilterParams;

@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
