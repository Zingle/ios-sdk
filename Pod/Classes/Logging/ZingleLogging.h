//
//  ZingleLogging.h
//  Pods
//
//  Created by Jason Neel on 6/8/16.
//
//

#ifndef ZingleLogging_h
#define ZingleLogging_h

#define ZINGLE_LOG_CONTEXT      889

#define ZNGLogError(frmt, ...)      SYNC_LOG_OBJC_MAYBE(zngLogLevel, LOG_FLAG_ERROR, ZINGLE_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define ZNGLogWarn(frmt, ...)      ASYNC_LOG_OBJC_MAYBE(zngLogLevel, LOG_FLAG_WARN, ZINGLE_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define ZNGLogInfo(frmt, ...)      ASYNC_LOG_OBJC_MAYBE(zngLogLevel, LOG_FLAG_INFO, ZINGLE_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define ZNGLogDebug(frmt, ...)      ASYNC_LOG_OBJC_MAYBE(zngLogLevel, LOG_FLAG_DEBUG, ZINGLE_LOG_CONTEXT, frmt, ##__VA_ARGS__)
#define ZNGLogVerbose(frmt, ...)      ASYNC_LOG_OBJC_MAYBE(zngLogLevel, LOG_FLAG_TRACE, ZINGLE_LOG_CONTEXT, frmt, ##__VA_ARGS__)


#endif /* ZingleLogging_h */
