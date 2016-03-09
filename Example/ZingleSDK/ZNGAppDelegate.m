//
//  ZNGAppDelegate.m
//  ZingleSDK
//
//  Created by Ryan Farley on 01/31/2016.
//  Copyright (c) 2016 Ryan Farley. All rights reserved.
//

#import "ZNGAppDelegate.h"
#import "AFNetworkActivityLogger.h"
#import <ZingleSDK/ZingleSDK.h>
#import "ZNGContactClient.h"
#import "ZNGConversationViewController.h"

@interface ZNGAppDelegate () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableViewController *tableVC;
@property (strong, nonatomic) NSMutableArray *conversations;

@end

@implementation ZNGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelOff];
    
    self.conversations = [[NSMutableArray alloc] init];

    self.tableVC = [[UITableViewController alloc] init];
    self.tableVC.title = @"Zingle SDK";
    self.tableVC.tableView.delegate = self;
    self.tableVC.tableView.dataSource = self;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController: self.tableVC];
    [self.window makeKeyAndVisible];
    
    [self loadConversations];
    
    return YES;
}

- (void)loadConversations
{
    NSString *token = @"viacheslav.marusyk@cyberhull.com";
    NSString *key = @"123qweasd";
    NSString *contactChannelValue = @"viacheslav.marusyk";
    NSString *contactId = @"b248a5d0-8f01-49eb-bda0-8cf2d13f4700";
    NSString *serviceId = @"e84bec95-b788-45ea-9d64-01db3d8742ac";
    
    // 1
    [[ZingleSDK sharedSDK] setToken:token andKey:key];
    
    // 2
    [[ZingleSDK sharedSDK] addConversationFromContactId:contactId toServiceId:serviceId contactChannelValue:contactChannelValue success:^(ZNGConversation *conversation) {
        
        [self.conversations addObject:conversation];
        [self.tableVC.tableView reloadData];
    } failure:^(ZNGError *error) {
        // handle failure
    }];
    
    [[ZingleSDK sharedSDK] addConversationFromServiceId:serviceId toContactId:contactId contactChannelValue:contactChannelValue success:^(ZNGConversation *conversation) {
        [self.conversations addObject:conversation];
        [self.tableVC.tableView reloadData];
    } failure:^(ZNGError *error) {
        // handle failure
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.conversations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGConversation *conversation = [self.conversations objectAtIndex:indexPath.row];
    NSString *from = conversation.toService ? @"contact" : @"service";
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.textLabel.text = [NSString stringWithFormat:@"Conversation from %@", from];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGConversation *conversation = [self.conversations objectAtIndex:indexPath.row];
    
    ZNGConversationViewController *vc = [[ZingleSDK sharedSDK] conversationViewControllerForConversation:conversation];

    [(UINavigationController *)self.window.rootViewController pushViewController:vc animated:YES];
}

@end
