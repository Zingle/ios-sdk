//
//  ZNGConversation.h
//  ZingleSDK
//
//  Copyright © 2015 Zingle.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ZNGService;
@class ZNGContact;
@class ZNGMessageCorrespondent;
@class ZNGChannelType;
@class ZNGMessage;

@interface ZNGConversation : NSObject

@property (nonatomic, retain) ZNGService *service;
@property (nonatomic, retain) ZNGMessageCorrespondent *from, *to;
@property (nonatomic, retain) ZNGChannelType *channelType;

- (id)initWithService:(ZNGService *)service usingChannelType:(ZNGChannelType *)channelType;
- (NSArray *)messages;
- (BOOL)isFromService;
- (void)toCorrespondant:(ZNGMessageCorrespondent *)to;
- (void)fromCorrespondant:(ZNGMessageCorrespondent *)from;
- (NSString *)messageDirectionFor:(ZNGMessage *)message;

- (ZNGMessage *)sendMessageWithBody:(NSString *)body error:(NSError **)error;
- (ZNGMessage *)sendMessageWithImage:(UIImage *)image error:(NSError **)error;

- (void)sendMessageWithBody:(NSString *)body
            completionBlock:(void (^) (void))completionBlock
                 errorBlock:(void (^) (NSError *error))errorBlock;

- (void)sendMessageWithImage:(UIImage *)image
             completionBlock:(void (^) (void))completionBlock
                  errorBlock:(void (^) (NSError *error))errorBlock;

@end
