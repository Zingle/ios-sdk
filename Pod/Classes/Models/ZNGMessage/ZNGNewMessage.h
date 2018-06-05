//
//  ZNGNewMessage.h
//  Pods
//
//  Created by Ryan Farley on 2/8/16.
//
//

#import <Mantle/Mantle.h>
#import "ZNGParticipant.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZNGNewMessage : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong, nullable) NSString* senderType;
@property(nonatomic, strong, nullable) ZNGParticipant* sender;
@property(nonatomic, strong, nullable) NSString* recipientType;
@property(nonatomic, strong, nullable) NSArray<ZNGParticipant *> * recipients;
@property(nonatomic, strong, nullable) NSArray* channelTypeIds; // Array of NSString
@property(nonatomic, strong, nullable) NSString* body;
@property(nonatomic, strong, nullable) NSArray* attachments;
@property(nonatomic, strong, nullable) NSString * uuid;

/**
 *  Outgoing image attachments for local rendering
 */
@property(nonatomic, strong, nullable) NSArray<UIImage *> * outgoingImageAttachments;

/**
 *  Asynchronously attaches the provided image data, resizing if necessary and populating outgoingImageAttachments.
 *
 *  @params maxSize Optional maximum image size.  Defaults to 800x800 if maxSize is CGSizeZero.
 */
- (void) attachImageData:(NSData *)imageData withMaximumSize:(CGSize)maxSize removingExisting:(BOOL)removeExisting completion:(void (^ _Nullable)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
