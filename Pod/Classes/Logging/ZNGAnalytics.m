//
//  ZNGAnalytics.m
//  Pods
//
//  Created by Jason Neel on 8/30/16.
//
//

#import "ZNGAnalytics.h"
#import "ZNGContact.h"
#import "ZNGUserAuthorization.h"
#import "ZNGInboxDataSet.h"
#import "ZNGContactField.h"
#import "ZNGTemplate.h"
#import "ZNGAutomation.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGLabel.h"
#import "ZNGContactGroup.h"
#import "ZNGTeam.h"
#import "ZNGUser.h"

@import Analytics;
@import SBObjectiveCWrapper;

static NSString * const HostPropertyName = @"Host";

@implementation ZNGAnalytics
{
    NSString * host;
}

#pragma mark - Initialization
+ (instancetype) sharedAnalytics
{
    static id singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (id) init
{
    self = [super init];
    
    if (self != nil)
    {
        _enabled = NO;
    }
    
    return self;
}

#pragma mark - Configuration
- (void) setSegmentWriteKey:(NSString *)segmentWriteKey
{
    if ([_segmentWriteKey length] > 0) {
        SBLogError(@"Segment write key being set, but it was already set earlier.  Ignoring.");
        return;
    }
    
    _segmentWriteKey = [segmentWriteKey copy];
    
    SEGAnalyticsConfiguration * config = [SEGAnalyticsConfiguration configurationWithWriteKey:_segmentWriteKey];
    config.trackApplicationLifecycleEvents = YES;
    config.recordScreenViews = YES;
    [SEGAnalytics setupWithConfiguration:config];
}

- (void) setZingleURL:(NSURL *)zingleURL
{
    _zingleURL = [zingleURL copy];
    
    host = [[[_zingleURL host] componentsSeparatedByString:@"."] firstObject];
}

#pragma mark - Metadata
- (NSMutableDictionary<NSString *, NSString *> *) defaultProperties
{
    NSMutableDictionary * properties = [[NSMutableDictionary alloc] init];
    
    if ([host length] > 0) {
        properties[HostPropertyName] = host;
    }
    
    return properties;
}

- (NSMutableDictionary<NSString *, NSString *> *) defaultPropertiesWithDestinationContact:(ZNGContact *)contact
{
    NSMutableDictionary * properties = [self defaultProperties];
    
    [properties setValue:[contact fullName] forKey:@"contactName"];
    [properties setValue:contact.contactId forKey:@"contactId"];
    
    return properties;
}

- (NSMutableDictionary<NSString *, NSString *> *) defaultPropertiesWithConversation:(ZNGConversation *)conversation
{
    NSMutableDictionary * properties;
    
    if ([conversation isKindOfClass:[ZNGConversationServiceToContact class]]) {
        ZNGConversationServiceToContact * serviceConversation = (ZNGConversationServiceToContact *)conversation;
        
        properties = [self defaultPropertiesWithDestinationContact:serviceConversation.contact];
        
        [properties setValue:serviceConversation.channel.channelType.displayName forKey:@"selectedChannelType"];
        [properties setValue:serviceConversation.channel.value forKey:@"selectedChannelValue"];
        [properties setValue:serviceConversation.channel.channelId forKey:@"selectedChannelId"];
    } else {
        properties = [self defaultProperties];
    }
    
    properties[@"conversationType"] = NSStringFromClass([conversation class]);

    return properties;
}

#pragma mark - Segment
- (SEGAnalytics *) segment
{
    if ((self.enabled) && (self.segmentWriteKey != nil)) {
        return [SEGAnalytics sharedAnalytics];
    }
    
    return nil;
}

#pragma mark - Tracking
- (void) _track:(NSString *)event properties:(NSDictionary <NSString *, NSString *> *)properties
{
    // Segment does not give the product people any way to filter by platform or OS, so we have to prepend this ugly identifier :(
    NSString * prefixedEventName = [NSString stringWithFormat:@"ios_%@", event];
    
    // Exclude Intercom since Intercom only allows a tiny number of events.  We'll keep iOS events out of it.
    NSDictionary * options = @{ @"integrations": @{ @"All": @YES, @"Intercom": @NO } };
    
    [[self segment] track:prefixedEventName properties:properties options:options];
}

#pragma mark - Login
- (void) trackLoginFailure
{
    NSString * event = @"Login failed";
    NSMutableDictionary * properties = [self defaultProperties];
    [self _track:event properties:properties];
}

- (void) trackLoginSuccessWithToken:(NSString *)token andUserAuthorizationObject:(ZNGUserAuthorization *)userAuthorization
{
    NSMutableDictionary<NSString *, NSString *> * traits = [[NSMutableDictionary alloc] init];
    
    // Using setValue:forKey: instead of shorthand [] or setObject:forKey: so we do not have to check for nil values
    [traits setValue:token forKey:@"username"];
    [traits setValue:userAuthorization.email forKey:@"email"];
    [traits setValue:userAuthorization.firstName forKey:@"firstName"];
    [traits setValue:userAuthorization.lastName forKey:@"lastName"];
    [traits setValue:userAuthorization.title forKey:@"title"];
    
    if (([userAuthorization.firstName length] > 0) && ([userAuthorization.lastName length] > 0)) {
        NSString * name = [NSString stringWithFormat:@"%@ %@", userAuthorization.firstName, userAuthorization.lastName];
        traits[@"name"] = name;
    }
    
    [[self segment] identify:userAuthorization.userId traits:traits];
    [self _track:@"Login succeeded" properties:[self defaultProperties]];
}

- (void) trackLogout
{
    [self _track:@"Logged out" properties:[self defaultProperties]];
    [[self segment] reset];
}

#pragma mark - Inbox
- (void) trackConversationFilterSwitch:(ZNGInboxDataSet *)inboxData
{
    NSString * event = @"Inbox filter changed";
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"inboxType"] = [inboxData description];
    properties[@"sorting"] = [inboxData sortFields];
    
    [self _track:event properties:properties];
}

