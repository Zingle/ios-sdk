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

/**
 *  If this flag is set, all message sending will call the failure block.
 */
@property (nonatomic, assign) BOOL alwaysFail;

@end
