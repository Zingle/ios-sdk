//
//  ZNGConversationViewController.m
//  Pods
//
//  Created by Ryan Farley on 3/6/16.
//
//

#import "ZNGConversationViewController.h"
#import "ZNGImageViewerController.h"
#import "ZingleSDK.h"
#import "DGActivityIndicatorView.h"
#import "ZNGContactClient.h"
#import "UIFont+OpenSans.h"
#import "ZNGContactViewController.h"

@interface ZNGConversationViewController ()

@property (nonatomic, strong) ZNGService *service;
@property (nonatomic, strong) ZNGContact *contact;
@property (nonatomic, strong) NSString *contactChannelValue;

@property (nonatomic, strong) ZNGConversation *conversation;

@property (nonatomic, strong) NSMutableArray *viewModels;

@property (strong, nonatomic) ZNGBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) ZNGBubbleImage *incomingBubbleImageData;

@property (weak) NSTimer *pollingTimer;

@property (strong, nonatomic) DGActivityIndicatorView *activityIndicator;




@property (strong, nonatomic) UIBarButtonItem *starBarButton;
@property (strong, nonatomic) UIBarButtonItem *confirmBarButton;
@property (strong, nonatomic) UIBarButtonItem *detailsBarButton;

@property (strong, nonatomic) UIImage *unstarredImage;
@property (strong, nonatomic) UIImage *starredImage;
@property (strong, nonatomic) UIButton *confirmButton;

@end

@implementation ZNGConversationViewController

+ (ZNGConversationViewController *)withService:(ZNGService *)service
                                       contact:(ZNGContact *)contact
                           contactChannelValue:(NSString *)contactChannelValue
                                    senderName:(NSString *)senderName
                                  receiverName:(NSString *)receiverName
{
    ZNGConversationViewController *vc = (ZNGConversationViewController *)[ZNGConversationViewController messagesViewController];
    
    if (vc) {
        vc.service = service;
        vc.contact = contact;
        vc.contactChannelValue = contactChannelValue;
        vc.senderName = senderName;
        vc.receiverName = receiverName;
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
    
    self.activityIndicator = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallPulseSync tintColor:[UIColor colorFromHexString:@"#00a0de"] size:30.0f];
    ;
    self.activityIndicator.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width)/2 - 15, ([UIScreen mainScreen].bounds.size.height)/2 - 15, 30, 30);
    [self.view addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
    
    self.senderDisplayName = self.senderName ?: @"Me";
    self.titleViewLabel.text = self.receiverName ?: @"Chat";
    self.titleViewLabel.font = [UIFont openSansBoldFontOfSize:17.0f];
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;

    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.showLoadEarlierMessagesHeader = NO;
    
    ZNGBubbleImageFactory *bubbleFactory = [[ZNGBubbleImageFactory alloc] init];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:self.outgoingBubbleColor];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:self.incomingBubbleColor];
    
    self.navigationController.navigationBar.tintColor = [UIColor colorFromHexString:@"#00a0de"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopPollingTimer)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startPollingTimer)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    self.senderId = self.service.serviceId;

    ZNGConversation *conversation = [[ZingleSDK sharedSDK] conversationToContact:self.contact.contactId];
    if (conversation) {
        self.conversation = conversation;
        self.conversation.delegate = self;
        [self refreshViewModels];
    } else {
        [self loadConversation];
    }
}

