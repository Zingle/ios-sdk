//
//  ZNGNetworkPhotoMediaItem.m
//  Pods
//
//  Created by Ryan Farley on 3/9/16.
//
//

#import "ZNGNetworkPhotoMediaItem.h"
#import "UIImageView+AFNetworking.h"
#import "ZNGMediaViewBubbleImageMasker.h"

@interface ZNGNetworkPhotoMediaItem ()

@property (strong, nonatomic) UIImageView *cachedImageView;

@end

@implementation ZNGNetworkPhotoMediaItem

#pragma mark - Initialization

- (instancetype)initWithURL:(NSString *)url
{
    self = [super init];
    if (self) {
        _url = [url copy];
    }
    return self;
}

-(void)dealloc
{
    _url = nil;
}

#pragma mark - Setters

-(void)setUrl:(NSString *)url
{
    _url = [url copy];
}

#pragma mark - ZNGMessageMediaData protocol

- (UIView *)mediaView
{
    if (self.url == nil) {
        return nil;
    }
    
    if (self.cachedImageView == nil) {
        CGSize size = [self mediaViewDisplaySize];
        self.cachedImageView = [[UIImageView alloc] init];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
        [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
        __weak __typeof__(self) weakSelf = self;
        [self.cachedImageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
            weakSelf.image = image;
            weakSelf.cachedImageView.image = image;
        } failure:nil];
        self.cachedImageView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
        self.cachedImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.cachedImageView.clipsToBounds = YES;
        [ZNGMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:self.cachedImageView isOutgoing:self.appliesMediaViewMaskAsOutgoing];
    }
    
    return self.cachedImageView;
}

@end
