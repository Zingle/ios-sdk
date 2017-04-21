//
//  ZNGConversationViewController.m
//  Pods
//
//  Created by Jason Neel on 6/20/16.
//
//

#import "ZNGConversationViewController.h"
#import "ZNGConversation.h"
#import "ZNGEvent.h"
#import "UIColor+ZingleSDK.h"
#import "JSQMessagesBubbleImage.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesTimestampFormatter.h"
#import "ZNGLogging.h"
#import "ZNGImageViewController.h"
#import "UIImage+ZingleSDK.h"
#import "ZNGEventCollectionViewCell.h"
#import "UIFont+Lato.h"
#import "JSQMessagesLoadEarlierHeaderView.h"
#import "ZNGConversationTimestampFormatter.h"
#import "ZNGAnalytics.h"
#import "ZNGGradientLoadingView.h"
#import "ZNGImageAttachment.h"
#import "ZNGConversationCellOutgoing.h"
#import "ZNGConversationCellIncoming.h"
#import "ZNGEventViewModel.h"
#import "UIImage+animatedGIF.h"
@import Photos;


static const int zngLogLevel = ZNGLogLevelDebug;

// How directly does the left panning gesture translate to speed of the time labels appearing on screen?
// 1.0 is an exact match
// The iOS 10 messages app appears to use something around 0.4
static const CGFloat timeLabelPanSpeed = 0.4;

static NSString * const EventCellIdentifier = @"EventCell";

// We will use a more aggressive polling interval when testing on a simulator (that cannot support push notifications)
#if TARGET_IPHONE_SIMULATOR
static const uint64_t PollingIntervalSeconds = 10;
#else
static const uint64_t PollingIntervalSeconds = 30;
#endif

static NSString * const EventsKVOPath = @"conversation.eventViewModels";
static NSString * const LoadingKVOPath = @"conversation.loading";
static void * ZNGConversationKVOContext  =   &ZNGConversationKVOContext;

@interface JSQMessagesViewController ()

// Public declaration of private inset updating methods.  Barf.
- (void)jsq_updateCollectionViewInsets;
- (void)jsq_setCollectionViewInsetsTopValue:(CGFloat)top bottomValue:(CGFloat)bottom;

// Public declarations of methods required by our input toolbar delegate protocol that are already implemented by the base JSQMessagesViewController privately
- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressLeftBarButton:(UIButton *)sender;
- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressRightBarButton:(UIButton *)sender;

// Avoiding overriding this private method is an exercise in frustration.  Why is this not part of JSQMessageData??!?  View controllers should do literally everything!
- (BOOL)isOutgoingMessage:(id<JSQMessageData>)messageItem;

@end

@interface ZNGConversationViewController ()

@property (nonatomic, strong) JSQMessagesBubbleImage * outgoingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage * incomingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage * outgoingBubbleMediaMaskData;
@property (nonatomic, strong) JSQMessagesBubbleImage * incomingBubbleMediaMaskData;
@property (nonatomic, strong) JSQMessagesBubbleImage * intenralNoteBubbleImageData;
@property (nonatomic, assign) BOOL isVisible;

/**
 *  As this value climbs above its default (around -4.0,) the exact time label appears from the right of the screen as the user is panning left.
 */
@property (nonatomic, assign) CGFloat timeLabelPenetration;

@end

@implementation ZNGConversationViewController
{
    dispatch_source_t pollingTimerSource;
    BOOL checkedInitialVisibleCells;
    
    BOOL moreMessagesAvailableRemotely;
    BOOL hasDisplayedInitialData;
    
    BOOL showingImageView;
    
    /**
     *  A UUID sent to the server with a message to prevent duplicate messages in the case of specific
     *   timeout timing and the user hitting send again.
     *  This value is changed any time the text is changed.
     */
    NSString * uuid;
    
    ZNGGradientLoadingView * loadingGradient;
    
    NSUInteger pendingInsertionCount;   // See http://victorlin.me/posts/2016/04/29/uicollectionview-invalid-number-of-items-crash-issue for why this awful variable is required
    
    BOOL caTransactionToDisableAnimationsPushed;
    
    NSMutableArray<NSData *> * outgoingImageAttachments;
    
    /**
     *  YES if the last scrolling action left us at the bottom of our content (within a few points) or if there is another reason we now want to be bottom pinned (e.g. just sent a message)
     */
    BOOL stuckToBottom;
    
    /**
     *  The number of new events that have arrived under our current scroll position.
     *  This will count messages and internal notes but not other event types.
     */
    NSUInteger newEventsSinceLastScrolledToBottom;
    
    /**
     *  The fully off-screen value for the off screen right time labels.
     */
    CGFloat offScreenTimeLabelPenetration;
    
    NSDateFormatter * timeFormatter;
    
    /**
     *  Used for delayed messages.  Converts NSTimeInterval like 66.0 into "about a minute," etc.
     */
    NSDateComponentsFormatter * nearFutureTimeFormatter;
}

@dynamic collectionView;
@dynamic inputToolbar;

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([ZNGConversationViewController class])
                          bundle:[NSBundle bundleForClass:[ZNGConversationViewController class]]];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        [self _conv_commonInit];
    }
    
    return self;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self != nil) {
        [self _conv_commonInit];
    }
    
    return self;
}

