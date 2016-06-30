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
#import <ZingleSDK/ZNGConversationViewController.h>
#import <JSQMessagesViewController/JSQMessagesTimestampFormatter.h>
#import <ZingleSDK/ZNGConversationContactToService.h>

static NSString *kZNGToken = @"[YOUR ZINGLE TOKEN]";
static NSString *kZNGKey = @"[YOUR ZINGLE KEY]";

// User-Defined Channel if using Contact User Authorization
static NSString *kZNGChannelTypeId = @"7176e36e-87d2-4161-ae2b-6848fbf3de11";
static NSString *kZNGChannelValue = @"MyChatChannel1";

@implementation ContactServiceChoosingViewController
{
    ZingleContactSession * session;
    NSArray<ZNGContactService *> * contactServices;
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
        
        ZNGConversationViewController * conversationView = segue.destinationViewController;
        ZNGConversationContactToService * conversation = session.conversation;
        conversationView.conversation = conversation;
    }
}

@end
