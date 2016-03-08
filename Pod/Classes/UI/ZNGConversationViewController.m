//
//  ZNGConversationViewController.m
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import "ZNGConversationViewController.h"
#import "ZNGImageViewerController.h"
#import "SDWebImageManager.h"

@interface ZNGConversationViewController () 

@property (strong, nonatomic) ZNGBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) ZNGBubbleImage *incomingBubbleImageData;

@property (weak) NSTimer *pollingTimer;

@end

@implementation ZNGConversationViewController


+ (ZNGConversationViewController *)withConversation:(ZNGConversation *)conversation
{
    ZNGConversationViewController *demoVC = (ZNGConversationViewController *)[ZNGConversationViewController messagesViewController];
    
    if (demoVC) {
        demoVC.conversation = conversation;
    }
    
    return demoVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"ZingleSDK";
    
    self.conversation.delegate = self;
    
    if (self.conversation.toService) {
        self.senderId = self.conversation.contact.participantId;
    } else {
        self.senderId = self.conversation.service.participantId;
    }
    
    self.senderDisplayName = @"Me";
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;

    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.showLoadEarlierMessagesHeader = NO;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage zng_defaultTypingIndicatorImage]
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(detailsPressed:)];
    
    [ZNGCollectionViewCell registerMenuAction:@selector(customAction:)];
    [UIMenuController sharedMenuController].menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Custom Action"
                                                                                      action:@selector(customAction:)] ];
    
    [ZNGCollectionViewCell registerMenuAction:@selector(delete:)];
    
    ZNGBubbleImageFactory *bubbleFactory = [[ZNGBubbleImageFactory alloc] init];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor zng_messageBubbleBlueColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor zng_messageBubbleLightGrayColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopPollingTimer)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startPollingTimer)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
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
- (void)startPollingTimer{
    // Cancel a preexisting timer.
    [self.pollingTimer invalidate];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:10
                                                      target:self selector:@selector(refreshConversation)
                                                    userInfo:nil repeats:YES];
    self.pollingTimer = timer;
}
- (void)stopPollingTimer{
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}


#pragma mark - Helper methods

- (ZNGMessageViewModel *)viewModelForIndex:(NSInteger)index
{
    ZNGMessage *message = [self.conversation.messages objectAtIndex:index];
    NSString *senderDisplayName;
    if ([message.sender.correspondentId isEqualToString:self.senderId]) {
        senderDisplayName = self.senderDisplayName;
    } else {
        senderDisplayName = @"Received";
    }
    
    if (message.image) {
        ZNGPhotoMediaItem *item = [[ZNGPhotoMediaItem alloc] initWithImage:message.image];
        item.appliesMediaViewMaskAsOutgoing = [message.sender.correspondentId isEqualToString:self.senderId];
        return [[ZNGMessageViewModel alloc] initWithSenderId:message.sender.correspondentId
                                       senderDisplayName:senderDisplayName
                                                    date:message.createdAt
                                                   media:item];
    }
    
    if ([message.attachments count] > 0) {
        
        ZNGPhotoMediaItem *item = [[ZNGPhotoMediaItem alloc] init];
        item.appliesMediaViewMaskAsOutgoing = [message.sender.correspondentId isEqualToString:self.senderId];
        __weak typeof(self) weakSelf = self;
        [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:[message.attachments firstObject]]
                                                        options:0
                                                       progress:nil
                                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                          
                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                              message.image = image;
                                                              item.image = image;
                                                              [weakSelf.collectionView reloadData];
                                                          });
                                                      }];

        return [[ZNGMessageViewModel alloc] initWithSenderId:message.sender.correspondentId
                            senderDisplayName:senderDisplayName
                                         date:message.createdAt
                                        media:item];
    }
    return [[ZNGMessageViewModel alloc] initWithSenderId:message.sender.correspondentId
                        senderDisplayName:senderDisplayName
                                     date:message.createdAt
                                     text:message.body];
}

#pragma mark - ZNGConversationDelegate

- (void)messagesUpdated
{
    [self startPollingTimer];
    
    [self finishReceivingMessage];
}

#pragma mark - Actions

- (void)detailsPressed:(UIBarButtonItem *)sender
{
    NSLog(@"Details button pressed!");
}

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
    [self.conversation sendMessageWithBody:text success:^(ZNGMessage *message, ZNGStatus *status) {
        [self.conversation.messages addObject:message];
        [self finishSendingMessageAnimated:YES];
    } failure:^(ZNGError *error) {
        //
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
        
        [self.conversation sendMessageWithImage:chosenImage success:^(ZNGMessage *message, ZNGStatus *status) {
            
            [self.conversation.messages addObject:message];
            [self finishSendingMessageAnimated:YES];

        } failure:^(ZNGError *error) {
            //
        }];
    }];
}

#pragma mark - ZingleSDK CollectionView DataSource

- (id<ZNGMessageData>)collectionView:(ZNGCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self viewModelForIndex:indexPath.item];
}

- (void)collectionView:(ZNGCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    [self.conversation.messages removeObjectAtIndex:indexPath.item];
}

- (id<ZNGMessageBubbleImageDataSource>)collectionView:(ZNGCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessageViewModel *message = [self viewModelForIndex:indexPath.item];
    
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
        ZNGMessageViewModel *message = [self viewModelForIndex:indexPath.item];
        return [[ZNGTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(ZNGCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessageViewModel *message = [self viewModelForIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        ZNGMessageViewModel *previousMessage = [self viewModelForIndex:indexPath.item - 1];
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
    return [self.conversation.messages count];
}

- (UICollectionViewCell *)collectionView:(ZNGCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGCollectionViewCell *cell = (ZNGCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    ZNGMessageViewModel *msg = [self viewModelForIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
        }
        else {
            cell.textView.textColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}

#pragma mark - UICollectionView Delegate

#pragma mark - Custom menu items

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        [self customAction:sender];
        return;
    }
    
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)customAction:(id)sender
{
    NSLog(@"Custom action received! Sender: %@", sender);
    
    [[[UIAlertView alloc] initWithTitle:@"Custom Action"
                                message:nil
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil]
     show];
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
    ZNGMessageViewModel *currentMessage = [self viewModelForIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        ZNGMessageViewModel *previousMessage = [self viewModelForIndex:indexPath.item - 1];
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
    ZNGMessage *message = [self.conversation.messages objectAtIndex:indexPath.item];
    
    if (message.image) {
        ZNGImageViewerController *imageViewer = [ZNGImageViewerController imageViewerController];
        self.automaticallyScrollsToMostRecentMessage = NO;
        imageViewer.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:imageViewer animated:YES completion:^{
            imageViewer.imageView.image = message.image;
        }];
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
    [self.conversation sendMessageWithImage:[UIPasteboard generalPasteboard].image success:^(ZNGMessage *message, ZNGStatus *status) {
        
        [self.conversation.messages addObject:message];
        [self finishSendingMessageAnimated:YES];
        
    } failure:^(ZNGError *error) {
        //
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
