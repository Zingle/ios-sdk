//
//  ZNGTemplate.h
//  Pods
//
//  Created by Ryan Farley on 2/10/16.
//
//

#import <Mantle/Mantle.h>

extern NSString * const ZNGTemplateTypeAutomatedWelcome;
extern NSString * const ZNGTemplateTypeWelcome;
extern NSString * const ZNGTemplateTypeGeneral;

@interface ZNGTemplate : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *templateId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *body;
@property (nonatomic) BOOL isGlobal;

/**
 *  Returns YES if this template contains a placeholder string for a response time
 */
- (BOOL) requiresResponseTime;

/**
 *  All values allowed as replacements for response_time
 */
- (NSArray<NSString *> *) responseTimeChoices;

/**
 *  Returns this template's body, having replaced all placeholders for response time with the specified string.
 */
- (NSString *) bodyWithResponseTime:(NSString *)responseTimeString;

@end
