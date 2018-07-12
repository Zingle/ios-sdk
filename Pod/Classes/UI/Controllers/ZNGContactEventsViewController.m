//
//  ZNGContactEventsViewController.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/12/18.
//

#import "ZNGContactEventsViewController.h"
#import "ZNGContact.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGCalendarEvent.h"

@interface ZNGContactEventsViewController ()

@end

@implementation ZNGContactEventsViewController

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    if (self.conversation != nil) {
        // Update title
        self.titleLabel.text = [NSString stringWithFormat:@"%@'s events", [self.conversation remoteName]];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // TODO: Scroll to show today (in case there are a billion finished events pushing future events off screen)
}

- (IBAction) pressedDone:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
