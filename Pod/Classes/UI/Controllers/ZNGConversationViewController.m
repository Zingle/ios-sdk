//
//  ZNGConversationViewController.m
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import "ZNGConversationViewController.h"
#import "ZNGImageViewerController.h"

@interface ZNGConversationViewController ()

@property (nonatomic, strong) ZNGConversation *conversation;

@property (nonatomic, strong) NSMutableArray *viewModels;

@property (strong, nonatomic) ZNGBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) ZNGBubbleImage *incomingBubbleImageData;

@property (weak) NSTimer *pollingTimer;

@end

@implementation ZNGConversationViewController

+ (ZNGConversationViewController *)withConversation:(ZNGConversation *)conversation
{
    ZNGConversationViewController *vc = (ZNGConversationViewController *)[ZNGConversationViewController messagesViewController];
    
    if (vc) {
        vc.conversation = conversation;
    }
    
    return vc;
}

#pragma mark - Properties

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Chat";
    
    self.conversation.delegate = self;
    
    if (self.conversation.toService) {
        self.senderId = self.conversation.contact.participantId;
    } else {
        self.senderId = self.conversation.service.participantId;
    }
    
    self.senderDisplayName = self.senderName ?: @"Me";
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;

    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.showLoadEarlierMessagesHeader = NO;
    
    ZNGBubbleImageFactory *bubbleFactory = [[ZNGBubbleImageFactory alloc] init];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:self.outgoingBubbleColor];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:self.incomingBubbleColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopPollingTimer)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startPollingTimer)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [self refreshViewModels];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.delegateModal) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                              target:self
                                                                                              action:@selector(closePressed:)];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startPollingTimer];
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
    self.automaticallyScrollsToMostRecentMessage = YES;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self stopPollingTimer];
}

- (void)refreshConversation
{
    [self.conversation updateMessages];
}

#pragma mark - Timer Long Poll
- (void)startPollingTimer
{
    // Cancel a preexisting timer.
    [self.pollingTimer invalidate];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:10
                                                      target:self selector:@selector(refreshConversation)
                                                    userInfo:nil repeats:YES];
    self.pollingTimer = timer;
}

- (void)stopPollingTimer
{
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}


#pragma mark - Helper methods

- (void)refreshViewModels
{
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    for (ZNGMessage *message in self.conversation.messages) {
        NSString *senderDisplayName;
        if ([message.sender.correspondentId isEqualToString:self.senderId])
        {
            senderDisplayName = self.senderDisplayName;
        } else
        {
            senderDisplayName = self.receiverName;
        }
        if ([message.attachments count] > 0)
        {
            ZNGNetworkPhotoMediaItem *item = [[ZNGNetworkPhotoMediaItem alloc] initWithURL:message.attachments[0]];
            item.appliesMediaViewMaskAsOutgoing = [message.sender.correspondentId isEqualToString:self.senderId];
            ZNGMessageViewModel *viewModel =   [[ZNGMessageViewModel alloc] initWithSenderId:message.sender.correspondentId
                                               senderDisplayName:senderDisplayName
                                                            date:message.createdAt
                                                           media:item];
            [tempArray addObject:viewModel];
        } else if (message.body) {
            ZNGMessageViewModel *viewModel =   [[ZNGMessageViewModel alloc] initWithSenderId:message.sender.correspondentId
                                                                           senderDisplayName:senderDisplayName
                                                                                        date:message.createdAt
                                                                                        text:message.body];
            [tempArray addObject:viewModel];
        }
    }
    
    self.viewModels = tempArray;
    [self.collectionView reloadData];
}

- (void)showErrorSendingMessage
{
    [[[UIAlertView alloc] initWithTitle:@"There was a problem sending your message. Please try again later."
                                message:nil
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

#pragma mark - ZNGConversationDelegate

- (void)messagesUpdated
{
    [self startPollingTimer];
    
    [self refreshViewModels];
    
    [self finishReceivingMessage];
}

#pragma mark - Actions

- (void)closePressed:(UIBarButtonItem *)sender
{
    [self.delegateModal didDismissZNGConversationViewController:self];
}

#pragma mark - ZNGBaseViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    [self.conversation sendMessageWithBody:text success:^(ZNGStatus *status) {
        ZNGMessageViewModel *viewModel =   [[ZNGMessageViewModel alloc] initWithSenderId:senderId
                                                                       senderDisplayName:senderDisplayName
                                                                                    date:[NSDate date]
                                                                                    text:text];
        [self.viewModels addObject:viewModel];
        [self finishSendingMessageAnimated:YES];
    } failure:^(ZNGError *error) {
        [self showErrorSendingMessage];
    }];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Take a Photo", @"Choose a Photo", nil];
    
    [sheet showFromToolbar:self.inputToolbar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    if( buttonIndex == 0 )
    {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else if( buttonIndex == 1)
    {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        [self.conversation sendMessageWithImage:chosenImage success:^(ZNGStatus *status) {
            ZNGPhotoMediaItem *item = [[ZNGPhotoMediaItem alloc] initWithImage:chosenImage];
            item.appliesMediaViewMaskAsOutgoing = YES;
            ZNGMessageViewModel *viewModel =   [[ZNGMessageViewModel alloc] initWithSenderId:self.senderId
                                                                           senderDisplayName:self.senderDisplayName
                                                                                        date:[NSDate date]
                                                                                       media:item];
            [self.viewModels addObject:viewModel];
            [self finishSendingMessageAnimated:YES];

        } failure:^(ZNGError *error) {
            [self showErrorSendingMessage];
        }];
    }];
}

#pragma mark - ZingleSDK CollectionView DataSource

- (id<ZNGMessageData>)collectionView:(ZNGCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewModels objectAtIndex:indexPath.item];
}

