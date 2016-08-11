//
//  ZNGServiceToContactViewController.m
//  Pods
//
//  Created by Jason Neel on 7/5/16.
//
//

#import "ZNGServiceToContactViewController.h"
#import "ZNGContactViewController.h"
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
#import "ZNGPulsatingBarButtonImage.h"
#import "ZNGTemplate.h"
#import "UIViewController+ZNGSelectTemplate.h"

static NSString * const ConfirmedText = @" Confirmed ";
static NSString * const UnconfirmedText = @" Unconfirmed ";

static NSString * const KVOContactChannelsPath = @"conversation.contact.channels";
static NSString * const KVOContactConfirmedPath = @"conversation.contact.isConfirmed";
static NSString * const KVOChannelPath = @"conversation.channel";

static void * KVOContext = &KVOContext;

@implementation ZNGServiceToContactViewController
{
    ZNGPulsatingBarButtonImage * confirmButton;
    UIView * bannerContainer;
    
    dispatch_source_t emphasizeTimer;
}

@dynamic conversation;

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        [self setupKVO];
    }
    
    return self;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self != nil) {
        [self setupKVO];
    }
    
    return self;
}

- (void) setupKVO
{
    [self addObserver:self forKeyPath:KVOContactChannelsPath options:NSKeyValueObservingOptionNew context:KVOContext];
    [self addObserver:self forKeyPath:KVOContactConfirmedPath options:NSKeyValueObservingOptionNew context:KVOContext];
    [self addObserver:self forKeyPath:KVOChannelPath options:NSKeyValueObservingOptionNew context:KVOContext];
}

- (void) dealloc
{
    if (emphasizeTimer != nil) {
        dispatch_source_cancel(emphasizeTimer);
    }
    
    [self removeObserver:self forKeyPath:KVOChannelPath context:KVOContext];
    [self removeObserver:self forKeyPath:KVOContactConfirmedPath context:KVOContext];
    [self removeObserver:self forKeyPath:KVOContactChannelsPath context:KVOContext];
}

- (BOOL) weAreSendingOutbound
{
    return YES;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self updateConfirmedButton];
    [self setupBannerContainer];
    
    self.inputToolbar.contentView.textView.placeHolder = @"Type a reply here";
    [self.inputToolbar setCurrentChannel:self.conversation.channel];
    
    [self updateUIForAvailableChannels];
    
    [self startEmphasisTimer];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == KVOContext) {
        if ([keyPath isEqualToString:KVOContactConfirmedPath]) {
            [self updateConfirmedButton];
        } else if ([keyPath isEqualToString:KVOChannelPath]) {
            self.inputToolbar.currentChannel = self.conversation.channel;
        } else if ([keyPath isEqualToString:KVOContactChannelsPath]) {
            [self updateUIForAvailableChannels];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) updateUIForAvailableChannels
{
    if ([self.conversation.contact.channels count] == 0) {
        self.inputToolbar.noSelectedChannelText = @"No channels available";
        [self.inputToolbar disableInput];
    } else {
        self.inputToolbar.noSelectedChannelText = nil;
        [self.inputToolbar enableInput];
    }
}

- (ZNGContact *) contact
{
    ZNGConversationServiceToContact * conversation = (ZNGConversationServiceToContact *)self.conversation;
    return conversation.contact;
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItems
{
    NSArray<UIBarButtonItem *> * superButtonItems = [super rightBarButtonItems];
    NSMutableArray<UIBarButtonItem *> * items = ([superButtonItems count] > 0) ? [superButtonItems mutableCopy] : [[NSMutableArray alloc] init];
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    UIImage * confirmImage = [UIImage imageNamed:@"confirmButton" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImage * selectedImage = [UIImage imageNamed:@"confirmButtonSelected" inBundle:bundle compatibleWithTraitCollection:nil];
    confirmButton = [[ZNGPulsatingBarButtonImage alloc] initWithImage:confirmImage selectedImage:selectedImage target:self action:@selector(pressedConfirmedButton:)];
    confirmButton.emphasisImage = [UIImage imageNamed:@"confirmButtonEmptyCircle" inBundle:bundle compatibleWithTraitCollection:nil];
    [items addObject:confirmButton];
    
    return items;
}

- (NSArray<UIAlertAction *> *)alertActionsForDetailsButton
{
    NSArray<UIAlertAction *> * superActions = [super alertActionsForDetailsButton];
    NSMutableArray<UIAlertAction *> * actions = ([superActions count] > 0) ? [superActions mutableCopy] : [[NSMutableArray alloc] init];
    
    UIAlertAction * editContact = [UIAlertAction actionWithTitle:@"Edit contact" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self pressedEditContact];
    }];
    [actions addObject:editContact];
    
    BOOL alreadyShowingDetailedEvents = [self.conversation isKindOfClass:[ZNGConversationDetailedEvents class]];
    NSString * detailedEventsText = (alreadyShowingDetailedEvents) ? @"Hide detailed events" : @"Show detailed events";
    UIAlertAction * toggleDetailedEvents = [UIAlertAction actionWithTitle:detailedEventsText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (alreadyShowingDetailedEvents) {
            self.conversation = [[ZNGConversationServiceToContact alloc] initWithConversation:self.conversation];
        } else {
            self.conversation = [[ZNGConversationDetailedEvents alloc] initWithConversation:self.conversation];
        }
        
        [self.conversation loadRecentEventsErasingOlderData:YES];
    }];
    [actions addObject:toggleDetailedEvents];
    
    ZNGContact * contact = self.conversation.contact;
    BOOL isStarred = [self.conversation.contact isStarred];
    NSString * starText = isStarred ? @"Unstar conversation" : @"Star conversation";
    UIAlertAction * toggleStarred = [UIAlertAction actionWithTitle:starText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (isStarred) {
            [contact unstar];
        } else {
            [contact star];
        }
    }];
    [actions addObject:toggleStarred];
    
    return actions;
}

