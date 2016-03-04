//
//  ZNGNewConvoViewController.m
//  Pods
//
//  Created by Ryan Farley on 3/2/16.
//
//

#import "ZNGNewConvoViewController.h"
#import <ZingleSDK/ZingleSDK.h>
#import "ZNGMessageViewModel.h"

@interface ZNGNewConvoViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ZNGNewConvoViewController

- (id)initWithConversation:(ZNGConversation *)conversation
{
    NSBundle *bundle = [NSBundle bundleForClass:ZingleSDK.class];
    self = (ZNGNewConvoViewController *)[[UIStoryboard storyboardWithName:@"Zingle" bundle:bundle] instantiateInitialViewController];
    
    if (self) {
        _conversation = conversation;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.conversation.delegate = self;
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 160.0;
    
    UINib *messageCell = [UINib nibWithNibName:NSStringFromClass([ZNGMessageTableViewCell class]) bundle:[NSBundle bundleForClass:[self class]]];
    [self.tableView registerNib:messageCell forCellReuseIdentifier:[ZNGMessageTableViewCell reuseIdentifier]];
}

#pragma mark - ZNGConversationDelegate
- (void)messagesUpdated
{
    [self.tableView reloadData];
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.conversation.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessageViewModel *messageViewModel = [self messageViewModelWithMessage:[self.conversation.messages objectAtIndex:indexPath.row]];
    ZNGMessageTableViewCell *cell = (ZNGMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[ZNGMessageTableViewCell reuseIdentifier]];
    [cell configureCellForMessage:messageViewModel withDirection:[self.conversation messageDirectionFor:messageViewModel.message]];
    return cell;
}

- (ZNGMessageViewModel *)messageViewModelWithMessage:(ZNGMessage *)message
{
    ZNGMessageViewModel *messageViewModel = [[ZNGMessageViewModel alloc] initWithMessage:message];
    if (self.inboundBackgroundColor) messageViewModel.inboundBackgroundColor = self.inboundBackgroundColor;
    if (self.outboundBackgroundColor) messageViewModel.outboundBackgroundColor = self.outboundBackgroundColor;
    if (self.inboundTextColor) messageViewModel.inboundTextColor = self.inboundTextColor;
    if (self.outboundTextColor) messageViewModel.outboundTextColor = self.outboundTextColor;
    if (self.eventBackgroundColor) messageViewModel.eventBackgroundColor = self.eventBackgroundColor;
    if (self.eventTextColor) messageViewModel.eventTextColor = self.eventTextColor;
    if (self.authorTextColor) messageViewModel.authorTextColor = self.authorTextColor;
    if (self.bodyPadding) messageViewModel.bodyPadding = self.bodyPadding;
    if (self.messageVerticalMargin) messageViewModel.messageVerticalMargin = self.messageVerticalMargin;
    if (self.messageHorziontalMargin) messageViewModel.messageHorziontalMargin = self.messageHorziontalMargin;
    if (self.messageIndentAmount) messageViewModel.messageIndentAmount = self.messageIndentAmount;
    if (self.cornerRadius) messageViewModel.cornerRadius = self.cornerRadius;
    if (self.arrowOffset) messageViewModel.arrowOffset = self.arrowOffset;
    if (self.arrowBias) messageViewModel.arrowBias = self.arrowBias;
    if (self.arrowWidth) messageViewModel.arrowWidth = self.arrowWidth;
    if (self.arrowHeight) messageViewModel.arrowHeight = self.arrowHeight;
    if (self.messageFont) messageViewModel.messageFont = self.messageFont;
    if (self.fromName) messageViewModel.fromName = self.fromName;
    if (self.toName) messageViewModel.toName = self.toName;
    if (self.arrowPosition != ZNGArrowPositionUnset) messageViewModel.arrowPosition = self.arrowPosition;
    return messageViewModel;
}

@end
