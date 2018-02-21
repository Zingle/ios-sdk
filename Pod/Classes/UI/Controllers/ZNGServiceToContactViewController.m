//
//  ZNGServiceToContactViewController.m
//  Pods
//
//  Created by Jason Neel on 7/5/16.
//
//

#import "ZNGServiceToContactViewController.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGEvent.h"
#import "UIFont+Lato.h"
#import "UIImage+ZingleSDK.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGContactClient.h"
#import "ZNGContactField.h"
#import "ZNGLogging.h"
#import "ZNGConversationDetailedEvents.h"
#import "ZNGEventCollectionViewCell.h"
#import "ZNGConversationFlowLayout.h"
#import "ZNGTemplate.h"
#import "UIViewController+ZNGSelectTemplate.h"
#import "ZNGContactEditViewController.h"
#import "ZNGAnalytics.h"
#import "ZingleAccountSession.h"
#import "ZNGLogging.h"
#import "ZNGForwardingViewController.h"
#import "ZNGInitialsAvatarCache.h"
#import "ZNGEventViewModel.h"
#import "ZNGUserAuthorization.h"
#import "UILabel+NetworkStatus.h"
#import "ZNGPaddedLabel.h"
#import "ZNGConversationTypingIndicatorCell.h"
#import "ZNGMessageData.h"
#import "JSQMessagesViewController/JSQMessageBubbleImageDataSource.h"
#import "ZNGPendingResponseOrNote.h"
#import "ZNGAssignmentViewController.h"
#import "ZNGTeam.h"
#import "ZNGUser.h"

@import SDWebImage;

static const int zngLogLevel = ZNGLogLevelInfo;

static NSString * const AssignmentUITypeActionMenu = @"action menu";

static NSString * const ConfirmedText = @" Confirmed ";
static NSString * const UnconfirmedText = @" Unconfirmed ";

static NSString * const KVOContactChannelsPath = @"conversation.contact.channels";
static NSString * const KVOContactCustomFieldsPath = @"conversation.contact.customFieldValues";
static NSString * const KVOTeamAssignment = @"conversation.contact.assignedToTeamId";
static NSString * const KVOUserAssignment = @"conversation.contact.assignedToUserId";
static NSString * const KVOChannelPath = @"conversation.channel";
static NSString * const KVOInputLockedPath = @"conversation.lockedDescription";
static NSString * const KVOReplyingUsersPath = @"conversation.pendingResponses";

static NSString * const TypingIndicatorCellID = @"typingIndicator";

static void * KVOContext = &KVOContext;

@interface JSQMessagesViewController (PrivateInsetManipulation)

- (void)jsq_updateCollectionViewInsets;

@end

enum ZNGConversationSections
{
    ZNGConversationSectionMessages,
    ZNGConversationSectionTypingIndicators,
    ZNGConversationSectionCount
};

@implementation ZNGServiceToContactViewController
{
    UIView * bannerContainer;
    UILabel * titleLabel;
    
    UIView * blockedChannelBanner;
    UILabel * blockedChannelLabel;
    NSLayoutConstraint * blockedChannelOnScreenConstraint;
    NSLayoutConstraint * blockedChannelOffScreenConstraint;
    
    ZNGPaddedLabel * networkStatusLabel;
        
    NSUInteger fireZIndex;
    
    NSMutableArray<NSDate *> * robotTouchTimes;
    NSDate * lastRobotVolleyTime;
    
    ZNGMessage * messageToForward;
    
    NSTimer * textViewChangeTimer;
    
    /**
     *  This flag is unset when a user first starts typing a message.  When this is unset, the first input will immediately cause a
     *   "user is typing" notification to be sent to the server.  The flag is then set so a normal delay precedes any future notifications
     *   during the same editing session.
     */
    BOOL sentInitialTypingNotification;
    
    BOOL viewHasAppeared;
    BOOL titleWasSingleLineLastUpdate;
    
    /**
     *  Used for delayed messages.  Converts NSTimeInterval like 66.0 into "about a minute," etc.
     */
    NSDateComponentsFormatter * nearFutureTimeFormatter;
}

@dynamic conversation;
@dynamic inputToolbar;

+ (UINib *)nib
{
    // JSQMessagesViewController's viewDidLoad tries to rudely load us from nib using this return value.  We do not want this, since we're coming from a storyboard earlier.
    return nil;
}

+ (instancetype)messagesViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([ZNGConversationViewController class])
                                          bundle:[NSBundle bundleForClass:[ZNGConversationViewController class]]];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        _allowForwarding = YES;
        [self setupKVO];
    }
    
    return self;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self != nil) {
        _allowForwarding = YES;
        [self setupKVO];
    }
    
    return self;
}

- (void) setupKVO
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyNetworkStatusChanged:) name:ZNGNetworkLookoutStatusChanged object:nil];
    
    [self addObserver:self forKeyPath:KVOContactChannelsPath options:NSKeyValueObservingOptionNew context:KVOContext];
    [self addObserver:self forKeyPath:KVOContactCustomFieldsPath options:NSKeyValueObservingOptionNew context:KVOContext];
    [self addObserver:self forKeyPath:KVOChannelPath options:NSKeyValueObservingOptionNew context:KVOContext];
    [self addObserver:self forKeyPath:KVOInputLockedPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:KVOContext];
    [self addObserver:self forKeyPath:KVOReplyingUsersPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:KVOContext];
    [self addObserver:self forKeyPath:KVOTeamAssignment options:NSKeyValueObservingOptionNew context:KVOContext];
    [self addObserver:self forKeyPath:KVOUserAssignment options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:KVOContext];
}