- (void) _conv_commonInit
{
    // Default property values
    _outgoingBubbleColor = [UIColor zng_outgoingMessageBubbleColor];
    _incomingBubbleColor = [UIColor zng_messageBubbleLightGrayColor];
    _internalNoteColor = [UIColor zng_note_yellow];
    _incomingTextColor = [UIColor zng_text_gray];
    _outgoingTextColor = [UIColor whiteColor];
    _internalNoteTextColor = [UIColor zng_text_gray];
    _authorTextColor = [UIColor lightGrayColor];
    _messageFont = [UIFont latoFontOfSize:17.0];
    _textInputFont = [UIFont latoFontOfSize:16.0];
    
    offScreenTimeLabelPenetration = 0.0;
    _timeLabelPenetration = offScreenTimeLabelPenetration;
    
    outgoingImageAttachments = [[NSMutableArray alloc] initWithCapacity:2];
    
    [self addObserver:self forKeyPath:EventsKVOPath options:NSKeyValueObservingOptionNew context:ZNGConversationKVOContext];
    [self addObserver:self forKeyPath:LoadingKVOPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:ZNGConversationKVOContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyMediaMessageMediaDownloaded:) name:kZNGMessageMediaLoadedNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupLoadingGradient];
    
    [self updateUUID];
    
    timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateStyle = NSDateFormatterNoStyle;
    timeFormatter.timeStyle = NSDateFormatterShortStyle;
    
    nearFutureTimeFormatter = [[NSDateComponentsFormatter alloc] init];
    nearFutureTimeFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
    nearFutureTimeFormatter.includesApproximationPhrase = YES;
    nearFutureTimeFormatter.allowedUnits = (NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay);
    nearFutureTimeFormatter.formattingContext = NSFormattingContextMiddleOfSentence;
    
    self.automaticallyScrollsToMostRecentMessage = NO;
    
    self.inputToolbar.contentView.textView.font = self.textInputFont;
    self.inputToolbar.sendButtonColor = self.sendButtonColor;
    self.inputToolbar.sendButtonFont = self.sendButtonFont;
    
    self.outgoingCellIdentifier = [ZNGConversationCellOutgoing cellReuseIdentifier];
    self.incomingCellIdentifier = [ZNGConversationCellIncoming cellReuseIdentifier];
    self.outgoingMediaCellIdentifier = [ZNGConversationCellOutgoing mediaCellReuseIdentifier];
    self.incomingMediaCellIdentifier = [ZNGConversationCellIncoming mediaCellReuseIdentifier];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.collectionView.collectionViewLayout.messageBubbleFont = self.messageFont;
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    UINib * nib = [UINib nibWithNibName:NSStringFromClass([ZNGEventCollectionViewCell class]) bundle:bundle];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:EventCellIdentifier];
    
    [self setupBarButtonItems];
    
    UIImage * bubbleImage = [UIImage imageNamed:@"zingleBubble" inBundle:bundle compatibleWithTraitCollection:nil];
        
    JSQMessagesBubbleImageFactory * bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:bubbleImage capInsets:UIEdgeInsetsZero];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:self.outgoingBubbleColor];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:self.incomingBubbleColor];
    self.intenralNoteBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:self.internalNoteColor];
    self.outgoingBubbleMediaMaskData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor blackColor]];
    self.incomingBubbleMediaMaskData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor blackColor]];
    
    // Add tappa tappa tappa to the new message deal
    UITapGestureRecognizer * tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressedNewMessageBanner:)];
    [self.moreMessagesView addGestureRecognizer:tapper];
    
    // Pan gesture recognizer for revealing times
    UIPanGestureRecognizer * panner = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    panner.cancelsTouchesInView = NO;
    panner.delaysTouchesEnded = NO;
    panner.delegate = self;
    [self.collectionView addGestureRecognizer:panner];
    
    // Use a weak timer so that we can have a refresh timer going that will continue to work even if the conversation
    //   object is changed out from under us, but we will also not leak.
    __weak ZNGConversationViewController * weakSelf = self;
    pollingTimerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    uint64_t pollingIntervalNanoseconds = PollingIntervalSeconds * NSEC_PER_SEC;
    dispatch_source_set_timer(pollingTimerSource, dispatch_time(DISPATCH_TIME_NOW, pollingIntervalNanoseconds), pollingIntervalNanoseconds, 5 * NSEC_PER_SEC /* 5 sec leeway */);
    dispatch_source_set_event_handler(pollingTimerSource, ^{
        if (weakSelf.isVisible) {
            [weakSelf.conversation loadRecentEventsErasingOlderData:NO];
        }
    });
    dispatch_resume(pollingTimerSource);
}

- (void) setupLoadingGradient
{
    loadingGradient = [[ZNGGradientLoadingView alloc] initWithFrame:CGRectMake(0.0, 0.0, 480.0, 6.0)];
    loadingGradient.hidesWhenStopped = YES;
    loadingGradient.centerColor = [UIColor zng_loadingGradientInnerColor];
    loadingGradient.edgeColor = [UIColor zng_loadingGradientOuterColor];
    
    loadingGradient.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:loadingGradient];
    
    NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:loadingGradient attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint * height = [NSLayoutConstraint constraintWithItem:loadingGradient attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:6.0];
    NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:loadingGradient attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint * right = [NSLayoutConstraint constraintWithItem:loadingGradient attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    
    [self.view addConstraints:@[top, height, left, right]];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isVisible = YES;
    
    if (showingImageView) {
        // Reset the scroll setting to normal now that we have returned from an image view.
        self.automaticallyScrollsToMostRecentMessage = YES;
        showingImageView = NO;
    }
    
    [self markAllVisibleMessagesAsRead];
    checkedInitialVisibleCells = YES;
    
    self.conversation.automaticallyRefreshesOnPushNotification = YES;
    
    [self checkForMoreRemoteMessagesAvailable];
}

- (void) viewWillDisappear:(BOOL)animated
{
    checkedInitialVisibleCells = NO;
    
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    self.isVisible = NO;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    self.conversation.automaticallyRefreshesOnPushNotification = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:LoadingKVOPath context:ZNGConversationKVOContext];
    [self removeObserver:self forKeyPath:EventsKVOPath context:ZNGConversationKVOContext];
    
    if (pollingTimerSource != nil) {
        dispatch_source_cancel(pollingTimerSource);
    }
}

- (void) setupBarButtonItems
{
    NSArray<UIBarButtonItem *> * barItems = [self rightBarButtonItems];
    
    if ([barItems count] == 0) {
        ZNGLogDebug(@"There are no right bar button items.");
        return;
    }
    
    self.navigationItem.rightBarButtonItems = barItems;
}

- (void) setMessageFont:(UIFont *)messageFont
{
    _messageFont = messageFont;
    
    self.collectionView.collectionViewLayout.messageBubbleFont = messageFont;
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void) setTextInputFont:(UIFont *)textInputFont
{
    _textInputFont = textInputFont;
    self.inputToolbar.contentView.textView.font = textInputFont;
}

- (void) updateUUID
{
    NSString * newUUID = [[[NSUUID alloc] init] UUIDString];
    ZNGLogVerbose(@"Updating message UUID from %@ to %@", uuid, newUUID);
    uuid = newUUID;
}

#pragma mark - Data properties
- (void) setConversation:(ZNGConversation *)conversation
{
    _conversation = conversation;
    hasDisplayedInitialData = NO;
    newEventsSinceLastScrolledToBottom = 0;
    
    // Update title and collection view
    [self.navigationItem setTitle:conversation.remoteName];
    [self.collectionView reloadData];
}

- (void) checkForMoreRemoteMessagesAvailable
{
    moreMessagesAvailableRemotely = (self.conversation.totalEventCount > [self.conversation.events count]);
}

#pragma mark - Actions
- (void) messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressLeftBarButton:(UIButton *)sender { /* unused */ }

