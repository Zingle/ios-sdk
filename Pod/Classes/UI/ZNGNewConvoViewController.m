//
//  ZNGNewConvoViewController.m
//  Pods
//
//  Created by Ryan Farley on 3/2/16.
//
//

#import "ZNGNewConvoViewController.h"
#import <ZingleSDK/ZingleSDK.h>

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
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ZNGConversationDelegate
- (void)messagesUpdated
{
    
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.conversation.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMessage *message = [self.conversation.messages objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZNGMessageCell"];
    cell.textLabel.text = message.body;
    return cell;
}

#pragma mark - UITableViewDelegate

@end
