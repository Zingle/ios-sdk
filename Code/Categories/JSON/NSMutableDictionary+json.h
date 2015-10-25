#import <Foundation/Foundation.h>

@interface NSMutableDictionary (json)

+ (NSMutableDictionary *)dictionaryWithJsonString:(NSString *)json;
+ (NSMutableDictionary *)dictionaryWithJsonData:(NSData *)json;

- (NSData *)jsonData;
- (NSString *)jsonString;
- (NSString *)queryString;
- (id)objectAtPath:(NSString *)path expectedClass:(Class)class;
- (id)objectAtPath:(NSString *)path expectedClass:(Class)class default:(id)defaultValue;

@end