- (void)setupBarButtonItems
{
    self.unstarredImage = [UIImage zng_lrg_unstarredImage];
    self.starredImage = [UIImage zng_lrg_starredImage];
    
    if (self.contact.isStarred) {
        self.starBarButton = [[UIBarButtonItem alloc] initWithImage: self.starredImage
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(starButtonPressed:)];
        self.starBarButton.tintColor = [UIColor colorFromHexString:@"#FFCF3A"];
    } else {
        self.starBarButton = [[UIBarButtonItem alloc] initWithImage:self.unstarredImage
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(starButtonPressed:)];
        self.starBarButton.tintColor = [UIColor colorFromHexString:@"#B6B8BA"];
    }
    
    self.confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    self.confirmButton.layer.cornerRadius = 5;
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont openSansBoldFontOfSize:17.0f];
    [self.confirmButton addTarget:self action:@selector(confirmedButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.confirmBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    
    if (self.contact.isConfirmed) {
        self.confirmButton.backgroundColor = [UIColor colorFromHexString:@"#00a0de"];
        [self.confirmButton setTitle:@" Confirmed " forState:UIControlStateNormal];
        [self.confirmButton sizeToFit];
    } else {
        self.confirmButton.backgroundColor = [UIColor colorFromHexString:@"#02CE68"];
        [self.confirmButton setTitle:@" Unconfirmed " forState:UIControlStateNormal];
        [self.confirmButton sizeToFit];
    }
    
    self.detailsBarButton = [[UIBarButtonItem alloc] initWithImage: [UIImage zng_defaultTypingIndicatorImage]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(detailsButtonPressed:)];
    self.detailsBarButton.tintColor = [UIColor colorFromHexString:@"#00a0de"];
    
    self.navigationItem.rightBarButtonItems = @[self.detailsBarButton , self.confirmBarButton, self.starBarButton];
}

- (void)confirmedButtonPressed:(UIBarButtonItem *)sender
{
    self.confirmButton.enabled = NO;

    NSNumber *confirmedParam = self.contact.isConfirmed ? @NO : @YES;
    if (self.contact.isConfirmed) {
        self.contact.isConfirmed = NO;
        self.confirmButton.backgroundColor = [UIColor colorFromHexString:@"#02CE68"];
        [self.confirmButton setTitle:@" Unconfirmed " forState:UIControlStateNormal];
        [self.confirmButton sizeToFit];
    } else {
        self.contact.isConfirmed = YES;
        self.confirmButton.backgroundColor = [UIColor colorFromHexString:@"#00a0de"];
        [self.confirmButton setTitle:@" Confirmed " forState:UIControlStateNormal];
        [self.confirmButton sizeToFit];
    }
    NSDictionary *params = @{@"is_confirmed" : confirmedParam };
    [ZNGContactClient updateContactWithId:self.contact.contactId withServiceId:self.service.serviceId withParameters:params success:^(ZNGContact *contact, ZNGStatus *status) {
        self.contact = contact;
        self.confirmButton.enabled = YES;
    } failure:^(ZNGError *error) {
        self.confirmButton.enabled = YES;
    }];
}

- (void)starButtonPressed:(UIBarButtonItem *)sender
{
    self.starBarButton.enabled = NO;

    NSNumber *starParam = self.contact.isStarred ? @NO : @YES;
    if (self.contact.isStarred) {
        self.contact.isStarred = NO;
        self.starBarButton.image = self.unstarredImage;
        self.starBarButton.tintColor = [UIColor colorFromHexString:@"#B6B8BA"];
    } else {
        self.contact.isStarred = YES;
        self.starBarButton.image = self.starredImage;
        self.starBarButton.tintColor = [UIColor colorFromHexString:@"#FFCF3A"];
    }
    NSDictionary *params = @{@"is_starred" : starParam };
    [ZNGContactClient updateContactWithId:self.contact.contactId withServiceId:self.service.serviceId withParameters:params success:^(ZNGContact *contact, ZNGStatus *status) {
        self.contact = contact;
        self.starBarButton.enabled = YES;
    } failure:^(ZNGError *error) {
        self.starBarButton.enabled = YES;
    }];

}

- (void)detailsButtonPressed:(UIBarButtonItem *)sender
{
    ZNGContactViewController *vc = [ZNGContactViewController withContact:self.contact withService:self.service];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)loadConversation
{
    [[ZingleSDK sharedSDK] addConversationFromService:self.service toContact:self.contact contactChannelValue:self.contactChannelValue success:^(ZNGConversation *conversation) {
        self.conversation = conversation;
        self.conversation.delegate = self;
        
        [self refreshViewModels];
    } failure:^(ZNGError *error) {
        [[[UIAlertView alloc] initWithTitle:@"There was a problem loading this conversation. Please try again later."
                                    message:nil
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        [self.activityIndicator removeFromSuperview];
        [self.activityIndicator stopAnimating];
    }];
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
    [self finishReceivingMessageAnimated:NO];
    [self.activityIndicator removeFromSuperview];
    [self.activityIndicator stopAnimating];
    [self setupBarButtonItems];
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
