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

static const int zngLogLevel = ZNGLogLevelInfo;
static const uint64_t PollingIntervalSeconds = 10;
static NSString * const EventsKVOPath = @"conversation.events";
static void * ZNGConversationKVOContext  =   &ZNGConversationKVOContext;

@interface ZNGConversationViewController ()

@property (nonatomic, strong) JSQMessagesBubbleImage * outgoingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage * incomingBubbleImageData;
@property (nonatomic, assign) BOOL isVisible;

@end

@implementation ZNGConversationViewController
{
    dispatch_source_t pollingTimerSource;
    BOOL checkedInitialVisibleCells;
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
    [self addObserver:self forKeyPath:EventsKVOPath options:NSKeyValueObservingOptionNew context:ZNGConversationKVOContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyMediaMessageMediaDownloaded:) name:kZNGMessageMediaLoadedNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    [self setupBarButtonItems];
    
    JSQMessagesBubbleImageFactory * bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:self.outgoingBubbleColor];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:self.incomingBubbleColor];
    
    // Use a weak timer so that we can have a refresh timer going that will continue to work even if the conversation
    //   object is changed out from under us, but we will also not leak.
    __weak ZNGConversationViewController * weakSelf = self;
    pollingTimerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    uint64_t pollingIntervalNanoseconds = PollingIntervalSeconds * NSEC_PER_SEC;
    dispatch_source_set_timer(pollingTimerSource, dispatch_time(DISPATCH_TIME_NOW, pollingIntervalNanoseconds), pollingIntervalNanoseconds, 5 * NSEC_PER_SEC /* 5 sec leeway */);
    dispatch_source_set_event_handler(pollingTimerSource, ^{
        if (weakSelf.isVisible) {
            [weakSelf.conversation updateEvents];
        }
    });
    dispatch_resume(pollingTimerSource);
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isVisible = YES;
    
    [self markAllVisibleMessagesAsRead];
    checkedInitialVisibleCells = YES;
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
    
    // Update title and collection view
    [self.navigationItem setTitle:conversation.remoteName];
    [self.collectionView reloadData];
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
- (UIColor *)incomingTextColor
{
    if (_incomingTextColor == nil) {
        _incomingTextColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
    }
    return _incomingTextColor;
}

