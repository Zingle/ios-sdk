//
//  ZNGConstants.m
//  Pods
//
//  Created by Ryan Farley on 2/5/16.
//
//

#import "ZNGConstants.h"

@implementation ZNGConstants

NSString *const kZingleErrorDomain              = @"ZINGLE ERROR";
NSString *const kJSONParseErrorDomain           = @"JSON PARSE ERROR";

NSString *const kLiveBaseURL                    = @"https://api.zingle.me/v1/";
NSString *const kQABaseURL                      = @"https://qa-api.zingle.me/v1/";

NSString *const kAccountsResourcePath           = @"accounts";
NSString *const kAccountPlansResourcePath       = @"accounts/%@/plans";
NSString *const kServiceResourcePath            = @"services";
NSString *const kTimeZoneResourcePath           = @"time-zones";
NSString *const kAvailablePhoneNumbersPath      = @"available-phone-numbers";
NSString *const kServiceChannelsResourcePath    = @"services/%@/channels";
NSString *const kContactsResourcePath           = @"services/%@/contacts";
NSString *const kMessagesResourcePath           = @"services/%@/messages";

@end
