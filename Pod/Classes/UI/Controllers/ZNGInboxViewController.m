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
#import "ZNGLogging.h"
#import "ZingleAccountSession.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGServiceToContactViewController.h"
#import "UIFont+Lato.h"
#import "JSQMessagesTimestampFormatter.h"
#import "ZNGAnalytics.h"
#import "ZNGLabelGridView.h"
#import "ZNGInboxDataSet.h"
#import "ZNGContactDataSetBuilder.h"

static int const zngLogLevel = ZNGLogLevelInfo;

static void * ZNGInboxKVOContext  =   &ZNGInboxKVOContext;
static NSString * const ZNGKVOContactsLoadingInitialDataPath   =   @"data.loadingInitialData";
static NSString * const ZNGKVOContactsLoadingPath   =   @"data.loading";
static NSString * const ZNGKVOContactsPath          =   @"data.contacts";

@interface ZNGInboxViewController ()

@end

@implementation ZNGInboxViewController
{
    UIRefreshControl * refreshControl;
    
    NSDateFormatter * dayOfWeekFormatter;
    NSDateFormatter * dateWithoutYearFormatter;
    NSDateFormatter * dateWithYearFormatter;
    NSDateFormatter * timeFormatter;
    
    NSTimer * refreshTimer;
    
    UIImage * unconfirmedImage;
    UIImage * unconfirmedLateImage;
    
    NSMutableDictionary<NSIndexPath *, NSTimer *> * refreshUnconfirmedTimers;
    NSTimer * cancelSwipesTimer;
    
    BOOL swipeActive;
    BOOL pendingReloadBlockedBySwipe;
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
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGInboxViewController class]];
    unconfirmedImage = [UIImage imageNamed:@"unconfirmedCircle" inBundle:bundle compatibleWithTraitCollection:nil];
    unconfirmedLateImage = [UIImage imageNamed:@"unconfirmedLateCircle" inBundle:bundle compatibleWithTraitCollection:nil];
    
    refreshUnconfirmedTimers = [[NSMutableDictionary alloc] init];
    
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

    if (self.title == nil) {
        self.title = @"Inbox";
    }
    
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
    
    // If we are in a narrow split view (one view at a time,) we will deselect when being presented.
    // Alternatively, on an iPad, we wish to retain our selection.
    if ([self.splitViewController.viewControllers count] == 1) {
        self.selectedContact = nil;
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startRefreshTimer];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [self stopRefreshTimer];
    [self cancelCancelSwipesTimer];
    [super viewDidDisappear:animated];
}

- (ZNGInboxDataSet *) initialDataSet
{
    return [ZNGInboxDataSet dataSetWithBlock:^(ZNGContactDataSetBuilder * _Nonnull builder) {
        builder.contactClient = self.session.contactClient;
    }];
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
    
    ZNGLogVerbose(@"Setting pendingReloadBlockedBySwipe and swipeActive to NO due to data change.");
    pendingReloadBlockedBySwipe = NO;
    swipeActive = NO;
    
    _data = data;
    [_data refresh];
    
    [[ZNGAnalytics sharedAnalytics] trackConversationFilterSwitch:data];
}

- (void) setSelectedContact:(ZNGContact *)selectedContact
{
    // This delay is to prevent us from trying to show the first contact before our table view has been refreshed.
    // Our KVO-triggered logic here is often hit before the logic to update the table view, causing a NSIndexPath out of bounds
    //  crash when attempting to select a row.
    // Seen as https://fabric.io/zingle/ios/apps/com.zingleme.zingle/issues/5877e6420aeb16625b0ae506 and
    //  https://fabric.io/zingle/ios/apps/com.zingleme.zingle/issues/583490700aeb16625b2a4c0d and
    //  http://jira.zinglecorp.com:8080/browse/MOBILE-496 and
    //  http://jira.zinglecorp.com:8080/browse/MOBILE-518
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
    });
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
    } else if ([keyPath isEqualToString:ZNGKVOContactsPath]) {
        [self handleContactsUpdateWithChangeDictionary:change];
    }
}