-(UIColor *)outgoingTextColor
{
    if (_outgoingTextColor == nil) {
        _outgoingTextColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
    }
    return _outgoingTextColor;
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
- (void) refreshConversation
{
    // TODO: Implement
}

- (void) didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    [self.conversation sendMessageWithBody:text success:^(ZNGStatus *status) {
        [self finishSendingMessageAnimated:YES];
    } failure:^(ZNGError *error) {
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
    }
}

- (void) handleEventsChange:(NSDictionary<NSString *, id> *)change
{
    int changeType = [change[NSKeyValueChangeKindKey] intValue];
    
    switch (changeType)
    {
        case NSKeyValueChangeInsertion:
            [self finishReceivingMessageAnimated:YES];
            break;
            
        case NSKeyValueChangeRemoval:
        case NSKeyValueChangeSetting:
        case NSKeyValueChangeReplacement:
        default:
            // Any of these cases, we will be safe and reload
            [self.collectionView reloadData];
    }
}

- (void) notifyMediaMessageMediaDownloaded:(NSNotification *)notification
{
    ZNGMessage * message = notification.object;
    NSIndexPath * indexPath = [self indexPathForEventWithId:message.messageId];
    
    if (indexPath != nil) {
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}

#pragma mark - Accessory button
- (NSArray<UIAlertAction *> *)alertActionsForAccessoryButton
{
    NSMutableArray<UIAlertAction *> * actions = [[NSMutableArray alloc] initWithCapacity:3];
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        ZNGLogInfo(@"The user's current device does not have a camera, does not allow camera access, or the camera is currently unavailable.");
    } else {
        UIAlertAction * takePhoto = [UIAlertAction actionWithTitle:@"Take a photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePickerWithCameraMode:YES];
        }];
        [actions addObject:takePhoto];
    }
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        ZNGLogInfo(@"The user's photo library is currently not available or is empty.");
    } else {
        UIAlertAction * choosePhoto = [UIAlertAction actionWithTitle:@"Choose a photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePickerWithCameraMode:NO];
        }];
        [actions addObject:choosePhoto];
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [actions addObject:cancel];
    
    return actions;
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItems
{
    if ([[self alertActionsForDetailsButton] count] > 0) {
    UIBarButtonItem * detailsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage zng_defaultTypingIndicatorImage] style:UIBarButtonItemStylePlain target:self action:@selector(detailsButtonPressed:)];
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
    NSArray<UIAlertAction *> * actions = [self alertActionsForAccessoryButton];
    
    if ([actions count] == 0) {
        ZNGLogWarn(@"Accessory button was pressed, but we have no options with which to present the user.  Ignoring.");
        return;
    }
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (UIAlertAction * action in actions) {
        [alert addAction:action];
    }
    
    [self presentViewController:alert animated:YES completion:nil];
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
    [self.conversation sendMessageWithImage:image success:^(ZNGStatus *status) {
        [self finishSendingMessageAnimated:YES];
    } failure:^(ZNGError *error) {
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
        
        if (event.message != nil) {
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
    // A small optimization: We will always mark all visible cells as read whenever we appear.  If we haven't done that yet, we do not need to mark messages
    //  read one at a time.
    if (!checkedInitialVisibleCells) {
        return;
    }
    
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
    
    if (event.message != nil) {
        [self markMessagesReadIfNecessary:@[event.message]];
    }
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate * time = [self timeForEventAtIndexPath:indexPath];
    
    if (time == nil) {
        return 0.0;
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
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

// Returns nil if we do not need to show a time this soon
- (NSDate *) timeForEventAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * thisEvent = [self eventAtIndexPath:indexPath];
    ZNGEvent * priorEvent = [self priorEventToIndexPath:indexPath];
    BOOL showTimestamp = YES;
    NSDate * thisEventTime = thisEvent.createdAt;
    NSDate * priorEventTime = priorEvent.createdAt;
    
    if ((thisEventTime != nil) && (priorEventTime != nil)) {
        NSTimeInterval timeSinceLastEvent = [thisEventTime timeIntervalSinceDate:priorEventTime];
        
        if (![self timeBetweenEventsBigEnoughToWarrantTimestamp:timeSinceLastEvent]) {
            showTimestamp = NO;
        }
    }
    
    return (showTimestamp) ? thisEventTime : nil;
}

- (BOOL) timeBetweenEventsBigEnoughToWarrantTimestamp:(NSTimeInterval)interval
{
    static NSTimeInterval fiveMinutes = 5.0 * 60.0;
    return (interval > fiveMinutes);
}

// Returns nil if displaying the name above this message is deemed unnecessary
- (NSString *) nameForMessageAtIndexPath:(NSIndexPath *)indexPath
{
    // Are we adding a sender name to this message?
    
    // If this is the first message in this direction from this specific sender, then yes.
    ZNGEvent * thisEvent = [self eventAtIndexPath:indexPath];
    ZNGMessage * priorMessageThisDirection = nil;
    
    if ([thisEvent isMessage]) {
        priorMessageThisDirection = [self.conversation priorMessageWithSameDirection:thisEvent.message];
    }
    
    // We show the name if either 1) this is the first message in this direction or 2) the last message in this direction came from a different person.
    // This one check will satisfy both conditions since in 1) priorMessageThisDirection == nil --> priorMessageThisDirection.senderId isEqualToString is always NO.
    BOOL isNewPerson = (![[priorMessageThisDirection triggeredByUserIdOrSenderId] isEqualToString:[thisEvent.message triggeredByUserIdOrSenderId]]);
    return isNewPerson ? thisEvent.message.senderDisplayName : nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate * messageTime = [self timeForEventAtIndexPath:indexPath];
    
    if (messageTime != nil) {
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:messageTime];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * name = [self nameForMessageAtIndexPath:indexPath];
    return (name != nil) ? [[NSAttributedString alloc] initWithString:name] : nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // This is where the channel would be displayed when viewing as a service.  By default, this will not be shown.
    return nil;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.conversation.events count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell * cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
    
    if ([event isMessage]) {
        if (!event.message.isMediaMessage) {
            if ([self weAreSendingOutbound] == [event.message isOutbound]) {
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
    } else {
        ZNGLogError(@"Attempting to display a non-message (%@) event.  We cannot yet handle this!!  Panic!!!", event.eventType);
    }
    
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