- (void) didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    // Remove any attachment sentinels
    NSString * attachmentCharacters = [NSString stringWithFormat:@"%c\ufffc", NSAttachmentCharacter];
    NSCharacterSet * attachmentCharacterSet = [NSCharacterSet characterSetWithCharactersInString:attachmentCharacters];
    text = [[text componentsSeparatedByCharactersInSet:attachmentCharacterSet] componentsJoinedByString:@""];
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    self.inputToolbar.inputEnabled = NO;
    self.inputToolbar.contentView.textView.text = @"";
    
    stuckToBottom = YES;
    
    [self.conversation sendMessageWithBody:text imageData:[outgoingImageAttachments copy] uuid:uuid success:^(ZNGStatus *status) {
        self.inputToolbar.inputEnabled = YES;
        [self finishSendingMessageAnimated:YES];
    } failure:^(ZNGError *error) {
        self.inputToolbar.inputEnabled = YES;
        [self finishSendingMessageAnimated:YES];
        
        NSString * errorTitle = @"Unable to send";
        NSString * errorMessage = @"Error encountered while sending the message.";
        
        if (error.zingleErrorCode == ZINGLE_ERROR_EMPTY_MESSAGE) {
            errorTitle = @"Unable to send an empty message";
            
            NSCharacterSet * braceCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
            NSRange replacementCharacterRange = [text rangeOfCharacterFromSet:braceCharacterSet];
            BOOL mayContainReplacementStrings = (replacementCharacterRange.location != NSNotFound);
            
            if (mayContainReplacementStrings) {
                // They sent a message with {replacement fields}, but the server reported that the message was empty.  This is probably a result of
                //  a custom field or channel value replacement value that is empty.  See: http://jira.zinglecorp.com:8080/browse/MOBILE-316
                errorMessage = @"The fields sent in this message are empty.  The message was not sent.";
            }
        }
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:errorTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
    }];
    
    [self finishSendingMessageAnimated:YES];
}

- (void) finishSendingMessageAnimated:(BOOL)animated
{
    stuckToBottom = YES;
    [outgoingImageAttachments removeAllObjects];
    [super finishSendingMessageAnimated:animated];
}

- (void) pressedNewMessageBanner:(UITapGestureRecognizer *)tapper
{
    if ([self.conversation.events count] == 0) {
        return;
    }
    
    [self scrollToBottomAnimated:YES];
}

#pragma mark - Pan timestamps
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return (otherGestureRecognizer == self.collectionView.panGestureRecognizer);
}

- (BOOL) gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panner
{
    CGPoint velocity = [panner velocityInView:self.collectionView];
    CGFloat leftness = fabs(MIN(velocity.x, 0.0));
    CGFloat verticalness = fabs(velocity.y);
    CGFloat relativeLeftness = leftness - verticalness;
    
    // We must be going significantly leftward to start the gesture.
    return (relativeLeftness > 25.0);
}

- (void) didPan:(UIPanGestureRecognizer *)panner
{
    switch (panner.state) {
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panner translationInView:self.collectionView];
            CGFloat leftness = fabs(MIN(translation.x, 0.0)) + offScreenTimeLabelPenetration;
            self.timeLabelPenetration = leftness * timeLabelPanSpeed;
        }
            return;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            self.timeLabelPenetration = offScreenTimeLabelPenetration;
            return;
            
        default:
            // Nothing to do
            return;
    }
}

- (void) setTimeLabelPenetration:(CGFloat)timeLabelPenetration
{
    if (timeLabelPenetration == _timeLabelPenetration) {
        // No change.  Shortcut all display logic.
        return;
    }
    
    _timeLabelPenetration = timeLabelPenetration;
    BOOL shouldAnimate = (timeLabelPenetration == offScreenTimeLabelPenetration);
    [self updateVisibleTimeLabelLocationsAnimated:shouldAnimate];
}

- (void) updateVisibleTimeLabelLocationsAnimated:(BOOL)animated
{
    NSArray<JSQMessagesCollectionViewCell *> * visibleCells = [self.collectionView visibleCells];
    
    for (JSQMessagesCollectionViewCell * cell in visibleCells) {
        NSIndexPath * indexPath = [self.collectionView indexPathForCell:cell];
        ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
        [self updateTimeLabelLocationForCell:cell forEventViewModel:viewModel animated:animated];
    }
}

- (void) updateTimeLabelLocationForCell:(JSQMessagesCollectionViewCell *)theCell forEventViewModel:(ZNGEventViewModel *)viewModel animated:(BOOL)animated
{
    if ((![viewModel.event isMessage]) && (![viewModel.event isNote])) {
        // This is not a message nor a note.  No time.
        return;
    }
    
    NSAssert([theCell respondsToSelector:@selector(timeOffScreenConstraint)] && [theCell respondsToSelector:@selector(exactTimeLabel)], @"Cell is expected to have properties for timeOffScreenConstraint and exactTimeLabel.  It is instead of type %@", [theCell class]);
    
    ZNGConversationCellOutgoing * cell = (ZNGConversationCellOutgoing *)theCell;
    
    CGFloat maxPenetration = cell.exactTimeLabel.frame.size.width + fabs(offScreenTimeLabelPenetration) * 2.0;
    CGFloat penetration = -MIN(self.timeLabelPenetration, maxPenetration);
    
    if (animated) {
        [cell layoutIfNeeded];
        
        [UIView animateWithDuration:0.38 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            cell.timeOffScreenConstraint.constant = -penetration;
            [cell layoutIfNeeded];
        } completion:nil];
    } else {
        cell.timeOffScreenConstraint.constant = -penetration;
        [cell layoutIfNeeded];
    }
}

#pragma mark - Data notifications
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context != ZNGConversationKVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:EventsKVOPath]) {
        [self handleEventsChange:change];
    } else if ([keyPath isEqualToString:LoadingKVOPath]) {
        BOOL wasLoading = ([change[NSKeyValueChangeOldKey] isKindOfClass:[NSNumber class]]) ? [change[NSKeyValueChangeOldKey] boolValue] : NO;
        BOOL isLoading = ([change[NSKeyValueChangeNewKey] isKindOfClass:[NSNumber class]]) ? [change[NSKeyValueChangeNewKey] boolValue] : NO;
        
        if ((!wasLoading) && (isLoading)) {
            [loadingGradient startAnimating];
        } else if ((wasLoading) && (!isLoading)) {
            [loadingGradient stopAnimating];
        }
    }
}

- (void) showOrHideLoadEarlierMessagesButton
{
    BOOL moreEventsExist = (self.conversation.events != 0) && ([self.conversation.events count] < self.conversation.totalEventCount);
    self.showLoadEarlierMessagesHeader = moreEventsExist;
}

