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
#import "ZingleSDK/ZingleSDK-Swift.h"
#import "ZNGConversationTimestampFormatter.h"
#import "JSQMessagesInputToolbar+DisablingInput.h"

static const int zngLogLevel = ZNGLogLevelInfo;

static NSString * const EventCellIdentifier = @"EventCell";

// We will use a more aggressive polling interval when testing on a simulator (that cannot support push notifications)
#if TARGET_IPHONE_SIMULATOR
static const uint64_t PollingIntervalSeconds = 10;
#else
static const uint64_t PollingIntervalSeconds = 30;
#endif

static NSString * const EventsKVOPath = @"conversation.events";
static NSString * const LoadingKVOPath = @"conversation.loading";
static void * ZNGConversationKVOContext  =   &ZNGConversationKVOContext;

@interface JSQMessagesViewController ()

// Public declarations of methods required by our input toolbar delegate protocol that are already implemented by the base JSQMessagesViewController privately
- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressLeftBarButton:(UIButton *)sender;
- (void)messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressRightBarButton:(UIButton *)sender;

// Avoiding overriding this private method is an exercise in frustration.  Why is this not part of JSQMessageData??!?  View controllers should do literally everything!
- (BOOL)isOutgoingMessage:(id<JSQMessageData>)messageItem;

@end

@interface ZNGConversationViewController ()

@property (nonatomic, strong) JSQMessagesBubbleImage * outgoingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage * incomingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage * intenralNoteBubbleImageData;
@property (nonatomic, assign) BOOL isVisible;

@end

@implementation ZNGConversationViewController
{
    dispatch_source_t pollingTimerSource;
    BOOL checkedInitialVisibleCells;
    
    BOOL moreMessagesAvailableRemotely;
    BOOL hasDisplayedInitialData;
    
    GradientLoadingView * loadingGradient;
    
    NSUInteger pendingInsertionCount;   // See http://victorlin.me/posts/2016/04/29/uicollectionview-invalid-number-of-items-crash-issue for why this awful variable is required
}

@dynamic inputToolbar;

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
    [self addObserver:self forKeyPath:EventsKVOPath options:NSKeyValueObservingOptionNew context:ZNGConversationKVOContext];
    [self addObserver:self forKeyPath:LoadingKVOPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:ZNGConversationKVOContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyMediaMessageMediaDownloaded:) name:kZNGMessageMediaLoadedNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupLoadingGradient];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont latoFontOfSize:17.0];
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    UINib * nib = [UINib nibWithNibName:NSStringFromClass([ZNGEventCollectionViewCell class]) bundle:bundle];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:EventCellIdentifier];
    
    [self setupBarButtonItems];
    
    JSQMessagesBubbleImageFactory * bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:self.outgoingBubbleColor];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:self.incomingBubbleColor];
    self.internalNoteColor = [bubbleFactory outgoingMessagesBubbleImageWithColor:self.internalNoteColor];
    
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
    loadingGradient = [[GradientLoadingView alloc] initWithFrame:CGRectMake(0.0, 0.0, 480.0, 6.0)];
    loadingGradient.hidesWhenStopped = YES;
    loadingGradient.centerColor = [UIColor zng_lighterBlue];
    loadingGradient.edgeColor = [UIColor zng_lightBlue];
    
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
    
    [self markAllVisibleMessagesAsRead];
    checkedInitialVisibleCells = YES;
    
    [self checkForMoreRemoteMessagesAvailable];
}

