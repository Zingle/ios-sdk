//
//  ZNGConversationViewController.m
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import "ZNGConversationViewController.h"
#import "ZNGMessageEntryView.h"
#import "ZNGContactClient.h"
#import "ZNGMessageClient.h"
#import "ZNGErrorLabel.h"

@interface ZNGConversationViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, MessageEntryDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet ZNGErrorLabel *oErrorLabel;
@property (weak, nonatomic) IBOutlet UIView *oMessageEntryOutterview;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oMessageEntryHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oMessageEntryMaxHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oMessageEntryMinimumHeight;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *oInitialLoadActivityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *oTableView;

@property (weak, nonatomic) IBOutlet ZNGMessageEntryView *oMessageEntryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *oBottomLayoutGuideConstraint;

@property (weak, nonatomic) IBOutlet UIView *oTitleView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *oSendingActivityIndicator;
- (IBAction)didTouchSendMessageButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *oSendButton;
@property (weak, nonatomic) IBOutlet UILabel *oTitleLabel;


@property (nonatomic, strong) NSString *serviceId;
@property (nonatomic, strong) NSString *channelTypeName;
@property (nonatomic, strong) NSString *channelValue;
@property (nonatomic, strong) NSArray *messageList;

@end

@implementation ZNGConversationViewController


- (id)initWithServiceId:(NSString *)serviceId
    withChannelTypeName:(NSString *)channelTypeName
       fromChannelValue:(NSString *)channelValue
{
    self = [super init];
    
    if (self) {
        _serviceId = serviceId;
        _channelTypeName = channelTypeName;
        _channelValue = channelValue;
    }
    
    return self;
}

- (id)initWithServiceId:(NSString *)serviceId
       fromChannelValue:(NSString *)channelValue
{
    NSBundle *bundle = [NSBundle bundleForClass:ZingleSDK.class];
    self = (ZNGConversationViewController *)[[UIStoryboard storyboardWithName:@"Zingle" bundle:bundle] instantiateInitialViewController];
    
    if (self) {
        _serviceId = serviceId;
        _channelValue = channelValue;
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *params = @{
                             @"contact_channel_id" : self.channelValue
                             };
    
    [ZNGContactClient contactListWithServiceId:self.serviceId parameters:params success:^(NSArray *contacts) {
        
        [ZNGMessageClient messageListWithParameters:nil withServiceId:self.serviceId success:^(NSArray *messages) {
            
            self.messageList = messages;
        } failure:^(ZNGError *error) {
            
            NSLog(@"THERE'S BEEN AN ERROR!");
        }];
        
    } failure:^(ZNGError *error) {
        
        NSLog(@"THERE'S BEEN AN ERROR!");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