- (void) handleEventsChange:(NSDictionary<NSString *, id> *)change
{
    [self checkForMoreRemoteMessagesAvailable];
    
    if (!hasDisplayedInitialData) {
        // Delay the setting of this flag to allow the view to scroll to this new data.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hasDisplayedInitialData = YES;
        });
    }
    
    int changeType = [change[NSKeyValueChangeKindKey] intValue];
    
    switch (changeType)
    {
        case NSKeyValueChangeInsertion:
        {
            NSArray<ZNGEventViewModel *> * insertions = [change[NSKeyValueChangeNewKey] isKindOfClass:[NSArray class]] ? change[NSKeyValueChangeNewKey] : nil;
                        
            // Check for the special case of messages being inserted at the head of our data
            BOOL newDataIsAtHead = [[self.conversation.eventViewModels firstObject] isEqual:[insertions firstObject]];
            BOOL someDataAlreadyExisted = (([self.conversation.eventViewModels count] - [insertions count]) > 0);
            if (newDataIsAtHead && someDataAlreadyExisted) {
                NSIndexSet * indexes = [change[NSKeyValueChangeIndexesKey] isKindOfClass:[NSIndexSet class]] ? change[NSKeyValueChangeIndexesKey] : nil;
                
                if (indexes != nil) {
                    NSMutableArray * indexPaths = [[NSMutableArray alloc] initWithCapacity:[indexes count]];
                    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
                    }];
                    
                    // If we successfully get here, we will tell the collection view to insert the items and then return before calling finishReceivingMessageAnimated:
                    ZNGLogVerbose(@"Inserting %llu events into collection view to bring total to %llu", (unsigned long long)[insertions count], (unsigned long long)[self.conversation.events count]);
                    [self insertEventsAtIndexesWithoutScrolling:indexPaths];
                    return;
                }
            }
            
            ZNGLogVerbose(@"Calling finishReceivingMessagesAnimated: with %llu total events.", (unsigned long long)[self.conversation.events count]);
            [self finishReceivingMessageAnimated:hasDisplayedInitialData];  // Do not animate the initial scroll to bottom if this is our first data
            
            if ((hasDisplayedInitialData) && (!stuckToBottom)) {
                
                __block NSUInteger newMessagesAndNotesCount = 0;
                
                for (ZNGEventViewModel * eventViewModel in insertions) {
                    if (([eventViewModel.event isMessage]) || ([eventViewModel.event isNote])) {
                        newMessagesAndNotesCount++;
                    }
                }
                
                newEventsSinceLastScrolledToBottom += newMessagesAndNotesCount;
                [self updateUnreadBanner];
            }
            
            break;
        }
            
        case NSKeyValueChangeRemoval:
        case NSKeyValueChangeSetting:
        case NSKeyValueChangeReplacement:
        default:
            // Any of these cases, we will be safe and reload
            ZNGLogVerbose(@"Reloading collection view with %llu total events.", (unsigned long long)[self.conversation.events count]);
            [self.collectionView reloadData];
        
            if (!hasDisplayedInitialData) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self scrollToBottomAnimated:NO];
                });
            }
    }
}

- (void) scrollToBottomAnimated:(BOOL)animated
{
    stuckToBottom = YES;
    newEventsSinceLastScrolledToBottom = 0;
    [self updateUnreadBanner];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGRect bottomLeft = CGRectMake(0.0, self.collectionView.contentSize.height - 1.0, 1.0, 1.0);
        [self.collectionView scrollRectToVisible:bottomLeft animated:animated];
    });
}

// Using method stolen from http://stackoverflow.com/a/26401767/3470757 to insert/reload without scrolling
- (void) performCollectionViewUpdatesWithoutScrollingFromBottom:(void (^)())updates
{
    CGFloat bottomOffset = self.collectionView.contentSize.height - self.collectionView.contentOffset.y;

    if ((!caTransactionToDisableAnimationsPushed) && (self.collectionView != nil)) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        caTransactionToDisableAnimationsPushed = YES;
    }
    
    [self.collectionView performBatchUpdates:updates completion:^(BOOL finished) {
        self.collectionView.contentOffset = CGPointMake(0, self.collectionView.contentSize.height - bottomOffset);
        [CATransaction commit];
        caTransactionToDisableAnimationsPushed = NO;
    }];
}

- (void) insertEventsAtIndexesWithoutScrolling:(NSArray<NSIndexPath *> *)indexes
{
    pendingInsertionCount = [indexes count];
    
    [self performCollectionViewUpdatesWithoutScrollingFromBottom:^{
        [self.collectionView insertItemsAtIndexPaths:indexes];
        pendingInsertionCount = 0;
    }];
}

- (void) notifyMediaMessageMediaDownloaded:(NSNotification *)notification
{
    ZNGMessage * message = notification.object;
    NSArray<NSIndexPath *> * indexPaths = [self indexPathsForEventWithId:message.messageId];
    NSIndexPath * indexPath = [indexPaths firstObject];
    
    if (indexPath == nil) {
        // This message is not in our conversation
        return;
    }
    
    ZNGLogDebug(@"Reloading message %@ due to an image load", message.messageId);
    
    NSArray<NSIndexPath *> * visibleIndexPaths = [[self.collectionView indexPathsForVisibleItems] sortedArrayUsingSelector:@selector(compare:)];
    NSIndexPath * topPath = [visibleIndexPaths lastObject];
    NSComparisonResult comparison = [topPath compare:indexPath];
    
    if (comparison == NSOrderedDescending) {
        // The cell we are refreshing is above our current screen.  We need to keep our bottom offset.
        [self performCollectionViewUpdatesWithoutScrollingFromBottom:^{
            [self.collectionView reloadItemsAtIndexPaths:indexPaths];
        }];
    } else {
        // The cell we are refreshing is below or on screen.  Do not scroll.
        if ((!caTransactionToDisableAnimationsPushed) && (self.collectionView != nil)) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            caTransactionToDisableAnimationsPushed = YES;
        }

        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadItemsAtIndexPaths:indexPaths];
        } completion:^(BOOL finished) {
            caTransactionToDisableAnimationsPushed = NO;
            [CATransaction commit];
        }];
    }
}

