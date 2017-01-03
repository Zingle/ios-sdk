//
//  ZNGImageAttachment.m
//  Pods
//
//  Created by Jason Neel on 10/3/16.
//
//

#import "ZNGImageAttachment.h"

@implementation ZNGImageAttachment

- (id) initWithData:(NSData *)contentData ofType:(NSString *)uti
{
    self = [super initWithData:contentData ofType:uti];
    
    if (self != nil) {
        _maxDisplayHeight = 120.0;
    }
    
    return self;
}

- (CGRect) attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex
{
    if ((self.image.size.height == 0) || (self.image.size.width == 0)) {
        return [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
    }
    
    CGFloat downscaleHeight = self.maxDisplayHeight / self.image.size.height;
    CGFloat downscaleWidth = lineFrag.size.width / self.image.size.width;
    
    if ((downscaleHeight >= 1.0) && (downscaleWidth >= 1.0)) {
        // Our image will fit as is
        return [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
    }
    
    CGFloat downscale = MIN(downscaleWidth, downscaleHeight);
    return CGRectIntegral(CGRectMake(0.0, 0.0, self.image.size.width * downscale, self.image.size.height * downscale));
}

@end
