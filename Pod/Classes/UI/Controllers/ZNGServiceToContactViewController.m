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
#import "UIFont+OpenSans.h"
#import "UIImage+ZingleSDK.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGContactClient.h"
#import "ZNGContactField.h"
#import "ZNGLogging.h"
#import "ZNGConversationDetailedEvents.h"
#import "ZNGEventCollectionViewCell.h"
#import "ZNGConversationFlowLayout.h"
#import "ZNGPulsatingBarButtonImage.h"

static NSString * const ConfirmedText = @" Confirmed ";
static NSString * const UnconfirmedText = @" Unconfirmed ";

static NSString * const KVOContactConfirmedPath = @"conversation.contact.isConfirmed";

static void * KVOContext = &KVOContext;

@implementation ZNGServiceToContactViewController
{
    ZNGPulsatingBarButtonImage * confirmButton;
    UIView * bannerContainer;
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
    [self addObserver:self forKeyPath:KVOContactConfirmedPath options:NSKeyValueObservingOptionNew context:KVOContext];
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:KVOContactConfirmedPath context:KVOContext];
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
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == KVOContext) {
        if ([keyPath isEqualToString:KVOContactConfirmedPath]) {
            [self updateConfirmedButton];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
    confirmButton = [[ZNGPulsatingBarButtonImage alloc] initWithImage:confirmImage tintColor:[UIColor whiteColor] pulsateColor:[UIColor zng_green] target:self action:@selector(pressedConfirmedButton:)];
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
        
        [self.conversation updateEvents];
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

#pragma mark - Confirmed button
- (void) updateConfirmedButton
{
    if ([self.conversation.contact isConfirmed]) {
        [confirmButton stopPulsating];
    } else {
        [confirmButton startPulsating];
    }
}

- (void) pressedConfirmedButton:(id)sender
{
    ZNGContact * contact = [self contact];
    
    if (contact.isConfirmed) {
        [contact unconfirm];
        [self showBannerWithText:@"UNCONFIRMED"];
    } else {
        [contact confirm];
        [self showBannerWithText:@"CONFIRMED"];
    }
}

#pragma mark - Confirmed banner
- (void) setupBannerContainer
{
    bannerContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 30.0)];
    bannerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    bannerContainer.layer.masksToBounds = YES;
    
    NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:bannerContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint * width = [NSLayoutConstraint constraintWithItem:bannerContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:bannerContainer attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint * height = [NSLayoutConstraint constraintWithItem:bannerContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:nil multiplier:1.0 constant:30.0];
    
    [self.view addSubview:bannerContainer];
    [self.view addConstraints:@[top, width, left, height]];
}

- (void) showBannerWithText:(NSString *)text
{
    CGRect onScreenRect = CGRectMake(0.0, 0.0, bannerContainer.frame.size.width, bannerContainer.frame.size.height);
    CGRect offScreenRect = CGRectMake(0.0, -bannerContainer.frame.size.height, bannerContainer.frame.size.width, bannerContainer.frame.size.height);
    UIView * bannerContent = [[UIView alloc] initWithFrame:offScreenRect];
    bannerContent.backgroundColor = [UIColor zng_blue];
    
    UILabel * textLabel = [[UILabel alloc] initWithFrame:onScreenRect];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.font = [UIFont openSansBoldFontOfSize:15.0];
    textLabel.textColor = [UIColor whiteColor];
    textLabel.text = text;
    [bannerContent addSubview:textLabel];
    
    // Add off-screen
    [bannerContainer addSubview:bannerContent];
    
    // Animate on screen
    [UIView animateWithDuration:0.5 animations:^{
        bannerContent.frame = onScreenRect;
    } completion:^(BOOL finished) {
        // Animate back off screen
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 animations:^{
                bannerContent.frame = offScreenRect;
            } completion:^(BOOL finished) {
                [bannerContent removeFromSuperview];
            }];
        });
    }];
}

#pragma mark - Actions
- (void) inputToolbar:(ZNGConversationInputToolbar *)toolbar didPressInsertCustomFieldButton:(id)sender
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select a custom field to insert" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (ZNGContactField * customField in self.conversation.service.contactCustomFields) {
        UIAlertAction * action = [UIAlertAction actionWithTitle:customField.displayName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self insertCustomField:customField];
        }];
        [alert addAction:action];
    }
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) insertCustomField:(ZNGContactField *)customField
{
    // TODO: Once the server starts giving us replacement values
    // See: http://jira.zinglecorp.com:8080/browse/TECH-1940
    NSString * replacementValue = @"{PLACEHOLDER}";
    
    self.inputToolbar.contentView.textView.text = [self.inputToolbar.contentView.textView.text stringByAppendingString:replacementValue];
}

- (void) pressedEditContact
{
    ZNGConversationServiceToContact * conversation = (ZNGConversationServiceToContact *)self.conversation;
    ZNGContactViewController * contactView = [ZNGContactViewController withContact:conversation.contact session:(ZingleAccountSession *)conversation.messageClient.session];
    [self.navigationController pushViewController:contactView animated:YES];
}

@end
