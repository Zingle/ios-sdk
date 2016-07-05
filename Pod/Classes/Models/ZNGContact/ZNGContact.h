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

@interface ZNGContact : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString* contactId;
@property(nonatomic) BOOL isConfirmed;
@property(nonatomic) BOOL isStarred;
@property(nonatomic, strong) ZNGMessage* lastMessage;
@property(nonatomic, strong) NSArray<ZNGChannel *> * channels; // Array of ZNGChannel
@property(nonatomic, strong) NSArray * customFieldValues; // Array of ZNGContactFieldValue or ZNGNewContactFieldValue.  Why do these two classes both exist?
@property(nonatomic, strong) NSArray<ZNGLabel *> * labels; // Array of ZNGLabel
@property(nonatomic, strong) NSDate* createdAt;
@property(nonatomic, strong) NSDate* updatedAt;

@property (nonatomic, weak, nullable) ZNGContactClient * contactClient;

-(ZNGContactFieldValue *)titleFieldValue;
-(ZNGContactFieldValue *)firstNameFieldValue;
-(ZNGContactFieldValue *)lastNameFieldValue;
-(ZNGChannel *)phoneNumberChannel;

/*
 *  Differs slightly from the phoneNumberChannel method in that this also checks if the contact has a recently used channel, then checks
 *   for a default phone number if there are multiples.
 */
- (ZNGChannel *)channelForFreshOutgoingMessage;

- (NSString *)fullName;

/**
 *  Returns YES if any of the inbox display information has changed between instances, such as name, last message, star, labels, confirmation status
 *
 *  @param old The instance of this contact to compare against.
 *  @returns YES if information has differed since the old instance.
 */
- (BOOL)requiresVisualRefeshSince:(ZNGContact *)old;

/**
 *  Returns YES if a table that contains this contact should emphasize the refresh.
 *  Changes to the message itself will cause a value of YES.
 *  Changes to star or confirmed status will return NO.
 */
- (BOOL) visualRefreshSinceOldMessageShouldAnimate:(ZNGContact *)old;

- (BOOL) isEqualToContact:(ZNGContact *)other;

@end
