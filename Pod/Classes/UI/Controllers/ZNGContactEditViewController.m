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
#import "ZingleSDK/ZingleSDK-Swift.h"
#import "ZNGLabel.h"
#import "UIColor+ZingleSDK.h"
#import "Mantle/MTLJSONAdapter.h"
#import "ZingleAccountSession.h"
#import "ZNGContactClient.h"

enum  {
    ContactSectionDefaultCustomFields,
    ContactSectionChannels,
    ContactSectionLabels,
    ContactSectionOptionalCustomFields,
    ContactSectionCount
};

static const int zngLogLevel = ZNGLogLevelInfo;

static NSString * const HeaderReuseIdentifier = @"EditContactHeader";
static NSString * const SelectLabelSegueIdentifier = @"selectLabel";

@interface ZNGContactEditViewController ()

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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    lockedContactHeight = self.lockedContactHeightConstraint.constant;
    
    defaultCustomFieldDisplayNames = @[@"Title", @"First Name", @"Last Name"];
    
    [self generateDataArrays];
    
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    UINib * headerNib = [UINib nibWithNibName:NSStringFromClass([ZNGEditContactHeader class]) bundle:bundle];
    [self.tableView registerNib:headerNib forHeaderFooterViewReuseIdentifier:HeaderReuseIdentifier];
    
    self.tableView.estimatedRowHeight = 44.0;
    
    // For some reason UIAppearance does not work for these buttons, possibly because they were manually placed in IB instead of being auto generated as part
    //  of a nav controller.
    NSDictionary * attributes = @{ NSFontAttributeName: [UIFont latoFontOfSize:17.0] };
    [self.cancelButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.saveButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
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
        // Use Mantle for a lazy deep copy
        NSDictionary * contactDict = [MTLJSONAdapter JSONDictionaryFromModel:contact error:nil];
        _contact = [MTLJSONAdapter modelOfClass:[ZNGContact class] fromJSONDictionary:contactDict error:nil];
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
    [self.saveButton setTitle:saveOrCreate];
    NSString * name = [originalContact fullName];
    self.navItem.title = ([name length] > 0) ? name : @"Create Contact";
    
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
            [self presentViewController:alert animated:YES completion:nil];
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
        
        // If we're in a simulator, we will fake a push notification so our UI gets updated
#ifdef TARGET_IPHONE_SIMULATOR
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNGPushNotificationReceived object:contact];
#endif
        
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(ZNGError * _Nonnull error) {
        [self.loadingGradient stopAnimating];
        self.saveButton.enabled = YES;
        ZNGLogError(@"Unable to save contact: %@", error);
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Unable to save contact" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (BOOL) contactHasBeenChanged
{
    return [self.contact hasBeenEditedSince:originalContact];
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
        case ContactSectionOptionalCustomFields:
        {
            NSArray<ZNGContactFieldValue *> * customFields = (indexPath.section == ContactSectionDefaultCustomFields) ? defaultCustomFields : optionalCustomFields;
            
            ZNGContactCustomFieldTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"customField" forIndexPath:indexPath];
            cell.customFieldValue = customFields[indexPath.row];
            return cell;
        }
            
        case ContactSectionLabels:
        {
            ZNGContactLabelsTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"labels" forIndexPath:indexPath];
            cell.collectionView.dataSource = self;
            cell.collectionView.delegate = self;
            [cell.collectionView.collectionViewLayout invalidateLayout];
            [cell.collectionView reloadData];
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

#pragma mark - Collection view data source (labels collection view inside of the table)
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    // We always have one section for "add label."  We will have one more section if any labels are on this duder.
    return ([self.contact.labels count] > 0) ? 2 : 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;   // The "Add label" cell
    }
    
    return [self.contact.labels count];
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGLabelRoundedCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:ZNGContactLabelsCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        // "Add label" cell
        cell.label.text = @"ADD LABEL";
        
        cell.label.textColor = [UIColor grayColor];
        cell.label.backgroundColor = [UIColor clearColor];
        cell.label.borderColor = [UIColor grayColor];
        return cell;
    }
    
    ZNGLabel * label = self.contact.labels[indexPath.row];
    cell.label.text = [NSString stringWithFormat:@"%@   X ", [label.displayName uppercaseString]];
    UIColor * color = label.backgroundUIColor;
    cell.label.textColor = color;
    cell.label.borderColor = color;
    cell.label.backgroundColor = [color zng_colorByDarkeningColorWithValue:-0.5];
    return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        // They wish to add a label.
        [self performSegueWithIdentifier:SelectLabelSegueIdentifier sender:self];
        return;
    }
    
    if (indexPath.row > [self.contact.labels count]) {
        ZNGLogError(@"Touching a label caused an out of bounds.  Index %lld is outside of our %llu objects.", (long long)indexPath.row, (unsigned long long)[self.contact.labels count]);
        return;
    }
    
    // They are deleting a label.
    ZNGLabel * label = self.contact.labels[indexPath.row];
    NSString * message = [NSString stringWithFormat:@"Remove the %@ label from %@?", label.displayName, [self.contact fullName]];
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction * delete = [UIAlertAction actionWithTitle:@"Remove Label" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self doLabelRemoval:label];
    }];
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:delete];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Label selection
- (void) doLabelRemoval:(ZNGLabel *)label
{
    NSMutableArray * mutableLabels = [self.contact.labels mutableCopy];
    [mutableLabels removeObject:label];
    self.contact.labels = mutableLabels;
    
    NSIndexPath * labelsIndexPath = [NSIndexPath indexPathForRow:0 inSection:ContactSectionLabels];
    [self.tableView reloadRowsAtIndexPaths:@[labelsIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) labelSelectViewController:(ZNGLabelSelectViewController *)viewController didSelectLabel:(ZNGLabel *)label
{
    if (label != nil) {
        NSMutableArray * mutableLabels = [self.contact.labels mutableCopy];
        [mutableLabels addObject:label];
        self.contact.labels = mutableLabels;
        
        NSIndexPath * labelsIndexPath = [NSIndexPath indexPathForRow:0 inSection:ContactSectionLabels];
        [self.tableView reloadRowsAtIndexPaths:@[labelsIndexPath] withRowAnimation:UITableViewRowAnimationNone];
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
