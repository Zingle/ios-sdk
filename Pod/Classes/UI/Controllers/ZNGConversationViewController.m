//
//  ZNGConversationViewController.m
//  Pods
//
//  Created by Jason Neel on 6/20/16.
//
//

#import "ZNGConversationViewController.h"
#import "ZNGConversation.h"
#import "UIColor+ZingleSDK.h"
#import "JSQMessagesBubbleImage.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesTimestampFormatter.h"

static const uint64_t PollingIntervalSeconds = 10;
static NSString * const MessagesKVOPath = @"conversation.messages";
static void * ZNGConversationKVOContext  =   &ZNGConversationKVOContext;

@interface ZNGConversationViewController ()

@property (nonatomic, strong) JSQMessagesBubbleImage * outgoingBubbleImageData;
@property (nonatomic, strong) JSQMessagesBubbleImage * incomingBubbleImageData;
@property (nonatomic, assign) BOOL isVisible;

@end

@implementation ZNGConversationViewController
{
    dispatch_source_t pollingTimerSource;
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
    [self addObserver:self forKeyPath:MessagesKVOPath options:NSKeyValueObservingOptionNew context:ZNGConversationKVOContext];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
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
            [weakSelf.conversation updateMessages];
        }
    });
    dispatch_resume(pollingTimerSource);
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isVisible = YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    self.isVisible = NO;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:MessagesKVOPath context:ZNGConversationKVOContext];
    
    if (pollingTimerSource != nil) {
        dispatch_source_cancel(pollingTimerSource);
    }
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
        // TODO: Implement
    }];
}

- (void) didPressAccessoryButton:(UIButton *)sender
{
    
}

#pragma mark - Data notifications
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context != ZNGConversationKVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:MessagesKVOPath]) {
        [self handleMessagesChange:change];
    }
}

- (void) handleMessagesChange:(NSDictionary<NSString *, id> *)change
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

#pragma mark - Data source
- (NSString *)senderId
{
    return (self.conversation != nil ) ? [self.conversation meId] : @"";
}

- (NSString *)senderDisplayName
{
    return @"Me";
}

- (ZNGMessage *) messageAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray<ZNGMessage *> * messages = self.conversation.messages;
    return (indexPath.row < [messages count]) ? messages[indexPath.row] : nil;
}

- (ZNGMessage *) priorMessageToIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath * backOne = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
    return [self messageAtIndexPath:backOne];
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self messageAtIndexPath:indexPath];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessage * message = [self messageAtIndexPath:indexPath];
    
    if ([message.senderId isEqualToString:[self senderId]]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // No avatars
    return nil;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate * time = [self timeForMessageAtIndexPath:indexPath];
    
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

// Returns nil if we do not need to show a time this soon
- (NSDate *) timeForMessageAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessage * thisMessage = [self messageAtIndexPath:indexPath];
    ZNGMessage * priorMessage = [self priorMessageToIndexPath:indexPath];
    BOOL showTimestamp = YES;
    NSDate * thisMessageTime = thisMessage.createdAt;
    NSDate * priorMessageTime = priorMessage.createdAt;
    
    if ((thisMessageTime != nil) && (priorMessageTime != nil)) {
        NSTimeInterval timeSinceLastMessage = [thisMessageTime timeIntervalSinceDate:priorMessageTime];
        
        if (![self timeBetweenMessagesBigEnoughToWarrantTimestamp:timeSinceLastMessage]) {
            showTimestamp = NO;
        }
    }
    
    return (showTimestamp) ? thisMessageTime : nil;
}

- (BOOL) timeBetweenMessagesBigEnoughToWarrantTimestamp:(NSTimeInterval)interval
{
    static NSTimeInterval fiveMinutes = 5.0 * 60.0;
    return (interval > fiveMinutes);
}

// Returns nil if displaying the name above this message is deemed unnecessary
- (NSString *) nameForMessageAtIndexPath:(NSIndexPath *)indexPath
{
    // Are we adding a sender name to this message?
    
    // If this is the first message in this direction from this specific sender, then yes.
    ZNGMessage * thisMessage = [self messageAtIndexPath:indexPath];
    ZNGMessage * priorMessageThisDirection = [self.conversation priorMessageWithSameDirection:thisMessage];
    
    // We show the name if either 1) this is the first message in this direction or 2) the last message in this direction came from a different person.
    // This one check will satisfy both conditions since in 1) priorMessageThisDirection == nil --> priorMessageThisDirection.senderId isEqualToString is always NO.
    BOOL isNewPerson = (![priorMessageThisDirection.senderId isEqualToString:thisMessage.senderId]);
    return isNewPerson ? thisMessage.senderDisplayName : nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate * messageTime = [self timeForMessageAtIndexPath:indexPath];
    
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
    return [self.conversation.messages count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell * cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    ZNGMessage * message = [self messageAtIndexPath:indexPath];
    
    if ([message.senderId isEqualToString:[self senderId]]) {
        cell.textView.textColor = self.outgoingTextColor;
    } else {
        cell.textView.textColor = self.incomingTextColor;
    }
    
    cell.textView.linkTextAttributes = @{
                                         NSForegroundColorAttributeName : cell.textView.textColor,
                                         NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid)
                                         };
    
    cell.messageBubbleTopLabel.textColor = self.authorTextColor;
    
    return cell;
}

@end
