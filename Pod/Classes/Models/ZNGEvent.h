//
//  ZNGEvent.h
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGUser.h"
#import "ZNGAutomation.h"
#import "ZNGMessage.h"

@class ZNGContact;
@class ZNGEventViewModel;

@interface ZNGEvent : MTLModel<MTLJSONSerializing, JSQMessageData>

@property(nonatomic, strong) NSString* eventId;
@property(nonatomic, strong) NSString* contactId;
@property(nonatomic, strong) NSString* eventType;
@property(nonatomic, strong) NSString* body;
@property(nonatomic, strong) NSDate* createdAt;
@property(nonatomic, strong) ZNGUser* triggeredByUser;
@property(nonatomic, strong) ZNGAutomation* automation;
@property(nonatomic, strong) ZNGMessage* message;

/**
 *  An array of one ZNGEventViewModel in the case of an event with no attachments, up to at most one per attachment plus one text for a non-nil body.
 */
@property (nonatomic, readonly) NSArray<ZNGEventViewModel *> * viewModels;

// Added after parsing:
@property (nonatomic, copy) NSString * senderDisplayName;

+ (instancetype) eventForNewMessage:(ZNGMessage *)message;
+ (instancetype) eventForNewNote:(NSString *)note toContact:(ZNGContact *)contact;

+ (NSArray<NSString *> *) recognizedEventTypes;

- (BOOL) isMessage;
- (BOOL) isNote;

/**
 *  If this is a message with attachments, this attributedText will return all images in line in as text attachments.
 */
- (NSAttributedString *) attributedText;

@end
