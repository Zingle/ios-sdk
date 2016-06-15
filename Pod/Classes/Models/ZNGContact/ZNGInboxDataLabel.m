//
//  ZNGInboxDataLabel.m
//  Pods
//
//  Created by Jason Neel on 6/9/16.
//
//

#import "ZNGInboxDataLabel.h"

@implementation ZNGInboxDataLabel
{
    NSString * labelId;
}

- (id) initWithContactClient:(ZNGContactClient *)contactClient labelId:(NSString *)theLabelId;
{
    self = [super initWithContactClient:contactClient];
    
    if (self != nil) {
        labelId = theLabelId;
    }
    
    return self;
}

- (nonnull NSMutableDictionary *) parameters
{
    NSMutableDictionary * parameters = [super parameters];
    
    parameters[ParameterKeyLabelId] = labelId;
    
    return parameters;
}

@end
