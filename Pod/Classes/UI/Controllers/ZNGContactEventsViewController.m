//
//  ZNGContactEventsViewController.m
//  ZingleSDK
//
//  Created by Jason Neel on 7/12/18.
//

#import "ZNGContactEventsViewController.h"
#import "ZNGContact.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGCalendarEvent.h"
#import "ZNGContactEventTableViewCell.h"

static NSString * const EventCellId = @"event";

@interface ZNGContactEventsViewController ()

@end

@implementation ZNGContactEventsViewController
{
    NSArray<ZNGCalendarEvent *> * events;
    
    NSDateFormatter * eventDayFormatter;
    NSDateFormatter * eventMonthFormatter;
    NSDateFormatter * eventTimeFormatter;
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    NSBundle * bundle = [NSBundle bundleForClass:[ZNGContactEventsViewController class]];
    UINib * eventCellNib = [UINib nibWithNibName:NSStringFromClass([ZNGContactEventTableViewCell class]) bundle:bundle];
    [self.tableView registerNib:eventCellNib forCellReuseIdentifier:EventCellId];
    
    eventDayFormatter = [ZNGCalendarEvent eventDayFormatter];
    eventMonthFormatter = [ZNGCalendarEvent eventMonthFormatter];
    eventTimeFormatter = [ZNGCalendarEvent eventTimeFormatter];
    
    if (self.conversation != nil) {
        // Update title
        self.titleLabel.text = [NSString stringWithFormat:@"%@'s events", [self.conversation remoteName]];
    }
    
    events = [self.conversation.contact.calendarEvents sortedArrayUsingDescriptors:[ZNGCalendarEvent sortDescriptors]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // TODO: Scroll to show today (in case there are a billion finished events pushing future events off screen)
}

#pragma mark - Table data
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [events count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGCalendarEvent * event = events[indexPath.row];
    ZNGContactEventTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:EventCellId forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.eventNameLabel.text = event.title;
    cell.dayLabel.text = [eventDayFormatter stringFromDate:event.startsAt];
    cell.monthLabel.text = [[eventMonthFormatter stringFromDate:event.startsAt] uppercaseString];
    
    NSString * startTime = [eventTimeFormatter stringFromDate:event.startsAt];
    NSString * endTime = [eventTimeFormatter stringFromDate:event.endsAt];
    cell.timeLabel.text = [NSString stringWithFormat:@"%@ - %@", startTime, endTime];
    
    UIColor * textColor = [self.conversation.service textColorForCalendarEvent:event];
    UIColor * backgroundColor = [self.conversation.service backgroundColorForCalendarEvent:event];
    cell.roundedBackgroundView.backgroundColor = backgroundColor;
    cell.roundedBackgroundView.layer.borderColor = [textColor CGColor];
    cell.dividerLine.backgroundColor = textColor;
    
    for (UILabel * label in cell.textLabels) {
        label.textColor = textColor;
    }
    
    return cell;
}

#pragma mark - Actions
- (IBAction) pressedDone:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
