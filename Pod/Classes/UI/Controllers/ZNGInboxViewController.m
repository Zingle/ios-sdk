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
#import "ZNGInboxDataFilters.h"
#import "ZNGLogging.h"
#import "ZingleAccountSession.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGServiceToContactViewController.h"
#import "UIFont+Lato.h"
#import "JSQMessagesTimestampFormatter.h"
#import "ZNGAnalytics.h"
#import "ZingleSDK/ZingleSDK-Swift.h"

static int const zngLogLevel = ZNGLogLevelInfo;

static void * ZNGInboxKVOContext  =   &ZNGInboxKVOContext;
static NSString * const ZNGKVOContactsLoadingInitialDataPath   =   @"data.loadingInitialData";
static NSString * const ZNGKVOContactsLoadingPath   =   @"data.loading";
static NSString * const ZNGKVOContactsPath          =   @"data.contacts";

@interface ZNGInboxViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation ZNGInboxViewController
{
    UIRefreshControl * refreshControl;
    
    NSDateFormatter * dayOfWeekFormatter;
    NSDateFormatter * dateWithoutYearFormatter;
    NSDateFormatter * dateWithYearFormatter;
    NSDateFormatter * timeFormatter;
    
    NSTimer * refreshTimer;
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
    [self addObserver:self forKeyPath:ZNGKVOContactsLoadingInitialDataPath options:NSKeyValueObservingOptionNew context:ZNGInboxKVOContext];
    [self addObserver:self forKeyPath:ZNGKVOContactsLoadingPath options:NSKeyValueObservingOptionNew context:ZNGInboxKVOContext];
    [self addObserver:self forKeyPath:ZNGKVOContactsPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:ZNGInboxKVOContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyContactSelfMutated:) name:ZNGContactNotificationSelfMutated object:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self removeObserver:self forKeyPath:ZNGKVOContactsPath context:ZNGInboxKVOContext];
    [self removeObserver:self forKeyPath:ZNGKVOContactsLoadingPath context:ZNGInboxKVOContext];
    [self removeObserver:self forKeyPath:ZNGKVOContactsLoadingInitialDataPath context:ZNGInboxKVOContext];
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
    
    refreshControl = [self configuredRefreshControl];
    [self.tableView addSubview:refreshControl];
    
    // Creating view for extending background color
    CGRect frame = self.tableView.bounds;
    frame.origin.y = -frame.size.height;
    UIView* bgView = [[UIView alloc] initWithFrame:frame];
    bgView.backgroundColor = [UIColor whiteColor];
    
    // Adding the view below the refresh control
    [self.tableView insertSubview:bgView atIndex:0];
    
    // Time/date formatting
    timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateStyle = NSDateFormatterNoStyle;
    timeFormatter.timeStyle = NSDateFormatterShortStyle;
    dayOfWeekFormatter = [[NSDateFormatter alloc] init];
    dayOfWeekFormatter.dateFormat = @"EEEE";
    dateWithYearFormatter = [[NSDateFormatter alloc] init];
    dateWithYearFormatter.dateFormat = @"MMM d, y";
    dateWithoutYearFormatter = [[NSDateFormatter alloc] init];
    dateWithoutYearFormatter.dateFormat = @"MMM d";

    
    self.title = @"Inbox";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 118.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[ZNGTableViewCell nib] forCellReuseIdentifier:[ZNGTableViewCell cellReuseIdentifier]];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self showActivityIndicator];
}

- (nonnull UIRefreshControl *) configuredRefreshControl
{
    UIRefreshControl * refresher = [[UIRefreshControl alloc] init];
    refresher.backgroundColor = [UIColor whiteColor];
    refresher.tintColor = [UIColor zng_lightBlue];
    [refresher addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    return refresher;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.data == nil) {
        self.data = [self initialDataSet];
    }
    
    self.selectedContact = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startRefreshTimer];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [self stopRefreshTimer];
    [super viewDidDisappear:animated];
}

- (ZNGInboxDataSet *) initialDataSet
{
    return [[ZNGInboxDataOpen alloc] initWithContactClient:self.session.contactClient];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    NSIndexPath * selectedContactIndexPath = [self.tableView indexPathForSelectedRow];
    
    if (selectedContactIndexPath != nil) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self.tableView scrollToRowAtIndexPath:selectedContactIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        } completion:nil];
    }
}

