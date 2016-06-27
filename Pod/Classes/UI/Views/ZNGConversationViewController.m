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
    BOOL isVisible;
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
    isVisible = YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    isVisible = NO;
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

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.conversation.messages[indexPath.row];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessage * message = self.conversation.messages[indexPath.row];
    
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

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Insert timestamp here?
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Insert sender name here?
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Insert channel type and/or value here?
    return nil;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.conversation.messages count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell * cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    ZNGMessage * message = self.conversation.messages[indexPath.row];
    
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
