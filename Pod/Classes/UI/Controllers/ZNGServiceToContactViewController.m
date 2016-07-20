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

#pragma mark - Star/confirmed updates
- (void) updateConfirmedButton
{
    if ([self.conversation.contact isConfirmed]) {
        [confirmButton stopPulsating];
    } else {
        [confirmButton startPulsating];
    }
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

- (void) pressedConfirmedButton:(id)sender
{
    ZNGContact * contact = [self contact];
    
    if (contact.isConfirmed) {
        [contact unconfirm];
    } else {
        [contact confirm];
    }
}

@end
