//
//  ZingleLogging.h
//  Pods
//
//  Created by Jason Neel on 6/8/16.
//
//

#ifndef ZingleLogging_h
#define ZingleLogging_h

#ifdef DD_LEGACY_MACROS
#undef DD_LEGACY_MACROS
#define DD_LEGACY_MACROS    1
#endif

#import <CocoaLumberjack/CocoaLumberjack.h>

#define ZINGLE_LOG_CONTEXT      889
#define ZINGLE_LOG_LEVEL_DEF   zngLogLevel

#define ZINGLE_LOG_LEVEL_OFF    0
#define ZINGLE_LOG_LEVEL_ERROR

/**
 *  Log levels are used to filter out logs. Used together with flags.
 */
typedef NS_ENUM(NSUInteger, ZNGLogLevel){
    /**
     *  No logs
     */
    ZNGLogLevelOff       = 0,
    
    /**
     *  Error logs only
     */
    ZNGLogLevelError     = DDLogLevelError,
    
    /**
     *  Error and warning logs
     */
    ZNGLogLevelWarning   = DDLogLevelWarning,
    
    /**
     *  Error, warning and info logs
     */
    ZNGLogLevelInfo      = DDLogLevelInfo,
    
    /**
     *  Error, warning, info and debug logs
     */
    ZNGLogLevelDebug     = DDLogLevelDebug,
    
    /**
     *  Error, warning, info, debug and verbose logs
     */
    ZNGLogLevelVerbose   = DDLogLevelVerbose,
    
    /**
     *  All logs (1...11111)
     */
    ZNGLogLevelAll       = DDLogLevelAll
};

#define ZNGLogError(frmt, ...)      LOG_MAYBE(NO, ZINGLE_LOG_LEVEL_DEF, DDLogFlagError, ZINGLE_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ZNGLogWarn(frmt, ...)      LOG_MAYBE(LOG_ASYNC_ENABLED, ZINGLE_LOG_LEVEL_DEF, DDLogFlagWarning, ZINGLE_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ZNGLogInfo(frmt, ...)      LOG_MAYBE(LOG_ASYNC_ENABLED, ZINGLE_LOG_LEVEL_DEF, DDLogFlagInfo, ZINGLE_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ZNGLogDebug(frmt, ...)      LOG_MAYBE(LOG_ASYNC_ENABLED, ZINGLE_LOG_LEVEL_DEF, DDLogFlagDebug, ZINGLE_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ZNGLogVerbose(frmt, ...)      LOG_MAYBE(LOG_ASYNC_ENABLED, ZINGLE_LOG_LEVEL_DEF, DDLogFlagVerbose, ZINGLE_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)


#endif /* ZingleLogging_h */
