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

static NSString *kZNGToken = @"[YOUR ZINGLE TOKEN]";
static NSString *kZNGKey = @"[YOUR ZINGLE KEY]";

static NSString *kZNGServiceId = @"22111111-1111-1111-1111-111111111111";

// User-Defined Channel if using Contact User Authorization
static NSString *kZNGChannelTypeId = @"7176e36e-87d2-4161-ae2b-6848fbf3de11";
static NSString *kZNGChannelValue = @"MyChatChannel1";

@interface ContactServiceChoosingViewController ()

@end

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
    }];
}

#pragma mark - Table
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactServiceTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"contactServiceCell"];
    
    // TODO: Implement
    
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected contact service #%ld", (long)indexPath.row);
}


@end
