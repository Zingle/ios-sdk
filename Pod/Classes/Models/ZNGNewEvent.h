//
//  ZNGNewEvent.h
//  Pods
//
//  Created by Robert Harrison on 5/20/16.
//
//

#import <Mantle/Mantle.h>

@interface ZNGNewEvent : MTLModel<MTLJSONSerializing>

@property(nonatomic, strong) NSString *eventType;
@property(nonatomic, strong) NSString *contactId;
@property(nonatomic, strong) NSString *body;

@end
