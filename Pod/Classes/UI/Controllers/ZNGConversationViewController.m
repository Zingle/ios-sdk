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
#import "ZNGServiceConversationToolbarContentView.h"
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

@import SBObjectiveCWrapper;
@import Shimmer;

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
static NSString * const LoadedInitialDataKVOPath = @"conversation.loadedInitialData";
static void * ZNGConversationKVOContext  =   &ZNGConversationKVOContext;

@interface JSQMessagesViewController ()

// Public declaration of private inset updating methods.  Barf.
- (void)jsq_updateCollectionViewInsets;
- (void)jsq_setCollectionViewInsetsTopValue:(CGFloat)top bottomValue:(CGFloat)bottom;
- (void)jsq_setToolbarBottomLayoutGuideConstant:(CGFloat)constant;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomLayoutGuide;


// Public declarations of methods required by our input toolbar delegate protocol that are already implemented by the base JSQMessagesViewController privately
- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressLeftBarButton:(UIButton *)sender;
- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressRightBarButton:(UIButton *)sender;

// Avoiding overriding this private method is an exercise in frustration.  Why is this not part of JSQMessageData??!?  View controllers should do literally everything!
- (BOOL)isOutgoingMessage:(id<JSQMessageData>)messageItem;

@end

@interface ZNGConversationViewController ()

@property (nonatomic, strong) JSQMessagesBubbleImage * outgoingBubbleMediaMaskData;
@property (nonatomic, strong) JSQMessagesBubbleImage * incomingBubbleMediaMaskData;
@property (nonatomic, assign) BOOL isVisible;

/**
 *  As this value climbs above its default (around -4.0,) the exact time label appears from the right of the screen as the user is panning left.
 */
@property (nonatomic, assign) CGFloat timeLabelPenetration;

@end