- (void) notifyContactSelfMutated:(NSNotification *)notification
{
    // We cannot use the normal KVO to detect this change since it occured in place within the object.
    
    if ([self.data.contacts containsObject:notification.object]) {
        [self reloadTableData];
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
            
            [self reloadTableData];
            break;
            
        case NSKeyValueChangeRemoval:
            ZNGLogVerbose(@"Removing %ld items", (unsigned long)[paths count]);
            
            if (([paths count] == 1) && (!pendingReloadBlockedBySwipe)) {
                [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
                [self retainSelection];
            } else {
                [self reloadTableData];
            }

            break;
            
        case NSKeyValueChangeReplacement:
        {
            ZNGLogVerbose(@"Replacing %ld items", (unsigned long)[paths count]);
            [self reloadTableData];

            break;
        }
            
        case NSKeyValueChangeSetting:
        default:
            ZNGLogVerbose(@"Reloading the table to new data with %llu items", (unsigned long long)[self.data.contacts count]);
            // For either an unknown change or a whole array replacement (which we do not expect with non-empty data,) blow away the table and reload it
            [self reloadTableData];
    }
}

/**
 *  Reloads the table data, recording swipe table cell offsets and current selection for restoration after reload
 */
- (void) reloadTableData
{
    if (!swipeActive) {
        [self.tableView reloadData];
        [self retainSelection];
    } else {
        ZNGLogDebug(@"Delaying refresh while some swiping is happening.");
        ZNGLogVerbose(@"Setting pendingReloadBlockedBySwipe to YES due to active swipe during a reload");
        pendingReloadBlockedBySwipe = YES;
    }
}

- (void) swipeTableCellWillBeginSwiping:(MGSwipeTableCell *)cell
{
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    ZNGLogVerbose(@"%@ swiping began (setting swipeActive to YES)", indexPath);
    
    [self resetCancelSwipesTimer];
    
    swipeActive = YES;
}

- (void) swipeTableCellWillEndSwiping:(MGSwipeTableCell *)cell
{
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    
    ZNGLogVerbose(@"%@ swiping ended (setting swipeActive to NO)", indexPath);
    swipeActive = NO;
    
    if (pendingReloadBlockedBySwipe) {
        ZNGLogVerbose(@"Clearing pendingReloadBlockedBySwipe to NO as we finally refresh the table after swipe-induced delay");
        pendingReloadBlockedBySwipe = NO;
        [self.tableView reloadData];
    }
}

- (BOOL) swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction fromPoint:(CGPoint)point
{
    // Prevent multiple rapid fire edits
    return (!swipeActive && !pendingReloadBlockedBySwipe);
}

- (void) cancelCancelSwipesTimer
{
    [cancelSwipesTimer invalidate];
    cancelSwipesTimer = nil;
}

- (void) resetCancelSwipesTimer
{
    // If the cell has had a swipe active for 10 seconds, cancel it.
    [self cancelCancelSwipesTimer];
    cancelSwipesTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(collapseAllSwipeGestures) userInfo:nil repeats:NO];
}

- (void) collapseAllSwipeGestures
{
    [self cancelCancelSwipesTimer];
    
    for (MGSwipeTableCell * cell in [self.tableView visibleCells]) {
        [cell hideSwipeAnimated:YES];
    }
    
    ZNGLogVerbose(@"Clearing swipeActive flag to NO while collapsing all swipe gestures");
    swipeActive = NO;
    
    if (pendingReloadBlockedBySwipe) {
        ZNGLogVerbose(@"... also clearing pendingReloadBlockedBySwipe to NO as we refresh while canceling all swipe gestures");
        pendingReloadBlockedBySwipe = NO;
        [self.tableView reloadData];
    }
}