- (void) viewWillDisappear:(BOOL)animated
{
    checkedInitialVisibleCells = NO;
    
    self.isVisible = NO;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
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

#pragma mark - Data properties
- (void) setConversation:(ZNGConversation *)conversation
{
    _conversation = conversation;
    hasDisplayedInitialData = NO;
    
    // Update title and collection view
    [self.navigationItem setTitle:conversation.remoteName];
    [self.collectionView reloadData];
}

- (void) checkForMoreRemoteMessagesAvailable
{
    moreMessagesAvailableRemotely = (self.conversation.totalEventCount > [self.conversation.events count]);
}

#pragma mark - UI properties

-(UIColor *)outgoingBubbleColor
{
    if (_outgoingBubbleColor == nil) {
        _outgoingBubbleColor = [UIColor zng_messageBubbleBlueColor];
    }
    return _outgoingBubbleColor;
}

-(UIColor *)incomingBubbleColor
{
    if (_incomingBubbleColor == nil) {
        _incomingBubbleColor = [UIColor zng_messageBubbleLightGrayColor];
    }
    return _incomingBubbleColor;
}

-(UIColor *)internalNoteColor
{
    if (_internalNoteColor == nil) {
        _internalNoteColor = [UIColor zng_note_yellow];
    }
    return _internalNoteColor;
}

- (UIColor *)incomingTextColor
{
    if (_incomingTextColor == nil) {
        _incomingTextColor = [UIColor zng_text_gray];
    }
    return _incomingTextColor;
}

-(UIColor *)outgoingTextColor
{
    if (_outgoingTextColor == nil) {
        _outgoingTextColor = [UIColor zng_text_gray];
    }
    return _outgoingTextColor;
}

- (UIColor *)internalNoteTextColor
{
    if (_internalNoteTextColor == nil) {
        _internalNoteTextColor = [UIColor zng_text_gray];
    }
    
    return _internalNoteTextColor;
}

-(UIColor *)authorTextColor
{
    if (_authorTextColor == nil) {
        _authorTextColor = [UIColor lightGrayColor];
    }
    return _authorTextColor;
}

-(NSString *)receiverName
{
    if (_receiverName == nil) {
        _receiverName = @"Received";
    }
    return _receiverName;
}

#pragma mark - Actions
- (void) messagesInputToolbar:(JSQMessagesInputToolbar *)toolbar didPressLeftBarButton:(UIButton *)sender { /* unused */ }

- (void) didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    [self.inputToolbar disableInput];
    
    [self.conversation sendMessageWithBody:text success:^(ZNGStatus *status) {
        [self.inputToolbar enableInput];
        [self finishSendingMessageAnimated:YES];
    } failure:^(ZNGError *error) {
        [self.inputToolbar enableInput];
        [self finishSendingMessageAnimated:YES];
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable to send" message:@"Error encountered while sending message." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
    }];
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
        // Delay the setting of this flag to allow the view to scroll to this new data.  This delay could probably be less than one second, but that
        //  is fine for the current use of this flag (loading older data when scrolling back to the top.)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hasDisplayedInitialData = YES;
        });
    }
    
    int changeType = [change[NSKeyValueChangeKindKey] intValue];
    
    switch (changeType)
    {
        case NSKeyValueChangeInsertion:
        {
            NSArray * insertions = [change[NSKeyValueChangeNewKey] isKindOfClass:[NSArray class]] ? change[NSKeyValueChangeNewKey] : nil;
                        
            // Check for the special case of messages being inserted at the head of our data
            BOOL newDataIsAtHead = [[self.conversation.events firstObject] isEqual:[insertions firstObject]];
            BOOL someDataAlreadyExisted = (([self.conversation.events count] - [insertions count]) > 0);
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
            break;
        }
            
        case NSKeyValueChangeRemoval:
        case NSKeyValueChangeSetting:
        case NSKeyValueChangeReplacement:
        default:
            // Any of these cases, we will be safe and reload
            ZNGLogVerbose(@"Reloading collection view with %llu total events.", (unsigned long long)[self.conversation.events count]);
            [self.collectionView reloadData];
    }
}

// Remove after temporary debugging
- (void)finishReceivingMessageAnimated:(BOOL)animated {
    
    ZNGLogVerbose(@"Finish receiving messages called with %llu items", (unsigned long long)[self collectionView:self.collectionView numberOfItemsInSection:0]);
    
    [super finishReceivingMessageAnimated:animated];
}

// Using method stolen from http://stackoverflow.com/a/26401767/3470757 to insert at head without scrolling
- (void) insertEventsAtIndexesWithoutScrolling:(NSArray<NSIndexPath *> *)indexes
{
    CGFloat bottomOffset = self.collectionView.contentSize.height - self.collectionView.contentOffset.y;
    pendingInsertionCount = [indexes count];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:indexes];
        pendingInsertionCount = 0;
    } completion:^(BOOL finished) {
        self.collectionView.contentOffset = CGPointMake(0, self.collectionView.contentSize.height - bottomOffset);
        [CATransaction commit];
    }];
}

- (void) notifyMediaMessageMediaDownloaded:(NSNotification *)notification
{
    ZNGMessage * message = notification.object;
    NSIndexPath * indexPath = [self indexPathForEventWithId:message.messageId];
    
    if (indexPath != nil) {
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}

#pragma mark - Text view delegate
- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // We want to detect if they are starting to delete a custom field such as {FIRST_NAME}.
    // If they delete the right brace, it should delete the entire placeholder.
    
    // Detect a backspace
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
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressAttachImageButton:(id)sender
{
    UIAlertController * alert =[UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
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
    if ([[self alertActionsForDetailsButton] count] > 0) {
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
    picker.allowsEditing = YES;
    picker.sourceType = cameraMode ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void) didPressAccessoryButton:(UIButton *)sender
{
    [self inputToolbar:nil didPressAttachImageButton:nil];
}


- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage * image = info[UIImagePickerControllerEditedImage];
    
    if (image == nil) {
        ZNGLogError(@"No image data was found after the user selected an image.");
        return;
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        BOOL cameraMode = (picker.sourceType == UIImagePickerControllerSourceTypeCamera);
        [self sendImage:image fromCameraMode:cameraMode];
    }];
}

- (void) sendImage:(UIImage *)image fromCameraMode:(BOOL)cameraMode
{
    [self.inputToolbar disableInput];
    
    [self.conversation sendMessageWithImage:image success:^(ZNGStatus *status) {
        [self.inputToolbar enableInput];
        [self finishSendingMessageAnimated:YES];
    } failure:^(ZNGError *error) {
        [self.inputToolbar enableInput];
        
        UIAlertAction * retrySameImage = [UIAlertAction actionWithTitle:@"Retry the same image" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self sendImage:image fromCameraMode:cameraMode];
        }];
        
        UIAlertAction * chooseAnotherImage = [UIAlertAction actionWithTitle:@"Try another image" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePickerWithCameraMode:cameraMode];
        }];
        
        UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Error Sending Message" message:@"Unable to attach the selected image" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:retrySameImage];
        [alert addAction:chooseAnotherImage];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