@implementation ZNGConversationViewController
{
    dispatch_source_t pollingTimerSource;
    
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
    
    ZNGImageAttachmentController * imageAttachmentController;
    NSMutableArray<NSData *> * outgoingImageAttachments;
    
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
    
    NSMutableSet<NSIndexPath *> * indexPathsOfVisibleCellsWithRelativeTimesToRefresh;
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
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGConversationViewController class]];
    _outgoingBubbleColor = [UIColor colorNamed:@"ZNGOutboundBubbleBackground" inBundle:bundle compatibleWithTraitCollection:nil];
    _incomingBubbleColor = [UIColor colorNamed:@"ZNGInboundBubbleBackground" inBundle:bundle compatibleWithTraitCollection:nil];
    _internalNoteColor = [UIColor colorNamed:@"ZNGInternalNoteBackground" inBundle:bundle compatibleWithTraitCollection:nil];
    _incomingTextColor = [UIColor colorNamed:@"ZNGInboundBubbleText" inBundle:bundle compatibleWithTraitCollection:nil];
    _outgoingTextColor = [UIColor colorNamed:@"ZNGOutboundBubbleText" inBundle:bundle compatibleWithTraitCollection:nil];
    _internalNoteTextColor = [UIColor colorNamed:@"ZNGInternalNoteText" inBundle:bundle compatibleWithTraitCollection:nil];
    _authorTextColor = [UIColor lightGrayColor];
    _messageFont = [UIFont latoFontOfSize:17.0];
    _textInputFont = [UIFont latoFontOfSize:16.0];
    _showSkeletonViewWhenLoading = YES;
    _stuckToBottom = YES;
    
    if (@available(iOS 13.0, *)) {
        _authorTextColor = [UIColor tertiaryLabelColor];
    }
    
    offScreenTimeLabelPenetration = 0.0;
    _timeLabelPenetration = offScreenTimeLabelPenetration;
    
    outgoingImageAttachments = [[NSMutableArray alloc] initWithCapacity:2];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyImageAttachmentSizeChanged:) name:ZNGEventViewModelImageSizeChangedNotification object:nil];
    [self addObserver:self forKeyPath:EventsKVOPath options:NSKeyValueObservingOptionNew context:ZNGConversationKVOContext];
    [self addObserver:self forKeyPath:LoadingKVOPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:ZNGConversationKVOContext];
    [self addObserver:self forKeyPath:LoadedInitialDataKVOPath options:NSKeyValueObservingOptionNew context:ZNGConversationKVOContext];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.outgoingCellIdentifier = [ZNGConversationCellOutgoing cellReuseIdentifier];
    self.incomingCellIdentifier = [ZNGConversationCellIncoming cellReuseIdentifier];
    self.outgoingMediaCellIdentifier = [ZNGConversationCellOutgoing mediaCellReuseIdentifier];
    self.incomingMediaCellIdentifier = [ZNGConversationCellIncoming mediaCellReuseIdentifier];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGConversationViewController class]];
    UINib * headerNib = [UINib nibWithNibName:@"ZNGConversationHeader" bundle:bundle];
    [self.collectionView registerNib:headerNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    
    [self setupLoadingGradient];
    
    [self updateUUID];
    
    indexPathsOfVisibleCellsWithRelativeTimesToRefresh = [[NSMutableSet alloc] initWithCapacity:20];
    
    timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateStyle = NSDateFormatterNoStyle;
    timeFormatter.timeStyle = NSDateFormatterShortStyle;
    
    self.automaticallyScrollsToMostRecentMessage = NO;
    
    for (UIView * view in self.skeletonCircles) {
        view.layer.cornerRadius = view.layer.frame.size.width / 2.0;
        view.layer.masksToBounds = YES;
    }
    
    for (UIView * view in self.skeletonRectangles) {
        view.layer.cornerRadius = view.layer.frame.size.height / 2.0;
        view.layer.masksToBounds = YES;
    }
    
    self.skeletonView.hidden = YES;
    self.skeletonView.contentView = self.skeletonContentView;
    self.skeletonView.shimmeringSpeed = 300;
    self.skeletonView.shimmeringPauseDuration = 0.15;
    
    if (self.showSkeletonViewWhenLoading) {
        // A slight delay before showing the skeleton view allows auto layout to jiggle around while it comes to terms
        //  with its existence within a navigation controller.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.skeletonView.shimmering = YES;
            self.skeletonView.hidden = self.conversation.loadedInitialData;
        });
    }
    
    self.inputToolbar.contentView.textView.font = self.textInputFont;
    self.inputToolbar.sendButtonColor = self.sendButtonColor;
    self.inputToolbar.sendButtonFont = self.sendButtonFont;
    
    if (@available(iOS 13.0, *)) {
        self.inputToolbar.barTintColor = [UIColor systemBackgroundColor];
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.collectionView.collectionViewLayout.messageBubbleFont = self.messageFont;
    
    UINib * eventNib = [UINib nibWithNibName:NSStringFromClass([ZNGEventCollectionViewCell class]) bundle:bundle];
    [self.collectionView registerNib:eventNib forCellWithReuseIdentifier:EventCellIdentifier];
    
    [self setupBarButtonItems];
    
    UIImage * bubbleImage = [UIImage imageNamed:@"zingleBubble" inBundle:bundle compatibleWithTraitCollection:nil];
        
    JSQMessagesBubbleImageFactory * bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:bubbleImage capInsets:UIEdgeInsetsZero];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:self.outgoingBubbleColor];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:self.incomingBubbleColor];
    self.internalNoteBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:self.internalNoteColor];
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
        if (weakSelf == nil) {
            return;
        }
        
        if (weakSelf.isVisible) {
            [weakSelf.conversation loadRecentEventsErasingOlderData:NO];
        }
        
        ZNGConversationViewController * strongSelf = weakSelf;
        if ([strongSelf->indexPathsOfVisibleCellsWithRelativeTimesToRefresh count] > 0) {
            NSMutableSet<NSIndexPath *> * visibleCells = [NSMutableSet setWithArray:[strongSelf.collectionView indexPathsForVisibleItems]];
            [visibleCells intersectSet:strongSelf->indexPathsOfVisibleCellsWithRelativeTimesToRefresh];
            
            if ([visibleCells count] > 0) {
                // Put the reloads into a CATransaction with actions disabled to prevent a flicker when reloading the cell.
                // This flicker is due to alpha being set in the default layout attributes of collection view cells.
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                [strongSelf.collectionView reloadItemsAtIndexPaths:[visibleCells allObjects]];
                [CATransaction commit];
            }
        }
    });
    dispatch_resume(pollingTimerSource);
}

