//
//  TestAttributedStringMentions.m
//  Tests
//
//  Created by Serhii Derhach on 27.04.2021.
//  Copyright © 2021 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/NSAttributedString+Mentions.h"
#import "ZingleSDK/ZNGEventViewModel.h"

static NSString * const userName = @"Somebody";
static NSString * const userID = @"123-345-567";
static NSString * const teamName = @"Some_team";
static NSString * const teamID = @"123-345-567-890";
static NSString * const noteMessage = @" mentioned ";


@interface TestAttributedStringMentions : XCTestCase

@end

@implementation TestAttributedStringMentions

- (void)testUserMention
{
    NSAttributedString * testNote = [self noteUserMentioned];

    // API expected '{u@xxxxxx--uuid}' for user mentioned
    NSString * expectedString = [NSString stringWithFormat:@"{u@%@}%@", userID, noteMessage];
    XCTAssertEqualObjects([testNote formattedMentionForAPI], expectedString);
}

- (void)testTeamMention
{
    NSAttributedString * testNote = [self noteTeamMentioned];

    // API expected '{t@xxxxxx--uuid}' for team mentioned
    // In this case is 'Mentioned at the end {t@123-345-567-890}'
    NSString * expectedString = [NSString stringWithFormat:@"%@{t@%@}", noteMessage, teamID];
    XCTAssertEqualObjects([testNote formattedMentionForAPI], expectedString);
}

- (void)testMultiplyUserAndTeamMention
{
    NSAttributedString * testNote = [self noteTeamAndUserMentioned];

    // In this case is 'Mentioned at the end {t@123-345-567-890}{u@123-345-567}'
    NSString * expectedString = [NSString stringWithFormat:@"%@{t@%@}{u@%@}", noteMessage, teamID, userID];
    XCTAssertEqualObjects([testNote formattedMentionForAPI], expectedString);
}

- (void)testTeamMentioned
{
    NSAttributedString * testNote = [self noteTeamMentioned];

    // Expected result: @"team"
    NSString * expectedString = @"team";
    XCTAssertEqualObjects([testNote mentionedContactType], expectedString);
}

- (void)testUserMentioned
{
    NSAttributedString * testNote = [self noteUserMentioned];

    // Expected result: @"user"
    NSString * expectedString = @"user";
    XCTAssertEqualObjects([testNote mentionedContactType], expectedString);
}

- (void)testNobodyMentioned
{
    NSAttributedString * testNote = [self noteNoMentions];

    // Expected result: empty string
    NSString * expectedString = @"";
    XCTAssertEqualObjects([testNote mentionedContactType], expectedString);
}



#pragma mark - utility stuff

- (NSAttributedString *)noteNoMentions
{
    NSString * noteMessage = @"In this note, nobody is mentioned.";
    NSDictionary * someAttributes = @{NSForegroundColorAttributeName:[UIColor redColor]};
    NSAttributedString * note = [[NSAttributedString alloc] initWithString:noteMessage attributes:someAttributes];
    return note;
}

- (NSAttributedString *)noteUserMentioned
{
    NSDictionary * userAttributes = @{ZNGEventUserMentionAttribute: userID, ZNGEventMentionAttribute: userID};
    NSAttributedString * userMention = [[NSAttributedString alloc] initWithString:userName attributes:userAttributes];
    
    NSMutableAttributedString * note = [[NSMutableAttributedString alloc] initWithAttributedString:userMention];
    // Appending note message
    [note appendAttributedString: [[NSAttributedString alloc] initWithString:noteMessage]];
    return note;
}

- (NSAttributedString *)noteTeamMentioned
{
    NSDictionary * teamAttributes = @{ZNGEventTeamMentionAttribute: teamID, ZNGEventMentionAttribute: teamID};
    NSAttributedString * teamMention = [[NSAttributedString alloc] initWithString:teamName attributes:teamAttributes];
    
    NSMutableAttributedString * note = [[NSMutableAttributedString alloc] initWithString:noteMessage];
    // Append team mention
    [note appendAttributedString: teamMention];

    return note;
}

- (NSAttributedString *)noteTeamAndUserMentioned
{
    NSDictionary * teamAttributes = @{ZNGEventTeamMentionAttribute: teamID, ZNGEventMentionAttribute: teamID};
    NSAttributedString * teamMention = [[NSAttributedString alloc] initWithString:teamName attributes:teamAttributes];

    NSDictionary * userAttributes = @{ZNGEventUserMentionAttribute: userID, ZNGEventMentionAttribute: userID};
    NSAttributedString * userMention = [[NSAttributedString alloc] initWithString:userName attributes:userAttributes];

    NSMutableAttributedString * note = [[NSMutableAttributedString alloc] initWithString:noteMessage];
    // Append mentions
    [note appendAttributedString:teamMention];
    [note appendAttributedString:userMention];

    return note;
}

@end
