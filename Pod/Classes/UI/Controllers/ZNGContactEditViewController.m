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
#import "ZNGContactLabelsTableViewCell.h"
#import "ZNGLogging.h"
#import "ZNGChannel.h"
#import "ZNGLabelRoundedCollectionViewCell.h"
#import "ZNGLabel.h"
#import "UIColor+ZingleSDK.h"
#import "Mantle/MTLJSONAdapter.h"
#import "ZingleAccountSession.h"
#import "ZNGContactClient.h"
#import "ZNGAnalytics.h"
#import "ZNGGradientLoadingView.h"
#import "ZNGLabelGridView.h"
#import "ZNGContactDefaultFieldsTableViewCell.h"

enum  {
    ContactSectionDefaultCustomFields,
    ContactSectionChannels,
    ContactSectionGroups,
    ContactSectionLabels,
    ContactSectionOptionalCustomFields,
    ContactSectionCount
};

static const int zngLogLevel = ZNGLogLevelInfo;

static NSString * const HeaderReuseIdentifier = @"EditContactHeader";
static NSString * const FooterReuseIdentifier = @"EditContactFooter";
static NSString * const SelectLabelSegueIdentifier = @"selectLabel";

@interface ZNGContactEditViewController () <ZNGLabelGridViewDelegate>

@end

@implementation ZNGContactEditViewController
{
    ZNGContact * originalContact;
    
    CGFloat lockedContactHeight;
    
    NSArray<NSString *> * defaultCustomFieldDisplayNames;
    NSArray<NSString *> * editableCustomFieldDataTypes;
    NSArray<ZNGContactFieldValue *> * defaultCustomFields;
    NSArray<ZNGContactFieldValue *> * optionalCustomFields;
    NSArray<ZNGChannel *> * phoneNumberChannels;
    NSArray<ZNGChannel *> * nonPhoneNumberChannels;
    
    UIImage * deleteXImage;
    
    __weak ZNGContactLabelsTableViewCell * labelsGridCell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    lockedContactHeight = self.lockedContactHeightConstraint.constant;
    
    defaultCustomFieldDisplayNames = @[@"Title", @"First Name", @"Last Name"];
    
    [self generateDataArrays];
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    deleteXImage = [[UIImage imageNamed:@"deleteX" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UINib * headerNib = [UINib nibWithNibName:NSStringFromClass([ZNGEditContactHeader class]) bundle:bundle];
    UINib * footerNib = [UINib nibWithNibName:@"ZNGEditContactFooter" bundle:bundle];
    [self.tableView registerNib:headerNib forHeaderFooterViewReuseIdentifier:HeaderReuseIdentifier];
    [self.tableView registerNib:footerNib forHeaderFooterViewReuseIdentifier:FooterReuseIdentifier];
    
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 10.0)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 10.0)];
    
    [self updateUIForNewContact];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self showOrHideLockedContactBarAnimated:NO];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) setContact:(ZNGContact *)contact
{
    originalContact = contact;
 
    if (contact == nil) {
        ZNGLogInfo(@"Edit contact screen has been loaded with no contact.  Assuming a new contact.");
        _contact = [[ZNGContact alloc] init];
    } else {
        // ZNGContact's copy is a deep copy
        _contact = [contact copy];
    }

    [self updateUIForNewContact];
}

