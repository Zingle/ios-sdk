//
//  TestAttributedStringGrouping.m
//  Tests
//
//  Created by Jason Neel on 2/8/18.
//  Copyright © 2018 Zingle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ZingleSDK/NSAttributedString+GroupingSubstrings.h"

@interface TestAttributedStringGrouping : XCTestCase

@end

@implementation TestAttributedStringGrouping

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testSingleLineSingleGroup
{
    NSString * singleLine = @"This is a line of text.  Woo.";
    NSAttributedString * singleLineAttributed = [[NSAttributedString alloc] initWithString:singleLine];
    
    NSArray * groups = [singleLineAttributed substringsByLineAndAttributes];
    
    XCTAssertEqual([groups count], 1);
    XCTAssertEqualObjects(groups[0], singleLine);
}

- (void) testTwoLinesTwoGroups
{
    NSString * firstLine = @"This is one line.";
    NSString * secondLine = @"This is an entirely different line.";
    NSString * bothLines = [NSString stringWithFormat:@"%@\n%@", firstLine, secondLine];
    NSAttributedString * attributed = [[NSAttributedString alloc] initWithString:bothLines];
    
    NSArray * groups = [attributed substringsByLineAndAttributes];
    
    XCTAssertEqual([groups count], 2);
    XCTAssertEqualObjects(groups[0], firstLine);
    XCTAssertEqualObjects(groups[1], secondLine);
}

- (void) testEmptyLinesNotIncluded
{
    NSString * firstLine = @"This is one line.";
    NSString * lastLine = @"This is an entirely different line.";
    NSString * manyLines = [NSString stringWithFormat:@"%@\n\n\n\n\n\n%@", firstLine, lastLine];
    NSAttributedString * attributed = [[NSAttributedString alloc] initWithString:manyLines];

    NSArray * groups = [attributed substringsByLineAndAttributes];
    
    XCTAssertEqual([groups count], 2);
    XCTAssertEqualObjects(groups[0], firstLine);
    XCTAssertEqualObjects(groups[1], lastLine);
}

- (void) testPartiallyAttributedMakesTwoGroups
{
    NSString * firstString = @"This is an ";
    NSString * secondString = @"attributed string!";
    NSAttributedString * attributedSecondString = [[NSAttributedString alloc] initWithString:secondString attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
    
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] initWithString:firstString];
    [attributedString appendAttributedString:attributedSecondString];
    
    NSArray * groups = [attributedString substringsByLineAndAttributes];
    
    XCTAssertEqual([groups count], 2);
    XCTAssertEqualObjects(groups[0], firstString);
    XCTAssertEqualObjects(groups[1], secondString);
}

@end
