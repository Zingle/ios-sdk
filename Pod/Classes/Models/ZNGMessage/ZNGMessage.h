//
//  ZNGMessage.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGCorrespondent.h"

@interface ZNGMessage : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *communicationDirection;
@property (nonatomic, strong) NSString *bodyLanguageCode;
@property (nonatomic, strong) NSString *translatedBody;
@property (nonatomic, strong) NSString *translatedBodyLanguageCode;
@property (nonatomic, strong) NSNumber *triggeredByUserId;
@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) NSString *senderType;
@property (nonatomic, strong) ZNGCorrespondent *sender;
@property (nonatomic, strong) NSString *recipientType;
@property (nonatomic, strong) ZNGCorrespondent *recipient;
@property (nonatomic, strong) NSArray *attachments;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *readAt;

@end
