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
#import "ZNGPagedArray.h"

@interface ZNGInboxViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) ZNGPagedArray *pagedArray;
@property (strong, nonatomic) NSMutableDictionary *dataLoadingOperations;
//@property (nonatomic) BOOL loadingNextPage;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *contacts;
@property (strong, nonatomic) NSString *serviceId;
@property (strong, nonatomic) ZNGService *service;

@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

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

- (NSArray *)contacts {
    return (NSArray *)_pagedArray;
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
    
    [self refresh:nil];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    [ZNGServiceClient serviceWithId:self.serviceId success:^(ZNGService *service, ZNGStatus *status) {
        self.service = service;
        [ZNGContactClient contactListWithServiceId:self.serviceId parameters:nil success:^(NSArray *contacts, ZNGStatus *status) {
            
            self.pagedArray = [[ZNGPagedArray alloc] initWithCount:status.totalRecords objectsPerPage:status.pageSize];
            self.pagedArray.delegate = self;
            [self.pagedArray setObjects:contacts forPage:status.page];
            
            self.dataLoadingOperations = [NSMutableDictionary dictionary];
            
            self.tableView.hidden = NO;
            [self.activityIndicator removeFromSuperview];
            [self.activityIndicator stopAnimating];
            [self.tableView reloadData];
            [refreshControl endRefreshing];
        } failure:^(ZNGError *error) {
            [self.activityIndicator removeFromSuperview];
            [self.activityIndicator stopAnimating];
            [refreshControl endRefreshing];
        }];
    } failure:^(ZNGError *error) {
        [self.activityIndicator removeFromSuperview];
        [self.activityIndicator stopAnimating];
        [refreshControl endRefreshing];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.selectedIndexPath) {
        ZNGContact *contact = [[self contacts] objectAtIndex:self.selectedIndexPath.row];
        if ([contact.contactId isEqualToString:@"DELETED"]) {
            self.tableView.hidden = YES;
            self.activityIndicator = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallPulseSync tintColor:[UIColor colorFromHexString:@"#00a0de"] size:30.0f];
            ;
            self.activityIndicator.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width)/2 - 15, ([UIScreen mainScreen].bounds.size.height)/2 - 15, 30, 30);
            [self.view addSubview:self.activityIndicator];
            [self.activityIndicator startAnimating];
            [self refresh:nil];
        } else {
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }
    }
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self contacts] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContact *contact = [[self contacts] objectAtIndex:indexPath.row];
    ZNGTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGTableViewCell cellReuseIdentifier]];
    [cell configureCellWithContact:contact withServiceId:self.serviceId];
    [cell.labelCollectionView reloadData];
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPath = indexPath;
    
    ZNGContact *contact = [[self contacts] objectAtIndex:indexPath.row];
        
    ZNGConversationViewController *vc = [[ZingleSDK sharedSDK] conversationViewControllerToContact:contact service:self.service senderName:@"Me" receiverName:[contact fullName]];

    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - ZNGPagedArrayDelegate

- (void)pagedArray:(ZNGPagedArray *)pagedArray willAccessIndex:(NSUInteger)index returnObject:(__autoreleasing id *)returnObject {
    
    
    if ([*returnObject isKindOfClass:[NSNull class]]) {
        [self _setShouldLoadDataForPage:[pagedArray pageForIndex:index]];
    } else {
        [self _preloadNextPageIfNeededForIndex:index];
    }
}

#pragma mark - Private methods
- (void)_setShouldLoadDataForPage:(NSUInteger)page {
    
    if (!_pagedArray.pages[@(page)] && !_dataLoadingOperations[@(page)]) {
        // Don't load data if there already is a loading operation in progress
        [self _loadDataForPage:page];
    }
}

- (void)_loadDataForPage:(NSUInteger)page {
    
    _dataLoadingOperations[@(page)] = [NSString stringWithFormat: @"%ld", (long)page];;
    
    NSIndexSet *indexes = [_pagedArray indexSetForPage:page];
    
    NSDictionary *params = @{
                             @"page_size" : [NSNumber numberWithInteger: self.pagedArray.objectsPerPage],
                             @"page" : [NSNumber numberWithInteger: page]
                             };
    [ZNGContactClient contactListWithServiceId:self.serviceId parameters:params success:^(NSArray *contacts, ZNGStatus *status) {

        [_dataLoadingOperations removeObjectForKey:@(status.page)];
        [self.pagedArray setObjects:contacts forPage:status.page];
        
        NSMutableArray *indexPathsToReload = [NSMutableArray array];
        NSIndexSet *indexes = [self.pagedArray indexSetForPage:status.page];
        
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
                [indexPathsToReload addObject:indexPath];
            }
        }];
        
        if (indexPathsToReload.count > 0) {
            [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
        }
    } failure:^(ZNGError *error) {
        [_dataLoadingOperations removeObjectForKey:@(page)];
    }];
}

- (void)_preloadNextPageIfNeededForIndex:(NSUInteger)index {
    
    NSUInteger currentPage = [_pagedArray pageForIndex:index];
    NSUInteger preloadPage = [_pagedArray pageForIndex:index+5];
    
    if (preloadPage > currentPage && preloadPage <= _pagedArray.numberOfPages) {
        [self _setShouldLoadDataForPage:preloadPage];
    }
}

@end