- (id<ZNGMessageBubbleImageDataSource>)collectionView:(ZNGCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessageViewModel *message = [self.viewModels objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<ZNGMessageAvatarImageDataSource>)collectionView:(ZNGCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(ZNGCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item % 3 == 0) {
        ZNGMessageViewModel *message = [self.viewModels objectAtIndex:indexPath.item];
        return [[ZNGTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(ZNGCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessageViewModel *message = [self.viewModels objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId] && (self.senderName == nil)) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        ZNGMessageViewModel *previousMessage = [self.viewModels objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(ZNGCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.viewModels count];
}

- (UICollectionViewCell *)collectionView:(ZNGCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGCollectionViewCell *cell = (ZNGCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    ZNGMessageViewModel *msg = [self.viewModels objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = self.outgoingTextColor;
        }
        else {
            cell.textView.textColor = self.incomingTextColor;
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
        
        cell.messageBubbleTopLabel.textColor = self.authorTextColor;
    }
    
    return cell;
}

#pragma mark - ZingleSDK collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(ZNGCollectionView *)collectionView
                   layout:(ZNGCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item % 3 == 0) {
        return kZNGCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(ZNGCollectionView *)collectionView
                   layout:(ZNGCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessageViewModel *currentMessage = [self.viewModels objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId] && (self.senderName == nil)) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        ZNGMessageViewModel *previousMessage = [self.viewModels objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kZNGCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(ZNGCollectionView *)collectionView
                   layout:(ZNGCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(ZNGCollectionView *)collectionView
                header:(ZNGLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(ZNGCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(ZNGCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessageViewModel *viewModel = [self.viewModels objectAtIndex:indexPath.item];
    if (viewModel.isMediaMessage) {
        if ([viewModel.media isKindOfClass:[ZNGNetworkPhotoMediaItem class]]) {
            UIImage *image = ((UIImageView *)viewModel.media).image;
            if (image) {
                ZNGImageViewerController *imageViewer = [ZNGImageViewerController imageViewerController];
                self.automaticallyScrollsToMostRecentMessage = NO;
                imageViewer.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                [self presentViewController:imageViewer animated:YES completion:^{
                    imageViewer.imageView.image = image;
                }];
            }
        }
    }
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(ZNGCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self scrollToBottomAnimated:YES];
        return;
    }
    
    [self scrollToBottomAnimated:YES];
    // If there's an image in the pasteboard, `send` it.
    [self.conversation sendMessageWithImage:[UIPasteboard generalPasteboard].image success:^(ZNGStatus *status) {
        
        ZNGPhotoMediaItem *item = [[ZNGPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
        item.appliesMediaViewMaskAsOutgoing = YES;
        ZNGMessageViewModel *viewModel =   [[ZNGMessageViewModel alloc] initWithSenderId:self.senderId
                                                                       senderDisplayName:self.senderDisplayName
                                                                                    date:[NSDate date]
                                                                                   media:item];
        [self.viewModels addObject:viewModel];
        [self finishSendingMessageAnimated:YES];
        
    } failure:^(ZNGError *error) {
        [self showErrorSendingMessage];
    }];
}

#pragma mark - ZNGComposerTextViewPasteDelegate methods

- (BOOL)composerTextView:(ZNGComposerTextView *)textView shouldPasteWithSender:(id)sender
{
    if ([UIPasteboard generalPasteboard].image) {
        
        [[[UIAlertView alloc] initWithTitle:@"Send image in clipboard?"
                                    message:nil
                                   delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"Send", nil] show];
        
        return NO;
    }
    return YES;
}

@end
