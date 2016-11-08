//
//  ZNGMockServiceClient.h
//  ZingleSDK
//
//  Created by Jason Neel on 10/27/16.
//  Copyright © 2016 Zingle. All rights reserved.
//

#import <ZingleSDK/ZingleSDK.h>
#import "ZingleSDK/ZNGServiceClient.h"
#import <XCTest/XCTest.h>

@interface ZNGMockServiceClient : ZNGServiceClient

@property (nonatomic, strong) NSArray<ZNGService *> * services;

/**
 *  This expectation will be fulfilled any time a single service is requested.
 *  Once it is first fulfilled, this property is set to nil automatically.
 */
@property (nonatomic, strong) XCTestExpectation * serviceRequestedExpectation;

/**
 *  If this flag is set, an exception will be thrown if any service is refreshed.
 */
@property (nonatomic, assign) BOOL throwExceptionOnAnyServiceRequest;

@end
