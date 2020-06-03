//
//  ZNGEventMetadataEntry.h
//  ZingleSDK
//
//  Created by Jason Neel on 6/2/20.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ZNGEventMetadataEntryMentionTypeUser;
extern NSString * const ZNGEventMetadataEntryMentionTypeTeam;

@interface ZNGEventMetadataEntry : MTLModel <MTLJSONSerializing>

/**
 * Metadata type, e.g. "userMention" or "teamMention"
 */
@property (nonatomic, strong, nullable) NSString * type;

/**
 * The UUID of the person/team/etc. referenced in the metadata
 */
@property (nonatomic, strong, nullable) NSString * uuid;

@property (nonatomic, strong, nullable) NSNumber * start;
@property (nonatomic, strong, nullable) NSNumber * end;

@end

NS_ASSUME_NONNULL_END