- (void) setupLoadingGradient
{
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGConversationViewController class]];
    
    loadingGradient = [[ZNGGradientLoadingView alloc] initWithFrame:CGRectMake(0.0, 0.0, 480.0, 6.0)];
    loadingGradient.hidesWhenStopped = YES;
    loadingGradient.centerColor = [UIColor colorNamed:@"ZNGLogoGradient" inBundle:bundle compatibleWithTraitCollection:nil];
    loadingGradient.edgeColor = [UIColor colorNamed:@"ZNGLogo" inBundle:bundle compatibleWithTraitCollection:nil];
    
    loadingGradient.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:loadingGradient];
    
    NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:loadingGradient attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
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
    
    self.conversation.automaticallyRefreshes = YES;
    
    [self checkForMoreRemoteMessagesAvailable];
}

- (void) viewWillDisappear:(BOOL)animated
{
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
    self.conversation.automaticallyRefreshes = NO;
    
    [self removeObserver:self forKeyPath:LoadedInitialDataKVOPath context:ZNGConversationKVOContext];
    [self removeObserver:self forKeyPath:LoadingKVOPath context:ZNGConversationKVOContext];
    [self removeObserver:self forKeyPath:EventsKVOPath context:ZNGConversationKVOContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (pollingTimerSource != nil) {
        dispatch_source_cancel(pollingTimerSource);
    }
}

- (void) setupBarButtonItems
{
    NSArray<UIBarButtonItem *> * barItems = [self rightBarButtonItems];
    
    if ([barItems count] == 0) {
        SBLogDebug(@"There are no right bar button items.");
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

- (void) setShowSkeletonViewWhenLoading:(BOOL)showSkeletonViewWhenLoading
{
    _showSkeletonViewWhenLoading = showSkeletonViewWhenLoading;
    
    self.skeletonView.shimmering = showSkeletonViewWhenLoading;
    
    if (!showSkeletonViewWhenLoading) {
        self.skeletonView.hidden = YES;
    } else {
        self.skeletonView.hidden = self.conversation.loadedInitialData;
    }
}

- (void) updateUUID
{
    NSString * newUUID = [[[NSUUID alloc] init] UUIDString];
    SBLogVerbose(@"Updating message UUID from %@ to %@", uuid, newUUID);
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
    
    self.stuckToBottom = YES;
    
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
        } else if ([text length] > ZNGMessageMaximumCharacterLength) {
            errorTitle = @"Message is too long";
            errorMessage = [NSString stringWithFormat:@"Messages longer than %llu characters cannot be sent.", (unsigned long long)ZNGMessageMaximumCharacterLength];
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
    self.stuckToBottom = YES;
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
    } else if ([keyPath isEqualToString:LoadedInitialDataKVOPath]) {
        if (self.showSkeletonViewWhenLoading) {
            self.skeletonView.hidden = self.conversation.loadedInitialData;
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
            self->hasDisplayedInitialData = YES;
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
                    SBLogVerbose(@"Inserting %llu events into collection view to bring total to %llu", (unsigned long long)[insertions count], (unsigned long long)[self.conversation.events count]);
                    [self insertEventsAtIndexesWithoutScrolling:indexPaths];
                    return;
                }
            }
            
            SBLogVerbose(@"Calling finishReceivingMessagesAnimated: with %llu total events, %@ received data already.",
                          (unsigned long long)[self.conversation.events count],
                          hasDisplayedInitialData ? @"HAS" : @"HAS NOT");
            [self finishReceivingMessageAnimated:hasDisplayedInitialData];  // Do not animate the initial scroll to bottom if this is our first data
            
            if ((hasDisplayedInitialData) && (!self.stuckToBottom)) {
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
            SBLogVerbose(@"Reloading collection view with %llu total events.", (unsigned long long)[self.conversation.events count]);
            [self.collectionView reloadData];
        
            if (!hasDisplayedInitialData) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self scrollToBottomAnimated:NO];
                });
            }
    }
}

