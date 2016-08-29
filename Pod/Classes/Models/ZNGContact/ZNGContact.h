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

/**
 *  The notification posted whenever a contact mutates itself.  The object in the NSNotification will be the updated ZNGContact
 */
extern NSString * __nonnull const ZNGContactNotificationSelfMutated;

NS_ASSUME_NONNULL_BEGIN

@interface ZNGContact : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* contactId;
@property(nonatomic) BOOL isConfirmed;
@property(nonatomic) BOOL isStarred;
@property(nonatomic) BOOL lockedBySource;
@property(nonatomic, strong, nullable) ZNGMessage* lastMessage;
@property(nonatomic, strong, nullable) NSArray<ZNGChannel *> * channels; // Array of ZNGChannel
@property(nonatomic, strong, nullable) NSArray * customFieldValues; // Array of ZNGContactFieldValue or ZNGNewContactFieldValue.  Why do these two classes both exist?
@property(nonatomic, strong, nullable) NSArray<ZNGLabel *> * labels; // Array of ZNGLabel
@property(nonatomic, strong, nullable) NSDate* createdAt;
@property(nonatomic, strong, nullable) NSDate* updatedAt;

@property (nonatomic, weak, nullable) ZNGContactClient * contactClient;

-(nullable ZNGContactFieldValue *)titleFieldValue;
-(nullable ZNGContactFieldValue *)firstNameFieldValue;
-(nullable ZNGContactFieldValue *)lastNameFieldValue;

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
 *  Returns a default channel if available.  Returns the only channel if only one exists.
 */
- (nullable ZNGChannel *)defaultChannel;

/**
 *  Returns the first available channel of the specified type
 */
- (nullable ZNGChannel *)channelOfType:(ZNGChannelType *)type;

- (nullable NSString *)fullName;

/**
 *  Returns YES if any of the inbox display information has changed between instances, such as name, last message, star, labels, confirmation status
 *
 *  @param old The instance of this contact to compare against.
 *  @returns YES if information has differed since the old instance.
 */
- (BOOL)requiresVisualRefeshSince:(nullable ZNGContact *)old;

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

#pragma mark - Mutators
- (void) star;
- (void) unstar;
- (void) confirm;
- (void) unconfirm;

NS_ASSUME_NONNULL_END

@end
