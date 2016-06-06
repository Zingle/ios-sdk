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
#import "ZNGTemplateClient.h"
#import "ZNGAutomationClient.h"
#import "ZNGContactClient.h"
#import "ZNGMessageClient.h"
#import "ZNGServiceClient.h"

@interface ZNGConversationViewController ()

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

static NSString *kZNGSendMessageError = @"There was a problem sending your message. Please try again later.";
static NSString *kZNGDeleteMessageError = @"There was a problem deleting your message. Please try again later.";

+ (ZNGConversationViewController *)toService:(ZNGService *)service
                                     contact:(ZNGContact *)contact
                                  senderName:(NSString *)senderName
                                receiverName:(NSString *)receiverName
{
    ZNGConversationViewController *vc = (ZNGConversationViewController *)[ZNGConversationViewController messagesViewController];
    
    if (vc) {
        vc.toService = YES;
        vc.service = service;
        vc.contact = contact;
        vc.senderName = senderName;
        vc.receiverName = receiverName;
    }
    
    return vc;
}

+ (ZNGConversationViewController *)toContact:(ZNGContact *)contact
                                     service:(ZNGService *)service
                                  senderName:(NSString *)senderName
                                receiverName:(NSString *)receiverName
{
    ZNGConversationViewController *vc = (ZNGConversationViewController *)[ZNGConversationViewController messagesViewController];
    
    if (vc) {
        vc.toService = NO;
        vc.service = service;
        vc.contact = contact;
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
    
    self.senderDisplayName = self.senderName ?: @"Me";
    
    self.titleViewLabel.font = [UIFont openSansBoldFontOfSize:17.0f];
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    self.showLoadEarlierMessagesHeader = NO;
    
    ZNGBubbleImageFactory *bubbleFactory = [[ZNGBubbleImageFactory alloc] init];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:self.outgoingBubbleColor];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:self.incomingBubbleColor];
    
    if (self.service) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stopPollingTimer)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startPollingTimer)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        ZNGConversation *conversation;
        if (self.toService) {
            self.senderId = self.contact.contactId;
            conversation = [[ZingleSDK sharedSDK] conversationToService:self.service.serviceId];
        } else {
            self.senderId = self.service.serviceId;
            conversation = [[ZingleSDK sharedSDK] conversationToContact:self.contact.contactId];
        }
        if (conversation) {
            [self showActivityIndicator];
            self.conversation = conversation;
            self.conversation.delegate = self;
            [self refreshViewModels];
        } else {
            [self loadConversation];
        }
        if (!self.toService) {
            [self setupBarButtonItems];
        }

        
    }
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[ZingleSDK sharedSDK] clearCachedConversations];
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
        self.starBarButton.tintColor = [UIColor zng_yellow];
    } else {
        self.starBarButton = [[UIBarButtonItem alloc] initWithImage:self.unstarredImage
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(starButtonPressed:)];
        self.starBarButton.tintColor = [UIColor zng_gray];
    }
    
    self.confirmButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    self.confirmButton.layer.cornerRadius = 5;
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont openSansBoldFontOfSize:17.0f];
    [self.confirmButton addTarget:self action:@selector(confirmedButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.confirmBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.confirmButton];
    
    if (self.contact.isConfirmed) {
        self.confirmButton.backgroundColor = [UIColor zng_lightBlue];
        [self.confirmButton setTitle:@" Confirmed " forState:UIControlStateNormal];
        [self.confirmButton sizeToFit];
    } else {
        self.confirmButton.backgroundColor = [UIColor zng_green];
        [self.confirmButton setTitle:@" Unconfirmed " forState:UIControlStateNormal];
        [self.confirmButton sizeToFit];
    }
    
    self.detailsBarButton = [[UIBarButtonItem alloc] initWithImage: [UIImage zng_defaultTypingIndicatorImage]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(detailsButtonPressed:)];
    
    self.navigationItem.rightBarButtonItems = @[self.detailsBarButton , self.confirmBarButton, self.starBarButton];
    
    if (self.toService) {
        self.titleViewLabel.text = self.service.displayName;
    } else {
        self.titleViewLabel.text = [self.contact fullName];
    }
}

- (void)refreshContact
{
    [ZNGContactClient contactWithId:self.contact.contactId withServiceId:self.service.serviceId success:^(ZNGContact *contact, ZNGStatus *status) {
        self.contact = contact;
        [self setupBarButtonItems];
    } failure:nil];
}

