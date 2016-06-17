//
//  ZNGContactServicesViewController.h
//  Pods
//
//  Created by Robert Harrison on 5/27/16.
//
//

#import <UIKit/UIKit.h>

#import "ZNGContactService.h"

@class ZingleContactSession;

@protocol ZNGContactServicesViewControllerDelegate <NSObject>

- (void)contactServicesViewControllerDidSelectContactService:(ZNGContactService *)contactService;

@end

@interface ZNGContactServicesViewController : UIViewController

@property (nonatomic, weak) id<ZNGContactServicesViewControllerDelegate> delegate;

@property (nonatomic, strong) NSArray<ZNGContactService *> * availableContactServices;

+ (instancetype)contactServicesViewController;

@end
