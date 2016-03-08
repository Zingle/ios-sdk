
//

#import "ZNGMessagesCollectionViewFlowLayoutInvalidationContext.h"

@implementation ZNGMessagesCollectionViewFlowLayoutInvalidationContext

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.invalidateFlowLayoutDelegateMetrics = NO;
        self.invalidateFlowLayoutAttributes = NO;
        _invalidateFlowLayoutMessagesCache = NO;
    }
    return self;
}

+ (instancetype)context
{
    ZNGMessagesCollectionViewFlowLayoutInvalidationContext *context = [[ZNGMessagesCollectionViewFlowLayoutInvalidationContext alloc] init];
    context.invalidateFlowLayoutDelegateMetrics = YES;
    context.invalidateFlowLayoutAttributes = YES;
    return context;
}

#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: invalidateFlowLayoutDelegateMetrics=%@, invalidateFlowLayoutAttributes=%@, invalidateDataSourceCounts=%@, invalidateFlowLayoutMessagesCache=%@>",
            [self class], @(self.invalidateFlowLayoutDelegateMetrics), @(self.invalidateFlowLayoutAttributes), @(self.invalidateDataSourceCounts), @(self.invalidateFlowLayoutMessagesCache)];
}

@end
