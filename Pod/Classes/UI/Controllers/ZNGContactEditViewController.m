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
#import "UIFont+Lato.h"
#import "ZNGContactField.h"
#import "ZNGContactFieldValue.h"
#import "ZNGService.h"
#import "ZNGContactCustomFieldTableViewCell.h"
#import "ZNGLogging.h"

static const int zngLogLevel = ZNGLogLevelInfo;

static NSString * const HeaderReuseIdentifier = @"EditContactHeader";

@interface ZNGContactEditViewController ()

@end

@implementation ZNGContactEditViewController
{
    CGFloat lockedContactHeight;
    
    NSArray<NSString *> * defaultCustomFieldDisplayNames;
    NSArray<NSString *> * editableCustomFieldDataTypes;
    NSArray<ZNGContactFieldValue *> * defaultCustomFields;
    NSArray<ZNGContactFieldValue *> * optionalCustomFields;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    lockedContactHeight = self.lockedContactHeightConstraint.constant;
    
    defaultCustomFieldDisplayNames = @[@"Title", @"First Name", @"Last Name"];
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    UINib * headerNib = [UINib nibWithNibName:NSStringFromClass([ZNGEditContactHeader class]) bundle:bundle];
    [self.tableView registerNib:headerNib forHeaderFooterViewReuseIdentifier:HeaderReuseIdentifier];
    
    // For some reason UIAppearance does not work for these buttons, possibly because they were manually placed in IB instead of being auto generated as part
    //  of a nav controller.
    NSDictionary * attributes = @{ NSFontAttributeName: [UIFont latoFontOfSize:17.0] };
    [self.cancelButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.saveButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
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
    self.navItem.title = [contact fullName];
    [self generateCustomFields];
    [self.tableView reloadData];
}

- (void) setService:(ZNGService *)service
{
    _service = service;
    [self generateCustomFields];
    [self.tableView reloadData];
}

- (void) generateCustomFields
{
    NSMutableArray<ZNGContactFieldValue *> * defaultValues = [[NSMutableArray alloc] initWithCapacity:[defaultCustomFieldDisplayNames count]];
    NSMutableArray<ZNGContactFieldValue *> * otherValues = [[NSMutableArray alloc] initWithCapacity:[self.service.contactCustomFields count]];
    
    for (ZNGContactField * customField in self.service.contactCustomFields) {
        NSMutableArray<ZNGContactFieldValue *> * destinationArray = ([defaultCustomFieldDisplayNames containsObject:customField.displayName]) ? defaultValues : otherValues;
        [destinationArray addObject:[self contactFieldValueForContactField:customField]];
    }
    
    defaultCustomFields = defaultValues;
    optionalCustomFields = otherValues;
}

- (ZNGContactFieldValue *) contactFieldValueForContactField:(ZNGContactField *)field
{
    // See if this contact has a value
    ZNGContactFieldValue * value = [self.contact contactFieldValueForType:field];
    
    if (value == nil) {
        value = [[ZNGContactFieldValue alloc] init];
        value.customField = field;
    }
    
    return value;
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

#pragma mark - IBActions
- (IBAction)pressedCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view delegate
// TODO: Implement this
//- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    ZNGEditContactHeader * header = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:HeaderReuseIdentifier];
//    
//    // TODO: Do stuff
//    
//    return header;
//}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Default";
        default:
            return @"Optional";
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return [defaultCustomFields count];
        default:
            return [optionalCustomFields count];
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray<ZNGContactFieldValue *> * customFields;
    
    switch (indexPath.section) {
        case 0:
            customFields = defaultCustomFields;
            break;
        default:
            customFields = optionalCustomFields;
    }
    
    ZNGLogVerbose(@"Setting cell %@ to %@", indexPath, customFields[indexPath.row]);
    
    ZNGContactCustomFieldTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"customField" forIndexPath:indexPath];
    cell.customFieldValue = customFields[indexPath.row];
    return cell;
}

@end
