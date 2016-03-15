//
//  ZNGAppDelegate.m
//  ZingleSDK
//
//  Created by Ryan Farley on 01/31/2016.
//  Copyright (c) 2016 Ryan Farley. All rights reserved.
//

#import "ZNGAppDelegate.h"
#import <ZingleSDK/ZingleSDK.h>
#import "ZNGContactClient.h"
#import "ZNGConversationViewController.h"
#import "ZNGInboxViewController.h"
#import "AFNetworkActivityLogger.h"

@interface ZNGAppDelegate () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableViewController *tableVC;
@property (strong, nonatomic) NSMutableArray *conversations;

@end

@implementation ZNGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityLogger sharedLogger] startLogging];
        
    NSString *token = @"rfarley@zingleme.com";
    NSString *key = @"WfM-uYS-CBV-n6J";
    
    // 1
    [[ZingleSDK sharedSDK] setToken:token andKey:key];
    
    ZNGInboxViewController *vc = [ZNGInboxViewController inboxViewController];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController: vc];
    [self.window makeKeyAndVisible];
    
    
    return YES;
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