- (void) startRefreshTimer
{
    [refreshTimer invalidate];
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(_doRefresh) userInfo:nil repeats:YES];
}

- (void) stopRefreshTimer
{
    [refreshTimer invalidate];
    refreshTimer = nil;
}

#pragma mark - Setters
- (void) setData:(ZNGInboxDataSet *)data
{
    if ([data isEqual:self.data]) {
        ZNGLogInfo(@"Neglecting to replace current %@ with %@ due to equality.", [self.data class], [data class]);
        return;
    }
    
    ZNGLogDebug(@"Inbox data changed from %@ to %@", _data, data);
    
    _data = data;
    [_data refresh];
    
    [[ZNGAnalytics sharedAnalytics] trackConversationFilterSwitch:data];
}

- (void) setSelectedContact:(ZNGContact *)selectedContact
{
    _selectedContact = selectedContact;
    NSIndexPath * newSelection = [self indexPathForContact:selectedContact];
    NSIndexPath * oldSelection = [self.tableView indexPathForSelectedRow];
    
    if ([newSelection isEqual:oldSelection]) {
        [self.tableView scrollToRowAtIndexPath:newSelection atScrollPosition:UITableViewScrollPositionNone animated:NO];
        return;
    }
    
    if (oldSelection != nil) {
        [self.tableView deselectRowAtIndexPath:oldSelection animated:NO];
    }
    
    if (newSelection != nil) {
        // As per UIKit documentation for selectRowAtIndexPath:animated:scrollPosition:, calling select row with None for scroll position
        //  followed by scrollToRowAtIndexPath... with None for scroll position will do the minimum amount of scrolling to put the selected row on screen.
        [self.tableView selectRowAtIndexPath:newSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.tableView scrollToRowAtIndexPath:newSelection atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}

#pragma mark - Key Value Observing
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context != ZNGInboxKVOContext) {
        return;
    }
    
    if ([keyPath isEqualToString:ZNGKVOContactsLoadingPath]) {
        // This check for isRefreshing seems redundant, but calling endRefreshing while the refreshControl is not refreshing causes the scroll view to stop.
        // See: http://stackoverflow.com/questions/20549475/uitableview-insertrows-without-locking-main-thread
        if ((!self.data.loading) && (refreshControl.isRefreshing)) {
            [refreshControl endRefreshing];
        }
    } else if ([keyPath isEqualToString:ZNGKVOContactsLoadingInitialDataPath]) {
        if (self.data.loadingInitialData) {
            self.tableView.hidden = YES;
            [self showActivityIndicator];
        } else {
            // We just finished loading
            [self hideActivityIndicator];
            self.tableView.hidden = NO;
        }
    } else if ([keyPath isEqualToString:ZNGKVOContactsPath]) {
        [self handleContactsUpdateWithChangeDictionary:change];
    }
}