#pragma mark - Collection view scrolling/updates
- (void) scrollToBottomAnimated:(BOOL)animated
{
    self.stuckToBottom = YES;
    newEventsSinceLastScrolledToBottom = 0;
    [self updateUnreadBanner];
    
    // Add a slight delay to allow the collection view layout to update.
    // Removing this delay can sometimes cause the conversation not to scroll fully down.
    // This is especially noticeable when sending a new message that creates a large message bubble.  Without the 0.1 delay, the conversation
    //  would scroll down to see just the top of the new bubble but not the entire bubble.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGRect bottomLeft = CGRectMake(0.0, self.collectionView.contentSize.height - 1.0, 1.0, 1.0);
        SBLogVerbose(@"Scrolling conversation view down to %@", NSStringFromCGRect(bottomLeft));
        [self.collectionView scrollRectToVisible:bottomLeft animated:animated];
    });
}

// Using method stolen from http://stackoverflow.com/a/26401767/3470757 to insert/reload without scrolling
- (void) performCollectionViewUpdatesWithoutScrollingFromBottom:(void (^)(void))updates
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
        self->caTransactionToDisableAnimationsPushed = NO;
    }];
}

- (void) insertEventsAtIndexesWithoutScrolling:(NSArray<NSIndexPath *> *)indexes
{
    pendingInsertionCount = [indexes count];
    
    [self performCollectionViewUpdatesWithoutScrollingFromBottom:^{
        [self.collectionView insertItemsAtIndexPaths:indexes];
        self->pendingInsertionCount = 0;
    }];
}

