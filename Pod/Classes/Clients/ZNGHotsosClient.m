//
//  ZNGHotsosClient.m
//  Pods
//
//  Created by Jason Neel on 12/7/16.
//
//

#import "ZNGHotsosClient.h"
#import <AFNetworking/AFNetworking.h>
#import "ZNGLogging.h"
#import "ZNGService.h"
#import "ZNGSettingsField.h"
#import "ZNGSetting.h"

#define kHotsosURLCode          @"hotsos_url"
#define kHotsosUsernameCode     @"hotsos_username"
#define kHotsosPasswordCode     @"hotsos_password"

static const int zngLogLevel = ZNGLogLevelWarning;

@implementation ZNGHotsosClient

- (id) initWithService:(ZNGService *)service
{
    self = [super init];
    
    if (self != nil) {
        BOOL allHotsosFieldsPresent = (([[service hotsosHostName] length]) && ([[service hotsosUserName] length]) && ([[service hotsosPassword] length]));
        
        if (!allHotsosFieldsPresent) {
            ZNGLogError(@"Unable to find HotSOS URL, username, and/or password in settings: %@", service.settings);
            return nil;
        }
        
        _service = service;
    }
    
    return self;
}

- (NSString *) hotsosIssuePathForTerm:(NSString *)term
{
    NSString * fuzzyTerm = [[NSString stringWithFormat:@"%%%@%%", term] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSString stringWithFormat:@"https://%@/api/service.svc/rest/GetIssueCollection?nameLike=%@", [self.service hotsosHostName], fuzzyTerm];
}

- (void) getIssuesLike:(NSString *)term completion:(void (^)(NSArray<NSString *> * _Nullable matchingIssueNames, NSError * _Nullable error))completion;
{
    AFHTTPRequestOperationManager * requestManager = [AFHTTPRequestOperationManager manager];
    AFHTTPRequestSerializer * requestSerializer = [AFHTTPRequestSerializer serializer];
    AFXMLParserResponseSerializer * responseSerializer = [AFXMLParserResponseSerializer serializer];
    
    [requestSerializer setAuthorizationHeaderFieldWithUsername:[self.service hotsosUserName] password:[self.service hotsosPassword]];
    [requestSerializer setValue:@"application/xml" forHTTPHeaderField:@"Content-type"];
    responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/xml", nil];
    
    requestManager.responseSerializer = responseSerializer;
    requestManager.requestSerializer = requestSerializer;
    
    [requestManager GET:[self hotsosIssuePathForTerm:term] parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id _Nonnull responseObject) {
        NSLog(@"Response object is a %@", [responseObject class]);
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        // TODO: implement
    }];
}

@end
