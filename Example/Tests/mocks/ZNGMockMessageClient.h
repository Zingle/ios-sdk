//
//  ZNGMockMessageClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 3/7/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import <ZingleSDK/ZNGMessageClient.h>

@interface ZNGMockMessageClient : ZNGMessageClient

@property (nonatomic, strong) NSArray<NSDictionary <NSString *, NSString *> *> * lastSentMessageAttachments;

@end