- (void) dealloc
{
    [[ZNGInitialsAvatarCache sharedCache] clearCache];
    
    [self removeObserver:self forKeyPath:KVOUserAssignment context:KVOContext];
    [self removeObserver:self forKeyPath:KVOTeamAssignment context:KVOContext];
    [self removeObserver:self forKeyPath:KVOReplyingUsersPath context:KVOContext];
    [self removeObserver:self forKeyPath:KVOInputLockedPath context:KVOContext];
    [self removeObserver:self forKeyPath:KVOChannelPath context:KVOContext];
    [self removeObserver:self forKeyPath:KVOContactCustomFieldsPath context:KVOContext];
    [self removeObserver:self forKeyPath:KVOContactChannelsPath context:KVOContext];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) weAreSendingOutbound
{
    return YES;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    // Add a custom UILabel to support multi line titles
    titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont latoSemiBoldFontOfSize:18.0];
    titleLabel.textColor = [UIColor zng_lightBlue];
    titleLabel.numberOfLines = 2;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail; // Prevent wrapping since we will manually insert a subtitle with a '\n'
    titleLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = titleLabel;
    
    // Add a tap gesture recognizer to the title to link to the edit view
    UITapGestureRecognizer * titleTapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressedEditContact)];
    titleLabel.userInteractionEnabled = YES;
    [titleLabel addGestureRecognizer:titleTapper];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGServiceToContactViewController class]];
    UINib * typingIndicatorNib = [UINib nibWithNibName:@"ZNGConversationTypingIndicatorCell" bundle:bundle];
    [self.collectionView registerNib:typingIndicatorNib forCellWithReuseIdentifier:TypingIndicatorCellID];
    
    fireZIndex = INT_MAX;
    robotTouchTimes = [[NSMutableArray alloc] initWithCapacity:20];
    
    [self setupBannerContainer];
    
    self.inputToolbar.contentView.textView.placeHolder = @"Type a reply";
    [self.inputToolbar setCurrentChannel:self.conversation.channel];
    
    [self updateInputStatus];
    
    // Delayed message time formatter
    nearFutureTimeFormatter = [[NSDateComponentsFormatter alloc] init];
    nearFutureTimeFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
    nearFutureTimeFormatter.includesApproximationPhrase = YES;
    nearFutureTimeFormatter.allowedUnits = (NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay);
    nearFutureTimeFormatter.formattingContext = NSFormattingContextMiddleOfSentence;
    nearFutureTimeFormatter.maximumUnitCount = 1;
    
    // Avatars
    ZNGInitialsAvatarCache * avatarCache = [ZNGInitialsAvatarCache sharedCache];
    avatarCache.incomingTextColor = self.incomingTextColor;
    avatarCache.outgoingTextColor = self.outgoingTextColor;
    avatarCache.outgoingBackgroundColor = self.outgoingBubbleColor;
    avatarCache.incomingBackgroundColor = self.incomingBubbleColor;
    CGSize avatarSize = CGSizeMake(28.0, 28.0);
    avatarCache.avatarSize = avatarSize;
    avatarCache.font = [UIFont latoSemiBoldFontOfSize:12.0];
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = avatarSize;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = avatarSize;
    
    // Robot touching
    UITapGestureRecognizer * tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(someoneTouchedMyRobot:)];
    UITapGestureRecognizer * tapper2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(someoneTouchedMyRobot:)];
    [self.automationRobot addGestureRecognizer:tapper];
    [self.automationLabel addGestureRecognizer:tapper2];
    self.automationRobot.userInteractionEnabled = YES;
    self.automationLabel.userInteractionEnabled = YES;
    
    // Fix for the robot not existing in iOS 9.0 and earlier
    BOOL noRobotForMe = [[[UIDevice currentDevice] systemVersion] compare:@"9.1" options:NSNumericSearch] == NSOrderedAscending;
    if (noRobotForMe) {
        self.automationRobot.text = @"\U0001F4E1";
    }
    
    // Network status label
    networkStatusLabel = [[ZNGPaddedLabel alloc] init];
    networkStatusLabel.textInsets = UIEdgeInsetsMake(5.0, 0.0, 5.0, 0.0);
    networkStatusLabel.font = [UIFont latoFontOfSize:11.0];
    networkStatusLabel.textColor = [UIColor whiteColor];
    networkStatusLabel.textAlignment = NSTextAlignmentCenter;
    networkStatusLabel.minimumScaleFactor = 0.75;
    networkStatusLabel.adjustsFontSizeToFitWidth = YES;
    networkStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:networkStatusLabel];
    [self notifyNetworkStatusChanged:nil];
    
    // Locked status.
    // This has to be at the end of the current run loop because viewDidLoad does not actually finish loading the view; adjusting constraints here has no effect.  <3 Apple
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateForInputLockedStatus:self.conversation.lockedDescription oldStatus:nil];
    });
    
    NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:networkStatusLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:networkStatusLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint * right = [NSLayoutConstraint constraintWithItem:networkStatusLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    [self.view addConstraints:@[top, left, right]];
    
    // Add forward menu item
    UIMenuItem * forward = [[UIMenuItem alloc] initWithTitle:@"Forward" action:@selector(forwardMessage:)];
    [[UIMenuController sharedMenuController] setMenuItems:@[forward]];
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(forwardMessage:)];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    viewHasAppeared = YES;
    
    if ((self.stuckToBottom) && (self.conversation.contact != nil) && (!self.conversation.contact.isConfirmed)) {
        ZNGLogInfo(@"Confirming contact due to conversation view appearance.");
        [self.conversation.contact confirm];
    }
    
    [self updateTopInset];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateTitle];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == KVOContext) {
        if ([keyPath isEqualToString:KVOChannelPath]) {
            [self updateInputStatus];
        } else if ([keyPath isEqualToString:KVOContactChannelsPath]) {
            [self updateInputStatus];
        } else if ([keyPath isEqualToString:KVOContactCustomFieldsPath]) {
            [self updateTitle];
        } else if ([keyPath isEqualToString:KVOInputLockedPath]) {
            NSString * oldLockedString = change[NSKeyValueChangeOldKey];
            NSString * lockedString = change[NSKeyValueChangeNewKey];
            
            if (![oldLockedString isKindOfClass:[NSString class]]) {
                oldLockedString = nil;
            }
            if (![lockedString isKindOfClass:[NSString class]]) {
                lockedString = nil;
            }
            
            [self updateForInputLockedStatus:lockedString oldStatus:oldLockedString];
        } else if ([keyPath isEqualToString:KVOReplyingUsersPath]) {
            
            switch ([change[NSKeyValueChangeKindKey] intValue]) {
                case NSKeyValueChangeInsertion:
                {
                    NSIndexSet * indexes = change[NSKeyValueChangeIndexesKey];
                    [self.collectionView performBatchUpdates:^{
                        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:ZNGConversationSectionTypingIndicators]]];
                        }];
                    } completion:^(BOOL finished) {
                        if (self.stuckToBottom) {
                            [self scrollToBottomAnimated:YES];
                        }
                    }];
                    break;
                }
                    
                case NSKeyValueChangeRemoval:
                {
                    NSIndexSet * indexes = change[NSKeyValueChangeIndexesKey];
                    [self.collectionView performBatchUpdates:^{
                        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:idx inSection:ZNGConversationSectionTypingIndicators]]];
                        }];
                    } completion:nil];
                    break;
                }
                    
                default:
                    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:ZNGConversationSectionTypingIndicators]];
                    
            }
            
        } else if ([keyPath isEqualToString:KVOTeamAssignment]) {
            [self updateTitle];
        } else if ([keyPath isEqualToString:KVOUserAssignment]) {
            id oldUserIdOrNull = change[NSKeyValueChangeOldKey];
            id userIdOrNull = change[NSKeyValueChangeNewKey];
            NSString * oldUserId = ([oldUserIdOrNull isKindOfClass:[NSString class]]) ? oldUserIdOrNull : nil;
            NSString * userId = ([userIdOrNull isKindOfClass:[NSString class]]) ? userIdOrNull : nil;
            
            if ([userId isEqualToString:oldUserId]) {
                // Same guy.  No need to refresh.
                return;
            }
            
            [self updateTitle];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) notifyNetworkStatusChanged:(NSNotification *)notification
{
    [networkStatusLabel updateWithNetworkStatus:self.conversation.session.networkLookout.status];
    [self updateTopInset];
}

- (void) updateTopInset
{
    CGFloat networkStatusHeight = networkStatusLabel.intrinsicContentSize.height;
    CGFloat topAutomationBannerHeight = (self.automationBannerOnScreenConstraint.active) ? bannerContainer.frame.size.height : 0.0;
    CGFloat topBlockedBannerHeight = (blockedChannelBanner.superview != nil) ? blockedChannelBanner.frame.size.height : 0.0;
    CGFloat topBannerHeight = MAX(topBlockedBannerHeight, topAutomationBannerHeight);
    self.topContentAdditionalInset = MAX(networkStatusHeight, topBannerHeight);
}

- (void) updateForInputLockedStatus:(NSString *)lockedDescription oldStatus:(NSString *)oldLockedDescription
{
    NSAttributedString * oldTopString = [self attributedTextForAutomationBanner:oldLockedDescription];
    NSAttributedString * topString = [self attributedTextForAutomationBanner:lockedDescription];

    // We only set the automation label text if it is not nil.  We want old text to continue to exist as the banner is animated away.
    if ([topString length] > 0) {
        self.automationLabel.attributedText = topString;
    }
    
    BOOL topStatusChanged = (([topString length] == 0) != ([oldTopString length] == 0));
    
    if (topStatusChanged) {
        BOOL automationTextExists = ([topString length] > 0);
        ZNGLogDebug(@"Top automation banner is %@", automationTextExists ? @"appearing" : @"disappearing");
        
        [self updateInputStatus];
        
        [self.automationBannerContainerView layoutSubviews];
        [UIView animateWithDuration:0.5 animations:^{
            self.automationBannerOnScreenConstraint.active = automationTextExists;
            self.automationBannerOffScreenConstraint.active = !automationTextExists;
            [self.automationBannerContainerView layoutSubviews];
        }];
        
        [self updateTopInset];
    }
}

- (void) updateTitle
{
    if ([self.conversation remoteName] == nil) {
        return;
    }
    
    NSMutableAttributedString * title = [[NSMutableAttributedString alloc] initWithString:[self.conversation remoteName]];
    NSMutableAttributedString * subtitle = [self subtitle];
    BOOL deferUpdateToNextRunLoopCycle = NO;
    
    if ([subtitle length] > 0) {
        // Set smaller font/lighter color for subtitle
        NSRange range = NSMakeRange(0, [subtitle length]);
        [subtitle addAttribute:NSFontAttributeName value:[UIFont latoFontOfSize:14.0] range:range];
        [subtitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.58 alpha:1.0] range:range];
        
        // Check if our subtitle will be on a new line (usually) or the same line (iPhone landscape)
        BOOL isPhone = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone);
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        BOOL isLandscape = ((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight));
        BOOL useSingleLine = ((isPhone) && (isLandscape));
        
        if ((useSingleLine != titleWasSingleLineLastUpdate) && (viewHasAppeared)) {
            deferUpdateToNextRunLoopCycle = YES;
        }
        
        titleWasSingleLineLastUpdate = useSingleLine;
        
        if (useSingleLine) {
            // Space before the subtitle
            [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"  "]];
        } else {
            [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
        
        [title appendAttributedString:subtitle];
    }

    // Removing the title label from the navigation item and re-adding it next run loop cycle is necessary when changing
    //  its size to avoid some clipping shenanigans  We will do that if useSingleLine changed above, setting deferUpdateToNextRunLoopCycle.
    self.navigationItem.titleView = nil;
    titleLabel.attributedText = title;
    
    void (^sizeAndPlaceTitle)(void) = ^{
        CGSize size = [self->titleLabel intrinsicContentSize];
        self->titleLabel.frame = CGRectMake(0.0, 0.0, size.width, size.height);
        self.navigationItem.titleView = self->titleLabel;
    };
    
    if (deferUpdateToNextRunLoopCycle) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), sizeAndPlaceTitle);
    } else {
        sizeAndPlaceTitle();
    }
}