- (void) _trackSelectedInboxSort:(NSString *)type
{
    NSString * event = @"Inbox sorted";
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"type"] = type;
    
    [self _track:event properties:properties];
}

- (void) trackSelectedInboxSortNewest
{
    [self _trackSelectedInboxSort:@"newest"];
}

- (void) trackSelectedInboxSortOldest
{
    [self _trackSelectedInboxSort:@"oldest"];
}

- (void) trackSelectedInboxSortCustomField:(NSString *)fieldId
{
    [self _trackSelectedInboxSort:@"custom"];
}

- (void) trackToggledOpenFilter:(BOOL)open
{
    NSString * event = @"Conversation status tab selected";
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"toOpen"] = @(open);
    
    [self _track:event properties:properties];
}

- (void) trackToggledUnreadFilter:(BOOL)unread
{
    NSString * event = @"Unread toggled";
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"on"] = @(unread);
    
    [self _track:event properties:properties];
}

#pragma mark - Conversation events
- (void) trackInsertedCustomField:(ZNGContactField *)customField intoConversation:(ZNGConversationServiceToContact *)conversation
{
    NSString * recipientType = (conversation == nil) ? @"a new message" : @"an existing conversation";
    NSString * event = [NSString stringWithFormat:@"Inserted a custom field into %@", recipientType];
    
    NSMutableDictionary * properties = [self defaultPropertiesWithConversation:conversation];
    properties[@"customFieldName"] = customField.displayName;
    
    [self _track:event properties:properties];
}

- (void) trackInsertedTemplate:(ZNGTemplate *)template intoConversation:(ZNGConversationServiceToContact *)conversation
{
    NSString * recipientType = (conversation == nil) ? @"a new message" : @"an existing conversation";
    NSString * event = [NSString stringWithFormat:@"Inserted a template into %@", recipientType];

    NSMutableDictionary * properties = [self defaultPropertiesWithConversation:conversation];
    properties[@"templateName"] = template.displayName;
    
    [self _track:event properties:properties];
}

- (void) trackTriggeredAutomation:(ZNGAutomation *)automation onContact:(ZNGContact *)contact
{
    NSString * event = @"Triggered an automation";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    properties[@"automationName"] = automation.displayName;
    
    [self _track:event properties:properties];
}

- (void) trackSentSavedImageToConversation:(ZNGConversation *)conversation
{
    [self _track:@"Sent a saved image" properties:[self defaultPropertiesWithConversation:conversation]];
}

- (void) trackSentCameraImageToConversation:(ZNGConversation *)conversation
{
    [self _track:@"Sent a camera image" properties:[self defaultPropertiesWithConversation:conversation]];
}

