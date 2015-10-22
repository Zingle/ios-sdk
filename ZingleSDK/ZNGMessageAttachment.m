//
//  ZNGMessageAttachment.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZNGMessageAttachment.h"
#import "ZingleSDK.h"

NSString * const ZINGLE_CONTENT_TYPE_IMAGE_PNG = @"image/png";

@interface ZNGMessageAttachment()

@property (nonatomic, retain) NSString *contentType;
@property (nonatomic, retain) NSData *base64Data;

@end

@implementation ZNGMessageAttachment

- (id)init
{
    if( self = [super init] )
    {
        self.contentType = @"";
    }
    return self;
}

- (void)setImage:(UIImage *)image
{
    [self setData:UIImagePNGRepresentation(image) withContentType:ZINGLE_CONTENT_TYPE_IMAGE_PNG];
}

- (void)setData:(NSData *)data withContentType:(NSString *)contentType
{
    if( [data length] > [ZingleSDK sharedSDK].maxAttachmentSizeBytes )
    {
        [NSException raise:@"ZINGLE_MAX_ATTACHMENT_SIZE_REACHED" format:@"The attachment has exceeded the size limit."];
    }
    
    self.base64Data   = [data base64EncodedDataWithOptions:0];
    self.contentType  = contentType;
}

- (NSMutableDictionary *)asDictionary
{
    if( self.base64Data == nil )
    {
        [NSException raise:@"ZINGLE_NO_DATA_IN_ATTACHMENT" format:@"No data in message attachment."];
    }
    
    if( self.contentType == nil || [self.contentType isEqualToString:@""] )
    {
        [NSException raise:@"ZINGLE_MISSING_CONTENT_TYPE" format:@"No content type in message attachment."];
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:self.contentType forKey:@"content_type"];
    [dictionary setObject:[[NSString alloc] initWithData:self.base64Data encoding:NSUTF8StringEncoding] forKey:@"base64"];
    
    return dictionary;
}


@end
