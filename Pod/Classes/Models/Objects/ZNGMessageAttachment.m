//
//  ZNGMessageAttachment.m
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZNGMessageAttachment.h"
#import "ZingleSDK.h"
#import "ZingleError.h"

NSString * const ZINGLE_CONTENT_TYPE_IMAGE_PNG = @"image/png";

@interface ZNGMessageAttachment()

@property (nonatomic, retain) NSString *contentType;
@property (nonatomic, retain) NSData *imageData;

@end

@implementation ZNGMessageAttachment

- (id)init
{
    if( self = [super init] )
    {
        self.contentType = @"";
        self.url = @"";
    }
    return self;
}

- (void)setImage:(UIImage *)image
{
    [self setData:UIImagePNGRepresentation(image) withContentType:ZINGLE_CONTENT_TYPE_IMAGE_PNG];
}


- (void)setData:(NSData *)data withContentType:(NSString *)contentType
{
//    if( [data length] > [ZingleSDK sharedSDK].maxAttachmentSizeBytes )
//    {
//        [NSException raise:@"ZINGLE_MAX_ATTACHMENT_SIZE_REACHED" format:@"The attachment has exceeded the size limit."];
//    }
    
    self.imageData = data;
    self.contentType  = contentType;
}

- (UIImage *)getImageWithError:(NSError **)error
{
    if( self.imageData != nil ) {
        UIImage *image = [UIImage imageWithData:self.imageData];
        return image;
    } else if( self.url != nil && ![self.url isEqualToString:@""] ) {
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.url]]];
        return image;
    } else {
        *error = [[ZingleError alloc] initWithDomain:ZINGLE_ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionaryWithObject:@"No Image Attachment" forKey:NSLocalizedDescriptionKey]];
    }
    
    return nil;
}

- (void)getImageWithCompletionBlock:(void (^) (UIImage *image))completionBlock
                         errorBlock:(void (^) (NSError *requestError))errorBlock
{
    if( self.imageData != nil ) {
        UIImage *image = [UIImage imageWithData:self.imageData];
        completionBlock(image);
        return;
    } else if( self.url != nil && ![self.url isEqualToString:@""] ) {
        NSURL *url = [NSURL URLWithString:self.url];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:url];
        [request setHTTPMethod:@"GET"];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[[NSOperationQueue alloc] init]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       if( error != nil ) {
                                           errorBlock(error);
                                       } else {
                                           UIImage *image = [UIImage imageWithData:data];
                                           completionBlock(image);
                                       }
                                   });
                               }];
    } else {
        ZingleError *error = [[ZingleError alloc] initWithDomain:ZINGLE_ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionaryWithObject:@"No Image Attachment" forKey:NSLocalizedDescriptionKey]];
        errorBlock(error);
    }
}

- (NSMutableDictionary *)asDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if( self.imageData != nil ) {
        [dictionary setObject:self.contentType forKey:@"content_type"];
    
        NSData *base64Data = [self.imageData base64EncodedDataWithOptions:0];
        
        [dictionary setObject:[[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding] forKey:@"base64"];
        
    }
    
    return dictionary;
}


- (NSString *)description
{
    NSString *description = @"<ZNGMessageAttachment> {\r";
    description = [description stringByAppendingFormat:@"    contentType: %@\r", self.contentType];
    description = [description stringByAppendingFormat:@"    url: %@\r", self.url];
    description = [description stringByAppendingString:@"}"];
    
    return description;
}



@end