#pragma mark - Text view delegate
- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [self updateUUID];
    
    // Are they deleting an image?
    if ((textView == self.inputToolbar.contentView.textView) && ([text isEqualToString:@""])) {
        // They are deleting.  Check for an image.
        
        __block BOOL deletingImageAttachment = NO;
        [textView.attributedText enumerateAttributesInRange:range options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange attrRange, BOOL * _Nonnull stop) {
            if (attrs[NSAttachmentAttributeName] != nil) {
                deletingImageAttachment = YES;
                *stop = YES;
            }
        }];
        
        if (deletingImageAttachment) {
            // They are deleting at least one image attachment.  Clear them all.
            [outgoingImageAttachments removeAllObjects];
            
            // Note that mutation *is* allowed during this enumeration, per the documentation as of iOS 10.2.
            // We will remove any other image attachments that happen to be in this string.
            NSMutableAttributedString * result = [textView.attributedText mutableCopy];
            [result enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, [result length]) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
                [result deleteCharactersInRange:range];
            }];
            
            textView.attributedText = result;
            [self textViewDidChange:textView];
            return NO;
        }
    }
    
    // We want to detect if they are starting to delete a custom field such as {FIRST_NAME}.
    // If they delete the right brace, it should delete the entire placeholder.
    if ((range.length == 1) && ([text isEqualToString:@""])) {
        // This is a backspace.  Are they deleting a }?
        char deletingChar = [textView.text characterAtIndex:range.location];
        
        if (deletingChar == '}') {
            // Can we find a matching {?
            NSRange openingBraceRange = [textView.text rangeOfString:@"{" options:NSBackwardsSearch];
            
            if (openingBraceRange.location != NSNotFound) {
                // We found a template to delete.  Delete it.
                NSRange customFieldRange = NSMakeRange(openingBraceRange.location, range.location-openingBraceRange.location+1);
                textView.text = [textView.text stringByReplacingCharactersInRange:customFieldRange withString:@""];
                [self.inputToolbar toggleSendButtonEnabled];
                return NO;
            }
        }
    }
    
    if ([[ZNGConversationViewController superclass] instancesRespondToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        return [super textView:textView shouldChangeTextInRange:range replacementText:text];
    }
    
    return YES;
}

#pragma mark - Buttons

- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressAttachImageButton:(id)sender
{
    UIAlertController * alert =[UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIView * popoverSource = toolbar.contentView.leftBarButtonContainerView;
    
    if ([toolbar.contentView respondsToSelector:@selector(imageButton)]) {
        popoverSource = toolbar.contentView.imageButton;
    }
    
    alert.popoverPresentationController.sourceView = popoverSource;
    alert.popoverPresentationController.sourceRect = popoverSource.bounds;
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        ZNGLogInfo(@"The user's current device does not have a camera, does not allow camera access, or the camera is currently unavailable.");
    } else {
        UIAlertAction * takePhoto = [UIAlertAction actionWithTitle:@"Take a photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePickerWithCameraMode:YES];
        }];
        [alert addAction:takePhoto];
    }
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        ZNGLogInfo(@"The user's photo library is currently not available or is empty.");
    } else {
        UIAlertAction * choosePhoto = [UIAlertAction actionWithTitle:@"Choose a photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePickerWithCameraMode:NO];
        }];
        [alert addAction:choosePhoto];
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItems
{
    // Check if we have at least two items (since one will be cancel)
    if ([[self alertActionsForDetailsButton] count] > 1) {
        NSBundle * bundle = [NSBundle bundleForClass:[self class]];
        UIImage * detailsImage = [UIImage imageNamed:@"detailsButton" inBundle:bundle compatibleWithTraitCollection:nil];
        UIBarButtonItem * detailsButton = [[UIBarButtonItem alloc] initWithImage:detailsImage style:UIBarButtonItemStylePlain target:self action:@selector(detailsButtonPressed:)];
        return @[detailsButton];
    }
    
    return nil;
}

- (NSArray<UIAlertAction *> *)alertActionsForDetailsButton
{
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    return @[cancel];
}

- (void) detailsButtonPressed:(id)sender
{
    NSArray<UIAlertAction *> * alertActions = [self alertActionsForDetailsButton];
    
    if ([alertActions count] == 0) {
        ZNGLogDebug(@"No actions available for details button.");
        return;
    }
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // We would ideally use popoverPresentationController.barButtonItem here, but that crashes 100% of the time in iOS 9 for Apple reasons.
    // See: http://stackoverflow.com/questions/31590644/trouble-using-barbuttonitem-for-popoverpresentationcontroller-in-ios-9
    CGFloat size = 20.0;
    CGRect sourceRect = CGRectMake(self.view.bounds.size.width - (2.0 * size), 1.7 * size, size, size);
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = sourceRect;

    for (UIAlertAction * action in alertActions) {
        [alert addAction:action];
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

/**
 *  Shows an image picker.
 *
 *  @param cameraMode If YES, the image picker will be initialized with UIImagePickerControllerSourceTypeCamera, otherwise UIImagePickerControllerSourceTypePhotoLibrary
 */
- (void) showImagePickerWithCameraMode:(BOOL)cameraMode
{
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = cameraMode ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void) didPressAccessoryButton:(UIButton *)sender
{
    [self inputToolbar:self.inputToolbar didPressAttachImageButton:sender];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    if (info[UIImagePickerControllerReferenceURL] != nil) {
        // This is from the photo library.  We can load it from there.
        [self attachImageFromPhotoLibraryWithInfo:info];
    } else if (info[UIImagePickerControllerOriginalImage] != nil) {
        // This is probably straight from the camera; we do not have PH asset info to go along with the image.
        [self attachImageWithInfo:info];
    } else {
        ZNGLogError(@"Image picker did not return any any \"original image\" data.");
        [self showImageAttachmentError];
    }
}

- (void) attachImageWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage * image = info[UIImagePickerControllerOriginalImage];
    
    if (image == nil) {
        [self showImageAttachmentError];
        return;
    }
    
    NSData * imageData = UIImageJPEGRepresentation(image, 0.75);
    [outgoingImageAttachments addObject:imageData];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self attachImage:image];
    }];
}

- (void) attachImageFromPhotoLibraryWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage * image = info[UIImagePickerControllerOriginalImage];
    NSURL * url = info[UIImagePickerControllerReferenceURL];
    
    if ((image == nil) || (url == nil)) {
        ZNGLogError(@"No image data was found after the user selected an image.");
        [self showImageAttachmentError];
        return;
    }
    
    PHAsset * asset = [[PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil] lastObject];
    
    if (asset == nil) {
        // We were unable to retrieve a PHAsset from the supplied image.
        [self showImageAttachmentError];
        return;
    }
    
    PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.networkAccessAllowed = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if ([imageData length] == 0) {
            // We did not get image data.  Show an error.
            [self showImageAttachmentError];
        } else {
            [outgoingImageAttachments addObject:imageData];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage * image = [UIImage animatedImageWithAnimatedGIFData:imageData];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:YES completion:^{
                        [self attachImage:image];
                    }];
                });
            });
        }
    }];
}

- (void) showImageAttachmentError
{
    [self dismissViewControllerAnimated:NO completion:^{
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable to load image" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:NO completion:nil];
    }];
}