- (NSMutableAttributedString *) subtitle
{
    if (![self.conversation.session.service allowsAssignment]) {
        // This service does not have assignment enabled.  No subtitle.
        return nil;
    }
    
    if ([self.conversation.contact.assignedToTeamId length] > 0) {
        ZNGTeam * team = [self.conversation.session.service teamWithId:self.conversation.contact.assignedToTeamId];
        
        if (team != nil) {
            return [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Assigned to %@", team.displayName]];
        } else {
            return [[NSMutableAttributedString alloc] initWithString:@"Assigned to a team"];
        }
    }
    
    if ([self.conversation.contact.assignedToUserId length] > 0) {
        ZNGUser * user = [self.conversation.session userWithId:self.conversation.contact.assignedToUserId];
        
        if (user != nil) {
            NSMutableAttributedString * name = [[NSMutableAttributedString alloc] init];
            
            if ([user.userId isEqualToString:self.conversation.session.userAuthorization.userId]) {
                [name appendAttributedString:[[NSAttributedString alloc] initWithString:@"Assigned to You"]];
            } else {
                [name appendAttributedString:[[NSAttributedString alloc] initWithString:@"Assigned to "]];
                [name appendAttributedString:[[NSAttributedString alloc] initWithString:[user fullName]]];
            }
            
            return name;
        } else {
            return [[NSMutableAttributedString alloc] initWithString:@"Assigned to a teammate"];
        }
    }
    
    return [[NSMutableAttributedString alloc] initWithString:@"Unassigned"];
}

- (NSString *) commaAndifiedString:(NSArray<NSString *> *)components
{
    if ([components count] == 0) {
        return nil;
    }
    
    if ([components count] == 1) {
        return [components firstObject];
    }
    
    NSMutableString * string = [[NSMutableString alloc] initWithString:[components firstObject]];
    
    for (NSUInteger i=1; i < [components count]; i++) {
        NSString * component = components[i];
        
        if (i == [components count] - 1) {
            NSString * maybeOxfordComma = ([components count] != 2) ? @"," : @"";
            [string appendFormat:@"%@ and %@", maybeOxfordComma, component];
        } else {
            [string appendFormat:@", %@", component];
        }
    }
    
    return string;
}

- (NSAttributedString *) attributedTextForAutomationBanner:(NSString *)description
{
    NSRange inAutomationRange = [description rangeOfString:@"in automation:" options:NSCaseInsensitiveSearch];
    
    if ((description == nil) || (inAutomationRange.location == NSNotFound)) {
        // This is not an 'in automation' lock string
        return nil;
    }
    
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] initWithString:description];
    
    NSUInteger firstBoldIndex = inAutomationRange.location + inAutomationRange.length;
    NSRange rangeToBoldify;
    
    // Bold the automation name
    if (firstBoldIndex < [description length]) {
        rangeToBoldify = NSMakeRange(firstBoldIndex, [description length] - firstBoldIndex);
        
        UIFont * normalFont = self.automationLabel.font ?: [UIFont systemFontOfSize:15.0];
        UIFont * boldFont = [UIFont latoBoldFontOfSize:normalFont.pointSize];
        [attributedString addAttribute:NSFontAttributeName value:boldFont range:rangeToBoldify];
    }
    
    return attributedString;
}

- (ZNGContact *) contact
{
    ZNGConversationServiceToContact * conversation = (ZNGConversationServiceToContact *)self.conversation;
    return conversation.contact;
}

- (void) setStuckToBottom:(BOOL)stuckToBottom
{
    BOOL wasStuck = self.stuckToBottom;
    
    if (wasStuck != stuckToBottom) {
        [super setStuckToBottom:stuckToBottom];
        
        // Mark the conversation read (confirmed) if we are just scrolling down
        if ((stuckToBottom) && (self.conversation.contact != nil) && (!self.conversation.contact.isConfirmed)) {
            ZNGLogInfo(@"Marking conversation as read due to scroll to bottom.");
            [self.conversation.contact confirm];
        }
    }
}

- (void) setConversation:(ZNGConversationServiceToContact *)conversation
{
    [super setConversation:conversation];
    
    // Do we need to mark this conversation as read?
    if ((self.stuckToBottom) && (!conversation.contact.isConfirmed)) {
        ZNGLogInfo(@"Marking conversation as read on load.");
        [conversation.contact confirm];
    }
}

#pragma mark - Easter eggs
- (void) smoulderAtPoint:(CGPoint)point
{
    CAEmitterLayer * smoulderer = [CAEmitterLayer layer];
    smoulderer.frame = self.view.layer.bounds;
    smoulderer.renderMode = kCAEmitterLayerAdditive;
    smoulderer.beginTime = CACurrentMediaTime();
    smoulderer.zPosition = fireZIndex--;
    
    smoulderer.emitterPosition = point;
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGServiceToContactViewController class]];
    UIImage * particle = [UIImage imageNamed:@"particle" inBundle:bundle compatibleWithTraitCollection:nil];
    
    CAEmitterCell * cell = [CAEmitterCell emitterCell];
    cell.birthRate = 75;
    cell.lifetime = 3.0;
    cell.lifetimeRange = 0.5;
    cell.color = [[UIColor colorWithRed:0.8 green:0.4 blue:0.2 alpha:0.1]
                  CGColor];
    cell.contents = (id)[particle CGImage];
    cell.velocity = 10;
    cell.velocityRange = 20;
    cell.emissionRange = 2.0 * M_PI;
    cell.scale = 0.25;
    cell.scaleSpeed = 0.25;
    cell.spin = 0.0;
    cell.spinRange = 1.0;
    cell.name = @"fire";
    
    smoulderer.emitterCells = @[ cell ];
    
    
    [self.view.layer addSublayer:smoulderer];
    
    
    NSTimeInterval lifetime = 1.0 + (arc4random() % 5);
    
    // Set birth rate to 0, wait for last cells to expire (lifetime + lifetimeRange), then remove emitter layer
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(lifetime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [smoulderer setValue:@(0.0) forKeyPath:@"emitterCells.fire.birthRate"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((cell.lifetime + cell.lifetimeRange) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [smoulderer removeFromSuperlayer];
        });
    });
}

- (void) someoneTouchedMyRobot:(UITapGestureRecognizer *)tapper
{
    [robotTouchTimes addObject:[NSDate date]];
    
    if ([robotTouchTimes count] > 18) {
        [robotTouchTimes removeObjectAtIndex:0];
    }
    
    if ([self robotShouldShoot]) {
        [[ZNGAnalytics sharedAnalytics] trackEasterEggNamed:@"Automation robot ACTIVATE LASER EYES"];
        [self activateLaserRobotEyes];
        return;
    }
    
    [[ZNGAnalytics sharedAnalytics] trackEasterEggNamed:@"Automation robot was tickled"];
    [self vibrateRobot];
}

- (void) vibrateRobot
{
    static NSString * const vibrationKey = @"vibrate";
    
    // Make sure he is not already vibrating
    if ([self.automationRobot.layer animationForKey:vibrationKey] != nil) {
        return;
    }
    
    // Vibrate away
    CAKeyframeAnimation * vibration = [[CAKeyframeAnimation alloc] init];
    vibration.keyPath = @"transform";
    
    CATransform3D leftVibrateTransform = CATransform3DMakeTranslation(-2.0, 0.0, 0.0);
    CATransform3D rightVibrateTransform = CATransform3DMakeTranslation(2.0, 0.0, 0.0);
    
    NSValue * leftVibrate = [NSValue valueWithCATransform3D:leftVibrateTransform];
    NSValue * rightVibrate = [NSValue valueWithCATransform3D:rightVibrateTransform];
    
    vibration.values = @[ leftVibrate, rightVibrate, leftVibrate, rightVibrate, leftVibrate, rightVibrate, leftVibrate, rightVibrate, leftVibrate, rightVibrate ];
    
    vibration.duration = 0.5;
    
    [self.automationRobot.layer addAnimation:vibration forKey:vibrationKey];
}

- (void) vigorouslyVibrateRobotForDuration:(NSTimeInterval)duration
{
    static NSString * const vibrationKey = @"vibrate";

    // Vibrate away
    CAKeyframeAnimation * vibration = [[CAKeyframeAnimation alloc] init];
    vibration.keyPath = @"transform";
    
    CATransform3D leftVibrateTransform = CATransform3DMakeTranslation(-4.0, 0.0, 0.0);
    CATransform3D rightVibrateTransform = CATransform3DMakeTranslation(4.0, 0.0, 0.0);
    
    NSValue * leftVibrate = [NSValue valueWithCATransform3D:leftVibrateTransform];
    NSValue * rightVibrate = [NSValue valueWithCATransform3D:rightVibrateTransform];
    
    vibration.values = @[ leftVibrate, rightVibrate, leftVibrate, rightVibrate, leftVibrate, rightVibrate, leftVibrate, rightVibrate, leftVibrate, rightVibrate ];
    
    vibration.duration = 0.5;
    vibration.repeatCount = (duration / vibration.duration) - 1.0;
    
    [self.automationRobot.layer addAnimation:vibration forKey:vibrationKey];
}

- (BOOL) robotShouldShoot
{
    // Has he shot his load too recently?
    if (lastRobotVolleyTime != nil) {
        NSTimeInterval timeSinceLastVolley = [[NSDate date] timeIntervalSinceDate:lastRobotVolleyTime];
        
        if (timeSinceLastVolley < 30.0) {
            return NO;
        }
    }
    
    // Have they touched him enough to make it happen?
    if ([robotTouchTimes count] < 5) {
        return NO;
    }
    
    NSUInteger fifthMostRecentTouchTimeIndex = [robotTouchTimes count] - 5;
    NSDate * fifthMostRecentTouchTime = robotTouchTimes[fifthMostRecentTouchTimeIndex];
    NSTimeInterval spamTimeInterval = [[NSDate date] timeIntervalSinceDate:fifthMostRecentTouchTime];
    
    if (spamTimeInterval > 5.0) {
        // Not fast enough
        return NO;
    }
    
    // 10% chance
    return ((arc4random() % 10) == 0);
}

