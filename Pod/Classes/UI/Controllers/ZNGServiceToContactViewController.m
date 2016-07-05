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
#import "UIFont+OpenSans.h"
#import "UIImage+ZingleSDK.h"
#import "UIColor+ZingleSDK.h"
#import "ZNGContactClient.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelWarning;

static NSString * const ConfirmedText = @" Confirmed ";
static NSString * const UnconfirmedText = @" Unconfirmed ";

static NSString * const KVOContactStarredPath = @"conversation.contact.isStarred";
static NSString * const KVOContactConfirmedPath = @"conversation.contact.isConfirmed";

static void * KVOContext = &KVOContext;

@implementation ZNGServiceToContactViewController
{
    UIButton * confirmedButton;
    UIBarButtonItem * starButton;
    
    UIImage * starredImage;
    UIImage * notStarredImage;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        [self setupKVO];
    }
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
    [self addObserver:self forKeyPath:KVOContactStarredPath options:NSKeyValueObservingOptionNew context:KVOContext];
    [self addObserver:self forKeyPath:KVOContactConfirmedPath options:NSKeyValueObservingOptionNew context:KVOContext];
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:KVOContactConfirmedPath context:KVOContext];
    [self removeObserver:self forKeyPath:KVOContactStarredPath context:KVOContext];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == KVOContext) {
        if ([keyPath isEqualToString:KVOContactStarredPath]) {
            [self updateStarButton];
        } else if ([keyPath isEqualToString:KVOContactConfirmedPath]) {
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
    
    ZNGContact * contact = [self contact];
    
    UIColor * color;
    NSString * text;
    
    confirmedButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 40.0)];
    confirmedButton.layer.cornerRadius = 5.0;
    [confirmedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirmedButton.titleLabel.font = [UIFont openSansBoldFontOfSize:17.0];
    [confirmedButton addTarget:self action:@selector(pressedConfirmedButton:) forControlEvents:UIControlEventTouchUpInside];
    [self updateConfirmedButton];
    UIBarButtonItem * confirmBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:confirmedButton];
    

    starredImage = [UIImage zng_lrg_starredImage];
    notStarredImage = [UIImage zng_lrg_unstarredImage];
    starButton = [[UIBarButtonItem alloc] initWithImage:notStarredImage style:UIBarButtonItemStylePlain target:self action:@selector(pressedStarButton:)];
    [self updateStarButton];
    
    return @[confirmBarButtonItem, starButton];
}

- (NSArray<UIAlertAction *> *)alertActionsForDetailsButton
{
    NSArray<UIAlertAction *> * superActions = [super alertActionsForDetailsButton];
    NSMutableArray<UIAlertAction *> * actions = ([superActions count] > 0) ? [superActions mutableCopy] : [[NSMutableArray alloc] init];
    
    UIAlertAction * editContact = [UIAlertAction actionWithTitle:@"Edit contact" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self pressedEditContact];
    }];
    
    [actions addObject:editContact];
    
    return actions;
}

#pragma mark - Star/confirmed updates
- (void) updateConfirmedButton
{
    BOOL isConfirmed = [[self contact] isConfirmed];
    UIColor * color = (isConfirmed) ? [UIColor zng_lightBlue] : [UIColor zng_green];
    NSString * text = (isConfirmed) ? ConfirmedText : UnconfirmedText ;
    confirmedButton.backgroundColor = color;
    [confirmedButton setTitle:text forState:UIControlStateNormal];
    [confirmedButton sizeToFit];
    confirmedButton.enabled = YES;
}

- (void) updateStarButton
{
    BOOL isStarred = [[self contact] isStarred];
    UIImage * image = (isStarred) ? starredImage : notStarredImage;
    UIColor * tintColor = (isStarred) ? [UIColor zng_yellow] : [UIColor zng_gray];
    starButton.image = image;
    starButton.tintColor = tintColor;
    starButton.enabled = YES;
}

#pragma mark - Actions
- (void) pressedEditContact
{
    ZNGConversationServiceToContact * conversation = (ZNGConversationServiceToContact *)self.conversation;
    ZNGContactViewController * contactView = [ZNGContactViewController withContact:conversation.contact session:conversation.messageClient.session];
    [self.navigationController pushViewController:contactView animated:YES];
}

- (void) pressedStarButton:(id)sender
{
    starButton.enabled = NO;
    
    ZNGContact * contact = [self contact];
    
    if (contact.isStarred) {
        [contact unstar];
    } else {
        [contact star];
    }
}

- (void) pressedConfirmedButton:(id)sender
{
    confirmedButton.enabled = NO;
    
    ZNGContact * contact = [self contact];
    
    if (contact.isConfirmed) {
        [contact unconfirm];
    } else {
        [contact confirm];
    }
}

@end
