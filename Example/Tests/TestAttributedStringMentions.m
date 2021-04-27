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

@interface TestAttributedStringMentions : XCTestCase

@end

@implementation TestAttributedStringMentions

- (void)testUserMention {
    // Create attributed note
    NSString * userName = @"Somebody";
    NSString * userID = @"123-345-567";
    NSString * noteMessage = @" mentioned.";
    
    // API expected '{u@xxxxxx--uuid}' for user mentioned
    NSString * expectedString = [NSString stringWithFormat:@"{u@%@}%@", userID, noteMessage];
    
    NSDictionary * userAttributes = @{ZNGEventUserMentionAttribute: userID, ZNGEventMentionAttribute: userID};
    NSAttributedString * userMention = [[NSAttributedString alloc] initWithString:userName attributes:userAttributes];
    
    NSMutableAttributedString * testNote = [[NSMutableAttributedString alloc] initWithAttributedString:userMention];
    // Appending note message
    [testNote appendAttributedString: [[NSAttributedString alloc] initWithString:noteMessage]];

    XCTAssertEqualObjects([testNote formattedMentionForAPI], expectedString);
}

- (void)testTeamMention {
    // Create attributed note
    NSString * teamName = @"Some_team";
    NSString * teamID = @"123-345-567-890";
    NSString * noteMessage = @"Mentioned at the end ";
    
    // API expected '{t@xxxxxx--uuid}' for team mentioned
    // In this case is 'Mentioned at the end {t@123-345-567-890}'
    NSString * expectedString = [NSString stringWithFormat:@"%@{t@%@}", noteMessage, teamID];
    
    NSDictionary * teamAttributes = @{ZNGEventTeamMentionAttribute: teamID, ZNGEventMentionAttribute: teamID};
    NSAttributedString * teamMention = [[NSAttributedString alloc] initWithString:teamName attributes:teamAttributes];
    
    NSMutableAttributedString * testNote = [[NSMutableAttributedString alloc] initWithString:noteMessage];
    // Append team mention
    [testNote appendAttributedString: teamMention];

    XCTAssertEqualObjects([testNote formattedMentionForAPI], expectedString);
}

- (void)testMultiplyUserAndTeamMention {
    // Create attributed note
    NSString * teamName = @"Some_team";
    NSString * teamID = @"123-345-567-890";
    NSString * userName = @"Somebody";
    NSString * userID = @"123-345-567";
    NSString * noteMessage = @"Mentioned at the end ";
    
    // In this case is 'Mentioned at the end {t@123-345-567-890}{u@123-345-567}'
    NSString * expectedString = [NSString stringWithFormat:@"%@{t@%@}{u@%@}", noteMessage, teamID, userID];
    
    NSDictionary * teamAttributes = @{ZNGEventTeamMentionAttribute: teamID, ZNGEventMentionAttribute: teamID};
    NSAttributedString * teamMention = [[NSAttributedString alloc] initWithString:teamName attributes:teamAttributes];

    NSDictionary * userAttributes = @{ZNGEventUserMentionAttribute: userID, ZNGEventMentionAttribute: userID};
    NSAttributedString * userMention = [[NSAttributedString alloc] initWithString:userName attributes:userAttributes];

    NSMutableAttributedString * testNote = [[NSMutableAttributedString alloc] initWithString:noteMessage];
    // Append mentions
    [testNote appendAttributedString:teamMention];
    [testNote appendAttributedString:userMention];

    XCTAssertEqualObjects([testNote formattedMentionForAPI], expectedString);
}


@end
