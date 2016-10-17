//
//  ZNGAnalytics.m
//  Pods
//
//  Created by Jason Neel on 8/30/16.
//
//

#import "ZNGAnalytics.h"
#import "ZNGLogging.h"
#import "ZNGContact.h"
#import "ZNGUserAuthorization.h"
#import "ZNGInboxDataSet.h"
#import "ZNGContactField.h"
#import "ZNGTemplate.h"
#import "ZNGAutomation.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGLabel.h"
@import Analytics;

static const int zngLogLevel = ZNGLogLevelInfo;

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
        ZNGLogError(@"Segment write key being set, but it was already set earlier.  Ignoring.");
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

#pragma mark - Login
- (void) trackLoginFailureWithToken:(NSString *)token
{
    NSString * event = @"Login failed";
    NSMutableDictionary * properties = [self defaultProperties];
    [[self segment] track:event properties:properties];
}

- (void) trackLoginSuccessWithToken:(NSString *)token andUserAuthorizationObject:(ZNGUserAuthorization *)userAuthorization
{
    NSMutableDictionary<NSString *, NSString *> * traits = [[NSMutableDictionary alloc] init];
    
    // Using setValue:forKey: instead of shorthand [] or setObject:forKey: so we do not have to check for nil values
    [traits setValue:token forKey:@"username"];
    [traits setValue:userAuthorization.userId forKey:@"username"];
    [traits setValue:userAuthorization.email forKey:@"email"];
    [traits setValue:userAuthorization.firstName forKey:@"firstName"];
    [traits setValue:userAuthorization.lastName forKey:@"lastName"];
    [traits setValue:userAuthorization.title forKey:@"title"];
    
    if (([userAuthorization.firstName length] > 0) && ([userAuthorization.lastName length] > 0)) {
        NSString * name = [NSString stringWithFormat:@"%@ %@", userAuthorization.firstName, userAuthorization.lastName];
        traits[@"name"] = name;
    }
    
    [[self segment] identify:token traits:traits];
    [[self segment] track:@"Login succeeded" properties:[self defaultProperties]];
}

- (void) trackLogout
{
    [[self segment] track:@"Logged out" properties:[self defaultProperties]];
    [[self segment] reset];
}

#pragma mark - Inbox
- (void) trackConversationFilterSwitch:(ZNGInboxDataSet *)inboxData
{
    NSString * event = @"Inbox filter changed";
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"inboxType"] = [inboxData description];
    
    [[self segment] track:event properties:properties];
}

#pragma mark - Conversation events
- (void) trackInsertedCustomField:(ZNGContactField *)customField intoConversation:(ZNGConversationServiceToContact *)conversation
{
    NSString * recipientType = (conversation == nil) ? @"a new message" : @"an existing conversation";
    NSString * event = [NSString stringWithFormat:@"Inserted a custom field into %@", recipientType];
    
    NSMutableDictionary * properties = [self defaultPropertiesWithConversation:conversation];
    properties[@"customFieldName"] = customField.displayName;
    
    [[self segment] track:event properties:properties];
}

- (void) trackInsertedTemplate:(ZNGTemplate *)template intoConversation:(ZNGConversationServiceToContact *)conversation
{
    NSString * recipientType = (conversation == nil) ? @"a new message" : @"an existing conversation";
    NSString * event = [NSString stringWithFormat:@"Inserted a template into %@", recipientType];

    NSMutableDictionary * properties = [self defaultPropertiesWithConversation:conversation];
    properties[@"templateName"] = template.displayName;
    
    [[self segment] track:event properties:properties];
}

- (void) trackTriggeredAutomation:(ZNGAutomation *)automation onContact:(ZNGContact *)contact
{
    NSString * event = @"Triggered an automation";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    properties[@"automationName"] = automation.displayName;
    
    [[self segment] track:event properties:properties];
}

- (void) trackSentSavedImageToConversation:(ZNGConversation *)conversation
{
    [[self segment] track:@"Sent a saved image" properties:[self defaultPropertiesWithConversation:conversation]];
}

- (void) trackSentCameraImageToConversation:(ZNGConversation *)conversation
{
    [[self segment] track:@"Sent a camera image" properties:[self defaultPropertiesWithConversation:conversation]];
}

