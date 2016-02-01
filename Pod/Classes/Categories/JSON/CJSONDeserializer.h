#import <Foundation/Foundation.h>

extern NSString *const kJSONDeserializerErrorDomain /* = @"CJSONDeserializerErrorDomain" */;

typedef enum {
    
    // Fundamental scanning errors
    kJSONDeserializerErrorCode_NothingToScan = -11,
    kJSONDeserializerErrorCode_CouldNotDecodeData = -12,
    kJSONDeserializerErrorCode_CouldNotScanObject = -15,
    kJSONDeserializerErrorCode_ScanningFragmentsNotAllowed = -16,
    kJSONDeserializerErrorCode_DidNotConsumeAllData = -17,
    kJSONDeserializerErrorCode_FailedToCreateObject = -18,

    // Dictionary scanning
    kJSONDeserializerErrorCode_DictionaryStartCharacterMissing = -101,
    kJSONDeserializerErrorCode_DictionaryKeyScanFailed = -102,
    kJSONDeserializerErrorCode_DictionaryKeyNotTerminated = -103,
    kJSONDeserializerErrorCode_DictionaryValueScanFailed = -104,
    kJSONDeserializerErrorCode_DictionaryNotTerminated = -106,
    
    // Array scanning
    kJSONDeserializerErrorCode_ArrayStartCharacterMissing = -201,
    kJSONDeserializerErrorCode_ArrayValueScanFailed = -202,
    kJSONDeserializerErrorCode_ArrayValueIsNull = -203,
    kJSONDeserializerErrorCode_ArrayNotTerminated = -204,
    
    // String scanning
    kJSONDeserializerErrorCode_StringNotStartedWithBackslash = -301,
    kJSONDeserializerErrorCode_StringUnicodeNotDecoded = -302,
    kJSONDeserializerErrorCode_StringUnknownEscapeCode = -303,
    kJSONDeserializerErrorCode_StringNotTerminated = -304,
    kJSONDeserializerErrorCode_StringBadEscaping = -305,
    kJSONDeserializerErrorCode_StringCouldNotBeCreated = -306,

    // Number scanning
    kJSONDeserializerErrorCode_NumberNotScannable = -401
    
} EJSONDeserializerErrorCode;

enum {
    // The first three flags map to the corresponding NSJSONSerialization flags.
    kJSONDeserializationOptions_MutableContainers = (1UL << 0),
    kJSONDeserializationOptions_MutableLeaves = (1UL << 1),
    kJSONDeserializationOptions_AllowFragments = (1UL << 2),
    kJSONDeserializationOptions_LaxEscapeCodes = (1UL << 3),
    kJSONDeserializationOptions_Default = kJSONDeserializationOptions_MutableContainers,
};
typedef NSUInteger EJSONDeserializationOptions;

@interface CJSONDeserializer : NSObject

/// Object to return instead when a null encountered in the JSON. Defaults to NSNull. Setting to null causes the deserializer to skip null values.
@property (readwrite, nonatomic, strong) id nullObject;

/// JSON must be encoded in Unicode (UTF-8, UTF-16 or UTF-32). Use this if you expect to get the JSON in another encoding.

@property (readwrite, nonatomic, assign) EJSONDeserializationOptions options;

+ (CJSONDeserializer *)deserializer;

- (id)deserialize:(NSData *)inData error:(NSError **)outError;

- (id)deserializeAsDictionary:(NSData *)inData error:(NSError **)outError;
- (id)deserializeAsArray:(NSData *)inData error:(NSError **)outError;

@end
