//
//  ZNGContact.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGMessage.h"
#import "ZNGContactFieldValue.h"

@class ZNGChannel;
@class ZNGContactFieldValue;
@class ZNGLabel;
@class ZNGContactClient;
@class ZNGContactGroup;
@class ZNGNewContactFieldValue;
@class ZNGNewChannel;
@class ZNGTeam;
@class ZNGUser;

/**
 *  The notification posted whenever a contact mutates itself.  The object in the NSNotification will be the updated ZNGContact
 */
extern NSString * __nonnull const ZNGContactNotificationSelfMutated;

NS_ASSUME_NONNULL_BEGIN

@interface ZNGContact : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* contactId;
@property(nonatomic) BOOL isConfirmed;
@property(nonatomic) BOOL isStarred;
@property(nonatomic) BOOL isClosed;
@property(nonatomic) BOOL isMessageable;
@property(nonatomic, copy, nullable) NSString * lockedBySource;
@property(nonatomic, strong, nullable) ZNGMessage* lastMessage;
@property(nonatomic, strong, nullable) NSArray<ZNGChannel *> * channels; // Array of ZNGChannel
@property(nonatomic, strong, nullable) NSArray * customFieldValues; // Array of ZNGContactFieldValue or ZNGNewContactFieldValue.  Why do these two classes both exist?
@property(nonatomic, strong, nullable) NSArray<ZNGLabel *> * labels; // Array of ZNGLabel
@property(nonatomic, strong, nullable) NSArray<ZNGContactGroup *> * groups;
@property(nonatomic, strong, nullable) NSString * assignedToTeamId;
@property(nonatomic, strong, nullable) NSString * assignedToUserId;
@property(nonatomic, strong, nullable) NSDate* createdAt;
@property(nonatomic, strong, nullable) NSDate* updatedAt;
@property(nonatomic, strong, nullable) NSURL * avatarUri;

@property (nonatomic, weak, nullable) ZNGContactClient * contactClient;

-(nullable ZNGContactFieldValue *)titleFieldValue;
-(nullable ZNGContactFieldValue *)firstNameFieldValue;
-(nullable ZNGContactFieldValue *)lastNameFieldValue;
-(nullable ZNGContactFieldValue *)roomFieldValue;

/**
 *  Returns the contact field of the specified type if present in this contact.  Nil if there is no existing value.
 */
- (nullable ZNGContactFieldValue *) contactFieldValueForType:(ZNGContactField *)field;

/**
 *  If there is a default phone number channel, this will return that channel.  Otherwise, it will return the first available phone number channel.
 */
-(nullable ZNGChannel *)phoneNumberChannel;

/**
 *  Causes the contact to go refresh its own data in place.
 */
- (void) updateRemotely;

/**
 *  Updates this contact with a newer copy
 */
- (void) updateWithNewData:(ZNGContact *)contact;

/**
 *  Returns a default channel if available.  Returns the only channel if only one exists.
 */
- (nullable ZNGChannel *)defaultChannel;

/**
 *  Returns the first available channel of the specified type
 */
- (nullable ZNGChannel *)channelOfType:(ZNGChannelType *)type;

- (nullable NSString *)fullName;
- (nullable NSString *) initials;

/**
 *  Returns YES if the contact has been changed since the old copy.
 *
 *  @param old The older instance of the same contact.
 */
- (BOOL) changedSince:(nullable ZNGContact *)old;

/**
 *  Returns YES if a table that contains this contact should emphasize the refresh.
 *  Changes to the message itself will cause a value of YES.
 *  Changes to star or confirmed status will return NO.
 */
- (BOOL) visualRefreshSinceOldMessageShouldAnimate:(nullable ZNGContact *)old;

/**
 *  Returns YES if a contact's meta data has been edited since a previous copy.  Used primarily to check for dirtiness in contact edit UI.
 */
- (BOOL) hasBeenEditedSince:(ZNGContact *)old;

- (BOOL) isEqualToContact:(nullable ZNGContact *)other;

- (NSArray<ZNGChannel *> *) channelsWithValues;
- (NSArray<ZNGContactFieldValue *> *) customFieldsWithValues;

/**
 *  Converts the custom field values into the stripped down "new value" objects for sending to the server.
 *  Note that any fields that are locked for editing will be excluded from the resulting array.
 */
- (NSArray<ZNGNewContactFieldValue *> *) customFieldsWithValuesAsNewValueObjects;

/**
 *  Returns empty string new contact field value objects corresponding to all custom fields that have been deleted since the supplied copy of this contact.
 *  This is needed since PUTting a contact with missing fields does not remove those fields in the 1.x API :(
 */
- (NSArray<ZNGNewContactFieldValue *> *) customFieldsDeletedSince:(ZNGContact *)oldContact;

/**
 *  Returns YES if the field is uneditable either because it is locked itself (functionality not existing atm) or if the
 *   contact is locked by source and this custom field is locked by that state.
 */
- (BOOL) editingCustomFieldIsLocked:(ZNGContactFieldValue *)customField;

/**
 *  Returns YES if the user should not be able to edit the provided channel.  This generally means that the contact is locked by source and
 *   the channel type is phone number or email address.
 */
- (BOOL) editingChannelIsLocked:(ZNGChannel *)channel;

/**
 *  Returns a date, after which, this contact will be highlighted as "urgent" if still unconfirmed.
 */
- (NSDate *) lateUnconfirmedTime;

#pragma mark - Mutators
- (void) confirm;
- (void) unconfirm;
- (void) close;
- (void) reopen;
- (void) assignToTeam:(ZNGTeam *)team;
- (void) assignToUser:(ZNGUser *)user;
- (void) unassign;

NS_ASSUME_NONNULL_END

@end