- (void) shootParticlesIntoPoint:(CGPoint)point forDuration:(NSTimeInterval)duration
{
    NSTimeInterval particleLifetime = 0.75;
    
    if (duration < particleLifetime) {
        ZNGLogError(@"Particle lifetime of %.2f seconds is too long to exist within the %.2f second duration.", particleLifetime, duration);
        return;
    }
    
    NSUInteger particleRatePerSecond = 30;
    NSTimeInterval lastParticleBirthTime = duration - particleLifetime; // Our duration, allowing enough time for all particles to disipiate before our duration
    NSTimeInterval timeInbetweenParticles = 1.0 / (NSTimeInterval)particleRatePerSecond;
    NSTimeInterval time = 0.0;
    CGFloat particleBirthRadius = 75.0;
    CGFloat particleRadius = 2.0;
    
    UIColor * particleColor = [UIColor colorFromHexString:@"#e1a003"];
    
    CABasicAnimation * fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.fromValue = @0.2;
    fadeIn.toValue = @1.0;
    fadeIn.duration = 0.2;
    fadeIn.removedOnCompletion = NO;
    
    while (time < lastParticleBirthTime) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Vary particle distance within 10pt of edge of radius
            CGFloat centerDistance = (arc4random() % 20 + 10) + particleBirthRadius;
            
            // Random direction in 360 degrees
            CGFloat angle = M_PI * (arc4random() % 360) / 180.0;
            CGFloat dx = centerDistance * cos(angle);
            CGFloat dy = centerDistance * sin(angle);
            CGPoint particleStartingPoint = CGPointMake(point.x + dx, point.y + dy);
            
            CGRect startingRect = CGRectMake(particleStartingPoint.x - particleRadius, particleStartingPoint.y - particleRadius, particleRadius * 2.0, particleRadius * 2.0);
            
            CAShapeLayer * particle = [CAShapeLayer layer];
            UIBezierPath * path = [UIBezierPath bezierPathWithOvalInRect:startingRect];
            particle.path = [path CGPath];
            particle.fillColor = [particleColor CGColor];
            
            CABasicAnimation * move = [CABasicAnimation animationWithKeyPath:@"position"];
            move.fromValue = [NSValue valueWithCGPoint:particleStartingPoint];
            move.toValue = [NSValue valueWithCGPoint:CGPointMake(-dx, -dy)];
            move.duration = particleLifetime;
            move.removedOnCompletion = NO;
            [particle addAnimation:move forKey:@"move"];
            [particle addAnimation:fadeIn forKey:@"fadeIn"];
            [self.view.layer addSublayer:particle];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(particleLifetime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [particle removeFromSuperlayer];
            });
        });
        
        time += timeInbetweenParticles;
    }
}

- (void) activateLaserRobotEyes
{
    lastRobotVolleyTime = [NSDate date];
    
    NSTimeInterval buildUpTime = 2.0;
    
    [self vigorouslyVibrateRobotForDuration:buildUpTime];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(buildUpTime * 0.95 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGPoint robotCenter = [self.view convertPoint:self.automationRobot.center fromView:self.automationRobot.superview];
        CGPoint leftEyeCenter = CGPointMake(robotCenter.x - 3.5, robotCenter.y);
        CGPoint rightEyeCenter = CGPointMake(leftEyeCenter.x + 7.0, leftEyeCenter.y);
        CGRect leftEyeRect = CGRectMake(leftEyeCenter.x - 3.0, leftEyeCenter.y - 3.0, 6.0, 6.0);
        CGRect rightEyeRect = CGRectMake(rightEyeCenter.x - 3.0, rightEyeCenter.y - 3.0, 6.0, 6.0);
        
        CAShapeLayer * leftEyeCircle = [CAShapeLayer layer];
        leftEyeCircle.opacity = 0.0;
        [leftEyeCircle setPath:[[UIBezierPath bezierPathWithOvalInRect:leftEyeRect] CGPath]];
        [leftEyeCircle setFillColor:[[UIColor redColor] CGColor]];
        [self.view.layer addSublayer:leftEyeCircle];
        
        CAShapeLayer * rightEyeCircle = [CAShapeLayer layer];
        rightEyeCircle.opacity = 0.0;
        [rightEyeCircle setPath:[[UIBezierPath bezierPathWithOvalInRect:rightEyeRect] CGPath]];
        [rightEyeCircle setFillColor:[[UIColor redColor] CGColor]];
        [self.view.layer addSublayer:rightEyeCircle];
        
        
        NSTimeInterval eyeLightUpDuration = 3.0;
        
        CABasicAnimation * eyeCircleFadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
        eyeCircleFadeIn.duration = eyeLightUpDuration;
        eyeCircleFadeIn.fromValue = @0.0;
        eyeCircleFadeIn.toValue = @1.0;
        [leftEyeCircle addAnimation:eyeCircleFadeIn forKey:@"opacity"];
        [rightEyeCircle addAnimation:eyeCircleFadeIn forKey:@"opacity"];
        
        [self shootParticlesIntoPoint:leftEyeCenter forDuration:eyeLightUpDuration];
        [self shootParticlesIntoPoint:rightEyeCenter forDuration:eyeLightUpDuration];
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(eyeLightUpDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [leftEyeCircle removeFromSuperlayer];
            [rightEyeCircle removeFromSuperlayer];
            
            // First we want to find a random destination point somewhere near the center of the screen (inner 66%)
            CGFloat minX = self.view.layer.bounds.size.width * 0.33;
            CGFloat maxX = self.view.layer.bounds.size.width * 0.66;
            CGFloat minY = self.view.layer.bounds.size.height * 0.33;
            CGFloat maxY = self.view.layer.bounds.size.height * 0.66;
            
            CGFloat x = arc4random() % (uint32_t)(maxX - minX) + (uint32_t)minX;
            CGFloat y = arc4random() % (uint32_t)(maxY - minY) + (uint32_t)minY;
            CGPoint point = CGPointMake(x, y);
            
            
            // White flash
            CALayer * whiteFlash = [CALayer layer];
            whiteFlash.frame = self.view.layer.bounds;
            whiteFlash.backgroundColor = [[UIColor whiteColor] CGColor];
            [self.view.layer addSublayer:whiteFlash];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [whiteFlash removeFromSuperlayer];
            });
            
            
            // Make the lasers
            CGFloat initialLaserOpacity = 0.2;
            CGFloat initialLaserWidth = 1.0;
            CGFloat finalLaserWidth = 6.0;
            CAShapeLayer * leftLaser = [CAShapeLayer layer];
            leftLaser.opacity = initialLaserOpacity;
            UIBezierPath * leftLaserPath = [UIBezierPath bezierPath];
            [leftLaserPath moveToPoint:leftEyeCenter];
            [leftLaserPath addLineToPoint:point];
            leftLaser.path = [leftLaserPath CGPath];
            leftLaser.strokeColor = [[UIColor redColor] CGColor];
            leftLaser.lineWidth = initialLaserWidth;
            [self.view.layer addSublayer:leftLaser];
            
            CAShapeLayer * rightLaser = [CAShapeLayer layer];
            rightLaser.opacity = initialLaserOpacity;
            UIBezierPath * rightLaserPath = [UIBezierPath bezierPath];
            [rightLaserPath moveToPoint:rightEyeCenter];
            [rightLaserPath addLineToPoint:point];
            rightLaser.path = [rightLaserPath CGPath];
            rightLaser.strokeColor = [[UIColor redColor] CGColor];
            rightLaser.lineWidth = initialLaserWidth;
            [self.view.layer addSublayer:rightLaser];
            
            
            // Grow them over two seconds
            CGFloat fadeInDuration = 1.0;
            CABasicAnimation * laserFadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            laserFadeIn.duration = fadeInDuration;
            laserFadeIn.fromValue = @(initialLaserOpacity);
            laserFadeIn.toValue = @1.0;
            [leftLaser addAnimation:laserFadeIn forKey:@"fade"];
            [rightLaser addAnimation:laserFadeIn forKey:@"fade"];
            
            CABasicAnimation * laserGrow = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
            laserGrow.duration = fadeInDuration;
            laserGrow.fromValue = @(initialLaserWidth);
            laserGrow.toValue = @(finalLaserWidth);
            [leftLaser addAnimation:laserGrow forKey:@"fade"];
            [rightLaser addAnimation:laserGrow forKey:@"fade"];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self smoulderAtPoint:point];
            });
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fadeInDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [rightLaser removeFromSuperlayer];
                [leftLaser removeFromSuperlayer];
            });
        });
        
    });
}

#pragma mark - Button items
- (NSArray<UIAlertAction *> *)alertActionsForDetailsButton
{
    NSArray<UIAlertAction *> * superActions = [super alertActionsForDetailsButton];
    NSMutableArray<UIAlertAction *> * actions = ([superActions count] > 0) ? [superActions mutableCopy] : [[NSMutableArray alloc] init];
    
    NSString * uiType = @"ellipsis menu";
    
    if ([self.conversation.session.service allowsAssignment]) {
        UIAlertAction * assign = [UIAlertAction actionWithTitle:@"Assign" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self performSegueWithIdentifier:@"assign" sender:self];
        }];
        [actions addObject:assign];
    }
    
    UIAlertAction * editContact = [UIAlertAction actionWithTitle:@"View / edit contact" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self pressedEditContact];
    }];
    [actions addObject:editContact];
    
    BOOL alreadyConfirmed = self.conversation.contact.isConfirmed;
    NSString * confirmOrUnconfirmString = alreadyConfirmed ? @"Mark unread" : @"Mark read";
    UIAlertAction * confirm = [UIAlertAction actionWithTitle:confirmOrUnconfirmString style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (alreadyConfirmed) {
            [self.conversation.contact unconfirm];
            [[ZNGAnalytics sharedAnalytics] trackUnconfirmedContact:self.conversation.contact fromUIType:uiType];
        } else {
            [self.conversation.contact confirm];
            [[ZNGAnalytics sharedAnalytics] trackConfirmedContact:self.conversation.contact fromUIType:uiType];
        }
    }];
    [actions addObject:confirm];
    
    BOOL alreadyClosed = self.conversation.contact.isClosed;
    NSString * closeOrOpenString = alreadyClosed ? @"Open conversation" : @"Close conversation";
    UIAlertAction * closeOrOpen = [UIAlertAction actionWithTitle:closeOrOpenString style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (alreadyClosed) {
            [self.conversation.contact reopen];
            [[ZNGAnalytics sharedAnalytics] trackOpenedContact:self.conversation.contact fromUIType:uiType];
        } else {
            [self.conversation.contact close];
            [[ZNGAnalytics sharedAnalytics] trackClosedContact:self.conversation.contact fromUIType:uiType];
        }
    }];
    [actions addObject:closeOrOpen];
    
    BOOL alreadyShowingDetailedEvents = [self.conversation isKindOfClass:[ZNGConversationDetailedEvents class]];
    NSString * detailedEventsText = (alreadyShowingDetailedEvents) ? @"Hide detailed events" : @"Show detailed events";
    UIAlertAction * toggleDetailedEvents = [UIAlertAction actionWithTitle:detailedEventsText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (alreadyShowingDetailedEvents) {
            self.conversation = [[ZNGConversationServiceToContact alloc] initWithConversation:self.conversation];
            [[ZNGAnalytics sharedAnalytics] trackHidConversationDetails:self.conversation];
        } else {
            self.conversation = [[ZNGConversationDetailedEvents alloc] initWithConversation:self.conversation];
            [[ZNGAnalytics sharedAnalytics] trackShowedConversationDetails:self.conversation];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ZingleUserChangedDetailedEventsPreferenceNotification object:@(!alreadyShowingDetailedEvents)];
        [self.conversation loadRecentEventsErasingOlderData:YES];
    }];
    [actions addObject:toggleDetailedEvents];
    
    return actions;
}