- (void) trackAddedNote:(NSString *)note toConversation:(ZNGConversationServiceToContact *)conversation
{
    NSString * event = @"Added an internal note";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithConversation:conversation];
    properties[@"noteText"] = note;
    
    [self _track:event properties:properties];
}

- (void) trackAddedNoteSource:(NSString *)source
{
    NSString * event = @"Mention";
    NSMutableDictionary * properties = [self defaultProperties];
    
    properties[@"Source"] = source;
    [self _track:event properties:properties];
}

- (void) trackSentMessage:(ZNGMessage *)message inConversation:(ZNGConversation *)conversation
{
    NSString * event = @"Sent a message";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithConversation:conversation];
    [properties setValue:message.text forKey:@"messageText"];
    BOOL hasAttachment = ([message.attachments count] > 0);
    properties[@"hasAttachment"] = @(hasAttachment);
    
    [self _track:event properties:properties];
}

- (void) trackSentMessage:(NSString *)messageBody toContact:(ZNGContact *)contact
{
    NSString * event = @"Sent a message";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    [properties setValue:messageBody forKey:@"messageText"];
    properties[@"hasAttachment"] = @NO;

    [self _track:event properties:properties];
}

- (void) trackSentMessage:(NSString *)messageBody toMultipleContacts:(NSArray<ZNGContact *> *)contacts
{
    NSString * event = @"Sent a message to multiple contacts";
    
    NSMutableDictionary * properties = [self defaultProperties];
    
    NSMutableArray * contactIds = [[NSMutableArray alloc] initWithCapacity:[contacts count]];
    NSMutableArray * contactNames = [[NSMutableArray alloc] initWithCapacity:[contacts count]];
    
    for (ZNGContact * contact in contacts) {
        [contactIds addObject:contact.contactId];
        [contactNames addObject:[contact fullName]];
    }
    
    properties[@"contactNames"] = contactNames;
    properties[@"contactIds"] = contactIds;
    
    [self _track:event properties:properties];
}

- (void) trackSentMessage:(NSString *)messageBody toLabels:(NSArray<ZNGLabel *> *)labels
{
    NSString * event = @"Sent a message to label(s)";
    
    NSMutableDictionary * properties = [self defaultProperties];
    
    NSMutableArray * labelNames = [[NSMutableArray alloc] initWithCapacity:[labels count]];
    NSMutableArray * labelIds = [[NSMutableArray alloc] initWithCapacity:[labels count]];
    
    for (ZNGLabel * label in labels) {
        [labelNames addObject:label.displayName];
        [labelIds addObject:label.labelId];
    }
    
    properties[@"labelNames"] = labelNames;
    properties[@"labelIds"] = labelIds;
    
    [self _track:event properties:properties];
}

- (void) trackSentMessage:(NSString *)messageBody toGroups:(NSArray<ZNGContactGroup *> *)groups
{
    NSString * event = @"Sent a message to group(s)";
    
    NSMutableDictionary * properties = [self defaultProperties];
    
    NSMutableArray * groupNames = [[NSMutableArray alloc] initWithCapacity:[groups count]];
    NSMutableArray * groupIds = [[NSMutableArray alloc] initWithCapacity:[groups count]];
    
    for (ZNGContactGroup * group in groups) {
        [groupNames addObject:group.displayName];
        [groupIds addObject:group.groupId];
    }
    
    properties[@"groupNames"] = groupNames;
    properties[@"groupIds"] = groupIds;
    
    [self _track:event properties:properties];
}

- (void) trackSentMessage:(NSString *)messageBody toPhoneNumbers:(NSArray<NSString *> *)phoneNumbers
{
    NSString * event = @"Sent a message to phone number(s)";
    
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"phoneNumbers"] = phoneNumbers;
    
    [self _track:event properties:properties];
}


- (void) trackChangedChannel:(ZNGChannel *)channel inConversation:(ZNGConversationServiceToContact *)conversation
{
    // These conversation properties will include new channel info
    [self _track:@"Selected a channel" properties:[self defaultPropertiesWithConversation:conversation]];
}