- (void)confirmedButtonPressed:(UIBarButtonItem *)sender
{
    self.confirmButton.enabled = NO;

    NSNumber *confirmedParam = self.contact.isConfirmed ? @NO : @YES;
    if (self.contact.isConfirmed) {
        self.contact.isConfirmed = NO;
        self.confirmButton.backgroundColor = [UIColor zng_green];
        [self.confirmButton setTitle:@" Unconfirmed " forState:UIControlStateNormal];
        [self.confirmButton sizeToFit];
    } else {
        self.contact.isConfirmed = YES;
        self.confirmButton.backgroundColor = [UIColor zng_lightBlue];
        [self.confirmButton setTitle:@" Confirmed " forState:UIControlStateNormal];
        [self.confirmButton sizeToFit];
    }
    NSDictionary *params = @{@"is_confirmed" : confirmedParam };
    [ZNGContactClient updateContactWithId:self.contact.contactId withServiceId:self.service.serviceId withParameters:params success:^(ZNGContact *contact, ZNGStatus *status) {
//        self.contact = contact;
        if (self.detailDelegate) {
            [self.detailDelegate didUpdateContact];
        }
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
        self.starBarButton.tintColor = [UIColor zng_gray];
    } else {
        self.contact.isStarred = YES;
        self.starBarButton.image = self.starredImage;
        self.starBarButton.tintColor = [UIColor zng_yellow];
    }
    NSDictionary *params = @{@"is_starred" : starParam };
    [ZNGContactClient updateContactWithId:self.contact.contactId withServiceId:self.service.serviceId withParameters:params success:^(ZNGContact *contact, ZNGStatus *status) {
//        self.contact = contact;
        if (self.detailDelegate) {
            [self.detailDelegate didUpdateContact];
        }
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

- (void)showActivityIndicator
{
    self.activityIndicator = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallPulseSync tintColor:[UIColor zng_lightBlue] size:30.0f];
    ;
    CGRect actFrame = CGRectMake((self.navigationController.navigationBar.bounds.size.width)/2 - 15, (self.collectionView.bounds.size.height)/2 - 15, 30, 30);
    self.activityIndicator.frame = actFrame;
    [self.view addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
}

- (void)loadConversation
{
    [self showActivityIndicator];
    
    if (self.toService) {
        [[ZingleSDK sharedSDK] addConversationFromContact:self.contact toService:self.service success:^(ZNGConversation *conversation) {
            self.conversation = conversation;
            self.conversation.delegate = self;
            
        } failure:^(ZNGError *error) {
            [self showAlertForError:error];
            [self.activityIndicator removeFromSuperview];
            [self.activityIndicator stopAnimating];
        }];
    } else {
        [[ZingleSDK sharedSDK] addConversationFromService:self.service toContact:self.contact success:^(ZNGConversation *conversation) {
            self.conversation = conversation;
            self.conversation.delegate = self;
            
        } failure:^(ZNGError *error) {
            [self showAlertForError:error];
            [self.activityIndicator removeFromSuperview];
            [self.activityIndicator stopAnimating];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.toService) {
        self.titleViewLabel.text = self.service.displayName;
    } else {
        self.titleViewLabel.text = [self.contact fullName];
    }
    
    if (self.detailDelegate) {
        [self.detailDelegate didUpdateContact];
    }
    
    if (self.modalDelegate) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                              target:self
                                                                                              action:@selector(closePressed:)];
    }
    
    [self refreshContact];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startPollingTimer];
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
    self.automaticallyScrollsToMostRecentMessage = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopPollingTimer];
}

- (void)refreshConversation
{
    [self.conversation updateMessages];
}

- (void)showAlertForError:(ZNGError *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:error.errorText message:error.errorDescription preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction: ok];
    
    [self presentViewController:alert animated:YES completion:nil];
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
                                                                                       media:item
                                                                                        note:message.recipient.channel.formattedValue];
            [tempArray addObject:viewModel];
        } else if (message.body) {
            ZNGMessageViewModel *viewModel =   [[ZNGMessageViewModel alloc] initWithSenderId:message.sender.correspondentId
                                                                           senderDisplayName:senderDisplayName
                                                                                        date:message.createdAt
                                                                                        text:message.body
                                                                                        note:message.recipient.channel.formattedValue];
            [tempArray addObject:viewModel];
        }
    }
    
    self.viewModels = tempArray;
    [self finishReceivingMessageAnimated:NO];
    [self.activityIndicator removeFromSuperview];
    [self.activityIndicator stopAnimating];
}