- (void) updateUIForNewContact
{
    if (self.contact == nil) {
        ZNGLogInfo(@"Edit contact screen has been loaded with no contact.  Assuming a new contact.");
        _contact = [[ZNGContact alloc] init];
    }
    
    [self showOrHideLockedContactBarAnimated:NO];
    NSString * saveOrCreate = (originalContact != nil) ? @"Save" : @"Create";
    [self.saveButton setTitle:saveOrCreate forState:UIControlStateNormal];
    NSString * name = [originalContact fullName];
    self.titleLabel.text = ([name length] > 0) ? name : @"Create Contact";
    
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
    
    // Maintain default field order
    [defaultValues sortUsingComparator:^NSComparisonResult(ZNGContactFieldValue * _Nonnull obj1, ZNGContactFieldValue * _Nonnull obj2) {
        NSUInteger obj1SortIndex = [defaultCustomFieldDisplayNames indexOfObject:obj1.customField.displayName];
        NSUInteger obj2SortIndex = [defaultCustomFieldDisplayNames indexOfObject:obj2.customField.displayName];
        return [@(obj1SortIndex) compare:@(obj2SortIndex)];
    }];
    
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
        
        if (existingChannel != nil) {
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
    return @[@"EmailAddress", @"PhoneNumber"];
}

- (ZNGContactFieldValue *) contactFieldValueForContactField:(ZNGContactField *)field
{
    // See if this contact has a value
    ZNGContactFieldValue * value = [self.contact contactFieldValueForType:field];
    
    if (value == nil) {
        value = [[ZNGContactFieldValue alloc] init];
        
        NSMutableArray * mutableContactFields = [self.contact.customFieldValues mutableCopy];
        [mutableContactFields addObject:value];
        self.contact.customFieldValues = mutableContactFields;
    }
    
    // A bit of a code archaeological curiosity:
    //  This .customField = field line was originally in the value == nil block above, but sometimes the custom field's dataType and
    //  options value would be nil.  It is not clear where this data was being cleared, but moving setting of the custom field type
    //  out here blows away any erroneously cleared or missing data in that case.  I'd really rather not think further about why this is
    //  happening as the last man in the office on a Friday evening :-/
    value.customField = field;

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
- (void) saveAnyEditsInProgress
{
    for (ZNGContactEditTableViewCell * cell in [self.tableView visibleCells]) {
        if ([cell isKindOfClass:[ZNGContactEditTableViewCell class]]) {
            [cell applyChangesIfFirstResponder];
        }
    }
}

- (IBAction)pressedCancel:(id)sender
{
    [self saveAnyEditsInProgress];
    
    BOOL requireConfirmationBeforeCancel = [self contactHasBeenChanged];
    
    // If this is a brand new contact with no channels added, we can dismiss immediately
    if ((originalContact == nil) && ([[self.contact channelsWithValues] count] == 0)) {
        requireConfirmationBeforeCancel = NO;
    }
    
    // We will confirm before discarding information if the contact has been edited.
    if (requireConfirmationBeforeCancel) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Discard changes?" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction * discard = [UIAlertAction actionWithTitle:@"Discard Changes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction * returnToEditing = [UIAlertAction actionWithTitle:@"Continue Editing" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:returnToEditing];
        [alert addAction:discard];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)pressedSave:(id)sender
{
    self.saveButton.enabled = NO;
    [self saveAnyEditsInProgress];

    // First we will check if they are creating a fresh person and, if so, if they have actually entered a channel
    if (originalContact == nil) {
        if ([[self.contact channelsWithValues] count] == 0) {
            // Uh oh!
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable to create contact" message:@"A new contact must have at least one phone number or other communication channel" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:^{
                self.saveButton.enabled = YES;
            }];
            return;
        }
    }
    
    [self.loadingGradient startAnimating];
    
    // If we have no changes, we can just go poof
    if (![self contactHasBeenChanged]) {
        ZNGLogInfo(@"Contact editing screen is being dismissed via \"Save,\" but no changes were made.");
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    [self.contactClient updateContactFrom:originalContact to:self.contact success:^(ZNGContact * _Nonnull contact) {
        // We did it
        [self.loadingGradient stopAnimating];
        [self.delegate contactWasCreated:contact];
        
        if (originalContact == nil) {
            [[ZNGAnalytics sharedAnalytics] trackCreatedContact:contact];
        } else {
            [[ZNGAnalytics sharedAnalytics] trackEditedExistingContact:contact];
        }
        
        // If we do not have push notifications, we will fake a push notification so our UI gets updated
        if (![[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
            NSDictionary * userInfo = @{ @"aps" : @{ @"contact" : contact.contactId } };
            
            // Delay to give the magic elastic data time to catch up.  A GET soon enough after a POST will have the old data for Zingle server reasons.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ZNGPushNotificationReceived object:contact userInfo:userInfo];
            });
        }
     
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(ZNGError * _Nonnull error) {
        [self.loadingGradient stopAnimating];
        self.saveButton.enabled = YES;
        ZNGLogError(@"Unable to save contact: %@", error);
        
        NSString * description;
        
        if (error.zingleErrorCode == ZINGLE_ERROR_CHANNEL_MISSING_COUNTRY) {
            description = @"Invalid phone number.  A country code may be missing.";
        } else {
            description = error.errorDescription;
        }
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable to save contact" message:description preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (BOOL) contactHasBeenChanged
{
    return [self.contact hasBeenEditedSince:originalContact];
}

#pragma mark - Phone number cell delegate
- (void) userClickedPhoneNumberTypeButtonOnCell:(ZNGContactPhoneNumberTableViewCell *)cell
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Phone number type" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    alert.popoverPresentationController.sourceRect = cell.displayNameButton.bounds;
    alert.popoverPresentationController.sourceView = cell.displayNameButton;
    
    UIAlertAction * mobile = [UIAlertAction actionWithTitle:@"Mobile" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        cell.displayName = @"MOBILE";
    }];
    UIAlertAction * home = [UIAlertAction actionWithTitle:@"Home" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        cell.displayName = @"HOME";
    }];
    UIAlertAction * business = [UIAlertAction actionWithTitle:@"Business" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        cell.displayName = @"BUSINESS";
    }];
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:mobile];
    [alert addAction:home];
    [alert addAction:business];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) userClickedDeleteOnPhoneNumberTableCell:(ZNGContactPhoneNumberTableViewCell *)cell
{
    [self saveAnyEditsInProgress];
    
    // Are they actually deleting a channel with actual data in it or that existed previously?  If so, confirm.
    BOOL channelExistedPreviously = ([[originalContact channelsWithValues] containsObject:cell.channel]);
    BOOL dataIsWritten = ([cell.channel.value length] > 0);
    
    if (channelExistedPreviously || dataIsWritten) {
        // Confirm
        NSString * channelDescription = [self.service shouldDisplayRawValueForChannel:cell.channel] ? [cell.channel displayValueUsingRawValue] : [cell.channel displayValueUsingFormattedValue];
        NSString * message = [NSString stringWithFormat:@"Delete the %@ channel?", channelDescription ?: @""];
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self _deleteChannel:cell.channel];
        }];
        UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:delete];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        // No need to confirm
        [self _deleteChannel:cell.channel];
    }
}

