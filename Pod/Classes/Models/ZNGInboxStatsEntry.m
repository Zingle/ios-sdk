//
//  ZNGInboxStatsEntry.m
//  ZingleSDK
//
//  Created by Jason Neel on 1/24/18.
//

#import "ZNGInboxStatsEntry.h"
#import "ZingleValueTransformers.h"

@implementation ZNGInboxStatsEntry

+ (NSDictionary*)JSONKeyPathsByPropertyKey
{
    return @{
             NSStringFromSelector(@selector(openCount)): @"open",
             NSStringFromSelector(@selector(unreadCount)): @"unread",
             NSStringFromSelector(@selector(oldestUnconfirmed)): @"oldestUnconfirmed",
             };
}

- (id) initByCombiningEntries:(NSArray<ZNGInboxStatsEntry *> * _Nullable)entries
{
    ZNGInboxStatsEntry * totaledEntry = [self init];
    
    for (ZNGInboxStatsEntry * entry in entries) {
        totaledEntry.openCount = totaledEntry.openCount + entry.openCount;
        totaledEntry.unreadCount = totaledEntry.unreadCount + entry.unreadCount;
        
        if (totaledEntry.oldestUnconfirmed == nil) {
            // We do not yet have an unconfirmed time.  Use any present in this entry as the current oldest.
            totaledEntry.oldestUnconfirmed = entry.oldestUnconfirmed;
        } else if (entry.oldestUnconfirmed != nil) {
            // We have two times to compare
            NSTimeInterval timeFromCurrentOldestToThisOldest = [entry.oldestUnconfirmed timeIntervalSinceDate:totaledEntry.oldestUnconfirmed];
            
            if (timeFromCurrentOldestToThisOldest < 0.0) {
                // This new one is older
                totaledEntry.oldestUnconfirmed = entry.oldestUnconfirmed;
            }
        }
    }
    
    return totaledEntry;
}

+ (NSValueTransformer *)oldestUnconfirmedJSONTransformer
{
    return [ZingleValueTransformers dateValueTransformer];
}

@end