- (NSString * _Nullable) nameForMessageAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
    
    BOOL isOutboundMessage = ([event isMessage] && [event.message isOutbound]);
    BOOL isInternalNote = [event isNote];
    
    // We will show an employee name for every outbound message and note
    if (isOutboundMessage || isInternalNote) {
        return event.senderDisplayName;
    }
    
    // This is probably an incoming message.  The contact's name is in the title bar; we do not need one above message bubbles.
    return nil;
}

#pragma mark - Confirmed button
- (void) updateConfirmedButton
{
    if ([self.conversation.contact isConfirmed]) {
        confirmButton.selected = YES;
    } else {
        confirmButton.selected = NO;
    }
}

- (void) pressedConfirmedButton:(id)sender
{
    ZNGContact * contact = [self contact];
    
    if (contact.isConfirmed) {
        [contact unconfirm];
        confirmButton.selected = NO;
        [self showBannerWithText:@"UNCONFIRMED"];
    } else {
        [contact confirm];
        confirmButton.selected = YES;
        [self showBannerWithText:@"CONFIRMED"];
    }
}

- (void) startEmphasisTimer
{
    if (emphasizeTimer != nil) {
        return;
    }
    
    emphasizeTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    
    if (emphasizeTimer != nil) {
        uint64_t interval = 3 * NSEC_PER_SEC;
        dispatch_source_set_timer(emphasizeTimer, DISPATCH_TIME_NOW, interval, (uint64_t)(0.1 * NSEC_PER_SEC));
        __weak ZNGServiceToContactViewController * weakSelf = self;
        dispatch_source_set_event_handler(emphasizeTimer, ^{
            [weakSelf emphasizeConfirmButtonIfAppropriate];
        });
        dispatch_resume(emphasizeTimer);
    }
}

