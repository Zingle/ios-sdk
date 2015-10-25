#import "NSMutableDictionary+json.h"
#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"

static NSString *toString(id object) {
    return [NSString stringWithFormat: @"%@", object];
}

static NSString *urlEncode(id object) {
    NSString *string = toString(object);
    string = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    string = [string stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    return string;
}

@implementation NSMutableDictionary (json)

+ (NSMutableDictionary *)dictionaryWithJsonString:(NSString *)json
{
    return [NSMutableDictionary dictionaryWithJsonData:[json dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSMutableDictionary *)dictionaryWithJsonData:(NSData *)json
{
    NSError *jsonError = NULL;
    NSMutableDictionary *dictionary = (NSMutableDictionary*)[[CJSONDeserializer deserializer] deserialize:json error:&jsonError];
    return dictionary;
}

- (NSData *)jsonData
{
    NSError *jsonError;
    NSData *data = [[CJSONSerializer serializer] serializeObject:self error:&jsonError];
    
    if( data != nil )
    {
        return data;
    }
    
    return [[NSData alloc] init];
}

- (NSString *)jsonString
{
    NSData *jsonData = [self jsonData];
    if( jsonData != nil )
    {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return @"";
}

- (NSString *)queryString
{
    NSMutableArray *parts = [NSMutableArray array];
    for( id key in self )
    {
        id value = [self objectForKey:key];
        NSString *part = [NSString stringWithFormat:@"%@=%@", urlEncode(key), urlEncode(value)];
        [parts addObject:part];
    }
    return [parts componentsJoinedByString:@"&"];
}

- (id)objectAtPath:(NSString *)path expectedClass:(__unsafe_unretained Class)class
{
    return [self objectAtPath:path expectedClass:class default:nil];
}

- (id)objectAtPath:(NSString *)path expectedClass:(__unsafe_unretained Class)class default:(id)defaultValue
{
    NSScanner *scanner;
    NSArray *pieces = [path componentsSeparatedByString:@"."];
    
    if( pieces.count == 0 )
    {
        return nil;
    }
    
    id currentObject;
    currentObject = self;
    for( NSString *piece in pieces )
    {
        if( [currentObject isKindOfClass:[NSDictionary class]] )
        {
            currentObject = [currentObject objectForKey:piece];
            
            if( currentObject == nil )
            {
                return defaultValue;
            }
        }
        else if( [currentObject isKindOfClass:[NSArray class]] )
        {
            scanner = [NSScanner scannerWithString:piece];
            if( [scanner scanInteger:nil] && [scanner isAtEnd] )
            {
                int index = [piece intValue];
                if( index >= 0 && index < [currentObject count] )
                {
                    currentObject = [currentObject objectAtIndex:index];
                }
                else
                {
                    return defaultValue;
                }
            }
            else
            {
                return defaultValue;
            }
        }
        else
        {
            return defaultValue;
        }
    }
    
    if( currentObject == nil )
    {
        return defaultValue;
    }
    
    if( class != nil )
    {
        if( ![currentObject isKindOfClass:class] )
        {
            return defaultValue;
        }
    }
    
    return currentObject;
}

@end