- (NSString * _Nullable) nameForMessageAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGUser * typingIndicatorUser = [[self pendingResponseForTypingIndicatorAtIndexPath:indexPath] user];
    
    if (typingIndicatorUser != nil) {
        return [typingIndicatorUser fullName];
    }
    
    if (![self shouldShowSenderInfoForIndexPath:indexPath]) {
        return nil;
    }
    
    ZNGEvent * event = [[self eventViewModelAtIndexPath:indexPath] event];
    
    BOOL isOutboundMessage = ([event isMessage] && [event.message isOutbound]);
    BOOL isInternalNote = [event isNote];
    
    // We will show an employee name for every outbound message and note
    if (isOutboundMessage || isInternalNote) {
        return event.senderDisplayName ?: @"";
    }
    
    // This is probably an incoming message.  The contact's name is in the title bar; we do not need one above message bubbles.
    return nil;
}

#pragma mark - Confirmed banner
- (void) setupBannerContainer
{
    bannerContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 30.0)];
    bannerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    bannerContainer.layer.masksToBounds = YES;
    bannerContainer.userInteractionEnabled = NO;
    
    NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:bannerContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint * width = [NSLayoutConstraint constraintWithItem:bannerContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:bannerContainer attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint * height = [NSLayoutConstraint constraintWithItem:bannerContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:30.0];
    
    [self.view addSubview:bannerContainer];
    [self.view addConstraints:@[top, width, left, height]];
}

/**
 *  Enables/disables input appropriately for the current channel selection and its blocked status
 */