- (void) attachImage:(UIImage *)image
{
    if (image == nil) {
        return;
    }
    
    // Due to a bug in UITextView, we must save our font before inserting the image attachment and reset it afterward.
    // See: http://stackoverflow.com/questions/21742376/nsattributedstring-changed-font-unexpectedly-after-inserting-image
    
    UIFont * font = self.inputToolbar.contentView.textView.font;
    
    ZNGImageAttachment * attachment = [[ZNGImageAttachment alloc] init];
    attachment.image = image;
    NSAttributedString * imageString = [NSAttributedString attributedStringWithAttachment:attachment];
    NSMutableAttributedString * mutableString = [[self.inputToolbar.contentView.textView attributedText] mutableCopy];
    [mutableString appendAttributedString:imageString];
    self.inputToolbar.contentView.textView.attributedText = mutableString;
    self.inputToolbar.contentView.textView.font = font;
    
    [self.inputToolbar toggleSendButtonEnabled];
}

#pragma mark - Unread banner
- (void) updateUnreadBanner
{
    if (newEventsSinceLastScrolledToBottom == 0) {
        // Hide the banner if necessary
        if (self.moreMessagesViewOnScreenConstraint.isActive) {
            [self.moreMessagesContainerView layoutIfNeeded];
            [UIView animateWithDuration:0.5 animations:^{
                self.moreMessagesViewOffScreenConstraint.active = YES;
                self.moreMessagesViewOnScreenConstraint.active = NO;
                [self.moreMessagesContainerView layoutIfNeeded];
            }];
        }
        
        return;
    }
    
    // If we are stuck to the bottom, we will not show the banner
    if (stuckToBottom) {
        return;
    }
    
    // Update the text
    self.moreMessagesLabel.text = [NSString stringWithFormat:@"%llu new message%@", (unsigned long long)newEventsSinceLastScrolledToBottom, (newEventsSinceLastScrolledToBottom == 1) ? @"" : @"s"];
    
    // Show the banner if necessary
    if (self.moreMessagesViewOffScreenConstraint.isActive) {
        [self.moreMessagesContainerView layoutIfNeeded];
        [UIView animateWithDuration:0.5 animations:^{
            self.moreMessagesViewOnScreenConstraint.active = YES;
            self.moreMessagesViewOffScreenConstraint.active = NO;
            [self.moreMessagesContainerView layoutIfNeeded];
        }];
    }
}

#pragma mark - Message read marking
- (void) markAllVisibleMessagesAsRead
{
    NSArray<NSIndexPath *> * visibleIndexPaths = [self.collectionView indexPathsForVisibleItems];
    NSMutableOrderedSet<ZNGMessage *> * messages = [[NSMutableOrderedSet alloc] initWithCapacity:[visibleIndexPaths count]];
    
    for (NSIndexPath * indexPath in visibleIndexPaths) {
        ZNGEvent * event = [[self eventViewModelAtIndexPath:indexPath] event];
        
        if ([event isMessage]) {
            [messages addObject:event.message];
        }
    }
    
    [self markMessagesReadIfNecessary:[messages array]];
}

- (void) markMessagesReadIfNecessary:(NSArray<ZNGMessage *> *)messages
{
    NSMutableArray<ZNGMessage *> * unreadMessages = [[NSMutableArray alloc] initWithCapacity:[messages count]];
    
    for (ZNGMessage * message in messages) {
        if ([self weAreSendingOutbound] == [message isOutbound]) {
            // We sent this message; we don't need to mark it as read
            continue;
        }
        
        if (message.readAt != nil) {
            // This message was already read
            continue;
        }
        
        // This needs to be read
        [unreadMessages addObject:message];
    }
    
    if ([unreadMessages count] > 0) {
        [self.conversation markMessagesAsRead:unreadMessages];
    }
}

#pragma mark - Insets
- (void) jsq_updateCollectionViewInsets
{
    [self jsq_setCollectionViewInsetsTopValue:self.topLayoutGuide.length + self.topContentAdditionalInset
                                  bottomValue:CGRectGetMaxY(self.collectionView.frame) - CGRectGetMinY(self.inputToolbar.frame) + self.additionalBottomInset];
}

- (void)jsq_setCollectionViewInsetsTopValue:(CGFloat)top bottomValue:(CGFloat)bottom
{
    UIEdgeInsets insets = UIEdgeInsetsMake(top, 0.0, bottom, 0.0);
    UIEdgeInsets scrollIndicatorInsets = insets;
    self.collectionView.contentInset = insets;
    
    // If we have additional bottom space, subtract that from the scroll indidcator insets to keep the scroll bar from being odd.
    if (self.additionalBottomInset > 0.0) {
        scrollIndicatorInsets = UIEdgeInsetsMake(scrollIndicatorInsets.top, scrollIndicatorInsets.left, scrollIndicatorInsets.bottom - self.additionalBottomInset, scrollIndicatorInsets.right);
    }
    
    self.collectionView.scrollIndicatorInsets = scrollIndicatorInsets;
}

#pragma mark - Scrolling
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat bottomOffset = self.collectionView.contentSize.height - self.collectionView.contentOffset.y - self.collectionView.frame.size.height + self.collectionView.contentInset.bottom;
    BOOL isNowScrolledToBottom = (bottomOffset < 60.0);
    BOOL changed = (stuckToBottom != isNowScrolledToBottom);
    
    // If we're scrolling away from the bottom, we need to ensure that the scrolling is from user input and not some kind of refresh that may remove us from the bottom.
    if ((changed) && (!isNowScrolledToBottom)) {
        if ((!self.collectionView.isDragging) && (!self.collectionView.isDecelerating)) {
            // Something other than user input is making us leave the bottom.  This is a mistake, probably from many events arriving simultaneously.
            // (Put a break point here and investigate many simultaneous events before doing anything hasty like removing this check!)
            return;
        }
    }
    
    stuckToBottom = isNowScrolledToBottom;
    
    if (stuckToBottom) {
        newEventsSinceLastScrolledToBottom = 0;
    }
    
    if (changed) {
        [self updateUnreadBanner];
    }
}
- (BOOL) automaticallyScrollsToMostRecentMessage
{
    ZNGLogVerbose(@"Returning %@ for automaticallyScrollsToMostRecentMessage", stuckToBottom ? @"YES" : @"NO");

    return stuckToBottom;
}

#pragma mark - Data source
- (NSString *)senderId
{
    return (self.conversation != nil ) ? [self.conversation meId] : @"";
}

- (NSString *)senderDisplayName
{
    return @"Me";
}

