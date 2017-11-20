//
//  TestImageAttachmentSending.m
//  ZingleSDK
//
//  Created by Jason Neel on 3/7/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ZingleSDK/ZingleAccountSession.h>
#import <ZingleSDK/ZNGConversationServiceToContact.h>
#import <ZingleSDK/ZNGSocketClient.h>
#import "ZNGMockMessageClient.h"
#import "ZNGMockContactClient.h"
#import "ZNGMockServiceClient.h"
#import "ZNGMockEventClient.h"

@interface TestImageAttachmentSending : XCTestCase

@end

@implementation TestImageAttachmentSending
{
    ZNGMockMessageClient * messageClient;
    ZNGConversationServiceToContact * conversation;
}

- (void)setUp
{
    [super setUp];
    
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    ZNGSocketClient * socketClient = [[ZNGSocketClient alloc] initWithSession:session];
    
    ZNGChannel * channel = [[ZNGChannel alloc] init];
    ZNGChannelType * channelType = [[ZNGChannelType alloc] init];
    channelType.channelTypeId = @"1111-22222222222-333333333333-4444";
    channel.channelType = channelType;
    
    messageClient = [[ZNGMockMessageClient alloc] init];
    
    ZNGService * service = [[ZNGService alloc] init];
    ZNGContact * contact = [[ZNGContact alloc] init];
    contact.contactId = @"1234-ABCDEFABCDEFABCD-EFABCDEFABCD-1234";
    ZNGMockEventClient * eventClient = [[ZNGMockEventClient alloc] init];
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    
    conversation = [[ZNGConversationServiceToContact alloc] initFromService:service toContact:contact withCurrentUserId:@"" usingChannel:channel withMessageClient:messageClient eventClient:eventClient contactClient:contactClient socketClient:socketClient];
}

- (void) testSmallPngSentIntact
{
    NSBundle * bundle = [NSBundle bundleForClass:[TestImageAttachmentSending class]];
    UIImage * tinyPng = [UIImage imageNamed:@"tinyPng.png" inBundle:bundle compatibleWithTraitCollection:nil];
    XCTAssertNotNil(tinyPng, @"Loading small PNG from bundle");
    
    NSData * pngData = UIImagePNGRepresentation(tinyPng);
    messageClient.lastSentMessageAttachments = nil;
    
    XCTestExpectation * messageSent = [self expectationWithDescription:@"Message was sent"];
    
    [conversation sendMessageWithBody:@"" imageData:@[pngData] uuid:nil success:^(ZNGStatus * _Nullable status) {
        [messageSent fulfill];
    } failure:^(ZNGError * _Nullable error) {
        XCTFail(@"Message sent failed: %@", [error localizedDescription]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    NSDictionary<NSString *, NSString *> * attachment = [messageClient.lastSentMessageAttachments firstObject];
    NSString * base64DataString = attachment[@"base64"];
    NSData * imageData = [[NSData alloc] initWithBase64EncodedString:base64DataString options:NSUTF8StringEncoding];
    UIImage * image = [[UIImage alloc] initWithData:imageData];
    NSString * contentType = attachment[@"content_type"];
    
    XCTAssertEqualObjects(contentType, @"image/png", @"PNG attachment sent as a PNG");
    XCTAssert(CGSizeEqualToSize(tinyPng.size, image.size), @"Image size for a small PNG was preserved.");
}

- (void) testSmallJpgSentIntact
{
    NSBundle * bundle = [NSBundle bundleForClass:[TestImageAttachmentSending class]];
    UIImage * tinyJpg = [UIImage imageNamed:@"tinyJpg.jpg" inBundle:bundle compatibleWithTraitCollection:nil];
    XCTAssertNotNil(tinyJpg, @"Loading small JPG from bundle");
    
    NSData * jpgData = UIImageJPEGRepresentation(tinyJpg, 0.5);
    messageClient.lastSentMessageAttachments = nil;
    
    XCTestExpectation * messageSent = [self expectationWithDescription:@"Message was sent"];
    
    [conversation sendMessageWithBody:@"" imageData:@[jpgData] uuid:nil success:^(ZNGStatus * _Nullable status) {
        [messageSent fulfill];
    } failure:^(ZNGError * _Nullable error) {
        XCTFail(@"Message sent failed: %@", [error localizedDescription]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    NSDictionary<NSString *, NSString *> * attachment = [messageClient.lastSentMessageAttachments firstObject];
    NSString * base64DataString = attachment[@"base64"];
    NSData * imageData = [[NSData alloc] initWithBase64EncodedString:base64DataString options:NSUTF8StringEncoding];
    UIImage * image = [[UIImage alloc] initWithData:imageData];
    NSString * contentType = attachment[@"content_type"];
    
    XCTAssertEqualObjects(contentType, @"image/jpeg", @"JPEG attachment sent as a JPEG");
    XCTAssert(CGSizeEqualToSize(tinyJpg.size, image.size), @"Image size for a small JPEG was preserved.");
}

- (void) testLargePngResized
{
    NSBundle * bundle = [NSBundle bundleForClass:[TestImageAttachmentSending class]];
    UIImage * largePng = [UIImage imageNamed:@"1280.png" inBundle:bundle compatibleWithTraitCollection:nil];
    XCTAssertNotNil(largePng, @"Loading large PNG from bundle");
    
    NSData * pngData = UIImagePNGRepresentation(largePng);
    messageClient.lastSentMessageAttachments = nil;
    
    XCTestExpectation * messageSent = [self expectationWithDescription:@"Message was sent"];
    
    [conversation sendMessageWithBody:@"" imageData:@[pngData] uuid:nil success:^(ZNGStatus * _Nullable status) {
        [messageSent fulfill];
    } failure:^(ZNGError * _Nullable error) {
        XCTFail(@"Message sent failed: %@", [error localizedDescription]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    NSDictionary<NSString *, NSString *> * attachment = [messageClient.lastSentMessageAttachments firstObject];
    NSString * base64DataString = attachment[@"base64"];
    NSData * imageData = [[NSData alloc] initWithBase64EncodedString:base64DataString options:NSUTF8StringEncoding];
    UIImage * image = [[UIImage alloc] initWithData:imageData];
    NSString * contentType = attachment[@"content_type"];
    
    XCTAssertEqualObjects(contentType, @"image/jpeg", @"Large PNG attachment is converted to JPG and resized");
    XCTAssert((image.size.width <= 800.0) && (image.size.height <= 800.0), @"Large JPG is resized");
}

@end