- (void) updateInputStatus
{
    BOOL shouldDisableInput = NO;
    
    if ([self.conversation.contact.channels count] == 0) {
        self.inputToolbar.noSelectedChannelText = @"No channels available";
        shouldDisableInput = YES;
    } else if (![self.conversation.contact.channels containsObject:self.conversation.channel]) {
        // Our channel disappeared
        ZNGLogWarn(@"Currently selected channel is not present in the contact data.  Deselecting.");
        self.inputToolbar.noSelectedChannelText = @"Select a channel";
        shouldDisableInput = YES;
    }
    
    self.inputToolbar.currentChannel = self.conversation.channel;
    BOOL someKindOfBlock = (self.conversation.channel.blockOutbound || self.conversation.channel.blockInbound);
    
    if (!someKindOfBlock) {
        // Do we need to remove previous UI for a blocked channel?
        if (blockedChannelBanner.superview != nil) {
            // Remove this pre-existing banner
            [bannerContainer layoutIfNeeded];
            
            [UIView animateWithDuration:0.5 animations:^{
                [self->bannerContainer removeConstraint:self->blockedChannelOnScreenConstraint];
                [self->bannerContainer addConstraint:self->blockedChannelOffScreenConstraint];
                [self->bannerContainer layoutIfNeeded];
            } completion:^(BOOL finished) {
                [self->blockedChannelBanner removeFromSuperview];
                self->blockedChannelBanner = nil;
            }];
        }
    } else {
        NSString * text;
        
        if (bannerContainer == nil) {
            // Our view has not yet loaded.  We'll be back here in a moment, courtesy of viewDidLoad
            return;
        }
        
        if (self.conversation.channel.blockInbound) {
            if (self.conversation.channel.blockOutbound) {
                shouldDisableInput = YES;
                text = @"INBOUND AND OUTBOUND MESSAGES BLOCKED";
            } else {
                text = @"INBOUND MESSAGES FROM CONTACT BLOCKED";
            }
        } else {
            shouldDisableInput = YES;
            text = @"OUTBOUND MESSAGES TO CONTACT BLOCKED";
        }
        
        if (blockedChannelBanner.superview != nil) {
            // There is already a banner.  Update its text.
            blockedChannelLabel.text = text;
        } else {
            // We need to show a new banner
            CGRect rect = CGRectMake(0.0, 0.0, bannerContainer.frame.size.width, bannerContainer.frame.size.height);
            blockedChannelBanner = [[UIView alloc] initWithFrame:rect];
            blockedChannelBanner.translatesAutoresizingMaskIntoConstraints = NO;
            blockedChannelBanner.backgroundColor = [UIColor zng_strawberry];
            NSLayoutConstraint * height = [NSLayoutConstraint constraintWithItem:blockedChannelBanner attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:bannerContainer attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
            NSLayoutConstraint * width = [NSLayoutConstraint constraintWithItem:blockedChannelBanner attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:bannerContainer attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
            NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:blockedChannelBanner attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:bannerContainer attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
            blockedChannelOffScreenConstraint = [NSLayoutConstraint constraintWithItem:blockedChannelBanner attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bannerContainer attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
            blockedChannelOnScreenConstraint = [NSLayoutConstraint constraintWithItem:blockedChannelBanner attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:bannerContainer attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
            [bannerContainer addSubview:blockedChannelBanner];
            [bannerContainer addConstraints:@[height, width, left, blockedChannelOffScreenConstraint]];
            
            blockedChannelLabel = [[UILabel alloc] initWithFrame:rect];
            blockedChannelLabel.textAlignment = NSTextAlignmentCenter;
            blockedChannelLabel.font = [UIFont latoBoldFontOfSize:13.0];
            blockedChannelLabel.textColor = [UIColor whiteColor];
            blockedChannelLabel.text = text;
            blockedChannelLabel.translatesAutoresizingMaskIntoConstraints = NO;
            NSLayoutConstraint * centerX = [NSLayoutConstraint constraintWithItem:blockedChannelLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:blockedChannelBanner attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
            NSLayoutConstraint * centerY = [NSLayoutConstraint constraintWithItem:blockedChannelLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:blockedChannelBanner attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
            [blockedChannelBanner addSubview:blockedChannelLabel];
            [blockedChannelBanner addConstraints:@[centerX, centerY]];
            
            // Animate on screen
            [bannerContainer layoutIfNeeded];
            
            [UIView animateWithDuration:0.5 animations:^{
                [self->bannerContainer removeConstraint:self->blockedChannelOffScreenConstraint];
                [self->bannerContainer addConstraint:self->blockedChannelOnScreenConstraint];
                [self->bannerContainer layoutIfNeeded];
            } completion:nil];
        }
    }
    
    // Lock input if there is an automation lock message
    NSAttributedString * automationLockText = [self attributedTextForAutomationBanner:self.conversation.lockedDescription];
    shouldDisableInput |= ([automationLockText length] > 0);
    
    self.inputToolbar.inputEnabled = !shouldDisableInput;
}

#pragma mark - Collection view shenanigans
- (BOOL) shouldShowTimestampAboveIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    
    if ((![viewModel.event isMessage]) && (![viewModel.event isNote])) {
        // This is some kind of detailed event or typing indicator.  No timestamp.
        return NO;
    }
    
    BOOL shouldShowTimestamp = [super shouldShowTimestampAboveIndexPath:indexPath];
    
    if (!shouldShowTimestamp) {
        // Our super implementation does not require a timestamp here (i.e. it has been less than five minutes since the last message.)
        // We will still wish to do so if message channels have changed.
        shouldShowTimestamp = [self contactChannelAtIndexPathChangedSincePriorMessage:indexPath];
    }
    
    return shouldShowTimestamp;
}

- (BOOL) shouldShowChannelInfoUnderTimestamps
{
    return ([[self.conversation usedChannels] count] > 1);
}

- (BOOL) contactChannelAtIndexPathChangedSincePriorMessage:(NSIndexPath *)indexPath
{
    if (indexPath.section != ZNGConversationSectionMessages) {
        return NO;
    }
    
    ZNGEvent * event = [[self eventViewModelAtIndexPath:indexPath] event];
    ZNGEvent * priorEvent = [self.conversation priorEvent:event];
    
    // Have channels changed?
    ZNGChannel * thisChannel = [[event.message contactCorrespondent] channel];
    ZNGChannel * priorChannel = [[priorEvent.message contactCorrespondent] channel];
    
    if ((thisChannel != nil) && (priorChannel != nil) && (![thisChannel isEqual:priorChannel])) {
        // The channel has changed!
        return YES;
    }
    
    return NO;
}

/**
 *  Returns YES if the sender name/avatar should be shown based on adjacent messages.
 *  (There is either a message from a different sender below this message, there is a timestamp on the message below this one, or
 *   this is a typing indicator.)
 */
- (BOOL) shouldShowSenderInfoForIndexPath:(NSIndexPath *)indexPath
{
    // Always show user info for typing indicators
    if (indexPath.section == ZNGConversationSectionTypingIndicators) {
        return YES;
    }
    
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];

    // If this is not a message nor a note, we do not have sender info
    if ((![viewModel.event isMessage]) && (![viewModel.event isNote])) {
        return NO;
    }
    
    // Is this the last message?
    if (indexPath.row == ([self.conversation.eventViewModels count] - 1)) {
        return YES;
    }
    
    ZNGEventViewModel * nextViewModel = [self nextEventViewModelBelowIndexPath:indexPath];
    
    NSString * thisSenderId = [viewModel.event.message senderPersonId];
    NSString * nextSenderId = [nextViewModel.event.message senderPersonId];
    
    // Different person?
    if (![thisSenderId isEqualToString:nextSenderId]) {
        return YES;
    }
    
    // Is there a timestamp between us and the next message?
    if ([self shouldShowTimestampAboveIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]]) {
        return YES;
    }
    
    // This message is part of a similar group.  No sender info needed.
    return NO;
}

- (id<JSQMessageAvatarImageDataSource>) initialsAvatarForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGUser * typingIndicatorUser = [[self pendingResponseForTypingIndicatorAtIndexPath:indexPath] user];
    
    // If this cell is a typing indicator, we have the user data immediately available.
    if (typingIndicatorUser != nil) {
        return [[ZNGInitialsAvatarCache sharedCache] avatarForUserUUID:typingIndicatorUser.userId nameForFallbackAvatar:[typingIndicatorUser fullName] outgoing:YES];
    }
    
    if (![self shouldShowSenderInfoForIndexPath:indexPath]) {
        return nil;
    }
    
    ZNGEvent * event = [[self eventViewModelAtIndexPath:indexPath] event];
    
    NSString * senderUUID = event.message.triggeredByUser.userId ?: [event senderId];
    NSString * name;
    
    if (([event isMessage]) && (![event.message isOutbound])) {
        // Inbound
        NSString * firstName = [[self.conversation.contact firstNameFieldValue] value] ?: @"";
        NSString * lastName = [[self.conversation.contact lastNameFieldValue] value] ?: @"";
        
        NSUInteger nameLength = [firstName length] + [lastName length];
        
        if (nameLength > 0) {
            name = [[NSString stringWithFormat:@"%@ %@", firstName, lastName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        } else {
            // We do not have a name for this contact.
            NSBundle * bundle = [NSBundle bundleForClass:[ZNGServiceToContactViewController class]];
            UIImage * avatarImage = [UIImage imageNamed:@"anonymousAvatar" inBundle:bundle compatibleWithTraitCollection:nil];
            
            return [[ZNGInitialsAvatarCache sharedCache] avatarForUserUUID:senderUUID fallbackImage:avatarImage useCircleBackground:NO outgoing:NO];
        }
    } else {
        // Outbound.
        NSString * robotName =  @"\U0001F916";   // Robot face emoji
        
        // Robot face did not exist prior to iOS 9.1.  Use a satellite antenna for earlier.
        BOOL noRobotForMe = [[[UIDevice currentDevice] systemVersion] compare:@"9.1" options:NSNumericSearch] == NSOrderedAscending;
        if (noRobotForMe) {
            robotName = @"\U0001F4E1";  // Satellite antenna emoji
        }
        
        // Is it from us?  (current user)
        if (event.sending) {
            name = [self.conversation.session.userAuthorization displayName];
            senderUUID = self.conversation.session.userAuthorization.userId;
        } else {
            // If it's an automation, use the robot
            if (event.automation.automationId != nil) {
                name = robotName;
                senderUUID = event.automation.automationId;
            } else {
                // Find who triggered the event and use their name.
                name = [event.triggeredByUser fullName];
                
                if ([name length] == 0) {
                    // We have no triggering user.  Robot it is.
                    name = robotName;
                }
            }
        }
    }
    
    return [[ZNGInitialsAvatarCache sharedCache] avatarForUserUUID:senderUUID nameForFallbackAvatar:name outgoing:[self isOutgoingMessage:event]];
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ZNGConversationSectionTypingIndicators) {
        return [self pendingResponseForTypingIndicatorAtIndexPath:indexPath];
    }
    
    return [super collectionView:collectionView messageDataForItemAtIndexPath:indexPath];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // Typing indicators have no top text
    if (indexPath.section == ZNGConversationSectionTypingIndicators) {
        return nil;
    }
    
    NSAttributedString * attributedString = [super collectionView:collectionView attributedTextForCellTopLabelAtIndexPath:indexPath];
    
    // Check if we are showing a timestamp (i.e. super returned a string) and we want to display channel info (i.e. this user has more than one channel available)
    if (([attributedString length] > 0) && ([self shouldShowChannelInfoUnderTimestamps])) {
        ZNGEvent * event = [[self eventViewModelAtIndexPath:indexPath] event];
        ZNGChannel * channel = [[event.message contactCorrespondent] channel];
        
        if (channel != nil) {
            
            // Find a more complete copy of this channel object from the contact object if possible.
            for (ZNGChannel * testChannel in self.conversation.contact.channels) {
                if ([testChannel.channelId isEqualToString:channel.channelId]) {
                    channel = testChannel;
                    break;
                }
            }
            
            NSString * channelString = [self.conversation.service shouldDisplayRawValueForChannel:channel] ? [channel displayValueUsingRawValue] : [channel displayValueUsingFormattedValue];

            if ([channelString length] == 0) {
                channelString = @"Unknown channel";
                ZNGLogWarn(@"Channel display value is missing for channel %@", channel.channelId);
            }
            
            NSString * displayString = [NSString stringWithFormat:@"\n%@",channelString];
            NSDictionary * attributes = @{ NSFontAttributeName : [UIFont latoFontOfSize:10.0] };
            NSAttributedString * attributedChannelString = [[NSAttributedString alloc] initWithString:displayString attributes:attributes];
            NSMutableAttributedString * mutableString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
            [mutableString appendAttributedString:attributedChannelString];
            attributedString = mutableString;
        }
    }
    
    return attributedString;
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return ZNGConversationSectionCount;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == ZNGConversationSectionTypingIndicators) {
        return [self.conversation.pendingResponses count];
    }
    
    return [super collectionView:collectionView numberOfItemsInSection:section];
}

- (BOOL) collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (indexPath.section != ZNGConversationSectionMessages) {
        return NO;
    }
    
    if (action == @selector(forwardMessage:)) {
        ZNGEvent * event = [[self eventViewModelAtIndexPath:indexPath] event];
        return (self.allowForwarding && event.isMessage && !event.message.isOutbound);
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void) collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(forwardMessage:)) {
        ZNGMessage * message = [[[self eventViewModelAtIndexPath:indexPath] event] message];
        
        if (message != nil) {
            [self _doForwardMessage:message];
        }
    } else {
        [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
    }
}

// If the provided index path represents a typing indicator, this will return the corresponding user.  Otherwise it returns nil.
- (ZNGPendingResponseOrNote *) pendingResponseForTypingIndicatorAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != ZNGConversationSectionTypingIndicators) {
        return nil;
    }
    
    if (indexPath.row >= [self.conversation.pendingResponses count]) {
        ZNGLogError(@"Out of bounds retrieving user at index %lld in our %llu currently replying users.", (long long)indexPath.row, (unsigned long long)[self.conversation.pendingResponses count]);
        return nil;
    }
    
    return self.conversation.pendingResponses[indexPath.row];
}

