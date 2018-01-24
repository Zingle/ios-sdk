//
//  ZNGInboxStatsEntry.h
//  ZingleSDK
//
//  Created by Jason Neel on 1/24/18.
//

#import <Mantle/Mantle.h>

@interface ZNGInboxStatsEntry : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSUInteger openCount;
@property (nonatomic, assign) NSUInteger unreadCount;
@property (nonatomic, strong, nullable) NSDate * oldestUnconfirmed;

- (id _Nonnull) initByCombiningEntries:(NSArray<ZNGInboxStatsEntry *> * _Nullable)entries;

@end