- (void) notifyContactSelfMutated:(NSNotification *)notification
{
    // We cannot use the normal KVO to detect this change since it occured in place within the object.
    
    if ([self.data.contacts containsObject:notification.object]) {
        [self.tableView reloadData];
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
            [self.tableView reloadData];
            break;
            
        case NSKeyValueChangeRemoval:
            ZNGLogVerbose(@"Removing %ld items", (unsigned long)[paths count]);
            [self.tableView reloadData];

            break;
            
        case NSKeyValueChangeReplacement:
        {
            ZNGLogVerbose(@"Replacing %ld items", (unsigned long)[paths count]);
            [self.tableView reloadData];

            break;
        }
            
        case NSKeyValueChangeSetting:
        default:
            ZNGLogVerbose(@"Reloading the table to new data with %llu items", (unsigned long long)[self.data.contacts count]);
            // For either an unknown change or a whole array replacement (which we do not expect with non-empty data,) blow away the table and reload it
            [self.tableView reloadData];
    }
    
    // Ensure that we retain our selection visually
    if (self.selectedContact != nil) {
        NSIndexPath * selectedContactIndexPath = [self indexPathForContact:self.selectedContact];
        
        if ((selectedContactIndexPath != nil) && (![[self.tableView indexPathForSelectedRow] isEqual:selectedContactIndexPath])) {
            [self.tableView selectRowAtIndexPath:selectedContactIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

#pragma mark - Data Handling
- (void)refresh {
    self.tableView.hidden = YES;
    [self showActivityIndicator];
    [self refresh:nil];
}

- (void) _doRefresh
{
    [self.data refresh];
}

- (void)refresh:(UIRefreshControl *)aRefreshControl {
    [self _doRefresh];
}

- (void)showActivityIndicator
{
    // Empty, abstract implementation
}

- (void)hideActivityIndicator
{
    // Empty, abstract implementation
}

#pragma mark - UITableViewDataSource

- (ZNGContact *) contactAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row < [self.data.contacts count]) ? self.data.contacts[indexPath.row] : nil;
}

- (NSIndexPath *) indexPathForContact:(ZNGContact *)contact
{
    if (contact == nil) {
        return nil;
    }
    
    NSUInteger index = [self.data.contacts indexOfObject:contact];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    return [NSIndexPath indexPathForRow:index inSection:0];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.data.contacts count];
}

- (NSDateFormatter *) dateFormatterForContact:(ZNGContact *)contact
{
    NSCalendar * calendar = [NSCalendar currentCalendar];
    NSDate * now = [NSDate date];
    NSDate * messageTime = contact.lastMessage.createdAt ?: now;
    NSTimeInterval deltaTime = [now timeIntervalSinceDate:messageTime];
    
    NSCalendarUnit dayAndYear = NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitYear;
    NSDateComponents * nowComponents = [calendar components:dayAndYear fromDate:now];
    NSDateComponents * messageTimeComponents = [calendar components:dayAndYear fromDate:messageTime];
    
    NSTimeInterval oneDay = 24.0 * 60.0 * 60.0;
    NSTimeInterval oneWeek = oneDay * 7.0;
    
    if ((deltaTime < oneDay) && (nowComponents.day == messageTimeComponents.day)) {
        // This message was on this same calendar day
        return timeFormatter;
    } else if ((deltaTime < oneWeek) && (nowComponents.weekday != messageTimeComponents.weekday)) {
        // This message was within the past seven days but on a different day of the week (so we can unambiguously say "Sunday," etc.)
        return dayOfWeekFormatter;
    } else if (nowComponents.year == messageTimeComponents.year) {
        // It was more than a week ago within the same year
        return dateWithoutYearFormatter;
    }
    
    // This was a long time ago, son
    return dateWithYearFormatter;
}

- (NSString *) dateStringForContact:(ZNGContact *)contact
{
    NSDate * timestamp = contact.lastMessage.createdAt;
    
    if (timestamp == nil) {
        return nil;
    }
    
    return [[self dateFormatterForContact:contact] stringFromDate:timestamp];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContact * contact = [self contactAtIndexPath:indexPath];
    
    if (contact != nil) {
        ZNGTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGTableViewCell cellReuseIdentifier]];
        cell.labelGrid.font = [UIFont latoSemiBoldFontOfSize:9.0];
        [cell configureCellWithContact:contact withServiceId:self.session.service.serviceId];
        cell.dateLabel.text = [self dateStringForContact:contact];
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
        [self.data refreshStartingAtIndex:indexPath.row + 10 removingTail:YES];
    }
}

- (BOOL) shouldRequestNewDataAfterViewingIndexPath:(NSIndexPath *)indexPath
{
    // This method could be tweaked to take velocity into account.  For now we will just grab more data if we are within 10 items from the bottom of our current data.
    BOOL nearBottom = (indexPath.row > ([self.data.contacts count] - 10));
    BOOL moreDataAvailable = ([self.data.contacts count] < self.data.count);
    
    return (nearBottom && moreDataAvailable);
}

- (BOOL) _shouldShowConversation:(ZNGConversation *)conversation
{
    if (conversation == nil) {
        ZNGLogWarn(@"Selected conversation is nil.  Neglecting to ask delegate nor to display the conversation view.");
        return NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(inbox:shouldPresentConversation:)]) {
        return [self.delegate inbox:self shouldPresentConversation:conversation];
    }
    
    // Our delegate doesn't care or doesn't exist.  Let's do it.
    return YES;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContact *contact = [self contactAtIndexPath:indexPath];
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(selectedContact))];
    _selectedContact = contact;
    [self didChangeValueForKey:NSStringFromSelector(@selector(selectedContact))];
    
    if (contact == nil) {
        return;
    }
    
    ZNGConversationServiceToContact * conversation = [self.session conversationWithContact:contact];
    
    if ([self _shouldShowConversation:conversation]) {
        ZNGConversationViewController * vc = [self.session conversationViewControllerForConversation:conversation];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end