- (ZNGEventViewModel *) eventViewModelAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != ZNGConversationSectionMessages) {
        return nil;
    }
    
    return [super eventViewModelAtIndexPath:indexPath];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ZNGConversationSectionTypingIndicators) {
        ZNGPendingResponseOrNote * pendingResponse = (ZNGPendingResponseOrNote *)[self collectionView:collectionView messageDataForItemAtIndexPath:indexPath];
        
        if ([pendingResponse.eventType isEqualToString:ZNGPendingResponseTypeMessage]) {
            return self.outgoingBubbleImageData;
        } else if ([pendingResponse.eventType isEqualToString:ZNGPendingResponseTypeInternalNote]) {
            return self.internalNoteBubbleImageData;
        }
        
        // Unrecognized type.  Use the normal outgoing bubble image.
        ZNGLogError(@"Unexpected pending response type found: %@", pendingResponse.eventType);
        return self.outgoingBubbleImageData;
    }

    return [super collectionView:collectionView messageBubbleImageDataForItemAtIndexPath:indexPath];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id <JSQMessageData> messageData = [self collectionView:self.collectionView messageDataForItemAtIndexPath:indexPath];
    BOOL isTypingIndicator = (([messageData conformsToProtocol:@protocol(ZNGMessageData)]) && ([(id <ZNGMessageData>)messageData isTypingIndicator]));
    
    JSQMessagesCollectionViewCell * cell;
    NSURL * avatarURL = nil;
    ZNGEventViewModel * viewModel = nil;
    
    if (isTypingIndicator) {
        ZNGPendingResponseOrNote * pendingResponse = (ZNGPendingResponseOrNote *)messageData;
        ZNGConversationTypingIndicatorCell * typingCell = [collectionView dequeueReusableCellWithReuseIdentifier:TypingIndicatorCellID forIndexPath:indexPath];
        cell = typingCell;

        // Set dot color as appropriate for message/note
        BOOL isInternalNote = ([pendingResponse.eventType isEqualToString:ZNGPendingResponseTypeInternalNote]);
        typingCell.dotColor = (isInternalNote) ? self.internalNoteTextColor : self.outgoingTextColor;
        
        // We need to do the bubble coloring since we are not using [super collectionView:collectionView cellForItemAtIndexPath:indexPath]
        id<JSQMessageBubbleImageDataSource> bubbleImageDataSource = [self collectionView:self.collectionView messageBubbleImageDataForItemAtIndexPath:indexPath];
        cell.messageBubbleImageView.image = [bubbleImageDataSource messageBubbleImage];
        cell.messageBubbleImageView.highlightedImage = [bubbleImageDataSource messageBubbleHighlightedImage];
        
        cell.cellBottomLabel.attributedText = [self collectionView:self.collectionView attributedTextForCellBottomLabelAtIndexPath:indexPath];
        
        avatarURL = pendingResponse.user.avatarUri;
    } else {
        cell = [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
        
        viewModel = [self eventViewModelAtIndexPath:indexPath];

        // If this is not a message nor a note, we cannot add an avatar
        if ((![viewModel.event isMessage]) && (![viewModel.event isNote])) {
            return [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
        }
        
        if ([viewModel.event isMessage]) {
            avatarURL = ([viewModel.event isInboundMessage]) ? self.conversation.contact.avatarUri : viewModel.event.triggeredByUser.avatarUri;
        } else {
            avatarURL = viewModel.event.triggeredByUser.avatarUri;
        }
    }

    id <JSQMessageAvatarImageDataSource> initialsAvatarData = [self initialsAvatarForItemAtIndexPath:indexPath];

    if (avatarURL != nil) {
        [cell.avatarImageView sd_setImageWithURL:avatarURL placeholderImage:[initialsAvatarData avatarImage]];
    } else {
        cell.avatarImageView.image = [initialsAvatarData avatarImage];
    }
    
    // Make it a circle, dog
    CGSize avatarSize = ((isTypingIndicator) || ([viewModel.event.message isOutbound])) ? self.collectionView.collectionViewLayout.outgoingAvatarViewSize : self.collectionView.collectionViewLayout.incomingAvatarViewSize;
    cell.avatarImageView.layer.masksToBounds = YES;
    cell.avatarImageView.layer.cornerRadius = avatarSize.width / 2.0;
    
    return cell;
}

#pragma mark - Message bubble text field sizes
- (CGFloat) collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // No header for typing indicators
    if (indexPath.section == ZNGConversationSectionTypingIndicators) {
        return 0.0;
    }
    
    CGFloat height = [super collectionView:collectionView layout:collectionViewLayout heightForCellTopLabelAtIndexPath:indexPath];
    
    if (([self shouldShowTimestampAboveIndexPath:indexPath]) && ([self shouldShowChannelInfoUnderTimestamps])) {
        height += 18.0;
    }
    
    return height;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // No header for typing indicators
    if (indexPath.section == ZNGConversationSectionTypingIndicators) {
        return 0.0;
    }
    
    ZNGEventViewModel * eventViewModel = [self eventViewModelAtIndexPath:indexPath];
    return (eventViewModel.event.message.isDelayed) ? 18.0 : 0.0;
}

- (CGFloat) collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // See how much space our superclass wants for this label.
    // Sometimes it returns a non-zero value that will just be used for spacing.
    CGFloat superHeight = [super collectionView:collectionView layout:collectionViewLayout heightForCellBottomLabelAtIndexPath:indexPath];
    
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    BOOL wasForwarded = ([viewModel.event.message.forwardedByServiceId length] > 0);
    CGFloat ourHeight = (wasForwarded) ? 18.0 : 0.0;
    
    // Who wants more space?
    return MAX(superHeight, ourHeight);
}

#pragma mark - Message bubble text fields
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    NSString * forwardedDescription = [self forwardedDescriptionForEvent:viewModel.event];
    
    if ([forwardedDescription length] == 0) {
        return [super collectionView:collectionView attributedTextForCellBottomLabelAtIndexPath:indexPath];
    }
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGServiceToContactViewController class]];
    UIImage * forwardedIcon = [UIImage imageNamed:@"forwardArrow" inBundle:bundle compatibleWithTraitCollection:nil];
    NSTextAttachment * iconAttachment = [[NSTextAttachment alloc] init];
    iconAttachment.image = forwardedIcon;
    NSMutableAttributedString * string = [[NSAttributedString attributedStringWithAttachment:iconAttachment] mutableCopy];
    
    NSString * words = [NSString stringWithFormat:@" %@", forwardedDescription];
    NSDictionary * attributes = @{ NSFontAttributeName: [UIFont latoFontOfSize:12.0] };
    NSAttributedString * attributedDescription = [[NSAttributedString alloc] initWithString:words attributes:attributes];
    
    [string appendAttributedString:attributedDescription];
    return string;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEventViewModel * viewModel = [self eventViewModelAtIndexPath:indexPath];
    NSString * delayedDescription = [self delayedDescriptionForEvent:viewModel.event];
    
    if (delayedDescription == nil) {
        return nil;
    }
    
    // This message is indeed delayed
    
    // Begin the string with a clock icon
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGServiceToContactViewController class]];
    UIImage * clockIcon = [UIImage imageNamed:@"clockIcon" inBundle:bundle compatibleWithTraitCollection:nil];
    NSTextAttachment * clockIconAttachment = [[NSTextAttachment alloc] init];
    clockIconAttachment.image = clockIcon;
    NSMutableAttributedString * string = [[NSAttributedString attributedStringWithAttachment:clockIconAttachment] mutableCopy];
    
    // Append the words
    NSString * words = [NSString stringWithFormat:@"  %@", delayedDescription]; // add space after icon
    NSDictionary * attributes = @{ NSFontAttributeName: [UIFont latoFontOfSize:12.0] };
    NSAttributedString * attributedDescription = [[NSAttributedString alloc] initWithString:words attributes:attributes];
    
    // Put it all together
    [string appendAttributedString:attributedDescription];
    return string;
}

- (NSString *) delayedDescriptionForEvent:(ZNGEvent *)event
{
    if (!event.message.isDelayed) {
        return nil;
    }
    
    if (event.message.executeAt == nil) {
        ZNGLogWarn(@"Message %@ is delayed but has no execute_at date.  Showing ambiguous \"sending later\" header.", event.eventId);
        return @"Sending later";
    }
    
    NSTimeInterval timeUntilSending = [event.message.executeAt timeIntervalSinceNow];
    
    if (timeUntilSending < 60.0) {
        return @"Sending in less than a minute";
    }
    
    if (timeUntilSending < 0.0) {
        ZNGLogInfo(@"Message %@ still shows up as delayed, but its send time has passed.  Showing \"sending soon.\"", event.eventId);
        return @"Sending soon";
    }
    
    // Note that we have to take lowercaseString here because formattingContext is bugged and ignored in NSDateComponentsFormatter as of iOS 10.3.1
    NSString * justTimeIntervalString = [[nearFutureTimeFormatter stringFromTimeInterval:timeUntilSending] lowercaseString];
    return [NSString stringWithFormat:@"Sending in %@", justTimeIntervalString];
}

- (NSString *) forwardedDescriptionForEvent:(ZNGEvent *)event
{
    if ([event.message.forwardedByServiceId length] > 0) {
        // Do we see this service in our available services?  If so, show its name.
        for (ZNGService * service in self.conversation.session.availableServices) {
            if ([service.serviceId isEqualToString:event.message.forwardedByServiceId]) {
                return [NSString stringWithFormat:@"Forwarded from %@", service.displayName];
            }
        }
        
        return @"Forwarded from another service";
    }
    
    return nil;
}

#pragma mark - Text view delegate
- (void) textViewDidBeginEditing:(UITextView *)textView
{
    sentInitialTypingNotification = NO;
    [self.inputToolbar collapseInputButtons];
    [super textViewDidBeginEditing:textView];
}

- (void) textViewDidChange:(UITextView *)textView
{
    if (textView == self.inputToolbar.contentView.textView) {
        [textViewChangeTimer invalidate];
        textViewChangeTimer = nil;
        
        [self.inputToolbar collapseInputButtons];
        
        if ([textView.text length] == 0) {
            [self.conversation userClearedInput];
            sentInitialTypingNotification = NO; // Reset so we immediatley send a typing indicator if they type again
        } else {
            // Is this the first input change since the user started editing in the text field?  If so, call _textChanged immediately so other users
            //  see this user typing.
            if (!sentInitialTypingNotification) {
                sentInitialTypingNotification = YES;
                [self _textChanged];
            } else {
                // We've already sent at least one notification, so do the normal delay before spamming the server more.
                textViewChangeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_textChanged) userInfo:nil repeats:NO];
            }
        }
    }
    
    [super textViewDidChange:textView];
}

- (void) _textChanged
{
    [self.conversation userDidType:self.inputToolbar.contentView.textView.text];
}

#pragma mark - Assignment
- (void) userChoseToUnassignContact:(ZNGContact *)contact
{
    [[ZNGAnalytics sharedAnalytics] trackContactUnassigned:contact fromUIType:AssignmentUITypeActionMenu];
    [contact unassign];
}

- (void) userChoseToAssignContact:(ZNGContact *)contact toTeam:(ZNGTeam *)team
{
    [[ZNGAnalytics sharedAnalytics] trackContact:contact assignedToTeam:team fromUIType:AssignmentUITypeActionMenu];
    [contact assignToTeamWithId:team.teamId];
}

- (void) userChoseToAssignContact:(ZNGContact *)contact toUser:(ZNGUser *)user
{
    [[ZNGAnalytics sharedAnalytics] trackContact:contact assignedToUser:user fromUIType:AssignmentUITypeActionMenu];
    [contact assignToUserWithId:user.userId];
}

#pragma mark - Actions

- (void) didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    [textViewChangeTimer invalidate];
    textViewChangeTimer = nil;
    
    [super didPressSendButton:button withMessageText:text senderId:senderId senderDisplayName:senderDisplayName date:date];
}