- (void) emphasizeConfirmButtonIfAppropriate
{
    if ((self.conversation.contact != nil) && (![self.conversation.contact isConfirmed])) {
        [confirmButton emphasize];
    }
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

- (void) showBannerWithText:(NSString *)text
{
    CGRect rect = CGRectMake(0.0, 0.0, bannerContainer.frame.size.width, bannerContainer.frame.size.height);
    UIView * bannerContent = [[UIView alloc] initWithFrame:rect];
    bannerContent.translatesAutoresizingMaskIntoConstraints = NO;
    bannerContent.backgroundColor = [UIColor zng_lightBlue];
    NSLayoutConstraint * height = [NSLayoutConstraint constraintWithItem:bannerContent attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:bannerContainer attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    NSLayoutConstraint * width = [NSLayoutConstraint constraintWithItem:bannerContent attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:bannerContainer attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:bannerContent attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:bannerContainer attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint * offScreenY = [NSLayoutConstraint constraintWithItem:bannerContent attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bannerContainer attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint * onScreenY = [NSLayoutConstraint constraintWithItem:bannerContent attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:bannerContainer attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    [bannerContainer addSubview:bannerContent];
    [bannerContainer addConstraints:@[height, width, left, offScreenY]];
    
    UILabel * textLabel = [[UILabel alloc] initWithFrame:rect];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.font = [UIFont latoBoldFontOfSize:15.0];
    textLabel.textColor = [UIColor whiteColor];
    textLabel.text = text;
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint * centerX = [NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:bannerContent attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint * centerY = [NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:bannerContent attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    [bannerContent addSubview:textLabel];
    [bannerContent addConstraints:@[centerX, centerY]];

    
    // Animate on screen
    [bannerContainer layoutIfNeeded];
    
    [UIView animateWithDuration:0.5 animations:^{
        [bannerContainer removeConstraint:offScreenY];
        [bannerContainer addConstraint:onScreenY];
        [bannerContainer layoutIfNeeded];
    } completion:^(BOOL finished) {
        // Animate back off screen
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [bannerContainer layoutIfNeeded];
            
            [UIView animateWithDuration:0.5 animations:^{
                [bannerContainer removeConstraint:onScreenY];
                [bannerContainer addConstraint:offScreenY];
                [bannerContainer layoutIfNeeded];
            } completion:^(BOOL finished) {
                [bannerContent removeFromSuperview];
            }];
        });
    }];
}

#pragma mark - Collection view shenanigans
- (BOOL) shouldShowTimestampAboveIndexPath:(NSIndexPath *)indexPath
{
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
    return ([self.conversation.contact.channels count] > 1);
}

- (BOOL) contactChannelAtIndexPathChangedSincePriorMessage:(NSIndexPath *)indexPath
{
    ZNGEvent * event = [self eventAtIndexPath:indexPath];
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

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    NSAttributedString * attributedString = [super collectionView:collectionView attributedTextForCellTopLabelAtIndexPath:indexPath];
    
    // Check if we are showing a timestamp (i.e. super returned a string) and we want to display channel info (i.e. this user has more than one channel available)
    if (([attributedString length] > 0) && ([self shouldShowChannelInfoUnderTimestamps])) {
        ZNGEvent * event = [self eventAtIndexPath:indexPath];
        ZNGChannel * channel = [[event.message contactCorrespondent] channel];
        
        if (channel != nil) {
            NSString * channelString = [NSString stringWithFormat:@"\n%@: %@", channel.displayName, [self.conversation.service displayNameForChannel:channel]];
            NSDictionary * attributes = @{ NSFontAttributeName : [UIFont latoFontOfSize:12.0] };
            NSAttributedString * attributedChannelString = [[NSAttributedString alloc] initWithString:channelString attributes:attributes];
            NSMutableAttributedString * mutableString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
            [mutableString appendAttributedString:attributedChannelString];
            attributedString = mutableString;
        }
    }
    
    return attributedString;
}

- (CGFloat) collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [super collectionView:collectionView layout:collectionViewLayout heightForCellTopLabelAtIndexPath:indexPath];
    
    if (([self shouldShowTimestampAboveIndexPath:indexPath]) && ([self shouldShowChannelInfoUnderTimestamps])) {
        height += 18.0;
    }
    
    return height;
}

- (BOOL) shouldShowChannelInfo
{
    return ([self.conversation.contact.channels count] > 1);
}

#pragma mark - Actions
- (NSString *)displayNameForChannel:(ZNGChannel *)channel
{
    return [self.conversation.service displayNameForChannel:channel];
}

- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressInsertCustomFieldButton:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select a custom field to insert" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
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

- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressUseTemplateButton:(id)sender
{
    [self presentUserWithChoiceOfTemplate:self.conversation.service.templates completion:^(NSString * _Nullable selectedTemplateBody) {
        if (selectedTemplateBody != nil) {
            [self appendStringToMessageInput:selectedTemplateBody];
        }
    }];
}

- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressChooseChannelButton:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select a channel" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([self.conversation.contact.channels count] == 0) {
        alert.title = @"No available channels";
    }

    for (ZNGChannel * channel in self.conversation.contact.channels) {
        NSString * displayName = [self.conversation.service displayNameForChannel:channel];
        UIAlertAction * action = [UIAlertAction actionWithTitle:displayName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.conversation.channel = channel;
        }];
        [alert addAction:action];
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressAddInternalNoteButton:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Enter an internal note" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Internal note";
    }];
    UIAlertAction * addNote = [UIAlertAction actionWithTitle:@"Add note" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField * noteField = [alert.textFields firstObject];
        NSString * note = noteField.text;
        
        if ([note length] > 0) {
            [self addInternalNote:note];
        }
    }];
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:addNote];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressTriggerAutomationButton:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select an automation" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSUInteger automationCount = 0;
    
    for (ZNGAutomation * automation in self.conversation.service.automations) {
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
        }
    }];
}

- (void) addInternalNote:(NSString *)note
{
    __weak ZNGServiceToContactViewController * weakSelf = self;
    
    [self.conversation addInternalNote:note success:nil failure:^(ZNGError * _Nonnull error) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Failed to add note" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [weakSelf presentViewController:alert animated:YES completion:nil];
    }];
}

- (void) insertCustomField:(ZNGContactField *)customField
{
    NSString * replacementValue = [NSString stringWithFormat:@"{%@}", customField.replacementVariable];
    
    [self appendStringToMessageInput:replacementValue];
}

- (void) appendStringToMessageInput:(NSString *)text
{
    self.inputToolbar.contentView.textView.text = [self.inputToolbar.contentView.textView.text stringByAppendingString:text];

}

- (void) pressedEditContact
{
    ZNGConversationServiceToContact * conversation = (ZNGConversationServiceToContact *)self.conversation;
    ZNGContactViewController * contactView = [ZNGContactViewController withContact:conversation.contact session:(ZingleAccountSession *)conversation.messageClient.session];
    [self.navigationController pushViewController:contactView animated:YES];
}

@end