- (void) _deleteChannel:(ZNGChannel *)channel
{
    NSUInteger indexInPhoneChannels = [phoneNumberChannels indexOfObject:channel];
    
    if (indexInPhoneChannels == NSNotFound) {
        ZNGLogError(@"User pressed delete on a phone number table cell, but the cell's channel does not appear in our contact's %llu phone number channels", (unsigned long long)[phoneNumberChannels count]);
        return;
    }
    
    NSIndexPath * indexPath = [self indexPathForChannel:channel];
    
    NSMutableArray<ZNGChannel *> * mutableChannels = [self.contact.channels mutableCopy];
    NSMutableArray<ZNGChannel *> * mutablePhoneChannels = [phoneNumberChannels mutableCopy];
    [mutablePhoneChannels removeObjectAtIndex:indexInPhoneChannels];
    [mutableChannels removeObject:channel];
    self.contact.channels = mutableChannels;
    phoneNumberChannels = mutablePhoneChannels;
    
    if (indexPath == nil) {
        ZNGLogWarn(@"Unable to find row for delete animation after removing phone number channel.  Reloading entire channel section.");
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:ContactSectionChannels];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (NSIndexPath *) indexPathForChannel:(ZNGChannel *)channel
{
    NSUInteger row = NSNotFound;
    
    if (![channel isPhoneNumber]) {
        row = [nonPhoneNumberChannels indexOfObject:channel];
    } else {
        NSUInteger index = [phoneNumberChannels indexOfObject:channel];
        row = (index != NSNotFound) ? index + [nonPhoneNumberChannels count] : NSNotFound;
    }
    
    if (row == NSNotFound) {
        return nil;
    }
    
    return [NSIndexPath indexPathForRow:row inSection:ContactSectionChannels];
}

#pragma mark - Table view delegate
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // All sections other than the top profile section will have headers
    if (section == ContactSectionDefaultCustomFields) {
        return 0.0;
    }
    
    return 30.0;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10.0;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ZNGEditContactHeader * header = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:HeaderReuseIdentifier];
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    
    switch (section) {
        case ContactSectionDefaultCustomFields:
            // No header for top section
            return nil;
        case ContactSectionChannels:
            header.sectionLabel.text = @"CHANNELS";
            header.sectionImage.image = [UIImage imageNamed:@"editIconChannels" inBundle:bundle compatibleWithTraitCollection:nil];
            break;
        case ContactSectionGroups:
            header.sectionLabel.text = @"SEGMENTS";
            header.sectionImage.image = [[UIImage imageNamed:@"smallStalker" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        case ContactSectionLabels:
            header.sectionLabel.text = @"TAGS";
            header.sectionImage.image = [UIImage imageNamed:@"editIconLabels" inBundle:bundle compatibleWithTraitCollection:nil];
            break;
        case ContactSectionOptionalCustomFields:
            header.sectionLabel.text = @"CUSTOM FIELDS";
            header.sectionImage.image = [UIImage imageNamed:@"editIconCustomFields" inBundle:bundle compatibleWithTraitCollection:nil];
            break;
        default:
            ZNGLogError(@"Unexpected section %lld encountered in contact editing screen.", (long long)section);
            header.sectionLabel.text = @"OTHER";
            header.sectionImage.image = nil;
            break;
    }
    
    return header;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:FooterReuseIdentifier];
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return ContactSectionCount;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case ContactSectionDefaultCustomFields:
            return 1;
        case ContactSectionOptionalCustomFields:
            return [optionalCustomFields count];
        case ContactSectionGroups:
        case ContactSectionLabels:
            return 1;
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
        {
            ZNGContactDefaultFieldsTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"defaultFields" forIndexPath:indexPath];
            
            ZNGContactFieldValue * titleFieldValue = [self.contact titleFieldValue];
            ZNGContactFieldValue * firstNameFieldValue = [self.contact firstNameFieldValue];
            ZNGContactFieldValue * lastNameFieldValue = [self.contact lastNameFieldValue];
            
            cell.contact = self.contact;
            cell.titleFieldValue = titleFieldValue;
            cell.firstNameFieldValue = firstNameFieldValue;
            cell.lastNameFieldValue = lastNameFieldValue;
            
            BOOL locked = ([self.contact editingCustomFieldIsLocked:titleFieldValue]
                           || [self.contact editingCustomFieldIsLocked:firstNameFieldValue]
                           || [self.contact editingCustomFieldIsLocked:lastNameFieldValue]);
            
            cell.editingLocked = locked;
            
            return cell;
        }
            
        case ContactSectionOptionalCustomFields:
        {
            NSArray<ZNGContactFieldValue *> * customFields = (indexPath.section == ContactSectionDefaultCustomFields) ? defaultCustomFields : optionalCustomFields;
            
            ZNGContactCustomFieldTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"customField" forIndexPath:indexPath];
            ZNGContactFieldValue * customFieldValue = customFields[indexPath.row];
            cell.customFieldValue = customFieldValue;
            cell.editingLocked = [self.contact editingCustomFieldIsLocked:customFieldValue];
            return cell;
        }
            
        case ContactSectionGroups:
        {
            ZNGContactLabelsTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"groups" forIndexPath:indexPath];
            cell.labelsGrid.groups = self.contact.groups;
            return cell;
        }
            
        case ContactSectionLabels:
        {
            ZNGContactLabelsTableViewCell * cell = labelsGridCell;
            
            if (cell == nil) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"labels" forIndexPath:indexPath];
                labelsGridCell = cell;
            }

            cell.labelsGrid.labels = self.contact.labels;
            cell.labelsGrid.delegate = self;
            return cell;
        }
            
        case ContactSectionChannels:
        {
            if (indexPath.row >= [self.contact.channels count]) {
                // This is our placeholder row
                return [tableView dequeueReusableCellWithIdentifier:@"addPhone" forIndexPath:indexPath];
            }
            
            ZNGChannel * channel;
            
            if (indexPath.row < [nonPhoneNumberChannels count]) {
                channel = nonPhoneNumberChannels[indexPath.row];
            } else {
                channel = phoneNumberChannels[indexPath.row - [nonPhoneNumberChannels count]];
            }
            
            BOOL locked = [self.contact editingChannelIsLocked:channel];
            
            if ([channel isPhoneNumber]) {
                ZNGContactPhoneNumberTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"phone" forIndexPath:indexPath];
                cell.channel = channel;
                cell.editingLocked = locked;
                cell.delegate = self;
                return cell;
            }
            
            ZNGContactChannelTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"channel" forIndexPath:indexPath];
            cell.channel = channel;
            cell.editingLocked = locked;
            return cell;
        }
    }
    
    ZNGLogError(@"Unknown section %lld in contact editing table view", (long long)indexPath.section);
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == ContactSectionChannels) && (indexPath.row >= [self.contact.channels count])) {
        // This is the "Add phone number" row
        ZNGChannel * newPhoneChannel = [[ZNGChannel alloc] init];
        newPhoneChannel.channelType = [self.service phoneNumberChannelType];
        
        NSMutableArray * mutableChannels = [self.contact.channels mutableCopy];
        NSMutableArray * mutablePhoneChannels = [phoneNumberChannels mutableCopy];
        [mutableChannels addObject:newPhoneChannel];
        [mutablePhoneChannels addObject:newPhoneChannel];
        self.contact.channels = mutableChannels;
        phoneNumberChannels = mutablePhoneChannels;
        
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:ContactSectionChannels];
        [tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Label selection

- (void) labelGridPressedAddLabel:(ZNGLabelGridView *)grid
{
    [self performSegueWithIdentifier:SelectLabelSegueIdentifier sender:self];
}

- (void) labelGrid:(ZNGLabelGridView *)grid pressedRemoveLabel:(ZNGLabel *)label
{
    if (label == nil) {
        ZNGLogError(@"Remove label delegate method was called, but with no label selected.  Ignoring.");
        return;
    }
    
    NSString * message = [NSString stringWithFormat:@"Remove the %@ tag from %@?", label.displayName, [self.contact fullName]];
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction * delete = [UIAlertAction actionWithTitle:@"Remove Tag" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self doLabelRemoval:label];
    }];
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:delete];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) doLabelRemoval:(ZNGLabel *)label
{
    NSMutableArray * mutableLabels = [self.contact.labels mutableCopy];
    [mutableLabels removeObject:label];
    self.contact.labels = mutableLabels;
    
    // There's a lot of nonsense going on here to refresh things cleanly.
    // We need to record the table view's contentOffset before and set it after to prevent the table view from scrolling itself to
    //  the top due to the reloadRowsAtIndexPaths:.  There's something odd going on with calculating row height that causes this.
    // After that, we call scrollToRowAtIndexPath:, which will only have an effect in the case of the user adding labels that make the
    //  label section itself overflow off screen.  In that case, the table will be scrolled to keep the labels all on screen.
    labelsGridCell.labelsGrid.labels = mutableLabels;
    NSIndexPath * labelsIndexPath = [NSIndexPath indexPathForRow:0 inSection:ContactSectionLabels];
    CGPoint contentOffset = self.tableView.contentOffset;
    [self.tableView reloadRowsAtIndexPaths:@[labelsIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView setContentOffset:contentOffset animated:NO];
    [self.tableView scrollToRowAtIndexPath:labelsIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    
    [[ZNGAnalytics sharedAnalytics] trackRemovedLabel:label fromContact:self.contact];
}

- (void) labelSelectViewController:(ZNGLabelSelectViewController *)viewController didSelectLabel:(ZNGLabel *)label
{
    if (label != nil) {
        NSMutableArray * mutableLabels = [self.contact.labels mutableCopy];
        [mutableLabels addObject:label];
        self.contact.labels = mutableLabels;
        
        // See notes regarding table view scrolling above in doLabelRemoval:
        labelsGridCell.labelsGrid.labels = mutableLabels;
        NSIndexPath * labelsIndexPath = [NSIndexPath indexPathForRow:0 inSection:ContactSectionLabels];
        CGPoint contentOffset = self.tableView.contentOffset;
        [self.tableView reloadRowsAtIndexPaths:@[labelsIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView setContentOffset:contentOffset animated:NO];
        [self.tableView scrollToRowAtIndexPath:labelsIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        
        [[ZNGAnalytics sharedAnalytics] trackAddedLabel:label toContact:self.contact];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SelectLabelSegueIdentifier]) {
        ZNGLabelSelectViewController * vc = segue.destinationViewController;
        
        // We will remove labels already applied to this user
        NSMutableArray<ZNGLabel *> * availableLabels = [self.service.contactLabels mutableCopy];
        for (ZNGLabel * label in self.contact.labels) {
            [availableLabels removeObject:label];
        }
        
        vc.labels = availableLabels;
        vc.delegate = self;
    }
}

@end