- (void) notifyImageAttachmentSizeChanged:(NSNotification *)notification
{
    ZNGEventViewModel * viewModel = notification.object;
    
    if (![viewModel isKindOfClass:[ZNGEventViewModel class]]) {
        SBLogError(@"%@ notification was received, but the attached object is %@ instead of ZNGEventViewModel.  Weird.", ZNGEventViewModelImageSizeChangedNotification, [viewModel class]);
        return;
    }
    
    NSArray<NSIndexPath *> * indexPaths = [self indexPathsForEventWithId:viewModel.event.eventId];
    NSIndexPath * indexPath = [indexPaths firstObject];
    
    if (indexPath == nil) {
        // This message is not in our conversation
        return;
    }
    
    SBLogDebug(@"Reloading message %@ due to an image size change", viewModel.event.eventId);
    
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
            self->caTransactionToDisableAnimationsPushed = NO;
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
            [result enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, [result length]) options:0 usingBlock:^(id  _Nullable value, NSRange attrRange, BOOL * _Nonnull stop) {
                if (value != nil) {
                    [result deleteCharactersInRange:attrRange];
                }
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
            NSRange openingBraceRange = [[textView.text substringToIndex:range.location] rangeOfString:@"{" options:NSBackwardsSearch];

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
    UIView * sourceView = self.inputToolbar.contentView;
    
    if ([sourceView isKindOfClass:[ZNGServiceConversationToolbarContentView class]]) {
        ZNGServiceConversationToolbarContentView * toolbarContentView = (ZNGServiceConversationToolbarContentView *)sourceView;
        sourceView = toolbarContentView.imageButton;
    }
    
    imageAttachmentController = [[ZNGImageAttachmentController alloc] initWithDelegate:self popoverSource:sourceView popoverRect:sourceView.bounds];
    [imageAttachmentController startFromViewController:self];
}

- (void) imageAttachmentControllerDismissedWithoutSelection:(ZNGImageAttachmentController *)controller
{
    imageAttachmentController = nil;
}

- (void) imageAttachmentController:(ZNGImageAttachmentController *)controller selectedImage:(UIImage *)image imageData:(NSData *)imageData
{
    imageAttachmentController = nil;
    
    if ((image == nil) || (imageData == nil)) {
        SBLogError(@"ZNGImageAttachmentController returned nil image data from the success callback.  This displeases me.");
        return;
    }
    
    [outgoingImageAttachments addObject:imageData];
    [self attachImage:image];
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
        SBLogDebug(@"No actions available for details button.");
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

- (void) didPressAccessoryButton:(UIButton *)sender
{
    [self inputToolbar:self.inputToolbar didPressAttachImageButton:sender];
}

- (void) attachImage:(UIImage *)image
{
    if (image == nil) {
        return;
    }

    // Due to some peculiarities with UITextView, the current `typingAttributes` must be applied to the `NSAttributedString` that contains
    //  only the image that is being attached.  If not, the `typingAttributes` are overwritten with defaults, clearing any styling from
    //  the UITextField.  Thanks, iOS.
    NSDictionary<NSAttributedStringKey, id> * typingAttributes = self.inputToolbar.contentView.textView.typingAttributes;
    
    ZNGImageAttachment * attachment = [[ZNGImageAttachment alloc] init];
    attachment.image = image;
    NSMutableAttributedString * imageString = [[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy];
    
    // Add text styling to the image.  Yes, that's what I said.
    if ([typingAttributes count] == 0) {
        SBLogError(@"Unable to retrieve typingAttributes from the UITextView before appending an image.  Styling will likely break.");
    } else {
        [imageString addAttributes:typingAttributes range:NSMakeRange(0, [imageString length])];
    }
    
    NSMutableAttributedString * mutableString = [[self.inputToolbar.contentView.textView attributedText] mutableCopy];
    [mutableString appendAttributedString:imageString];
    
    self.inputToolbar.contentView.textView.attributedText = mutableString;
    
    [self.inputToolbar.contentView.textView becomeFirstResponder];
    [self.inputToolbar toggleSendButtonEnabled];
    
    [self updateUUID];
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
    if (self.stuckToBottom) {
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

#pragma mark - Insets
- (void) jsq_updateCollectionViewInsets
{
    [self jsq_setCollectionViewInsetsTopValue:self.view.safeAreaInsets.top + self.topContentAdditionalInset
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
    BOOL changed = (self.stuckToBottom != isNowScrolledToBottom);
    
    // If we're scrolling away from the bottom, we need to ensure that the scrolling is from user input and not some kind of refresh that may remove us from the bottom.
    if ((changed) && (!isNowScrolledToBottom)) {
        if ((!self.collectionView.isDragging) && (!self.collectionView.isDecelerating)) {
            // Something other than user input is making us leave the bottom.  This is a mistake, probably from many events arriving simultaneously.
            // (Put a break point here and investigate many simultaneous events before doing anything hasty like removing this check!)
            return;
        }
    }
    
    self.stuckToBottom = isNowScrolledToBottom;
    
    if (self.stuckToBottom) {
        newEventsSinceLastScrolledToBottom = 0;
    }
    
    if (changed) {
        [self updateUnreadBanner];
    }
}
- (BOOL) automaticallyScrollsToMostRecentMessage
{
    SBLogVerbose(@"Returning %@ for automaticallyScrollsToMostRecentMessage", self.stuckToBottom ? @"YES" : @"NO");

    return self.stuckToBottom;
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

- (ZNGEventViewModel *) nextEventViewModelBelowIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < ([self.conversation.eventViewModels count] - 1)) {
        return self.conversation.eventViewModels[indexPath.row + 1];
    }
    
    return nil;
}

- (ZNGEventViewModel *) priorViewModelToIndexPath:(NSIndexPath *)indexPath includingDelayedEvents:(BOOL)includeDelayed
{
    if (indexPath.row > 0) {
        ZNGEventViewModel * model = [self eventViewModelAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section]];
        
        if ((!includeDelayed) && (model.event.message.isDelayed)) {
            return [self priorViewModelToIndexPath:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section] includingDelayedEvents:NO];
        } else {
            return model;
        }
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
        return self.internalNoteBubbleImageData;
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

- (void) collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (![[collectionView indexPathsForVisibleItems] containsObject:indexPath]) {
        [indexPathsOfVisibleCellsWithRelativeTimesToRefresh removeObject:indexPath];
    }
}

// Used to mark messages as read
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    // If we are nearing the top of our loaded data and more data exists, go grab it
    NSUInteger proximityToTopOfDataToTriggerMoreDataLoad = 5;
    if ((hasDisplayedInitialData) && (moreMessagesAvailableRemotely) && (!self.conversation.loading) && (indexPath.section == 0) && (indexPath.row <= proximityToTopOfDataToTriggerMoreDataLoad)) {
        SBLogDebug(@"Scrolled near the top of our current events.  Loading older events...");
        [self.conversation loadOlderData];
    }

    // Update the hidden time label.
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    [self updateTimeLabelLocationForCell:(JSQMessagesCollectionViewCell *)cell forEventViewModel:viewModel animated:NO];
}

#pragma mark - JSQMessagesViewController collection view shenanigans

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    // Should we show "This is the start of the conversation?"
    
    // This is only relevant for the first section if subclasses happen to add more.
    if (section > 0) {
        return CGSizeZero;
    }
    
    // If no data is yet loaded, no
    if (!self.conversation.loadedInitialData) {
        return CGSizeZero;
    }
    
    // If we are showing the first page of data, yes
    if ([self.conversation.events count] >= self.conversation.totalEventCount) {
        return CGSizeMake(collectionView.bounds.size.width, 43.0);
    }
    
    return CGSizeZero;
}

- (UICollectionReusableView *) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (![kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
    
    return [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
}

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
    if ([self shouldShowTimestampAboveIndexPath:indexPath]) {
        return 36.0;
    }
    
    if ([self shouldShowFailureForIndexPath:indexPath]) {
        return 9.0;  // prevent clipping of the error icon
    }
    
    return 0.0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    static const CGFloat heightForText = 26.0;
    
    if (([self shouldShowAttachmentErrorForIndexPath:indexPath]) ||
        ([self shouldShowFailureForIndexPath:indexPath]) ||
        ([self shouldShowSendingForIndexPath:indexPath])) {
        
        return heightForText;
    }
    
    if ([[self nameForMessageAtIndexPath:indexPath] length] > 0) {
        return heightForText;
    }
    
    // If this is the last message in an inbound group, add some spacing
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    ZNGEventViewModel * nextViewModel = [self nextEventViewModelBelowIndexPath:indexPath];
    
    if (([viewModel.event isInboundMessage]) && (![nextViewModel.event isInboundMessage])) {
        // Add some extra spacing between this message and the next outbound message/detailed event
        return 26.0;
    }
    
    return 0.0;
}

- (BOOL) shouldShowSendingForIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    return viewModel.event.sending;
}

- (BOOL) shouldShowFailureForIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    return ([viewModel.event.message failed]);
}

- (BOOL) shouldShowAttachmentErrorForIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    return ((viewModel.attachmentStatus == ZNGEventViewModelAttachmentStatusFailed) || (viewModel.attachmentStatus == ZNGEventViewModelAttachmentStatusUnrecognizedType));
}