- (void) trackAddedNote:(NSString *)note toConversation:(ZNGConversationServiceToContact *)conversation
{
    NSString * event = @"Added an internal note";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithConversation:conversation];
    properties[@"noteText"] = note;
    
    [[self segment] track:event properties:properties];
}

- (void) trackSentMessage:(ZNGMessage *)message inConversation:(ZNGConversation *)conversation
{
    NSString * event = @"Sent a message";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithConversation:conversation];
    [properties setValue:message.text forKey:@"messageText"];
    BOOL hasAttachment = ([message.attachments count] > 0);
    properties[@"hasAttachment"] = @(hasAttachment);
    
    [[self segment] track:event properties:properties];
}

- (void) trackSentMessage:(NSString *)messageBody toContact:(ZNGContact *)contact
{
    NSString * event = @"Sent a message";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    [properties setValue:messageBody forKey:@"messageText"];
    properties[@"hasAttachment"] = @NO;

    [[self segment] track:event properties:properties];
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
    
    [[self segment] track:event properties:properties];
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
    
    [[self segment] track:event properties:properties];
}

- (void) trackSentMessage:(NSString *)messageBody toPhoneNumbers:(NSArray<NSString *> *)phoneNumbers
{
    NSString * event = @"Sent a message to phone number(s)";
    
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"phoneNumbers"] = phoneNumbers;
    
    [[self segment] track:event properties:properties];
}


- (void) trackChangedChannel:(ZNGChannel *)channel inConversation:(ZNGConversationServiceToContact *)conversation
{
    // These conversation properties will include new channel info
    [[self segment] track:@"Selected a channel" properties:[self defaultPropertiesWithConversation:conversation]];
}

- (void) trackConfirmedContact:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType;
{
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"contactName"] = [contact fullName];

    if ([sourceType length] > 0) {
        properties[@"source"] = sourceType;
    }
    
    [[self segment] track:@"Confirmed conversation" properties:properties];
}

- (void) trackUnconfirmedContact:(ZNGContact *)contact fromUIType:(nullable NSString *)sourceType;
{
    NSMutableDictionary * properties = [self defaultProperties];
    properties[@"contactName"] = [contact fullName];
    
    if ([sourceType length] > 0) {
        properties[@"source"] = sourceType;
    }
    
    [[self segment] track:@"Unconfirmed conversation" properties:properties];
}

- (void) trackStarredContact:(ZNGContact *)contact
{
    [[self segment] track:@"Starred contact" properties:[self defaultPropertiesWithDestinationContact:contact]];
}

- (void) trackUnstarredContact:(ZNGContact *)contact
{
    [[self segment] track:@"Unstarred contact" properties:[self defaultPropertiesWithDestinationContact:contact]];
}

- (void) trackShowedConversationDetails:(ZNGConversationServiceToContact *)conversation
{
    [[self segment] track:@"Showed detailed events in conversation" properties:[self defaultPropertiesWithConversation:conversation]];
}

- (void) trackHidConversationDetails:(ZNGConversationServiceToContact *)conversation
{
    [[self segment] track:@"Hid detailed events in conversation" properties:[self defaultPropertiesWithConversation:conversation]];
}

#pragma mark - Contact management
- (void) trackCreatedContact:(ZNGContact *)contact
{
    [[self segment] track:@"Created new contact" properties:[self defaultPropertiesWithDestinationContact:contact]];
}

- (void) trackEditedExistingContact:(ZNGContact *)contact
{
    [[self segment] track:@"Edited contact" properties:[self defaultPropertiesWithDestinationContact:contact]];
}

- (void) trackAddedLabel:(ZNGLabel *)label toContact:(ZNGContact *)contact
{
    NSString * event = @"Added a label to contact on the contact edit screen";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    [properties setValue:label.displayName forKey:@"labelName"];
    
    [[self segment] track:event properties:properties];
}

- (void) trackRemovedLabel:(ZNGLabel *)label fromContact:(ZNGContact *)contact
{
    NSString * event = @"Removed a label from contact on the contact edit screen";
    
    NSMutableDictionary * properties = [self defaultPropertiesWithDestinationContact:contact];
    [properties setValue:label.displayName forKey:@"labelName"];
    
    [[self segment] track:event properties:properties];
}


@end