#pragma mark - Message read marking
- (void) markAllVisibleMessagesAsRead
{
    NSArray<NSIndexPath *> * visibleIndexPaths = [self.collectionView indexPathsForVisibleItems];
    NSMutableArray<ZNGMessage *> * messages = [[NSMutableArray alloc] initWithCapacity:[visibleIndexPaths count]];
    
    for (NSIndexPath * indexPath in visibleIndexPaths) {
        ZNGEvent * event = [self eventAtIndexPath:indexPath];
        
        if ([event isMessage]) {
            [messages addObject:event.message];
        }
    }
    
    [self markMessagesReadIfNecessary:messages];
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
    ZNGEvent * event = (ZNGEvent *)messageItem;
    
    if ([event isKindOfClass:[ZNGEvent class]]) {
        if ([event isNote]) {
            return YES;
        }
        
        if ([event isMessage]) {
            return ([self weAreSendingOutbound] == [event.message isOutbound]);
        }
    }
    
    return [super isOutgoingMessage:messageItem];
}

- (ZNGEvent *) eventAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray<ZNGEvent *> * events = self.conversation.events;
    return (indexPath.row < [events count]) ? events[indexPath.row] : nil;
}

- (NSIndexPath *) indexPathForEventWithId:(NSString *)eventId
{
    NSUInteger index = [self.conversation.events indexOfObjectPassingTest:^BOOL(ZNGEvent * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
        return [event.eventId isEqualToString:eventId];
    }];
    return (index != NSNotFound) ? [NSIndexPath indexPathForRow:index inSection:0] : nil;
}

- (NSIndexPath *) indexPathForEvent:(ZNGEvent *)event
{
    return [self indexPathForEventWithId:event.eventId];
}

- (ZNGEvent *) priorEventToIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath * backOne = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
    return [self eventAtIndexPath:backOne];
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self eventAtIndexPath:indexPath];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
 
    if ([event.message isOutbound] == [self weAreSendingOutbound]) {
        return self.outgoingBubbleImageData;
    }
    
    if ([event isNote]) {
        return self.internalNoteColor;
    }
    
    return self.incomingBubbleImageData;
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
    
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
    
    if ([event isMessage]) {
        [self markMessagesReadIfNecessary:@[event.message]];
    }
}

#pragma mark - JSQMessagesViewController collection view shenanigans

- (BOOL)collectionView:(JSQMessagesCollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
    
    if ([event isMessage]) {
        return [super collectionView:collectionView shouldShowMenuForItemAtIndexPath:indexPath];
    }
    
    return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
    
    if ([event isMessage]) {
        return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
    }
    
    return NO;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return [self shouldShowTimestampAboveIndexPath:indexPath] ? kJSQMessagesCollectionViewCellLabelHeightDefault : 0.0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * name = [self nameForMessageAtIndexPath:indexPath];
    
    if (name == nil) {
        return 0.0;
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

- (void) collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
    
    if ([event.message isMediaMessage]) {
        ZNGImageViewController * imageView = [[ZNGImageViewController alloc] init];
        imageView.image = event.message.image;
        imageView.navigationItem.title = self.navigationItem.title;
        
        [self.navigationController pushViewController:imageView animated:YES];
    }
}

- (BOOL) shouldShowTimestampAboveIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * thisEvent = [self eventAtIndexPath:indexPath];
    ZNGEvent * priorEvent = [self priorEventToIndexPath:indexPath];
    NSDate * thisEventTime = thisEvent.createdAt;
    NSDate * priorEventTime = priorEvent.createdAt;
    
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
    ZNGEvent * thisEvent = [self eventAtIndexPath:indexPath];
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
    NSString * name = [self nameForMessageAtIndexPath:indexPath];
    NSDictionary * attributes = @{ NSFontAttributeName: [UIFont latoFontOfSize:12.0] };
    return (name != nil) ? [[NSAttributedString alloc] initWithString:name attributes:attributes] : nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.conversation.events count] - pendingInsertionCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
    
    if ([event isMessage] || [event isNote]) {
        JSQMessagesCollectionViewCell * cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
        cell.cellTopLabel.numberOfLines = 0;    // Support multiple lines
        
        if (!event.message.isMediaMessage) {
            
            if ([event isNote]) {
                cell.textView.textColor = self.internalNoteTextColor;
            } else if ([self weAreSendingOutbound] == [event.message isOutbound]) {
                cell.textView.textColor = self.outgoingTextColor;
            } else {
                cell.textView.textColor = self.incomingTextColor;
            }
            
            cell.textView.linkTextAttributes = @{
                                                 NSForegroundColorAttributeName : cell.textView.textColor,
                                                 NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid)
                                                 };
            
            cell.messageBubbleTopLabel.textColor = self.authorTextColor;
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