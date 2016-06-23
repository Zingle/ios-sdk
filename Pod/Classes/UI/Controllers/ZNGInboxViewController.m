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
#import "ZNGInboxDataFilters.h"
#import "ZNGLogging.h"
#import "ZingleAccountSession.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGConversationServiceToContact.h"

static int const zngLogLevel = ZNGLogLevelInfo;

static void * ZNGInboxKVOContext  =   &ZNGInboxKVOContext;
static NSString * const ZNGKVOContactsLoadingPath   =   @"data.loadingInitialData";
static NSString * const ZNGKVOContactsPath          =   @"data.contacts";

@interface ZNGInboxViewController () <UITableViewDataSource, UITableViewDelegate>

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

+ (instancetype) withSession:(ZingleAccountSession *)session
{
    ZNGInboxViewController * vc = [[ZNGInboxViewController alloc] init];
    vc.session = session;
    return vc;
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
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(data)) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:ZNGInboxKVOContext];
    [self addObserver:self forKeyPath:ZNGKVOContactsLoadingPath options:NSKeyValueObservingOptionNew context:ZNGInboxKVOContext];
    [self addObserver:self forKeyPath:ZNGKVOContactsPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:ZNGInboxKVOContext];
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:ZNGKVOContactsPath context:ZNGInboxKVOContext];
    [self removeObserver:self forKeyPath:ZNGKVOContactsLoadingPath context:ZNGInboxKVOContext];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(data)) context:ZNGInboxKVOContext];
}

+ (instancetype)withAccountSession:(ZingleAccountSession *)aSession
{
    ZNGInboxViewController *vc = (ZNGInboxViewController *)[ZNGInboxViewController inboxViewController];
    
    if (vc) {
        vc.session = aSession;
    }
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.hidden = YES;
    
    self.activityIndicator = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallPulseSync tintColor:[UIColor zng_lightBlue] size:30.0f];
    self.activityIndicator.frame = CGRectMake((self.navigationController.navigationBar.bounds.size.width)/2 - 15, (self.view.bounds.size.height)/2 - 15, 30, 30);
    [self.view addSubview:self.activityIndicator];
    
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
    
    [self showActivityIndicator];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.data == nil) {
        self.data = [[ZNGInboxDataSet alloc] initWithContactClient:self.session.contactClient];
    }
}

#pragma mark - Key Value Observing
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context != ZNGInboxKVOContext) {
        return;
    }
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(data))]) {
        ZNGInboxDataSet * oldData = change[NSKeyValueChangeOldKey];
        
        if (![self.data isEqual:oldData]) {
            // This is a new filtering type
            self.tableView.hidden = YES;
            [self showActivityIndicator];
        }
    } else if ([keyPath isEqualToString:ZNGKVOContactsLoadingPath]) {
        if (!self.data.loadingInitialData) {
            // We just finished loading
            [self hideActivityIndicator];
            self.tableView.hidden = NO;
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
        [paths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    
    // This check for isRefreshing seems redundant, but calling endRefreshing while the refreshControl is not refreshing causes the scroll view to stop.
    // See: http://stackoverflow.com/questions/20549475/uitableview-insertrows-without-locking-main-thread
    if (refreshControl.isRefreshing) {
        [refreshControl endRefreshing];
    }
    
    switch (changeType)
    {
        case NSKeyValueChangeInsertion:
            ZNGLogVerbose(@"Inserting %ld items", (unsigned long)[paths count]);
            [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSKeyValueChangeRemoval:
            ZNGLogVerbose(@"Removing %ld items", (unsigned long)[paths count]);
            [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSKeyValueChangeReplacement:
            ZNGLogVerbose(@"Replacing %ld items", (unsigned long)[paths count]);
            // TODO: Check for messages that have swapped locations and use move instead of reload on those rows
            [self.tableView reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSKeyValueChangeSetting:
        default:
            ZNGLogVerbose(@"Reloading the table");
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
    [self.data refresh];
}

- (void)showActivityIndicator
{
    [self.activityIndicator startAnimating];
    self.activityIndicator.hidden = NO;
}

- (void)hideActivityIndicator
{
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
}

#pragma mark - UITableViewDataSource

- (ZNGContact *) contactAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row < [self.data.contacts count]) ? self.data.contacts[indexPath.row] : nil;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.data.contacts count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContact * contact = [self contactAtIndexPath:indexPath];
    
    if (contact != nil) {
        ZNGTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGTableViewCell cellReuseIdentifier]];
        cell.session = self.session;
        [cell configureCellWithContact:contact withServiceId:self.session.service.serviceId];
        [cell.labelCollectionView reloadData];
        
        return cell;
    }
    
    ZNGLogError(@"Unable to load data for contact at index %ld.", (unsigned long)indexPath.row);
    return nil;
}

#pragma mark - UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContact *contact = [self contactAtIndexPath:indexPath];
    
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

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((!self.data.loading) && [self shouldRequestNewDataAfterViewingIndexPath:indexPath]) {
        [self.data refreshStartingAtIndex:indexPath.row + 10];
    }
}

- (BOOL) shouldRequestNewDataAfterViewingIndexPath:(NSIndexPath *)indexPath
{
    // This method could be tweaked to take velocity into account.  For now we will just grab more data if we are within 10 items from the bottom of our current data.
    BOOL nearBottom = (indexPath.row > ([self.data.contacts count] - 10));
    BOOL moreDataAvailable = ([self.data.contacts count] < self.data.count);
    
    return (nearBottom && moreDataAvailable);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPath = indexPath;
    
    ZNGContact *contact = [self contactAtIndexPath:indexPath];
    
    if (contact == nil) {
        return;
    }
    
    ZNGConversationServiceToContact * conversation = [self.session conversationWithContact:contact];
    ZNGConversationViewController * vc = [self.session conversationViewControllerForConversation:conversation];
    
    vc.detailDelegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - ZNGConversationViewControllerDelegate

- (void)didUpdateContact
{
    [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end