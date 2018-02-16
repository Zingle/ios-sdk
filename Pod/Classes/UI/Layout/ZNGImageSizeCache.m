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

static const int zngLogLevel = ZNGLogLevelWarning;

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
        NSMutableDictionary * loadedSizes = [[NSKeyedUnarchiver unarchiveObjectWithFile:self->cacheFilePath] mutableCopy];
        
        if ([loadedSizes count] > 0) {
            ZNGLogInfo(@"Loaded %llu cached image sizes from %@", (unsigned long long)[loadedSizes count], self->cacheFilePath);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [loadedSizes addEntriesFromDictionary:self->sizes];   // Merge any sizes that were recorded while our cache was loading from disk.
                self->sizes = loadedSizes;
            });
        } else {
            ZNGLogInfo(@"No cached image sizes were found at %@", self->cacheFilePath);
        }
        
        self->loading = NO;
    });
}

- (void) saveCachedSizes
{
    dispatch_async(fileThread, ^{
        ZNGLogInfo(@"Writing %llu cached sizes to %@", (unsigned long long)[self->sizes count], self->cacheFilePath);
        [NSKeyedArchiver archiveRootObject:self->sizes toFile:self->cacheFilePath];
    });
}

- (CGSize) sizeForImageWithPath:(NSString *)filename
{
    if (loading) {
        // Our cache has not yet loaded.
        ZNGLogInfo(@"Returning 0x0 as cached size because our cache has not yet loaded.");
        return CGSizeZero;
    }
    
    if ([filename isKindOfClass:[NSNull class]]) {
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