- (void)showErrorMessage:(NSString *)errorMessage
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:errorMessage
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction: ok];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - ZNGConversationDelegate

- (void)messagesUpdated:(BOOL)newMessages;
{
    [self startPollingTimer];
    if (newMessages) {
        [self refreshViewModels];
    } else {
        [self.activityIndicator removeFromSuperview];
        [self.activityIndicator stopAnimating];
    }
}

#pragma mark - Actions

- (void)closePressed:(UIBarButtonItem *)sender
{
    [self.modalDelegate didDismissZNGConversationViewController:self];
}

#pragma mark - ZNGBaseViewController method overrides

- (void)didPressSendButton:(UIButton *)buttonÏ
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    [self.conversation sendMessageWithBody:text success:^(ZNGStatus *status) {
        ZNGMessageViewModel *viewModel =   [[ZNGMessageViewModel alloc] initWithSenderId:senderId
                                                                       senderDisplayName:senderDisplayName
                                                                                    date:[NSDate date]
                                                                                    text:text
                                                                                    note:@"Delivered"];
        [self.viewModels addObject:viewModel];
        [self finishSendingMessageAnimated:YES];
    } failure:^(ZNGError *error) {
        [self showErrorMessage:kZNGSendMessageError];
    }];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *template = [UIAlertAction actionWithTitle:@"Use Template" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showTemplates:sender];
    }];
    [sheet addAction:template];
    
    UIAlertAction *customField = [UIAlertAction actionWithTitle:@"Insert Custom Field" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showCustomFields:sender];
    }];
    [sheet addAction:customField];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:@"Take a Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:picker animated:YES completion:nil];
    }];
    [sheet addAction:takePhoto];
    
    UIAlertAction *choosePhoto = [UIAlertAction actionWithTitle:@"Choose a Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:nil];
    }];
    [sheet addAction:choosePhoto];
    
    UIAlertAction *automations = [UIAlertAction actionWithTitle:@"Automation" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAutomations:sender];
    }];
    [sheet addAction:automations];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [sheet addAction:cancelAction];
    
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = sender;
        sheet.popoverPresentationController.sourceRect = sender.bounds;
    }
    
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showAutomations:(UIButton *)sender
{
    [ZNGAutomationClient automationListWithParameters:nil withServiceId:self.service.serviceId success:^(NSArray *automations, ZNGStatus *status) {
        
        UIAlertController *automationTemplate = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (ZNGAutomation *automation in automations) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:automation.displayName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                [ZNGContactClient triggerAutomationWithId:automation.automationId withContactId:self.contact.contactId withServiceId:self.service.serviceId success:^(ZNGStatus *status) {
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Automation triggered."
                                                                                   message:nil
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        [alert dismissViewControllerAnimated:YES completion:nil];
                    }];
                    [alert addAction: ok];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                } failure:^(ZNGError *error) {
                    [self showAlertForError:error];
                }];
            }];
            
            [automationTemplate addAction:action];
        }
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [automationTemplate addAction:cancelAction];
        
        if (automationTemplate.popoverPresentationController) {
            automationTemplate.popoverPresentationController.sourceView = sender;
            automationTemplate.popoverPresentationController.sourceRect = sender.bounds;
        }
        
        [self presentViewController:automationTemplate animated:YES completion:nil];
        
    } failure:^(ZNGError *error) {
        [self showAlertForError:error];
    }];
}

- (void)showTemplates:(UIButton *)sender
{
    [ZNGTemplateClient templateListWithParameters:nil withServiceId:self.service.serviceId success:^(NSArray *templ, ZNGStatus *status) {
        
        UIAlertController *templateMenu = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (ZNGTemplate *template in templ) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:template.displayName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                self.inputToolbar.contentView.textView.text = template.body;
                [self.inputToolbar toggleSendButtonEnabled];
            }];
            
            [templateMenu addAction:action];
        }
        
        if (templateMenu.popoverPresentationController) {
            templateMenu.popoverPresentationController.sourceView = sender;
            templateMenu.popoverPresentationController.sourceRect = sender.bounds;
        }
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [templateMenu addAction:cancelAction];
        
        [self presentViewController:templateMenu animated:YES completion:nil];

    } failure:^(ZNGError *error) {
        [self showAlertForError:error];
    }];
}

