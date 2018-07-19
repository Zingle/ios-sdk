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
#import "ZNGUserAuthorization.h"
#import "ZNGAvatarImageView.h"
#import "NSString+Initials.h"
#import "ZNGAssignTeamTableViewCell.h"
#import "ZNGAssignUserTableViewCell.h"
#import "ZNGTeam.h"
#import "ZNGAssignmentViewController.h"
#import "ZNGEditContactTransition.h"
#import "ZNGEditContactExitTransition.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGCalendarEvent.h"
#import "ZNGContactEventTableViewCell.h"
#import "ZNGContactMoreEventsTableViewCell.h"
#import "ZNGContactEventsViewController.h"

@import SBObjectiveCWrapper;

enum  {
    ContactSectionDefaultCustomFields,
    ContactSectionCalendarEvents,
    ContactSectionAssignment,
    ContactSectionChannels,
    ContactSectionGroups,
    ContactSectionLabels,
    ContactSectionOptionalCustomFields,
    ContactSectionCount
};

static NSString * const HeaderReuseIdentifier = @"EditContactHeader";
static NSString * const FooterReuseIdentifier = @"EditContactFooter";
static NSString * const SelectLabelSegueIdentifier = @"selectLabel";
static NSString * const AssignSegueIdentifier = @"assign";
static NSString * const EventsSegueIdentifier = @"events";
static NSString * const EventCellId = @"event";

@interface ZNGContactEditViewController () <ZNGLabelGridViewDelegate>

@end

@implementation ZNGContactEditViewController
{
    ZNGContact * originalContact;
    
    CGFloat lockedContactHeight;
    
    __weak UILabel * assignmentLabel;
    
    NSArray<NSString *> * defaultCustomFieldDisplayNames;
    NSArray<NSString *> * editableCustomFieldDataTypes;
    NSArray<ZNGContactFieldValue *> * defaultCustomFields;
    NSArray<ZNGContactFieldValue *> * optionalCustomFields;
    NSArray<ZNGChannel *> * phoneNumberChannels;
    NSArray<ZNGChannel *> * nonPhoneNumberChannels;
    
    NSArray<ZNGCalendarEvent *> * ongoingEvents;
    NSArray<ZNGCalendarEvent *> * futureEvents;
    NSUInteger futureEventTotalCount;
    
    UIImage * deleteXImage;
    
    __weak ZNGContactLabelsTableViewCell * labelsGridCell;
    
    NSDateFormatter * eventDayFormatter;
    NSDateFormatter * eventMonthFormatter;
    NSDateFormatter * eventTimeFormatter;
    NSDateFormatter * eventMonthDayTimeFormatter;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // If someone else has specified their own transitioningDelegate, we will relinquish control of our transitioning to them.
    if ((self.transitioningDelegate == nil) && (!self.useDefaultTransition)) {
        self.transitioningDelegate = self;
    }
    
    eventDayFormatter = [ZNGCalendarEvent eventDayFormatter];
    eventMonthFormatter = [ZNGCalendarEvent eventMonthFormatter];
    eventTimeFormatter = [ZNGCalendarEvent eventTimeFormatter];
    eventMonthDayTimeFormatter = [ZNGCalendarEvent eventMonthDayTimeFormatter];
    
    lockedContactHeight = self.lockedContactHeightConstraint.constant;
    
    defaultCustomFieldDisplayNames = @[@"Title", @"First Name", @"Last Name"];
    
    [self generateDataArrays];

    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    deleteXImage = [[UIImage imageNamed:@"deleteX" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UINib * headerNib = [UINib nibWithNibName:NSStringFromClass([ZNGEditContactHeader class]) bundle:bundle];
    UINib * footerNib = [UINib nibWithNibName:@"ZNGEditContactFooter" bundle:bundle];
    [self.tableView registerNib:headerNib forHeaderFooterViewReuseIdentifier:HeaderReuseIdentifier];
    [self.tableView registerNib:footerNib forHeaderFooterViewReuseIdentifier:FooterReuseIdentifier];
    UINib * eventNib = [UINib nibWithNibName:NSStringFromClass([ZNGContactEventTableViewCell class]) bundle:bundle];
    [self.tableView registerNib:eventNib forCellReuseIdentifier:EventCellId];
    
    self.tableView.estimatedRowHeight = 44.0;
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 10.0)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 10.0)];
    
    [self updateUIForNewContact];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self showOrHideLockedContactBar];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UILabel * __weak) assignmentLabel
{
    // If the assignment row is not visible, we return nil.
    NSArray<NSIndexPath *> * visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
    
    for (NSIndexPath * indexPath in visibleIndexPaths) {
        if (indexPath.section == ContactSectionAssignment) {
            return assignmentLabel;
        }
    }
    
    // We did not find any assignment rows in our visible paths
    return nil;
}