- (BOOL)isOutgoingMessage:(id<JSQMessageData>)messageItem
{
    ZNGEvent * event;
    
    if ([messageItem isKindOfClass:[ZNGEvent class]]) {
        event = (ZNGEvent *)messageItem;
    } else if ([messageItem isKindOfClass:[ZNGEventViewModel class]]) {
        event = (ZNGEvent *)((ZNGEventViewModel *)(messageItem)).event;
    }
    
    if (event != nil) {
        if ([event isNote]) {
            return YES;
        }
        
        if ([event isMessage]) {
            return ([self weAreSendingOutbound] == [event.message isOutbound]);
        }
    }
    
    return [super isOutgoingMessage:messageItem];
}

- (ZNGEventViewModel *) eventViewModelAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray<ZNGEventViewModel *> * viewModels = self.conversation.eventViewModels;
    return (indexPath.row < [viewModels count]) ? viewModels[indexPath.row] : nil;
}

- (NSArray<NSIndexPath *> *) indexPathsForEventWithId:(NSString *)eventId
{
    NSIndexSet * eventIndexSet = [self.conversation.eventViewModels indexesOfObjectsPassingTest:^BOOL(ZNGEventViewModel * _Nonnull viewModel, NSUInteger idx, BOOL * _Nonnull stop) {
        return [viewModel.event.eventId isEqualToString:eventId];
    }];
    
    if ([eventIndexSet count] == 0) {
        return nil;
    }
    
    NSMutableArray<NSIndexPath *> * paths = [[NSMutableArray alloc] initWithCapacity:[eventIndexSet count]];
    for (NSUInteger i = [eventIndexSet firstIndex]; i <= [eventIndexSet lastIndex]; i++) {
        [paths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    return paths;
}

/**
 *  The event prior to the supplied index path.  This may be multiple indexes behind the supplied index path if there are other event view model objects
 *   for the same event above the index path
 */
- (ZNGEvent *) priorEventToIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * thisEvent = [[self eventViewModelAtIndexPath:indexPath] event];
    
    for (NSInteger i = indexPath.row - 1; i >= 0; i--) {
        // Is this event for the same event (i.e. an attachment for that same message)
        ZNGEventViewModel * viewModel = self.conversation.eventViewModels[i];
        if (![viewModel.event isEqual:thisEvent]) {
            // No, it's a different one.  Hooray.
            return viewModel.event;
        }
    }
    
    return nil;
}

- (ZNGEventViewModel *) nextEventViewModelBelowIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < ([self.conversation.eventViewModels count] - 1)) {
        return self.conversation.eventViewModels[indexPath.row + 1];
    }
    
    return nil;
}

- (ZNGEventViewModel *) priorViewModelToIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0) {
        return [self eventViewModelAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section]];
    }
    
    return nil;
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self eventViewModelAtIndexPath:indexPath];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * event = [[self eventViewModelAtIndexPath:indexPath] event];
 
    if ([event.message isOutbound] == [self weAreSendingOutbound]) {
        return self.outgoingBubbleImageData;
    }
    
    if ([event isNote]) {
        return self.intenralNoteBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageBubbleImageDataSource>) messageBubbleMediaMaskDataForEvent:(ZNGEvent *)event
{
    if ([event.message isOutbound] == [self weAreSendingOutbound]) {
        return self.outgoingBubbleMediaMaskData;
    }
    
    return self.incomingBubbleMediaMaskData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // No avatars
    return nil;
}

// Used to mark messages as read
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    // If we are nearing the top of our loaded data and more data exists, go grab it
    NSUInteger proximityToTopOfDataToTriggerMoreDataLoad = 5;
    if ((hasDisplayedInitialData) && (moreMessagesAvailableRemotely) && (!self.conversation.loading) && (indexPath.row <= proximityToTopOfDataToTriggerMoreDataLoad)) {
        ZNGLogDebug(@"Scrolled near the top of our current events.  Loading older events...");
        [self.conversation loadOlderData];
    }
    
    
    // Now for marking messages read logic:
    
    // A small optimization: We will always mark all visible cells as read whenever we appear.  If we haven't done that yet, we do not need to mark messages
    //  read one at a time.
    if (!checkedInitialVisibleCells) {
        return;
    }
    
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    ZNGEvent * event = viewModel.event;
    
    if ([event isMessage]) {
        [self markMessagesReadIfNecessary:@[event.message]];
    }
    
    // Update the hidden time label.
    [self updateTimeLabelLocationForCell:(JSQMessagesCollectionViewCell *)cell forEventViewModel:viewModel animated:NO];
}

#pragma mark - JSQMessagesViewController collection view shenanigans

- (BOOL)collectionView:(JSQMessagesCollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * event = [[self eventViewModelAtIndexPath:indexPath] event];
    
    if ([event isMessage]) {
        return [super collectionView:collectionView shouldShowMenuForItemAtIndexPath:indexPath];
    }
    
    return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    ZNGEvent * event = [[self eventViewModelAtIndexPath:indexPath] event];
    
    if ([event isMessage]) {
        return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
    }
    
    return NO;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return [self shouldShowTimestampAboveIndexPath:indexPath] ? 36.0 : 0.0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * eventViewModel = [self eventViewModelAtIndexPath:indexPath];
    return (eventViewModel.event.message.isDelayed) ? 18.0 : 0.0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * name = [self nameForMessageAtIndexPath:indexPath];
    
    if (name == nil) {
        // If this is the last message in an inbound group, add some spacing
        ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
        ZNGEventViewModel * nextViewModel = [self nextEventViewModelBelowIndexPath:indexPath];
        
        if (([viewModel.event isInboundMessage]) && (![nextViewModel.event isInboundMessage])) {
            // Add some extra spacing between this message and the next outbound message/detailed event
            return 26.0;
        }
        
        return 0.0;
    }
    
    return 26.0;
}

- (BOOL) shouldShowTimestampAboveIndexPath:(NSIndexPath *)indexPath
{
    // We will always show the time for the very first message
    if (indexPath.row == 0) {
        return YES;
    }
    
    ZNGEvent * thisEvent = [[self eventViewModelAtIndexPath:indexPath] event];
    ZNGEventViewModel * priorEventViewModel = [self priorViewModelToIndexPath:indexPath];
    
    if ([thisEvent isEqual:priorEventViewModel.event]) {
        // The bubble above this one is for the same event.  Don't break them up with a timestamp, you maniac.
        return NO;
    }
    
    NSDate * thisEventTime = thisEvent.createdAt;
    NSDate * priorEventTime = priorEventViewModel.event.createdAt;
    
    if ((thisEventTime != nil) && (priorEventTime != nil)) {
        NSTimeInterval timeSinceLastEvent = [thisEventTime timeIntervalSinceDate:priorEventTime];
        
        if ([self timeBetweenEventsBigEnoughToWarrantTimestamp:timeSinceLastEvent]) {
            return YES;
        }
    }
    
    return NO;
}

