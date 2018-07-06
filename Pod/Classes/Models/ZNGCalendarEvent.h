//
//  ZNGCalendarEvent.h
//  ZingleSDK
//
//  Created by Jason Neel on 7/6/18.
//

#import <Mantle/Mantle.h>

@interface ZNGCalendarEvent : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong, nullable) NSString * calendarEventId;
@property (nonatomic, strong, nullable) NSString * eventTypeId;
@property (nonatomic, strong, nullable) NSString * title;
@property (nonatomic, strong, nullable) NSString * eventDescription;
@property (nonatomic, strong, nullable) NSDate * createdAt;
@property (nonatomic, strong, nullable) NSDate * updatedAt;
@property (nonatomic, strong, nullable) NSDate * startsAt;
@property (nonatomic, strong, nullable) NSDate * endsAt;

@end
