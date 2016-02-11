//
//  ZNGConversationViewController.m
//  Pods
//
//  Created by Ryan Farley on 2/11/16.
//
//

#import "ZNGConversationViewController.h"
#import "ZNGMessageEntryView.h"

@interface ZNGConversationViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, MessageEntryDelegate, UIScrollViewDelegate>

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

@end

@implementation ZNGConversationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