- (void) retainSelection
{
    if (self.selectedContact != nil) {
        // This method call is being kicked off by KVO *just* before the data is actually in place for indexPathForContact to reflect reality.  This 0.0 delay "fixes" this.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSIndexPath * selectedContactIndexPath = [self indexPathForContact:self.selectedContact];
            
            if (selectedContactIndexPath != nil) {
                if (![[self.tableView indexPathForSelectedRow] isEqual:selectedContactIndexPath]) {
                    [self.tableView selectRowAtIndexPath:selectedContactIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            } else if (!self.data.loadingInitialData) {
                // Our selected contact is no longer in our data.  De-select it.
                self.selectedContact = nil;
            }
        });
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
    NSArray<NSIndexPath *> * visibleIndexPaths = [[self.tableView indexPathsForVisibleRows] sortedArrayUsingSelector:@selector(compare:)];
    
    if ([visibleIndexPaths count] > 0) {
        NSUInteger topVisibleIndex = [[visibleIndexPaths firstObject] row];
        NSUInteger page = topVisibleIndex / self.data.pageSize;
        
        if (page != 0) {
            // We have scrolled past the first page.  Refresh the current page without removing tail
            [self.data refreshStartingAtIndex:topVisibleIndex removingTail:NO];
            return;
        }
    }
    
    // Standard refresh from the top
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
    ZNGTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ZNGTableViewCell cellReuseIdentifier]];
    cell.delegate = self;
    
    NSTimer * timer = refreshUnconfirmedTimers[indexPath];
    [timer invalidate];
    [refreshUnconfirmedTimers removeObjectForKey:indexPath];
    
    if (contact != nil) {
        
        cell.contactName.text = [contact fullName];
        NSUInteger lastMessageAttachmentCount = [contact.lastMessage.attachments count];
        
        cell.closedShadingOverlay.hidden = !(contact.isClosed);
        
        if ([contact.lastMessage.body length] > 0) {
            cell.lastMessage.text = contact.lastMessage.body;
        } else if (lastMessageAttachmentCount > 0) {
            cell.lastMessage.text = [NSString stringWithFormat:@"%llu attachment%@", (unsigned long long)lastMessageAttachmentCount, (lastMessageAttachmentCount != 1) ? @"s" : @""];
        } else {
            cell.lastMessage.text = nil;
        }
        
        if (contact.isConfirmed) {
            cell.unconfirmedCircle.image = nil;
        } else {
            NSTimeInterval timeUntilLate = [[contact lateUnconfirmedTime] timeIntervalSinceNow];
            
            if (timeUntilLate <= 0.0) {
                // Already late
                cell.unconfirmedCircle.image = unconfirmedLateImage;
            } else {
                // Not late yet.  Show unconfirmed image and swap to unconfirmed late later.
                cell.unconfirmedCircle.image = unconfirmedImage;
                
                NSTimer * timer = [NSTimer scheduledTimerWithTimeInterval:timeUntilLate target:self selector:@selector(refreshIndexPathFromTimer:) userInfo:indexPath repeats:NO];
                refreshUnconfirmedTimers[indexPath] = timer;
            }
        }
        
        cell.labelGrid.labels = contact.labels;
        cell.labelGrid.font = [UIFont latoSemiBoldFontOfSize:9.0];
        cell.dateLabel.text = [self dateStringForContact:contact];
        
        [self configureLeftButtonsForCell:cell contact:contact];
        [self configureRightButtonsForCell:cell contact:contact];
    } else {
        cell.contactName.text = nil;
        cell.lastMessage.text = nil;
        cell.unconfirmedCircle.image = nil;
        cell.closedShadingOverlay.hidden = YES;
    }
    
    return cell;
}

/**
 *  Called when we suspect a contact will go from unconfirmed to unconfirmed late
 */
