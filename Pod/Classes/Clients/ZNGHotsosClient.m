//
//  ZNGHotsosClient.m
//  Pods
//
//  Created by Jason Neel on 12/7/16.
//
//

#import "ZNGHotsosClient.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "ZNGLogging.h"
#import "ZNGService.h"
#import "ZNGSettingsField.h"
#import "ZNGSetting.h"

#define kHotsosURLCode          @"hotsos_url"
#define kHotsosUsernameCode     @"hotsos_username"
#define kHotsosPasswordCode     @"hotsos_password"

static const int zngLogLevel = ZNGLogLevelDebug;

@implementation ZNGHotsosClient
{
    NSMutableArray<NSString *> * matchingIssueNames;
    
    BOOL parsingAnIssueName;
}

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

/**
 *  Ensures that the hotsosHostName includes https:// and not http:// nor nothing at all
 */
- (NSString *) hotsosURLAsSSL
{
    NSURLComponents * components = [NSURLComponents componentsWithString:self.service.hotsosHostName];
    
    if (components == nil) {
        return nil;
    }
    
    if (components.host == nil) {
        components.host = components.path;
        components.path = nil;
    }
    
    components.scheme = @"https";
    return components.string;
}

- (NSString *) hotsosIssuePathForTerm:(NSString *)term
{
    NSString * fuzzyTerm = [[NSString stringWithFormat:@"%%%@%%", term] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSString stringWithFormat:@"%@/api/service.svc/rest/GetIssueCollection?nameLike=%@", [self hotsosURLAsSSL], fuzzyTerm];
}

- (void) getIssuesLike:(NSString *)term completion:(void (^)(NSArray<NSString *> * _Nullable matchingIssueNames, NSError * _Nullable error))completion;
{
    AFHTTPSessionManager * sessionManager = [AFHTTPSessionManager manager];
    AFHTTPRequestSerializer * requestSerializer = [AFHTTPRequestSerializer serializer];
    AFXMLParserResponseSerializer * responseSerializer = [AFXMLParserResponseSerializer serializer];
    
    [requestSerializer setAuthorizationHeaderFieldWithUsername:[self.service hotsosUserName] password:[self.service hotsosPassword]];
    [requestSerializer setValue:@"application/xml" forHTTPHeaderField:@"Content-type"];
    responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/xml", nil];
    
    sessionManager.responseSerializer = responseSerializer;
    sessionManager.requestSerializer = requestSerializer;
    
    [sessionManager GET:[self hotsosIssuePathForTerm:term] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSXMLParser * _Nullable responseObject) {
        responseObject.delegate = self;
        [responseObject parse];
        ZNGLogInfo(@"HotSOS returned %llu issues matching \"%%%@%%\"", (unsigned long long)[self->matchingIssueNames count], term);
        
        // Sanity check for non nil completion block
        if (completion == nil) {
            return;
        }
        
        NSError * error = [responseObject parserError];
        
        if (error != nil) {
            completion(nil, error);
        } else {
            completion(self->matchingIssueNames, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(nil, error);
        }
    }];
}

#pragma mark - XML parsing
- (void) parserDidStartDocument:(NSXMLParser *)parser
{
    ZNGLogDebug(@"Began parsing XML");
    matchingIssueNames = [[NSMutableArray alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict
{
    parsingAnIssueName = [elementName isEqualToString:@"a:Name"];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if ((parsingAnIssueName) && (string != nil)) {
        [matchingIssueNames addObject:string];
    }
}

@end
