//
//  ZNGImageSizeCache.m
//  Pods
//
//  Created by Jason Neel on 1/6/17.
//
//

#import "ZNGImageSizeCache.h"
#import "ZNGLogging.h"
#import "ZNGMessage.h"

static const int zngLogLevel = ZNGLogLevelDebug;

#define kCacheFileName @"imageSizeCache.dat"

@implementation ZNGImageSizeCache
{
    NSMutableDictionary<NSString *, NSValue *> * sizes;
    BOOL loading;
    
    dispatch_queue_t fileThread;
    NSString * cacheFilePath;;
}

+ (instancetype) sharedCache
{
    static dispatch_once_t onceToken;
    static ZNGImageSizeCache * singleton;
    
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    
    return singleton;
}

- (id) init
{
    self = [super init];
    
    if (self != nil) {
        sizes = [[NSMutableDictionary alloc] init];
        
        fileThread = dispatch_queue_create("com.zingleme.imageSizeCache.file", 0);
        dispatch_set_target_queue(fileThread, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
        
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString * cacheFolder = [paths firstObject];
        cacheFilePath = [cacheFolder stringByAppendingPathComponent:kCacheFileName];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDownloaded:) name:kZNGMessageMediaLoadedNotification object:nil];
        
        loading = YES;
        [self loadCachedSizes];
    }
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) loadCachedSizes
{
    dispatch_async(fileThread, ^{
        NSMutableDictionary * loadedSizes = [[NSKeyedUnarchiver unarchiveObjectWithFile:cacheFilePath] mutableCopy];
        
        if ([loadedSizes count] > 0) {
            ZNGLogInfo(@"Loaded %llu cached image sizes from %@", (unsigned long long)[loadedSizes count], cacheFilePath);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [loadedSizes addEntriesFromDictionary:sizes];   // Merge any sizes that were recorded while our cache was loading from disk.
                sizes = loadedSizes;
            });
        } else {
            ZNGLogInfo(@"No cached image sizes were found at %@", cacheFilePath);
        }
        
        loading = NO;
    });
}

- (void) saveCachedSizes
{
    dispatch_async(fileThread, ^{
        ZNGLogInfo(@"Writing %llu cached sizes to %@", (unsigned long long)[sizes count], cacheFilePath);
        [NSKeyedArchiver archiveRootObject:sizes toFile:cacheFilePath];
    });
}

- (void) imageDownloaded:(NSNotification *)notification
{
    ZNGMessage * message = notification.object;
    
    if (![message isKindOfClass:[ZNGMessage class]]) {
        NSAssert(NO, @"Notification for downloaded image attachment was from a %@ instead of a ZNGMessage.  What?", [message class]);
    }
    
    __block NSUInteger count = 0;
    
    [message.imageAttachmentsByName enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull filename, UIImage * _Nonnull image, BOOL * _Nonnull stop) {
        if ((filename != nil) && (image != nil)) {
            [self setSize:image.size forImageWithPath:filename save:NO];
            count++;
        }
    }];
    
    if (count > 0) {
        [self saveCachedSizes];
    }
}

- (CGSize) sizeForImageWithPath:(NSString *)filename
{
    if (loading) {
        // Our cache has not yet loaded.
        ZNGLogInfo(@"Returning 0x0 as cached size because our cache has not yet loaded.");
        return CGSizeZero;
    }
    
    NSString * name = [filename lastPathComponent];
    CGSize size = [sizes[name] CGSizeValue];
    
    ZNGLogDebug(@"Returning %@ as cached size for %@", NSStringFromCGSize(size), name);
    
    return size;
}

- (void) setSize:(CGSize)size forImageWithPath:(NSString *)filename save:(BOOL)save
{
    NSString * name = [filename lastPathComponent];
    
    ZNGLogDebug(@"Saving size of %@ for %@", NSStringFromCGSize(size), name);
    
    if (name == nil) {
        return;
    }
    
    NSValue * oldValue = sizes[name];
    NSValue * sizeValue = (CGSizeEqualToSize(size, CGSizeZero)) ? nil : [NSValue valueWithCGSize:size];
    sizes[name] = sizeValue;
    
    if ((![oldValue isEqualToValue:sizeValue]) && (save)) {
        [self saveCachedSizes];
    }
}

- (void) setSize:(CGSize)size forImageWithPath:(NSString *)filename
{
    [self setSize:size forImageWithPath:filename save:YES];
}


@end
