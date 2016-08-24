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
#import "ZNGContactChannelTableViewCell.h"
#import "ZNGContactPhoneNumberTableViewCell.h"
#import "ZNGLogging.h"
#import "ZNGChannel.h"

enum  {
    ContactSectionDefaultCustomFields,
    ContactSectionChannels,
    ContactSectionLabels,
    ContactSectionOptionalCustomFields,
    ContactSectionCount
};

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
    NSArray<ZNGChannel *> * phoneNumberChannels;
    NSArray<ZNGChannel *> * nonPhoneNumberChannels;
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
    [self generateDataArrays];
    [self.tableView reloadData];
}

- (void) setService:(ZNGService *)service
{
    _service = service;
    [self generateDataArrays];
    [self.tableView reloadData];
}

- (void) generateDataArrays
{
    // Set custom fields
    NSMutableArray<ZNGContactFieldValue *> * defaultValues = [[NSMutableArray alloc] initWithCapacity:[defaultCustomFieldDisplayNames count]];
    NSMutableArray<ZNGContactFieldValue *> * otherValues = [[NSMutableArray alloc] initWithCapacity:[self.service.contactCustomFields count]];
    
    for (ZNGContactField * customField in self.service.contactCustomFields) {
        NSMutableArray<ZNGContactFieldValue *> * destinationArray = ([defaultCustomFieldDisplayNames containsObject:customField.displayName]) ? defaultValues : otherValues;
        [destinationArray addObject:[self contactFieldValueForContactField:customField]];
    }
    
    defaultCustomFields = defaultValues;
    optionalCustomFields = otherValues;
    
    
    // Set channels
    NSMutableArray<ZNGChannel *> * newPhoneNumberChannels = [[NSMutableArray alloc] init];
    NSMutableArray<ZNGChannel *> * newChannels = [[NSMutableArray alloc] init];
    
    [self ensureContactHasAllRequiredChannelTypes];
    
    for (ZNGChannel * channel in self.contact.channels) {
        if ([channel isPhoneNumber]) {
            [newPhoneNumberChannels addObject:channel];
        } else {
            [newChannels addObject:channel];
        }
    }
    
    phoneNumberChannels = newPhoneNumberChannels;
    nonPhoneNumberChannels = newChannels;
}

- (void) ensureContactHasAllRequiredChannelTypes
{
    NSArray<NSString *> * channelTypeNames = [self omnipresentChannelTypeClasses];
    NSMutableArray<ZNGChannelType *> * requiredTypes = [[NSMutableArray alloc] initWithCapacity:[channelTypeNames count]];
    
    for (NSString * typeClass in channelTypeNames) {
        ZNGChannelType * type = [self.service channelTypeWithTypeClass:typeClass];
        
        if (type == nil) {
            continue;
        }
        
        ZNGChannel * existingChannel = [self.contact channelOfType:type];
        
        if (existingChannel == nil) {
            // They already have one of these
            continue;
        }
        
        // This contact does not have an entry for this required channel type.  Add one.
        [requiredTypes addObject:type];
    }
    
    if ([requiredTypes count] == 0) {
        // We're good to go; this guy does not need any more channels
        return;
    }
    
    NSMutableArray * mutableChannels = [self.contact.channels mutableCopy];

    for (ZNGChannelType * type in requiredTypes) {
        ZNGChannel * channel = [[ZNGChannel alloc] init];
        channel.channelType = type;
        
        [mutableChannels addObject:channel];
    }
    
    self.contact.channels = mutableChannels;
}

/**
 *  Returns an array of channel type names for channel types that will always be shown under a contact, whether or not they exist.
 */
- (NSArray<NSString *> *)omnipresentChannelTypeClasses
{
    return @[@"EmailAddress"];
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
    return ContactSectionCount;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case ContactSectionDefaultCustomFields:
            return @"Default";
        case ContactSectionOptionalCustomFields:
            return @"Optional";
        case ContactSectionLabels:
            return @"Labels";
        case ContactSectionChannels:
            return @"Channels";
        default:
            return nil;
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case ContactSectionDefaultCustomFields:
            return [defaultCustomFields count];
        case ContactSectionOptionalCustomFields:
            return [optionalCustomFields count];
        case ContactSectionLabels:
            // TODO: Change to 1 when implemented
            return 0;
        case ContactSectionChannels:
            return [self.contact.channels count] + 1;
        default:
            return 0;
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case ContactSectionDefaultCustomFields:
        case ContactSectionOptionalCustomFields:
        {
            NSArray<ZNGContactFieldValue *> * customFields = (indexPath.section == ContactSectionDefaultCustomFields) ? defaultCustomFields : optionalCustomFields;
            
            ZNGContactCustomFieldTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"customField" forIndexPath:indexPath];
            cell.customFieldValue = customFields[indexPath.row];
            return cell;
        }
            
        case ContactSectionLabels:
            // TODO: Implement
            return nil;
            
        case ContactSectionChannels:
        {
            if (indexPath.row >= [self.contact.channels count]) {
                // This is our placeholder row
                return [tableView dequeueReusableCellWithIdentifier:@"addPhone" forIndexPath:indexPath];
            }
            
            
            ZNGChannel * channel = self.contact.channels[indexPath.row];
            
            if ([channel isPhoneNumber]) {
                ZNGContactPhoneNumberTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"phone" forIndexPath:indexPath];
                cell.channel = channel;
                return cell;
            }
            
            ZNGContactChannelTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"channel" forIndexPath:indexPath];
            cell.channel = channel;
            return cell;
        }
    }
    
    ZNGLogError(@"Unknown section %lld in contact editing table view", (long long)indexPath.section);
    return nil;
}

@end
