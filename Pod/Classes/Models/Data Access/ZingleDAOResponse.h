//
//  ZingleDAOResponse.h
//  ZingleSDK
//
//  Copyright (c) 2015 Zingle.me. All rights reserved.
//

#import "ZingleModel.h"

extern int const ZINGLE_HTTP_STATUS_UNKNOWN;
extern int const ZINGLE_HTTP_STATUS_OK;
extern int const ZINGLE_HTTP_STATUS_BAD_REQUEST;
extern int const ZINGLE_HTTP_STATUS_UNAUTHORIZED;
extern int const ZINGLE_HTTP_STATUS_FORBIDDEN;
extern int const ZINGLE_HTTP_STATUS_NOT_FOUND;
extern int const ZINGLE_HTTP_STATUS_METHOD_NOT_ALLOWED;
extern int const ZINGLE_HTTP_STATUS_SERVER_ERROR;

@class ZingleError;

@interface ZingleDAOResponse : ZingleModel

@property (nonatomic, retain) NSString *requestedMethod, *requestedURL, *requestedPayload;

- (BOOL)successful;
- (int)httpStatusCode;
- (NSDictionary *)allHeaders;
- (id)headerValueForKey:(NSString *)key;
- (NSString *)responseAsString;
- (NSMutableDictionary *)responseAsDictionary;
- (id)result;
- (NSMutableDictionary *)status;
- (id)statusField:(NSString *)field;
- (BOOL)requestCompleted;
- (NSError *)error;

- (void)setUrlResponseData:(NSData *)urlResponseData;
- (void)setUrlResponseError:(NSError *)urlResponseError;
- (void)setUrlResponse:(NSURLResponse *)urlResponse;

@end