- (IBAction)pressedCancelAutomation:(id)sender
{
    self.automationCancelButton.enabled = NO;
    
    [self.conversation stopAutomationWithCompletion:^(BOOL success) {
        self.automationCancelButton.enabled = YES;
    }];
}

- (NSString *)displayNameForChannel:(ZNGChannel *)channel
{
    return [self.conversation.service shouldDisplayRawValueForChannel:channel] ? [channel displayValueUsingRawValue] : [channel displayValueUsingFormattedValue];
}

// Our super implementation of this is fine, but we must first ensure that there is a channel selected
- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressAttachImageButton:(id)sender
{
    if (self.conversation.channel == nil) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Please select a channel" message:@"A channel must be selected before sending an image." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [super inputToolbar:toolbar didPressAttachImageButton:sender];
    }
}

- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressInsertCustomFieldButton:(id)sender
{
    CGRect sourceRect = [self.view convertRect:toolbar.contentView.customFieldButton.frame fromView:toolbar.contentView.customFieldButton.superview];
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select a custom field to insert" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = sourceRect;
    
    NSArray<ZNGContactField *> * alphabeticalCustomFields = [self.conversation.service.contactCustomFields sortedArrayUsingComparator:^NSComparisonResult(ZNGContactField * _Nonnull obj1, ZNGContactField * _Nonnull obj2) {
        return [obj1.displayName compare:obj2.displayName options:NSCaseInsensitiveSearch];
    }];
    
    for (ZNGContactField * customField in alphabeticalCustomFields) {
        UIAlertAction * action = [UIAlertAction actionWithTitle:customField.displayName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self insertCustomField:customField];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"editContact"]) {
        ZNGContactEditViewController * vc = segue.destinationViewController;
        
        vc.conversation = self.conversation;
        vc.contactClient = self.conversation.contactClient;
        vc.service = self.conversation.service;
        vc.contact = self.conversation.contact;
    } else if ([segue.identifier isEqualToString:@"forward"]) {
        // Build a list of all services available to the current account other than the current one
        NSMutableArray<ZNGService *> * availableServices = [[NSMutableArray alloc] initWithCapacity:[self.conversation.session.availableServices count]];
        
        for (ZNGService * service in self.conversation.session.availableServices) {
            if (![service isEqual:self.conversation.session.service]) {
                [availableServices addObject:service];
            }
        }
        
        UINavigationController * navController = segue.destinationViewController;
        ZNGForwardingViewController * forwardingView = [navController.viewControllers firstObject];
        forwardingView.message = messageToForward;
        forwardingView.conversation = self.conversation;
        forwardingView.availableServices = availableServices;
        forwardingView.contact = self.conversation.contact;
        forwardingView.activeService = self.conversation.service;
    } else if ([segue.identifier isEqualToString:@"assign"]) {
        UINavigationController * navController = segue.destinationViewController;
        ZNGAssignmentViewController * assignView = [navController.viewControllers firstObject];
        assignView.session = self.conversation.session;
        assignView.contact = self.conversation.contact;
        assignView.delegate = self;
    }
}

- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressUseTemplateButton:(id)sender
{
    CGRect sourceRect = [self.view convertRect:toolbar.contentView.templateButton.frame fromView:toolbar.contentView.templateButton.superview];
    
    NSMutableArray<ZNGTemplate *> * generalTemplates = [[NSMutableArray alloc] initWithCapacity:[self.conversation.service.templates count]];
    
    for (ZNGTemplate * template in self.conversation.service.templates) {
        if ([template.type isEqualToString:ZNGTemplateTypeGeneral]) {
            [generalTemplates addObject:template];
        }
    }
    
    [self presentUserWithChoiceOfTemplate:generalTemplates fromRect:sourceRect inView:self.view completion:^(NSString * selectedTemplateBody, ZNGTemplate * selectedTemplate) {
        if (selectedTemplateBody != nil) {
            [self appendStringToMessageInput:selectedTemplateBody];
            [[ZNGAnalytics sharedAnalytics] trackInsertedTemplate:selectedTemplate intoConversation:self.conversation];
        }
    }];
}

- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressChooseChannelButton:(id)sender
{
    CGRect sourceRect = [self.view convertRect:toolbar.contentView.channelSelectButton.frame fromView:toolbar.contentView.channelSelectButton.superview];
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select a channel" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = sourceRect;
    
    if ([self.conversation.contact.channels count] == 0) {
        alert.title = @"No available channels";
    }

    for (ZNGChannel * channel in self.conversation.contact.channels) {
        NSString * displayName = [self.conversation.service shouldDisplayRawValueForChannel:channel] ? [channel displayValueUsingRawValue] : [channel displayValueUsingFormattedValue];
        UIAlertAction * action = [UIAlertAction actionWithTitle:displayName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.conversation.channel = channel;
        }];
        [alert addAction:action];
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressAddInternalNoteButton:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Enter an internal note" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Internal note";
    }];
    UIAlertAction * addNote = [UIAlertAction actionWithTitle:@"Add note" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField * noteField = [alert.textFields firstObject];
        NSString * note = [noteField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([note length] == 0) {
            UIAlertController * noteAlert = [UIAlertController alertControllerWithTitle:@"Notes cannot be empty" message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [noteAlert addAction:ok];
            [self presentViewController:noteAlert animated:YES completion:nil];
        } else {
            [self addInternalNote:note];
        }
    }];
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:addNote];
    [alert addAction:cancel];
    
    [self.inputToolbar.contentView.textView resignFirstResponder];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) inputToolbar:(ZNGServiceConversationInputToolbar *)toolbar didPressTriggerAutomationButton:(id)sender
{
    CGRect sourceRect = [self.view convertRect:toolbar.contentView.automationButton.frame fromView:toolbar.contentView.templateButton.superview];
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select an automation" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = sourceRect;
    
    NSUInteger automationCount = 0;
    
    for (ZNGAutomation * automation in [self.conversation.service activeAutomations]) {
        if ([automation canBeTriggedOnAContact]) {
            UIAlertAction * action = [UIAlertAction actionWithTitle:automation.displayName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self triggerAutomation:automation];
            }];
            [alert addAction:action];
            automationCount++;
        }
    }
    
    if (automationCount == 0) {
        alert.message = @"No automations are available.";
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) triggerAutomation:(ZNGAutomation *)automation
{
    [self.conversation triggerAutomation:automation completion:^(BOOL success) {
        if (!success) {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable to trigger automation" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [self scrollToBottomAnimated:YES];
            [[ZNGAnalytics sharedAnalytics] trackTriggeredAutomation:automation onContact:self.conversation.contact];
        }
    }];
}

- (void) addInternalNote:(NSString *)note
{
    __weak ZNGServiceToContactViewController * weakSelf = self;
    
    self.inputToolbar.inputEnabled = NO;
    self.inputToolbar.sendButton.enabled = NO;
    [self scrollToBottomAnimated:YES];
    
    [self.conversation addInternalNote:note success:^(ZNGStatus * _Nonnull status) {
        weakSelf.inputToolbar.inputEnabled = YES;
        [weakSelf scrollToBottomAnimated:YES];
        [[ZNGAnalytics sharedAnalytics] trackAddedNote:note toConversation:weakSelf.conversation];
    } failure:^(ZNGError * _Nonnull error) {
        weakSelf.inputToolbar.inputEnabled = YES;
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Failed to add note" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [weakSelf presentViewController:alert animated:YES completion:nil];
    }];
}

- (void) insertCustomField:(ZNGContactField *)customField
{
    NSString * replacementValue = [NSString stringWithFormat:@"{%@} ", customField.replacementVariable];
    
    [self appendStringToMessageInput:replacementValue];
    [[ZNGAnalytics sharedAnalytics] trackInsertedCustomField:customField intoConversation:self.conversation];
}

- (void) appendStringToMessageInput:(NSString *)text
{
    [self updateUUID];
    self.inputToolbar.contentView.textView.text = [self.inputToolbar.contentView.textView.text stringByAppendingString:text];
    [self.inputToolbar toggleSendButtonEnabled];
    [self.inputToolbar collapseInputButtons];
}

- (BOOL) _shouldModallyEditContact
{
    if ([self.delegate respondsToSelector:@selector(shouldShowEditContactScreenForContact:)]) {
        return [self.delegate shouldShowEditContactScreenForContact:self.conversation.contact];
    }
    
    // Our delegate does not exist or does not care.  We'll take care of this!
    return YES;
}

- (void) pressedEditContact
{
    if (![self _shouldModallyEditContact]) {
        return;
    }
    
    [self performSegueWithIdentifier:@"editContact" sender:self];
}

- (void) forwardMessage:(ZNGMessage *)message
{
    // This really shouldn't exist and shows a probable misunderstanding of the canPerformAction: flow on my part.
    // We need this selector to exist somewhere so we can use @selector(forwardMessage:) in the UIMenuAction, but we do not want
    //  the selector actually implemented to prevent the responder chain from automatically enabling forwardMessage for all of our
    //  collection view cells, regardless of our canPerformAction: return value.
    // To achieve this, we define the method here but override respondsToSelector below to prevent it from actually being called.
    //
    // This could also be achieved by defining a forwardMessage: method in some other class, but it's all ugly. :(
}

- (BOOL) respondsToSelector:(SEL)aSelector
{
    if (aSelector == @selector(forwardMessage:)) {
        return NO;
    }
    
    return [super respondsToSelector:aSelector];
}

- (void) _doForwardMessage:(ZNGMessage *)message
{
    messageToForward = message;
    [self performSegueWithIdentifier:@"forward" sender:self];
}

@end
