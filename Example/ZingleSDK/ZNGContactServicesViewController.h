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
@property (nonatomic, strong) ZingleContactSession * session;

@property (nonatomic, strong) NSString *channelValue;
@property (nonatomic, strong) NSString *channelTypeId;
@property (strong, nonatomic) NSString *serviceId;

+ (instancetype)contactServicesViewController;
+ (instancetype)withSession:(ZingleContactSession *)aSession;

@end