- (void)showCustomFields:(UIButton *)sender
{
    UIAlertController *fieldMenu = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (ZNGContactFieldValue *fieldValue in self.contact.customFieldValues) {
        if (fieldValue.value) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:fieldValue.value style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                UITextRange *selRange = self.inputToolbar.contentView.textView.selectedTextRange;
                UITextPosition *selStartPos = selRange.start;
                NSInteger idx = [self.inputToolbar.contentView.textView offsetFromPosition:self.inputToolbar.contentView.textView.beginningOfDocument toPosition:selStartPos];
                
                NSMutableString *textViewString = [NSMutableString stringWithString:self.inputToolbar.contentView.textView.text];
                [textViewString insertString:fieldValue.value atIndex:idx];
                self.inputToolbar.contentView.textView.text = textViewString;
                [self.inputToolbar toggleSendButtonEnabled];
            }];
            
            [fieldMenu addAction:action];
        }
    }
    
    if (fieldMenu.popoverPresentationController) {
        fieldMenu.popoverPresentationController.sourceView = sender;
        fieldMenu.popoverPresentationController.sourceRect = sender.bounds;
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [fieldMenu addAction:cancelAction];
    
    [self presentViewController:fieldMenu animated:YES completion:nil];
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
                                                                                       media:item
                                                                                        note:@"Delivered"];
            [self.viewModels addObject:viewModel];
            [self finishSendingMessageAnimated:YES];

        } failure:^(ZNGError *error) {
            [self showErrorMessage:kZNGSendMessageError];
        }];
    }];
}

#pragma mark - ZingleSDK CollectionView DataSource

- (id<ZNGMessageData>)collectionView:(ZNGCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewModels objectAtIndex:indexPath.item];
}

- (void)collectionView:(ZNGCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessageViewModel *messageViewModel = [self.viewModels objectAtIndex:indexPath.item];
    
    // Search for the message. Search in reverse because most likely message to delete will be at the end.
    // TODO: To make this more efficient, the ZNGMessageViewModel should have a messageId property.
    ZNGMessage *message = nil;
    for (ZNGMessage *m in [self.conversation.messages reverseObjectEnumerator]) {
        
        if ([messageViewModel.text isEqualToString:m.body] &&
            [messageViewModel.date compare:m.createdAt] == NSOrderedSame) {
            
            message = m;
            break;
        }
    
    }
    
    if (message != nil) {
        
        [ZNGMessageClient deleteMessages:@[message.messageId] withServiceId:self.service.serviceId success:^(ZNGStatus *status) {
            
        } failure:^(ZNGError *error) {
            [self showErrorMessage:kZNGDeleteMessageError];
        }];
        
        [self.viewModels removeObjectAtIndex:indexPath.item];
    }
    
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
    ZNGMessageViewModel *message = [self.viewModels objectAtIndex:indexPath.item];
    if (message.note) {
        return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Channel: %@", message.note]];
    }
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

#pragma mark - ZNGComposerTextViewPasteDelegate methods

- (BOOL)composerTextView:(ZNGComposerTextView *)textView shouldPasteWithSender:(id)sender
{
    if ([UIPasteboard generalPasteboard].image) {
    
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Send image in clipboard?" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction: cancel];
        
        UIAlertAction *send = [UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self scrollToBottomAnimated:YES];
            // If there's an image in the pasteboard, `send` it.
            [self.conversation sendMessageWithImage:[UIPasteboard generalPasteboard].image success:^(ZNGStatus *status) {
                
                ZNGPhotoMediaItem *item = [[ZNGPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
                item.appliesMediaViewMaskAsOutgoing = YES;
                ZNGMessageViewModel *viewModel =   [[ZNGMessageViewModel alloc] initWithSenderId:self.senderId
                                                                               senderDisplayName:self.senderDisplayName
                                                                                            date:[NSDate date]
                                                                                           media:item
                                                                                            note:@"Delivered"];
                [self.viewModels addObject:viewModel];
                [self finishSendingMessageAnimated:YES];
                
            } failure:^(ZNGError *error) {
                [self showErrorMessage:kZNGSendMessageError];
            }];
        }];
        [alert addAction: send];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        return NO;
    }
    return YES;
}

@end