- (void) setContact:(ZNGContact *)contact
{
    originalContact = contact;
 
    if (contact == nil) {
        SBLogInfo(@"Edit contact screen has been loaded with no contact.  Assuming a new contact.");
        _contact = [[ZNGContact alloc] init];
    } else {
        // ZNGContact's copy is a deep copy
        _contact = [contact copy];
        
        NSArray<NSSortDescriptor *> * sortDescriptors = [ZNGCalendarEvent sortDescriptors];
        
        // Show all ongoing events
        ongoingEvents = [[_contact ongoingCalendarEvents] sortedArrayUsingDescriptors:sortDescriptors];
        
        // Show at most two future events
        static const NSUInteger maxFutureEventCount = 2;
        NSArray<ZNGCalendarEvent *> * allFutureEvents = [[_contact futureCalendarEvents] sortedArrayUsingDescriptors:sortDescriptors];
        futureEventTotalCount = [allFutureEvents count];
        
        if (futureEventTotalCount < maxFutureEventCount) {
            futureEvents = allFutureEvents;
        } else {
            futureEvents = [allFutureEvents subarrayWithRange:NSMakeRange(0, maxFutureEventCount)];
        }
    }

    [self updateUIForNewContact];
}

- (void) updateUIForNewContact
{
    if (self.contact == nil) {
        SBLogInfo(@"Edit contact screen has been loaded with no contact.  Assuming a new contact.");
        _contact = [[ZNGContact alloc] init];
    }
    
    [self showOrHideLockedContactBar];
    NSString * saveOrCreate = (originalContact != nil) ? @"Save" : @"Create";
    [self.saveButton setTitle:saveOrCreate forState:UIControlStateNormal];
    NSString * name = [self.conversation remoteName];
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
        NSUInteger obj1SortIndex = [self->defaultCustomFieldDisplayNames indexOfObject:obj1.customField.displayName];
        NSUInteger obj2SortIndex = [self->defaultCustomFieldDisplayNames indexOfObject:obj2.customField.displayName];
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

- (void) showOrHideLockedContactBar
{
    CGFloat lockedBarHeight = [self.contact lockedBySource] ? lockedContactHeight : 0.0;
    
    if (self.lockedContactHeightConstraint.constant == lockedBarHeight) {
        // It's already the correct height
        return;
    }
    
    self.lockedContactHeightConstraint.constant = lockedBarHeight;
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Transition delegate
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[ZNGEditContactTransition alloc] init];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[ZNGEditContactExitTransition alloc] init];
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
        SBLogInfo(@"Contact editing screen is being dismissed via \"Save,\" but no changes were made.");
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    // Log any assignment changes to Segment
    if ([self.contact assignmentHasChangedSince:originalContact]) {
        static NSString * const AssignmentUIType = @"edit contact view";
        
        if ([self.contact.assignedToTeamId length] > 0) {
            ZNGTeam * team = [self.service teamWithId:self.contact.assignedToTeamId];
            [[ZNGAnalytics sharedAnalytics] trackContact:self.contact assignedToTeam:team fromUIType:AssignmentUIType];
        } else if ([self.contact.assignedToUserId length] > 0) {
            ZNGUser * dude = [self.conversation.session userWithId:self.contact.assignedToUserId];
            [[ZNGAnalytics sharedAnalytics] trackContact:self.contact assignedToUser:dude fromUIType:AssignmentUIType];
        } else {
            [[ZNGAnalytics sharedAnalytics] trackContactUnassigned:self.contact fromUIType:AssignmentUIType];
        }
    }
    
    [self.contactClient updateContactFrom:originalContact to:self.contact success:^(ZNGContact * _Nonnull contact) {
        // We did it
        [self.loadingGradient stopAnimating];
        [self.delegate contactWasCreated:contact];
        
        if (self->originalContact == nil) {
            [[ZNGAnalytics sharedAnalytics] trackCreatedContact:contact];
        } else {
            [[ZNGAnalytics sharedAnalytics] trackEditedExistingContact:contact];
        }
     
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(ZNGError * _Nonnull error) {
        [self.loadingGradient stopAnimating];
        self.saveButton.enabled = YES;
        SBLogError(@"Unable to save contact: %@", error);
        
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

- (void) pressedViewAllEvents:(id)sender
{
    [self performSegueWithIdentifier:EventsSegueIdentifier sender:self];
}

#pragma mark - Phone number cell delegate
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
        SBLogError(@"User pressed delete on a phone number table cell, but the cell's channel does not appear in our contact's %llu phone number channels", (unsigned long long)[phoneNumberChannels count]);
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
        SBLogWarning(@"Unable to find row for delete animation after removing phone number channel.  Reloading entire channel section.");
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

- (BOOL) shouldShowAssignmentSection
{
    return ([self.service allowsAssignment]);
}

- (BOOL) shouldShowCalendarEventsSection
{
    // Don't show events for a new contact
    if (originalContact == nil) {
        return NO;
    }
    
    return ([self.service allowsCalendarEvents]);
}

#pragma mark - Table view delegate
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // All sections other than the top profile section will have headers
    if (section == ContactSectionDefaultCustomFields) {
        return 0.0;
    }
    
    // If we have no assignment section, make sure it has no header
    if ((section == ContactSectionAssignment) && (![self shouldShowAssignmentSection])) {
        return 0.0;
    }
    
    // Same with calendar events
    if ((section == ContactSectionCalendarEvents) && (![self shouldShowCalendarEventsSection])) {
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
        case ContactSectionCalendarEvents:
            header.sectionLabel.text = @"EVENTS";
            header.sectionImage.image = [UIImage imageNamed:@"editIconEvents" inBundle:bundle compatibleWithTraitCollection:nil];
            
            if ([self shouldShowCalendarEventsSection]) {
                [header.moreButton setTitle:@"View all" forState:UIControlStateNormal];
                [header.moreButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
                [header.moreButton addTarget:self action:@selector(pressedViewAllEvents:) forControlEvents:UIControlEventTouchUpInside];
                header.moreButton.hidden = NO;
            }
            
            break;
        case ContactSectionAssignment:
            header.sectionLabel.text = @"ASSIGNMENT";
            header.sectionImage.image = [UIImage imageNamed:@"editIconAssignment" inBundle:bundle compatibleWithTraitCollection:nil];
            break;
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
            SBLogError(@"Unexpected section %lld encountered in contact editing screen.", (long long)section);
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
        case ContactSectionCalendarEvents:
            if (![self shouldShowCalendarEventsSection]) {
                return 0;
            }
            
            NSUInteger eventCount = [ongoingEvents count] + [futureEvents count];
            
            if (eventCount > 0) {
                NSUInteger rowCount = eventCount;
                
                // If there are additional events in the future, show one additional row for "more events"
                if (futureEventTotalCount > [futureEvents count]) {
                    rowCount++;
                }
                
                return rowCount;
            }
            
            // This contact has no events.  Show one row for "no events."
            return 1;
        case ContactSectionAssignment:
            return ([self shouldShowAssignmentSection]) ? 1 : 0;
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

- (ZNGAvatarImageView *) avatarForUser:(ZNGUser *)user
{
    return [[ZNGAvatarImageView alloc] initWithAvatarUrl:user.avatarUri
                                                initials:[[user fullName] initials]
                                                    size:CGSizeMake(32.0, 32.0)
                                         backgroundColor:[UIColor zng_outgoingMessageBubbleColor]
                                               textColor:[UIColor whiteColor]
                                                    font:[UIFont latoFontOfSize:14.0]];
}

- (ZNGCalendarEvent *) eventForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [ongoingEvents count]) {
        return ongoingEvents[indexPath.row];
    }
    
    NSUInteger futureEventIndex = indexPath.row - [ongoingEvents count];
    
    if (futureEventIndex < [futureEvents count]) {
        return futureEvents[futureEventIndex];
    }
    
    return nil;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case ContactSectionCalendarEvents:
        {
            if ([self.contact.calendarEvents count] == 0) {
                return [tableView dequeueReusableCellWithIdentifier:@"noEvents" forIndexPath:indexPath];
            }
            
            ZNGCalendarEvent * event = [self eventForIndexPath:indexPath];
            
            // If there is no event for this index path, we'll assume we have the "more events" row
            if (event == nil) {
                ZNGContactMoreEventsTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"moreEvents" forIndexPath:indexPath];
                NSUInteger additionalFutureEventCount = futureEventTotalCount - [futureEvents count];
                
                if (additionalFutureEventCount > 0) {
                    cell.moreEventsLabel.text = [NSString stringWithFormat:@"+%llu MORE", (unsigned long long)additionalFutureEventCount];
                } else {
                    cell.moreEventsLabel.text = @"View all events";
                }
                
                return cell;
            }
            
            ZNGContactEventTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:EventCellId forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if ((event.startsAt == nil) || (event.endsAt == nil)) {
                SBLogError(@"Missing either start date (%@) or end date (%@) for event.", event.startsAt, event.endsAt);
                cell.dayLabel.text = nil;
                cell.monthLabel.text = nil;
                cell.timeLabel.text = nil;
                cell.eventNameLabel.text = nil;
                return cell;
            }
            
            cell.eventNameLabel.text = event.title;
            cell.dayLabel.text = [eventDayFormatter stringFromDate:event.startsAt];
            cell.monthLabel.text = [[eventMonthFormatter stringFromDate:event.startsAt] uppercaseString];
            
            NSString * startTime = [eventTimeFormatter stringFromDate:event.startsAt];
            NSDateFormatter * endTimeFormatter = ([event singleDay]) ? eventTimeFormatter : eventMonthDayTimeFormatter;
            NSString * endTime = [endTimeFormatter stringFromDate:event.endsAt];
            cell.timeLabel.text = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
            
            UIColor * textColor = [self.service textColorForCalendarEvent:event];
            UIColor * backgroundColor = [self.service backgroundColorForCalendarEvent:event];
            cell.roundedBackgroundView.backgroundColor = backgroundColor;
            cell.roundedBackgroundView.layer.borderColor = [textColor CGColor];
            cell.dividerLine.backgroundColor = textColor;
            
            for (UILabel * label in cell.textLabels) {
                label.textColor = textColor;
            }
            
            return cell;
        }
            
        case ContactSectionAssignment:
        {
            if ([self.contact.assignedToUserId length] > 0) {
                ZNGAssignUserTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"userAssignment" forIndexPath:indexPath];

                // It's assigned to a user.  Is it me?
                ZingleAccountSession * session = (ZingleAccountSession *)self.contactClient.session;
                
                if ([self.contact.assignedToUserId isEqualToString:session.userAuthorization.userId]) {
                    // It's you!
                    // How are you, gentlemen?
                    cell.nameLabel.text = @"You";
                    [cell.avatarContainer addSubview:[self avatarForUser:session.userAuthorization]];
                } else {
                    // This is assigned to a user, but not the current user
                    ZNGUser * user = [session userWithId:self.contact.assignedToUserId];
                    
                    if (user == nil) {
                        cell.nameLabel.text = @"Someone";
                    } else {
                        cell.nameLabel.text = [user fullName];
                        [cell.avatarContainer addSubview:[self avatarForUser:user]];
                    }
                }
                
                assignmentLabel = cell.nameLabel;
                return cell;

            } else if ([self.contact.assignedToTeamId length] > 0) {
                // It's assigned to a team
                ZNGAssignTeamTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"teamAssignment" forIndexPath:indexPath];
                ZNGTeam * team = [self.service teamWithId:self.contact.assignedToTeamId];
                
                if (team == nil) {
                    SBLogWarning(@"%@ is assigned to team %@, but that team does not appear in our data.", [self.contact fullName], self.contact.assignedToTeamId);
                    cell.nameLabel.text = @"A team";
                    cell.emojiLabel.text = @"?";
                } else {
                    cell.nameLabel.text = team.displayName;
                    cell.emojiLabel.text = team.emoji;
                }
                
                assignmentLabel = cell.nameLabel;
                return cell;
            }
            
            // Else it's unassigned
            ZNGAssignUserTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"unassigned" forIndexPath:indexPath];
            assignmentLabel = cell.nameLabel;
            return cell;
        }
            
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
            
            BOOL channelTypeIsHumanReadable = [channel.channelType valueIsHumanReadable];
            BOOL locked = ((!channelTypeIsHumanReadable) || ([self.contact editingChannelIsLocked:channel]));
            
            if ([channel isPhoneNumber]) {
                ZNGContactPhoneNumberTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"phone" forIndexPath:indexPath];
                cell.service = self.service;
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
    
    SBLogError(@"Unknown section %lld in contact editing table view", (long long)indexPath.section);
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ContactSectionCalendarEvents) {
        if ([self eventForIndexPath:indexPath] == nil) {
            // This must be the "show more" row
            
            // Show a new view with all events
            [self performSegueWithIdentifier:EventsSegueIdentifier sender:self];
            
            // De-select after the transition
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
            });
        }
    } else if (indexPath.section == ContactSectionChannels) {
        if (indexPath.row >= [self.contact.channels count]) {
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
    } else if (indexPath.section == ContactSectionAssignment) {
        [self performSegueWithIdentifier:AssignSegueIdentifier sender:self];
        
        // De-select after the segue
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        });
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
        SBLogError(@"Remove label delegate method was called, but with no label selected.  Ignoring.");
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
    } else if ([segue.identifier isEqualToString:AssignSegueIdentifier]) {
        UINavigationController * navController = segue.destinationViewController;
        ZNGAssignmentViewController * assignView = [navController.viewControllers firstObject];
        assignView.session = (ZingleAccountSession *)self.contactClient.session;
        assignView.contact = self.contact;
        assignView.delegate = self;
    } else if ([segue.identifier isEqualToString:EventsSegueIdentifier]) {
        ZNGContactEventsViewController * eventsView = segue.destinationViewController;
        eventsView.conversation = self.conversation;
    }
}

#pragma mark - Assignment
- (void) userChoseToUnassignContact:(ZNGContact *)contact
{
    self.contact.assignedToTeamId = nil;
    self.contact.assignedToUserId = nil;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ContactSectionAssignment] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) userChoseToAssignContact:(ZNGContact *)contact toTeam:(ZNGTeam *)team
{
    self.contact.assignedToTeamId = team.teamId;
    self.contact.assignedToUserId = nil;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ContactSectionAssignment] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) userChoseToAssignContact:(ZNGContact *)contact toUser:(ZNGUser *)user
{
    self.contact.assignedToTeamId = nil;
    self.contact.assignedToUserId = user.userId;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ContactSectionAssignment] withRowAnimation:UITableViewRowAnimationNone];
}

@end