- (void) refreshIndexPathFromTimer:(NSTimer *)timer
{
    NSIndexPath * indexPath = timer.userInfo;
    
    if (![indexPath isKindOfClass:[NSIndexPath class]]) {
        ZNGLogError(@"Refresh inbox table cell timer was triggered with no index path data.  Ignoring.");
        return;
    }
    
    [refreshUnconfirmedTimers removeObjectForKey:indexPath];
    
    if ([self contactAtIndexPath:indexPath] != nil) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void) configureLeftButtonsForCell:(ZNGTableViewCell *)cell contact:(ZNGContact *)contact
{
    MGSwipeButton * confirmButton;
    ZNGContact * contactAfterChange = [contact copy];
    contactAfterChange.isConfirmed = !contactAfterChange.isConfirmed;
    BOOL changeWillCauseRemoval = ![self.data contactBelongsInDataSet:contactAfterChange];
    
    MGSwipeExpansionSettings * settings = [[MGSwipeExpansionSettings alloc] init];
    settings.buttonIndex = 0;
    settings.fillOnTrigger = changeWillCauseRemoval;
    settings.threshold = 1.4;
    
    __weak ZNGInboxViewController * weakSelf = self;
    
    if (contact.isConfirmed) {
        confirmButton = [MGSwipeButton buttonWithTitle:@"Unconfirm" backgroundColor:[UIColor zng_lightBlue] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            [weakSelf.data contactWasChangedLocally:contactAfterChange];
            
            [contact unconfirm];
            [[ZNGAnalytics sharedAnalytics] trackUnconfirmedContact:contact fromUIType:@"swipe"];
            [weakSelf clearSwipeActiveFlag];
            
            return !changeWillCauseRemoval;
        }];
    } else {
        confirmButton = [MGSwipeButton buttonWithTitle:@"Confirm" backgroundColor:[UIColor zng_lightBlue] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            [self.data contactWasChangedLocally:contactAfterChange];
            
            [contact confirm];
            [[ZNGAnalytics sharedAnalytics] trackConfirmedContact:contact fromUIType:@"swipe"];
            [weakSelf clearSwipeActiveFlag];

            return !changeWillCauseRemoval;
        }];
    }
    
    cell.leftButtons = @[confirmButton];
    cell.leftExpansion = settings;
}

- (void) configureRightButtonsForCell:(ZNGTableViewCell *)cell contact:(ZNGContact *)contact
{
    MGSwipeButton * closeButton;
    ZNGContact * contactAfterChange = [contact copy];
    contactAfterChange.isClosed = !contact.isClosed;
    contactAfterChange.isConfirmed = contactAfterChange.isClosed ? YES : contact.isConfirmed;   // Closing will also confirm
    BOOL changeWillCauseRemoval = ![self.data contactBelongsInDataSet:contactAfterChange];
    
    MGSwipeExpansionSettings * settings = [[MGSwipeExpansionSettings alloc] init];
    settings.buttonIndex = 0;
    settings.fillOnTrigger = changeWillCauseRemoval;
    settings.threshold = 2.0;
    
    __weak ZNGInboxViewController * weakSelf = self;
    
    if (contact.isClosed) {
        closeButton = [MGSwipeButton buttonWithTitle:@"Open" backgroundColor:[UIColor zng_green] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            [weakSelf.data contactWasChangedLocally:contactAfterChange];
            
            [contact reopen];
            [[ZNGAnalytics sharedAnalytics] trackOpenedContact:contact fromUIType:@"swipe"];
            [weakSelf clearSwipeActiveFlag];

            return !changeWillCauseRemoval;
        }];
    } else {
        closeButton = [MGSwipeButton buttonWithTitle:@"Close" backgroundColor:[UIColor zng_strawberry] callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
            [weakSelf.data contactWasChangedLocally:contactAfterChange];
            
            [contact close];
            [[ZNGAnalytics sharedAnalytics] trackClosedContact:contact fromUIType:@"swipe"];
            [weakSelf clearSwipeActiveFlag];
            
            return !changeWillCauseRemoval;
        }];
    }
    
    cell.rightButtons = @[closeButton];
    cell.rightExpansion = settings;
}

/**
 *  Used so the button actions above can clear the flag without requiring a strong reference
 */
- (void) clearSwipeActiveFlag
{
    swipeActive = NO;
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
        conversation.channel = [conversation defaultChannelForContact];
        
        ZNGConversationViewController * vc = [self.session conversationViewControllerForConversation:conversation];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
