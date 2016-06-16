//
//  ZNGContactConversationViewController.m
//  Pods
//
//  Created by Jason Neel on 6/16/16.
//
//

#import "ZNGContactConversationViewController.h"

@interface ZNGContactConversationViewController ()

@end

@implementation ZNGContactConversationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupBarButtonItems
{
    self.detailsBarButton = [[UIBarButtonItem alloc] initWithImage: [UIImage zng_defaultTypingIndicatorImage]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(detailsButtonPressed:)];
    
    self.navigationItem.rightBarButtonItems = @[self.detailsBarButton];
    
    if (self.toService) {
        self.titleViewLabel.text = self.service.displayName;
    } else {
        self.titleViewLabel.text = [self.contact fullName];
    }
}

- (void)confirmedButtonPressed:(UIBarButtonItem *)sender
{
}

- (void)starButtonPressed:(UIBarButtonItem *)sender
{
}

@end