- (BOOL) shouldShowTimestampAboveIndexPath:(NSIndexPath *)indexPath
{
    // We will always show the time for the very first message
    if (indexPath.row == 0) {
        return YES;
    }
    
    ZNGEvent * thisEvent = [[self eventViewModelAtIndexPath:indexPath] event];
    ZNGEventViewModel * priorEventViewModel = [self priorViewModelToIndexPath:indexPath includingDelayedEvents:NO];
    
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

#pragma mark - Cell text
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
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * content = nil;
    
    if ([self shouldShowFailureForIndexPath:indexPath]) {
        ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];

        // Does this look like a failure due to length?
        if ([viewModel.event.message.body length] > ZNGMessageMaximumCharacterLength) {
            content = @"Failed to send: message is too long";
        } else {
            content = @"Failed to send";
        }
    } else if ([self shouldShowSendingForIndexPath:indexPath]) {
        content = @"Sending";
    } else if ([self shouldShowAttachmentErrorForIndexPath:indexPath]) {
        ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
        
        if (viewModel.attachmentStatus == ZNGEventViewModelAttachmentStatusUnrecognizedType) {
            content = @"Unrecognized attachment type";
        } else if (viewModel.attachmentStatus == ZNGEventViewModelAttachmentStatusFailed) {
            content = @"Failed to download attachment";
        }
    } else {
        content = [self nameForMessageAtIndexPath:indexPath];
    }
    
    NSDictionary * attributes = @{ NSFontAttributeName: [UIFont latoFontOfSize:12.0] };
    return ([content length] > 0) ? [[NSAttributedString alloc] initWithString:content attributes:attributes] : nil;
}

