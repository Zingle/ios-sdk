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
    NSString *token = @"rfarley@zingleme.com";
    NSString *key = @"13oolvler";
    NSString *contactChannelValue = @"ryans.testapp";
    NSString *contactId = @"5cdeccca-c63c-4f23-8b1e-926d61773872";
    NSString *serviceId = @"e545a46e-bfcd-4db2-bfee-8e590fdcb33f";
    
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
    
    ZNGConversationViewController *chatViewController = [ZNGConversationViewController withConversation:conversation];

    [(UINavigationController *)self.window.rootViewController pushViewController:chatViewController animated:YES];
}

@end
