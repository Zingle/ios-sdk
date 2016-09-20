//
//  ContactServiceChoosingViewController.m
//  ZingleSDK
//
//  Created by Jason Neel on 6/17/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import "ContactServiceChoosingViewController.h"
#import "ContactServiceTableViewCell.h"
#import <ZingleSDK/ZingleSDK.h>
#import <ZingleSDK/ZingleContactSession.h>
#import <ZingleSDK/ZNGContactToServiceViewController.h>
#import <JSQMessagesViewController/JSQMessagesTimestampFormatter.h>
#import <ZingleSDK/ZNGConversationContactToService.h>

static NSString *kZNGToken = @"[YOUR ZINGLE TOKEN]";
static NSString *kZNGKey = @"[YOUR ZINGLE KEY]";

// User-Defined Channel if using Contact User Authorization
static NSString *kZNGChannelTypeId = @"076545a3-4d12-4162-8010-9bbb46f46b32";
static NSString *kZNGChannelValue = @"MyChatChannel1";

@implementation ContactServiceChoosingViewController
{
    ZingleContactSession * session;
    NSArray<ZNGContactService *> * contactServices;

    __weak ZNGContactToServiceViewController * conversationView;
}

- (void) viewDidLoad
{
    session = [ZingleSDK contactSessionWithToken:kZNGToken key:kZNGKey channelTypeId:kZNGChannelTypeId channelValue:kZNGChannelValue contactServiceChooser:^ZNGContactService * _Nullable(NSArray<ZNGContactService *> * _Nonnull theContactServices) {
        contactServices = theContactServices;
        
        if ([theContactServices count] > 0) {
            NSMutableArray<NSIndexPath *> * indexes = [[NSMutableArray alloc] init];
            
            for (NSUInteger i=0; i < [theContactServices count]; i++) {
                [indexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            
            [self.tableView insertRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        return nil;
    } errorHandler:nil];
    
    [session addObserver:self forKeyPath:NSStringFromSelector(@selector(conversation)) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
}

- (void) dealloc
{
    [session removeObserver:self forKeyPath:NSStringFromSelector(@selector(conversation))];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(conversation))]) {
        ZNGConversationContactToService * oldConversation = change[NSKeyValueChangeOldKey];
        ZNGConversationContactToService * conversation = change[NSKeyValueChangeNewKey];
        
        BOOL noOldConversation = (([oldConversation isKindOfClass:[NSNull class]]) || (oldConversation == nil));
        BOOL newConversationExists = ((![conversation isKindOfClass:[NSNull class]]) && (conversation != nil));
        
        if (noOldConversation && newConversationExists) {
            conversationView.conversation = conversation;
        }
    }
}

#pragma mark - Table
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [contactServices count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactServiceTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"contactServiceCell"];
    ZNGContactService * contactService = contactServices[indexPath.row];
    ZNGMessage * message = contactService.lastMessage;
    
    cell.serviceLabel.text = contactService.serviceDisplayName;
    cell.messageLabel.text = message.body;
    cell.timestampLabel.attributedText = [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.createdAt];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showMessages"]) {
        NSIndexPath * indexPath = [self.tableView indexPathForSelectedRow];
        ZNGContactService * selectedContactService = contactServices[indexPath.row];
        session.contactService = selectedContactService;
        
        ZNGContactToServiceViewController * aConversationView = segue.destinationViewController;
        conversationView = aConversationView;
        ZNGConversationContactToService * conversation = session.conversation;
        aConversationView.conversation = conversation;
    }
}

@end
