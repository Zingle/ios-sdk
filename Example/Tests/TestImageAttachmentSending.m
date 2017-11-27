//
//  TestImageAttachmentSending.m
//  ZingleSDK
//
//  Created by Jason Neel on 3/7/17.
//  Copyright © 2017 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ZingleSDK/ZingleAccountSession.h>
#import <ZingleSDK/ZNGEventViewModel.h>
#import <ZingleSDK/ZNGEvent.h>
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
    ZNGMockMessageClient * sharedMessageClient;
    ZNGConversationServiceToContact * sharedConversation;
}

- (void)setUp
{
    [super setUp];
    sharedConversation = [self freshConversation];
    sharedMessageClient = (ZNGMockMessageClient *)sharedConversation.messageClient;
}

- (ZNGConversationServiceToContact *) freshConversation
{
    ZingleAccountSession * session = [ZingleSDK accountSessionWithToken:@"token" key:@"key"];
    ZNGSocketClient * socketClient = [[ZNGSocketClient alloc] initWithSession:session];
    
    ZNGChannel * channel = [[ZNGChannel alloc] init];
    ZNGChannelType * channelType = [[ZNGChannelType alloc] init];
    channelType.channelTypeId = @"1111-22222222222-333333333333-4444";
    channel.channelType = channelType;
    
    ZNGMockMessageClient * messageClient = [[ZNGMockMessageClient alloc] init];
    
    ZNGService * service = [[ZNGService alloc] init];
    ZNGContact * contact = [[ZNGContact alloc] init];
    contact.contactId = @"1234-ABCDEFABCDEFABCD-EFABCDEFABCD-1234";
    ZNGMockEventClient * eventClient = [[ZNGMockEventClient alloc] init];
    ZNGMockContactClient * contactClient = [[ZNGMockContactClient alloc] init];
    
    return [[ZNGConversationServiceToContact alloc] initFromService:service toContact:contact withCurrentUserId:@"" usingChannel:channel withMessageClient:messageClient eventClient:eventClient contactClient:contactClient socketClient:socketClient];
}

- (void) testSmallPngSentIntact
{
    NSBundle * bundle = [NSBundle bundleForClass:[TestImageAttachmentSending class]];
    UIImage * tinyPng = [UIImage imageNamed:@"tinyPng.png" inBundle:bundle compatibleWithTraitCollection:nil];
    XCTAssertNotNil(tinyPng, @"Loading small PNG from bundle");
    
    NSData * pngData = UIImagePNGRepresentation(tinyPng);
    sharedMessageClient.lastSentMessageAttachments = nil;
    
    XCTestExpectation * messageSent = [self expectationWithDescription:@"Message was sent"];
    
    [sharedConversation sendMessageWithBody:@"" imageData:@[pngData] uuid:nil success:^(ZNGStatus * _Nullable status) {
        [messageSent fulfill];
    } failure:^(ZNGError * _Nullable error) {
        XCTFail(@"Message sent failed: %@", [error localizedDescription]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    NSDictionary<NSString *, NSString *> * attachment = [sharedMessageClient.lastSentMessageAttachments firstObject];
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
    sharedMessageClient.lastSentMessageAttachments = nil;
    
    XCTestExpectation * messageSent = [self expectationWithDescription:@"Message was sent"];
    
    [sharedConversation sendMessageWithBody:@"" imageData:@[jpgData] uuid:nil success:^(ZNGStatus * _Nullable status) {
        [messageSent fulfill];
    } failure:^(ZNGError * _Nullable error) {
        XCTFail(@"Message sent failed: %@", [error localizedDescription]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    NSDictionary<NSString *, NSString *> * attachment = [sharedMessageClient.lastSentMessageAttachments firstObject];
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
    sharedMessageClient.lastSentMessageAttachments = nil;
    
    XCTestExpectation * messageSent = [self expectationWithDescription:@"Message was sent"];
    
    [sharedConversation sendMessageWithBody:@"" imageData:@[pngData] uuid:nil success:^(ZNGStatus * _Nullable status) {
        [messageSent fulfill];
    } failure:^(ZNGError * _Nullable error) {
        XCTFail(@"Message sent failed: %@", [error localizedDescription]);
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    NSDictionary<NSString *, NSString *> * attachment = [sharedMessageClient.lastSentMessageAttachments firstObject];
    NSString * base64DataString = attachment[@"base64"];
    NSData * imageData = [[NSData alloc] initWithBase64EncodedString:base64DataString options:NSUTF8StringEncoding];
    UIImage * image = [[UIImage alloc] initWithData:imageData];
    NSString * contentType = attachment[@"content_type"];
    
    XCTAssertEqualObjects(contentType, @"image/jpeg", @"Large PNG attachment is converted to JPG and resized");
    XCTAssert((image.size.width <= 800.0) && (image.size.height <= 800.0), @"Large JPG is resized");
}

- (void) testSendingAttachmentImmediatelyAvailable
{
    ZNGConversationServiceToContact * conversation = [self freshConversation];

    NSBundle * bundle = [NSBundle bundleForClass:[TestImageAttachmentSending class]];
    UIImage * tinyPng = [UIImage imageNamed:@"tinyPng.png" inBundle:bundle compatibleWithTraitCollection:nil];
    XCTAssertNotNil(tinyPng, @"Loading small PNG from bundle");

    NSData * pngData = UIImagePNGRepresentation(tinyPng);
    
    [self keyValueObservingExpectationForObject:conversation keyPath:NSStringFromSelector(@selector(eventViewModels)) handler:^BOOL(id  _Nonnull observedObject, NSDictionary * _Nonnull change) {
        // Find a pending event with an available attachment
        for (ZNGEventViewModel * viewModel in conversation.eventViewModels) {
            if (viewModel.event.sending) {
                // We found our sending event.  Is the attachment available?
                if (viewModel.attachmentStatus == ZNGEventViewModelAttachmentStatusAvailable) {
                    return YES;
                } else {
                    // We found our sending event, but the attachment status is not available.  This is a bug.
                    XCTFail(@"Attachment is sending, but the attachment status is not available.");
                }
            }
        }
        
        return NO;
    }];
    
    [conversation sendMessageWithBody:@"" imageData:@[pngData] uuid:nil success:nil failure:nil];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
