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
#import "ZNGInboxDataFilters.h"

static void * ZNGInboxKVOContext  =   &ZNGInboxKVOContext;
static NSString * const ZNGKVOContactsLoadingPath   =   @"data.loadingInitialdata";
static NSString * const ZNGKVOContactsPath          =   @"data.contacts";

@interface ZNGInboxViewController () <UITableViewDataSource, UITableViewDelegate, ZNGPagedArrayDelegate>

@property (strong, nonatomic) ZNGPagedArray *pagedArray;
@property (strong, nonatomic) NSMutableDictionary *dataLoadingOperations;
@property (strong, nonatomic) DGActivityIndicatorView *activityIndicator;

@end

@implementation ZNGInboxViewController
{
    UIRefreshControl * refreshControl;
}

#pragma mark - Life cycle

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

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (void) commonInit
{
    [self addObserver:self forKeyPath:ZNGKVOContactsLoadingPath options:NSKeyValueObservingOptionNew context:ZNGInboxKVOContext];
    [self addObserver:self forKeyPath:ZNGKVOContactsPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:ZNGInboxKVOContext];
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:ZNGKVOContactsPath context:ZNGInboxKVOContext];
    [self removeObserver:self forKeyPath:ZNGKVOContactsLoadingPath context:ZNGInboxKVOContext];
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
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl setBackgroundColor:[UIColor whiteColor]];
    [refreshControl setTintColor:[UIColor zng_lightBlue]];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    // Creating view for extending background color
    CGRect frame = self.tableView.bounds;
    frame.origin.y = -frame.size.height;
    UIView* bgView = [[UIView alloc] initWithFrame:frame];
    bgView.backgroundColor = [UIColor whiteColor];
    
    // Adding the view below the refresh control
    [self.tableView insertSubview:bgView atIndex:0];
    
    self.title = @"Inbox";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 118.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[ZNGTableViewCell nib] forCellReuseIdentifier:[ZNGTableViewCell cellReuseIdentifier]];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self refresh];
}

#pragma mark - Key Value Observing
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context != ZNGInboxKVOContext) {
        return;
    }
    
    if ([keyPath isEqualToString:ZNGKVOContactsLoadingPath]) {
        if (self.data.loadingInitialData) {
            // Our data is loading
            
        } else {
            // Our data has either finished loading, or our data provider has disapeared.
        }
    } else if ([keyPath isEqualToString:ZNGKVOContactsPath]) {
        [self handleContactsUpdateWithChangeDictionary:change];
    }
}

- (void) handleContactsUpdateWithChangeDictionary:(NSDictionary<NSString *, id> *)change
{
    int changeType = [change[NSKeyValueChangeKindKey] intValue];
    NSIndexSet * changeIndexes = change[NSKeyValueChangeIndexesKey];
    NSMutableArray<NSIndexPath *> * paths = [[NSMutableArray alloc] initWithCapacity:[changeIndexes count]];
    [changeIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [paths addObject:[NSIndexPath indexPathWithIndex:idx]];
    }];
    
    switch (changeType)
    {
        case NSKeyValueChangeInsertion:
            [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSKeyValueChangeRemoval:
            [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSKeyValueChangeReplacement:
            [self.tableView reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSKeyValueChangeSetting:
        default:
            // For either an unknown change or a whole array replacement (which we do not expect with non-empty data,) blow away the table and reload it
            [self.tableView reloadData];
    }
}

#pragma mark - Data Handling
- (void)refresh {
    self.tableView.hidden = YES;
    [self showActivityIndicator];
    [self refresh:nil];
}

- (void)refresh:(UIRefreshControl *)aRefreshControl {
    [ZNGServiceClient serviceWithId:self.serviceId success:^(ZNGService *service, ZNGStatus *status) {
        self.service = service;
        
        NSMutableDictionary *combinedParams = [[NSMutableDictionary alloc] initWithDictionary:self.currentFilterParams copyItems:YES];
        [combinedParams setObject:@"last_message_created_at" forKey:@"sort_field"];
        [combinedParams setObject:@"desc" forKey:@"sort_direction"];
        [combinedParams setObject:@"greater_than(0)" forKey:@"last_message_created_at"];
        
        [ZNGContactClient contactListWithServiceId:self.serviceId parameters:combinedParams success:^(NSArray *contacts, ZNGStatus *status) {
            
            self.pagedArray = [[ZNGPagedArray alloc] initWithCount:status.totalRecords objectsPerPage:status.pageSize];
            self.pagedArray.delegate = self;
            if ([contacts count] > 0) {
                [self.pagedArray setObjects:contacts forPage:status.page];
            }
            
            self.dataLoadingOperations = [NSMutableDictionary dictionary];
            
            self.tableView.hidden = NO;
            [self hideActivityIndicator];
            [self.tableView reloadData];
            [refreshControl endRefreshing];
            
        } failure:^(ZNGError *error) {
            [self hideActivityIndicator];
            [refreshControl endRefreshing];
        }];
    } failure:^(ZNGError *error) {
        [self hideActivityIndicator];
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
            [self refresh];
        } else {
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }
    }
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[ZingleSDK sharedSDK] clearCachedConversations];
}

- (void)showActivityIndicator
{
    [self.activityIndicator stopAnimating];
    self.activityIndicator = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallPulseSync tintColor:[UIColor zng_lightBlue] size:30.0f];
    self.activityIndicator.frame = CGRectMake((self.navigationController.navigationBar.bounds.size.width)/2 - 15, (self.view.bounds.size.height)/2 - 15, 30, 30);
    [self.view addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
}

- (void)hideActivityIndicator
{
    self.activityIndicator.hidden = YES;
    [self.activityIndicator removeFromSuperview];
    [self.activityIndicator stopAnimating];
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

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContact *contact = [[self contacts] objectAtIndex:indexPath.row];
    if (![contact isKindOfClass:[NSNull class]]) {
        if (contact.labels.count > 4) {
            return 113;
        }
        if (contact.labels.count > 0) {
            return 87;
        }
    }
    return 71;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPath = indexPath;
    
    ZNGContact *contact = [[self contacts] objectAtIndex:indexPath.row];
    
    if ([contact isKindOfClass:[NSNull class]]) {
        return;
    }
    
    ZNGConversationViewController *vc = [[ZingleSDK sharedSDK] conversationViewControllerToContact:contact service:self.service senderName:@"Me" receiverName:[contact fullName]];
    vc.detailDelegate = self;
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


#pragma mark - ZNGConversationViewControllerDelegate

- (void)didUpdateContact
{
    [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end