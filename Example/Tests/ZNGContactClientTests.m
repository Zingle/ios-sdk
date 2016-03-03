//
//  ZNGContactClientTests.m
//  ZingleSDK
//
//  Created by Ryan Farley on 2/8/16.
//  Copyright © 2016 Ryan Farley. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZNGBaseTests.h"
#import "ZNGContactClient.h"

@interface ZNGContactClientTests : ZNGBaseTests

@property (nonatomic, strong) NSString *savedContactId;

@end

@implementation ZNGContactClientTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testContactList
{
    [ZNGContactClient contactListWithServiceId:[self serviceId] parameters:nil success:^(NSArray *contacts, ZNGStatus *status) {
        
        XCTAssert(contacts != nil, @"Contacts are nil!");
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactList"];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactList"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testContactList"];
}

- (void)testUpdateContactCustomFieldValue
{
    
    [ZNGContactClient contactListWithServiceId:[self serviceId] parameters:nil success:^(NSArray *contacts, ZNGStatus *status) {
        
        ZNGContact *contact = [contacts firstObject];
        ZNGContactFieldValue *fieldValue = [contact.customFieldValues firstObject];
        fieldValue.value = @"Matthews";
        
        [ZNGContactClient updateContactFieldValue:fieldValue withContactFieldId:fieldValue.customField.contactFieldId withContactId:contact.contactId withServiceId:[self serviceId] success:^(ZNGContact *contact, ZNGStatus *status) {
            
            XCTAssert(contact != nil, @"Contact is nil!");
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateContactCustomFieldValue"];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", error);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateContactCustomFieldValue"];
        }];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testUpdateContactCustomFieldValue"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testUpdateContactCustomFieldValue"];
}

- (void)testTriggerAutomation
{
    
    [ZNGContactClient contactListWithServiceId:[self serviceId] parameters:nil success:^(NSArray *contacts, ZNGStatus *status) {
        
        ZNGContact *contact = [contacts firstObject];
        
        [ZNGContactClient triggerAutomationWithId:[self automationId] withContactId:contact.contactId withServiceId:[self serviceId] success:^(ZNGContact *contact, ZNGStatus *status) {
            
            XCTAssert(contact != nil, @"Contact is nil!");
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testTriggerAutomation"];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", error);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testTriggerAutomation"];
        }];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testTriggerAutomation"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testTriggerAutomation"];
}

- (void)testAddLabelToContact
{
    
    [ZNGContactClient contactListWithServiceId:[self serviceId] parameters:nil success:^(NSArray *contacts, ZNGStatus *status) {
        
        ZNGContact *contact = [contacts firstObject];
        
        [ZNGContactClient addLabelWithId:[self labelId] withContactId:contact.contactId withServiceId:[self serviceId] success:^(ZNGContact *contact, ZNGStatus *status) {
            
            XCTAssert(contact != nil, @"Contact is nil!");
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testAddLabelToContact"];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", error);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testAddLabelToContact"];
        }];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testAddLabelToContact"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testAddLabelToContact"];
}

- (void)testRemoveLabelFromContact
{
    
    [ZNGContactClient contactListWithServiceId:[self serviceId] parameters:nil success:^(NSArray *contacts, ZNGStatus *status) {
        
        ZNGContact *contact = [contacts firstObject];
        
        [ZNGContactClient removeLabelWithId:[self labelId] withContactId:contact.contactId withServiceId:[self serviceId] success:^(ZNGStatus *status) {
            
            XCTAssert(contact != nil, @"Contact is nil!");
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testRemoveLabelFromContact"];
            
        } failure:^(ZNGError *error) {
            
            XCTFail(@"fail: \"%@\"", error);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testRemoveLabelFromContact"];
        }];
        
    } failure:^(ZNGError *error) {
        
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testRemoveLabelFromContact"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testRemoveLabelFromContact"];
}

- (void)testContactClient
{
    
    [ZNGContactClient saveContact:[self contact] withServiceId:[self serviceId] success:^(ZNGContact *contact, ZNGStatus *status) {
        
        self.savedContactId = contact.contactId;
        XCTAssert(contact != nil, @"Contact is nil!");
        
        [ZNGContactClient contactWithId:self.savedContactId withServiceId:[self serviceId] success:^(ZNGContact *contact, ZNGStatus *status) {
            
            XCTAssert(contact != nil, @"Contact is nil!");
            
            [ZNGContactClient updateContactWithId:self.savedContactId withServiceId:[self serviceId] withParameters:nil success:^(ZNGContact *contact, ZNGStatus *status) {
                
                XCTAssert(contact != nil, @"Contact is nil!");
                
                [ZNGContactClient deleteContactWithId:self.savedContactId withServiceId:[self serviceId] success:^(ZNGStatus *status) {
                    
                    [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactClient"];
                } failure:^(ZNGError *error) {
                    
                    XCTFail(@"fail: \"%@\"", error);
                    [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactClient"];
                }];
                
            } failure:^(ZNGError *error) {
                XCTFail(@"fail: \"%@\"", error);
                [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactClient"];
            }];
            
        } failure:^(ZNGError *error) {
            XCTFail(@"fail: \"%@\"", error);
            [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactClient"];
        }];
        
    } failure:^(ZNGError *error) {
        XCTFail(@"fail: \"%@\"", error);
        [[ZNGAsyncSemaphor sharedInstance] lift:@"testContactClient"];
    }];
    
    [[ZNGAsyncSemaphor sharedInstance] waitForKey:@"testContactClient"];
}

@end