#pragma mark -
- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.conversation.eventViewModels count] - pendingInsertionCount;
}

- (void) collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    // Is there an image here?
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    NSString * attachmentName = [viewModel attachmentName];
    
    if (([attachmentName length] == 0) || (viewModel.attachmentStatus != ZNGEventViewModelAttachmentStatusAvailable)) {
        return;
    }
    
    NSURL * attachmentURL = [NSURL URLWithString:attachmentName];
    
    ZNGImageViewController * imageView = [[ZNGImageViewController alloc] init];
    imageView.imageURL = attachmentURL;
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
        
        CGFloat contentAlpha = (event.sending || event.message.isDelayed || ([event.message failed])) ? 0.5 : 1.0;
        cell.messageBubbleImageView.alpha = contentAlpha;
        cell.mediaView.alpha = contentAlpha;
        
        if (([self shouldShowFailureForIndexPath:indexPath]) && ([cell isKindOfClass:[ZNGConversationCellOutgoing class]])) {
            ZNGConversationCellOutgoing * outgoingCell = (ZNGConversationCellOutgoing *)cell;
            outgoingCell.sendingErrorIconContainer.hidden = NO;
        }
        
        if (event.message.isDelayed) {
            [indexPathsOfVisibleCellsWithRelativeTimesToRefresh addObject:indexPath];
        } else {
            [indexPathsOfVisibleCellsWithRelativeTimesToRefresh removeObject:indexPath];
        }
        
        if ([viewModel isMediaMessage]) {
            if ([cell respondsToSelector:@selector(setMediaViewMaskingImage:)]) {
                ZNGConversationCellOutgoing * mediaCell = (ZNGConversationCellOutgoing *)cell;
                id<JSQMessageBubbleImageDataSource> bubbleImageDataSource = [self messageBubbleMediaMaskDataForEvent:event];
                mediaCell.mediaViewMaskingImage = [bubbleImageDataSource messageBubbleImage];
            } else {
                SBLogError(@"Collection view cell of type %@ does not respond to %@ as expected.", [cell class], NSStringFromSelector(@selector(setMediaViewMaskingImage:)));
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
            outgoingCell.exactTimeLabel.text = [timeFormatter stringFromDate:event.displayTime];
            [self updateTimeLabelLocationForCell:cell forEventViewModel:viewModel animated:NO];
        }
        
        return cell;
    }
    
    // else this is a non-message event
    ZNGEventCollectionViewCell * cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:EventCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [event text];
    return cell;
}

#pragma mark - Safe area fixes
/**
 *  This is mostly a copy/paste from the original JSQMessagesViewController keyboardController:keyboardDidChangeFrame: but with
 *   added support for safeAreaInsets to prevent the toolbar form being moved too far above the keyboard.
 */
- (void)keyboardController:(JSQMessagesKeyboardController *)keyboardController keyboardDidChangeFrame:(CGRect)keyboardFrame
{
    if (![self.inputToolbar.contentView.textView isFirstResponder] && self.toolbarBottomLayoutGuide.constant == 0.0) {
        return;
    }
    
    CGFloat bottomNonSafeSpace = 0.0;
    
    if (@available(iOS 11.0, *)) {
        bottomNonSafeSpace += self.view.safeAreaInsets.bottom;
    }
    
    CGFloat heightFromBottom = CGRectGetMaxY(self.collectionView.frame) - CGRectGetMinY(keyboardFrame) - bottomNonSafeSpace;
    
    heightFromBottom = MAX(0.0, heightFromBottom);
    
    [self jsq_setToolbarBottomLayoutGuideConstant:heightFromBottom];
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
