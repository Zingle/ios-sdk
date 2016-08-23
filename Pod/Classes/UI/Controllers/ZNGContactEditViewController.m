//
//  ZNGContactEditViewController.m
//  Pods
//
//  Created by Jason Neel on 8/23/16.
//
//

#import "ZNGContactEditViewController.h"
#import "ZNGContact.h"
#import "ZNGEditContactHeader.h"

static NSString * const HeaderReuseIdentifier = @"EditContactHeader";

@interface ZNGContactEditViewController ()

@end

@implementation ZNGContactEditViewController
{
    CGFloat lockedContactHeight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    lockedContactHeight = self.lockedContactHeightConstraint.constant;
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    UINib * headerNib = [UINib nibWithNibName:NSStringFromClass([ZNGEditContactHeader class]) bundle:bundle];
    [self.tableView registerNib:headerNib forHeaderFooterViewReuseIdentifier:HeaderReuseIdentifier];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self showOrHideLockedContactBarAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setContact:(ZNGContact *)contact
{
    _contact = contact;
    [self showOrHideLockedContactBarAnimated:NO];
}

- (void) showOrHideLockedContactBarAnimated:(BOOL)animated
{
    CGFloat lockedBarHeight = [self.contact lockedBySource] ? lockedContactHeight : 0.0;
    self.lockedContactHeightConstraint.constant = lockedBarHeight;
    [self.view setNeedsUpdateConstraints];
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{ [self.view layoutIfNeeded]; }];
    } else {
        [self.view layoutIfNeeded];
    }
}

#pragma mark - Table view delegate
- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ZNGEditContactHeader * header = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:HeaderReuseIdentifier];
    
    // TODO: Do stuff
    
    return header;
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@end