- (void) trackConfirmedContact:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType;
{
    NSString * event = @"Confirmed conversation";
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"contactName"] = [contact fullName];

    if ([sourceType length] > 0) {
        properties[@"source"] = sourceType;
        event = [event stringByAppendingFormat:@" by %@", sourceType];
    }
    
    [self _track:event properties:properties];
}

- (void) trackUnconfirmedContact:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType;
{
    NSString * event = @"Unconfirmed conversation";
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"contactName"] = [contact fullName];
    
    if ([sourceType length] > 0) {
        properties[@"source"] = sourceType;
        event = [event stringByAppendingFormat:@" by %@", sourceType];
    }
    
    [self _track:event properties:properties];
}

- (void) trackOpenedContact:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType
{
    NSString * event = @"Opened conversation";
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"contactName"] = [contact fullName];
    
    if ([sourceType length] > 0) {
        properties[@"source"] = sourceType;
        event = [event stringByAppendingFormat:@" by %@", sourceType];
    }
    
    [self _track:event properties:properties];
}

- (void) trackClosedContact:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType
{
    NSString * event = @"Closed conversation";
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"contactName"] = [contact fullName];
    
    if ([sourceType length] > 0) {
        properties[@"source"] = sourceType;
        event = [event stringByAppendingFormat:@" by %@", sourceType];
    }
    
    [self _track:event properties:properties];
}

- (void) trackShowedConversationDetails:(ZNGConversationServiceToContact *)conversation
{
    [self _track:@"Showed detailed events in conversation" properties:[self defaultPropertiesWithConversation:conversation]];
}

- (void) trackHidConversationDetails:(ZNGConversationServiceToContact *)conversation
{
    [self _track:@"Hid detailed events in conversation" properties:[self defaultPropertiesWithConversation:conversation]];
}

#pragma mark - Contact management
- (void) trackCreatedContact:(ZNGContact *)contact
{
    [self _track:@"Created new contact" properties:[self defaultPropertiesWithDestinationContact:contact]];
}

- (void) trackEditedExistingContact:(ZNGContact *)contact
{
    [self _track:@"Edited contact" properties:[self defaultPropertiesWithDestinationContact:contact]];
}

- (void) trackAddedLabel:(ZNGLabel *)label toContact:(ZNGContact *)contact
{
    NSString * event = @"Added a label to contact on the contact edit screen";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    [properties setValue:label.displayName forKey:@"labelName"];
    
    [self _track:event properties:properties];
}

- (void) trackRemovedLabel:(ZNGLabel *)label fromContact:(ZNGContact *)contact
{
    NSString * event = @"Removed a label from contact on the contact edit screen";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    [properties setValue:label.displayName forKey:@"labelName"];
    
    [self _track:event properties:properties];
}

- (void) trackContactUnassigned:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType
{
    NSString * event = @"Unassigned contact";
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    
    if ([sourceType length] > 0) {
        properties[@"source"] = sourceType;
        event = [event stringByAppendingFormat:@" by %@", sourceType];
    }
    
    [self _track:event properties:properties];
}

- (void) trackContact:(ZNGContact *)contact assignedToTeam:(ZNGTeam *)team fromUIType:(nullable NSString *)sourceType
{
    NSString * event = @"Assigned contact to team";
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    
    properties[@"teamName"] = team.displayName;
    properties[@"teamId"] = team.teamId;
    
    if ([sourceType length] > 0) {
        properties[@"source"] = sourceType;
        event = [event stringByAppendingFormat:@" by %@", sourceType];
    }
    
    [self _track:event properties:properties];
}

- (void) trackContact:(ZNGContact *)contact assignedToUser:(ZNGUser *)user fromUIType:(nullable NSString *)sourceType
{
    NSString * event = @"Assigned contact to user";
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    
    properties[@"userName"] = [user fullName];
    properties[@"userId"] = user.userId;
    
    if ([sourceType length] > 0) {
        properties[@"source"] = sourceType;
        event = [event stringByAppendingFormat:@" by %@", sourceType];
    }
    
    [self _track:event properties:properties];
}

#pragma mark - Easter eggs
- (void) trackEasterEggNamed:(NSString *)eggName
{
    NSString * event = @"Easter egg triggered";
    
    NSMutableDictionary * properties = [self defaultProperties];
    
    if (eggName != nil) {
        properties[@"easterEggName"] = eggName;
    }
    
    [self _track:event properties:properties];
}


@end