// Returns nil if we do not need to show a time this soon
- (NSDate *) timeForEventAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * thisEvent = [[self eventViewModelAtIndexPath:indexPath] event];
    NSDate * thisEventTime = thisEvent.createdAt;
    return thisEventTime;
}

- (BOOL) timeBetweenEventsBigEnoughToWarrantTimestamp:(NSTimeInterval)interval
{
    static NSTimeInterval fiveMinutes = 5.0 * 60.0;
    return (interval > fiveMinutes);
}

- (NSString *) nameForMessageAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self shouldShowTimestampAboveIndexPath:indexPath]) {
        NSDate * messageTime = [self timeForEventAtIndexPath:indexPath];
        
        if (messageTime != nil) {
            return [[ZNGConversationTimestampFormatter sharedFormatter] attributedTimestampForDate:messageTime];
        }
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    
    if (viewModel.event.message.isDelayed) {
        if (viewModel.event.message.executeAt == nil) {
            ZNGLogWarn(@"Message %@ is delayed but has no execute_at date.  Showing ambiguous \"sending later\" header.", viewModel.event.eventId);
            return [[NSAttributedString alloc] initWithString:@"Sending later"];
        }
        
        NSTimeInterval timeUntilSending = [viewModel.event.message.executeAt timeIntervalSinceNow];
        
        if (timeUntilSending < 0.0) {
            ZNGLogInfo(@"Message %@ still shows up as delayed, but its send time has passed.  Showing \"sending soon.\"", viewModel.event.eventId);
            return [[NSAttributedString alloc] initWithString:@"Sending soon"];
        }
        
        // Note that we have to take lowercaseString here because formattingContext is bugged and ignored in NSDateComponentsFormatter as of iOS 10.3.1
        NSString * justTimeIntervalString = [[nearFutureTimeFormatter stringFromTimeInterval:timeUntilSending] lowercaseString];
        NSString * fullString = [NSString stringWithFormat:@"Sending in %@", justTimeIntervalString];
        return [[NSAttributedString alloc] initWithString:fullString];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * name = [self nameForMessageAtIndexPath:indexPath];
    NSDictionary * attributes = @{ NSFontAttributeName: [UIFont latoFontOfSize:12.0] };
    return (name != nil) ? [[NSAttributedString alloc] initWithString:name attributes:attributes] : nil;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.conversation.eventViewModels count] - pendingInsertionCount;
}

- (void) collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    // Is there an image here?
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    UIImage * image = viewModel.event.message.imageAttachmentsByName[viewModel.attachmentName];
    
    if (image == nil) {
        return;
    }
    
    ZNGImageViewController * imageView = [[ZNGImageViewController alloc] init];
    imageView.image = image;
    imageView.navigationItem.title = self.navigationItem.title;
    
    // Prevent JSQMessagesViewController from being an absolute ass and scrolling to the bottom when we come back.
    showingImageView = YES;
    self.automaticallyScrollsToMostRecentMessage = NO;
    
    [self.navigationController pushViewController:imageView animated:YES];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    ZNGEvent * event = viewModel.event;
    
    if ([event isMessage] || [event isNote]) {
        JSQMessagesCollectionViewCell * cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
        cell.cellTopLabel.numberOfLines = 0;    // Support multiple lines
        
        cell.alpha = (event.message.sending || event.message.isDelayed) ? 0.5 : 1.0;
        
        if ([viewModel isMediaMessage]) {
            if ([cell respondsToSelector:@selector(setMediaViewMaskingImage:)]) {
                ZNGConversationCellOutgoing * mediaCell = (ZNGConversationCellOutgoing *)cell;
                id<JSQMessageBubbleImageDataSource> bubbleImageDataSource = [self messageBubbleMediaMaskDataForEvent:event];
                mediaCell.mediaViewMaskingImage = [bubbleImageDataSource messageBubbleImage];
            } else {
                ZNGLogError(@"Collection view cell of type %@ does not respond to %@ as expected.", [cell class], NSStringFromSelector(@selector(setMediaViewMaskingImage:)));
            }
        } else {
            UIColor * textColor;
            
            if ([event isNote]) {
                textColor = self.internalNoteTextColor;
            } else if ([self weAreSendingOutbound] == [event.message isOutbound]) {
                textColor = self.outgoingTextColor;
            } else {
                textColor = self.incomingTextColor;
            }
            
            NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString:[event text]];
            JSQMessagesCollectionViewFlowLayout * layout = (JSQMessagesCollectionViewFlowLayout *)collectionView.collectionViewLayout;
            
            NSMutableDictionary * linkAttributes = [[NSMutableDictionary alloc] init];
            linkAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle | NSUnderlinePatternSolid);
            
            if (textColor != nil) {
                linkAttributes[NSForegroundColorAttributeName] = textColor;
                [text addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, [text length])];
            }
            
            if (layout.messageBubbleFont != nil) {
                [text addAttribute:NSFontAttributeName value:layout.messageBubbleFont range:NSMakeRange(0, [text length])];
            }
            
            cell.textView.linkTextAttributes = linkAttributes;
            cell.textView.attributedText = text;
        }
        
        cell.messageBubbleTopLabel.textColor = self.authorTextColor;
        
        if (event.createdAt != nil) {
            // Both of our incoming and outgoing cell classes have properties for time label, so we'll just use outbound.
            ZNGConversationCellOutgoing * outgoingCell = (ZNGConversationCellOutgoing *)cell;
            outgoingCell.exactTimeLabel.text = [timeFormatter stringFromDate:event.createdAt];
            [self updateTimeLabelLocationForCell:cell forEventViewModel:viewModel animated:NO];
        }
        
        return cell;
    }
    
    // else this is a non-message event
    ZNGEventCollectionViewCell * cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:EventCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [event text];
    return cell;
}

#pragma mark - Abstract methods
- (BOOL) weAreSendingOutbound
{
    NSAssert(NO, @"Failed to override required method %s", __PRETTY_FUNCTION__);
    return NO;
}

@end

#pragma mark - Rotation fix
// This is a fix for a layout invalidation bug, specifically only seen so far in iPad builds inside of a split view.
// Similar to:  https://github.com/jessesquires/JSQMessagesViewController/issues/1042 and https://github.com/jessesquires/JSQMessagesViewController/issues/881
//
// This will probably be pull requested or at least mentioned on the JSQMessagesViewController Github page soon.  Not done yet.

@interface JSQMessagesViewController (Fix_For_iPad_Rotation)

- (void)jsq_resetLayoutAndCaches;

@end

@implementation ZNGConversationViewController (Fix_For_iPad_Rotation)

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [super jsq_resetLayoutAndCaches];
    } completion:nil];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

@end
