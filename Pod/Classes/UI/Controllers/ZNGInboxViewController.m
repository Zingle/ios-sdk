//
//  ZNGInboxViewController.m
//  Pods
//
//  Created by Ryan Farley on 3/14/16.
//
//

#import "ZNGInboxViewController.h"
#import "ZNGContact.h"
#import "ZNGContactClient.h"
#import "ZNGServiceClient.h"
#import "ZNGTableViewCell.h"
#import "DGActivityIndicatorView.h"

@interface ZNGInboxViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *contacts;
@property (strong, nonatomic) NSString *serviceId;
@property (strong, nonatomic) ZNGService *service;

@property (strong, nonatomic) DGActivityIndicatorView *activityIndicator;

@end

@implementation ZNGInboxViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([ZNGInboxViewController class])
                          bundle:[NSBundle bundleForClass:[ZNGInboxViewController class]]];
}

+ (instancetype)inboxViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([ZNGInboxViewController class])
                                          bundle:[NSBundle bundleForClass:[ZNGInboxViewController class]]];
}

+ (instancetype)withServiceId:(NSString *)serviceId
{
    ZNGInboxViewController *vc = (ZNGInboxViewController *)[ZNGInboxViewController inboxViewController];
    
    if (vc) {
        vc.serviceId = serviceId;
    }
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.hidden = YES;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    self.activityIndicator = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallPulseSync tintColor:[UIColor colorFromHexString:@"#00a0de"] size:30.0f];
    ;
    self.activityIndicator.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width)/2 - 15, ([UIScreen mainScreen].bounds.size.height)/2 - 15, 30, 30);
    [self.view addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
    
    self.title = @"Inbox";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 118.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[ZNGTableViewCell nib] forCellReuseIdentifier:[ZNGTableViewCell cellReuseIdentifier]];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [ZNGServiceClient serviceWithId:self.serviceId success:^(ZNGService *service, ZNGStatus *status) {
        self.service = service;
        [ZNGContactClient contactListWithServiceId:self.serviceId parameters:nil success:^(NSArray *contacts, ZNGStatus *status) {
            
            self.contacts = contacts;
            self.tableView.hidden = NO;
            [self.activityIndicator removeFromSuperview];
            [self.activityIndicator stopAnimating];
            [self.tableView reloadData];
            [refreshControl endRefreshing];
        } failure:^(ZNGError *error) {
            [refreshControl endRefreshing];
        }];
    } failure:^(ZNGError *error) {
        [refreshControl endRefreshing];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self refresh:nil];
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.contacts count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContact *contact = [self.contacts objectAtIndex:indexPath.row];
    ZNGTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGTableViewCell cellReuseIdentifier]];
    [cell configureCellWithContact:contact withServiceId:self.serviceId];
    [cell.labelCollectionView reloadData];
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContact *contact = [self.contacts objectAtIndex:indexPath.row];
        
    ZNGConversationViewController *vc = [[ZingleSDK sharedSDK] conversationViewControllerToContact:contact service:self.service senderName:@"Me" receiverName:[contact fullName]];

    [self.navigationController pushViewController:vc animated:YES];
}

@end