//
//  ZNGInboxDataLabel.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataLabel.h"

@implementation ZNGInboxDataLabel

+ (NSString *) description
{
    return @"Inbox data by label";
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: %@ %p>", [self class], self.labelId, self];
}

- (id) initWithContactClient:(ZNGContactClient *)contactClient labelId:(NSString *)theLabelId;
{
    self = [super initWithContactClient:contactClient];
    
    if (self != nil) {
        self.labelId = theLabelId;
    }
    
    return self;
}

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyLabelId] = self.labelId;
    
    return parameters;
}

@end
