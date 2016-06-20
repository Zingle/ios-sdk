//
//  MessageViewController.m
//  ZingleSDK
//
//  Created by Jason Neel on 6/20/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import "MessageViewController.h"
#import "ZNGContactService.h"
#import "ZNGConversation.h"
#import "ZingleContactSession.h"

@interface MessageViewController ()

@end

@implementation MessageViewController
{
    ZNGConversation * conversation;
    CGRect originalFrame;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.contactService.serviceDisplayName;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustForKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustForKeyboard:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    originalFrame = self.view.frame;
}

#pragma mark - Message data/comms
- (void) setContactService:(ZNGContactService *)contactService
{
    BOOL hadOlderContactService = (self.contactService != nil);
    _contactService = contactService;
    conversation = self.session.conversation;
    
    self.navigationItem.title = contactService.serviceDisplayName;
    
    if (hadOlderContactService) {
        [self.tableView reloadData];
    } else if ([conversation.messages count] > 0) {
        [self.tableView beginUpdates];
        [conversation.messages enumerateObjectsUsingBlock:^(ZNGMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        [self.tableView endUpdates];
    }
}

#pragma mark - Keyboard handling
- (void) adjustForKeyboard:(NSNotification *)notification
{
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        [UIView animateWithDuration:0.5 animations:^{
            self.view.frame = CGRectMake(originalFrame.origin.x, originalFrame.origin.y, self.view.frame.size.width, self.view.frame.size.height - keyboardFrame.size.height);
        }];
    } else if ([notification.name isEqualToString:UIKeyboardWillHideNotification]) {
        [UIView animateWithDuration:0.5 animations:^{
            self.view.frame = originalFrame;
        }];
    }
}

#pragma mark - Actions
- (IBAction)pressedAttach:(id)sender
{
    
}

- (IBAction)presesdSend:(id)sender
{
    if (conversation == nil) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Unable to send" message:@"We do not have an active conversation :(" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    self.sendButton.enabled = NO;
    self.inputTextField.enabled = NO;
    self.attachButton.enabled = NO;
    
    void (^reenableButtons)() = ^{
        self.sendButton.enabled = YES;
        self.inputTextField.enabled = YES;
        self.attachButton.enabled = YES;
    };
    
    [conversation sendMessageWithBody:self.inputTextField.text success:^(ZNGStatus *status) {
        [self.tableView reloadData];
        reenableButtons();
    } failure:^(ZNGError *error) {
        NSString * errorText = [NSString stringWithFormat:@"Error sending message: %@", error];
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Unable to send" message:errorText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        reenableButtons();
    }];
}

#pragma mark - Table
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [conversation.messages count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessage * message = conversation.messages[indexPath.row];
    static NSString * cellId = @"messageCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellId];
    }
    
    cell.textLabel.text = ([message isOutbound]) ? self.contactService.serviceDisplayName : @"Me";
    cell.detailTextLabel.text = message.body;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessage * message = conversation.messages[indexPath.row];
    NSDictionary * textAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"Helvetica" size:17.0] };
    CGRect rect = [message.body boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttributes context:nil];
    
    return rect.size.height;
}

@end
