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
#import "ZNGCalendarEventHeaderView.h"
#import "UIFont+Lato.h"
#import "UIColor+ZingleSDK.h"

@import SBObjectiveCWrapper;

static NSString * const EventCellId = @"event";
static NSString * const HeaderCellId = @"header";
static const CGFloat LeftMarginSize = 16.0;

@interface ZNGContactEventsViewController ()

@end

@implementation ZNGContactEventsViewController
{
    // Arrays of events per day, keyed by (localized!) human readable date string
    NSDictionary<NSString *, NSMutableArray<ZNGCalendarEvent *> *> * eventsByDateString;
    
    // Sort order of date strings
    NSArray<NSString *> * eventDateStringsInOrder;
    NSString * todayString;
    
    NSDateFormatter * eventDayFormatter;
    NSDateFormatter * eventMonthFormatter;
    NSDateFormatter * eventTimeFormatter;
    
    // Formatter that returns a string uniquely representing a calendar day.  This can be used both to group
    //  events by day and to display a title string for each day.  e.g. "May 7, 1985"
    NSDateFormatter * eventCategorizationFormatter;
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
    UINib * headerNib = [UINib nibWithNibName:NSStringFromClass([ZNGCalendarEventHeaderView class]) bundle:bundle];
    [self.tableView registerNib:headerNib forHeaderFooterViewReuseIdentifier:HeaderCellId];
    
    eventDayFormatter = [ZNGCalendarEvent eventDayFormatter];
    eventMonthFormatter = [ZNGCalendarEvent eventMonthFormatter];
    eventTimeFormatter = [ZNGCalendarEvent eventTimeFormatter];
    
    // e.g. "May 7, 1985"
    eventCategorizationFormatter = [[NSDateFormatter alloc] init];
    eventCategorizationFormatter.dateStyle = NSDateFormatterLongStyle;
    eventCategorizationFormatter.timeStyle = NSDateFormatterNoStyle;
    
    if (self.conversation != nil) {
        // Update title
        self.titleLabel.text = [NSString stringWithFormat:@"%@'s events", [self.conversation remoteName]];
    }
    
    [self parseEvents];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Scroll to show today (in case there are a billion finished events pushing future events off screen)
    NSUInteger todayIndex = [eventDateStringsInOrder indexOfObject:todayString];
    
    if (todayIndex != NSNotFound) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:NSNotFound inSection:todayIndex] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        });
    }
}

#pragma mark - Date crunching
- (void) parseEvents
{
    NSMutableDictionary <NSString *, NSMutableArray<ZNGCalendarEvent *> *> * newEventsByDate = [[NSMutableDictionary alloc] init];
    NSMutableDictionary <NSDateComponents *, NSString *> * dateStringsByComponents = [[NSMutableDictionary alloc] init];
    NSCalendar * calendar = [NSCalendar currentCalendar];
    
    // Ensure that we have an item for today, whether or not it will contain any events
    NSDate * now = [NSDate date];
    todayString = [eventCategorizationFormatter stringFromDate:now];
    newEventsByDate[todayString] = [[NSMutableArray alloc] init];
    NSDateComponents * todayComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:now];
    dateStringsByComponents[todayComponents] = todayString;
    
    for (ZNGCalendarEvent * event in self.conversation.contact.calendarEvents) {
        if (event.startsAt == nil) {
            SBLogWarning(@"Event %@ has a null starts_at date and will not be displayed.  This is odd.", event.calendarEventId);
            continue;
        }
        
        NSString * dateString = [eventCategorizationFormatter stringFromDate:event.startsAt];
        NSMutableArray * events = newEventsByDate[dateString];
        
        if (events == nil) {
            // This is the first event on this date; we need to create the array.
            events = [[NSMutableArray alloc] init];
            newEventsByDate[dateString] = events;
            
            // .. and record date components to determine sort order later
            NSDateComponents * components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:event.startsAt];
            dateStringsByComponents[components] = dateString;
        }
        
        [events addObject:event];
    }
    
    // Sort events within each date
    for (NSMutableArray * events in [newEventsByDate allValues]) {
        [events sortUsingDescriptors:[ZNGCalendarEvent sortDescriptors]];
    }
    
    // Sort the dates themselves and record the order
    NSMutableArray<NSString *> * newDateStringsInOrder = [[NSMutableArray alloc] init];
    
    NSArray<NSDateComponents *> * sortedDateComponents = [[dateStringsByComponents allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSDateComponents * dc1, NSDateComponents * dc2) {
        NSDate * date1 = [calendar dateFromComponents:dc1];
        NSDate * date2 = [calendar dateFromComponents:dc2];
        return [date1 compare:date2];
    }];
    
    for (NSDateComponents * dateComponents in sortedDateComponents) {
        NSString * dateString = dateStringsByComponents[dateComponents];
        [newDateStringsInOrder addObject:dateString];
    }
    
    eventDateStringsInOrder = newDateStringsInOrder;
    eventsByDateString = newEventsByDate;
}

#pragma mark - Table data
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [eventsByDateString count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section > [eventDateStringsInOrder count]) {
        SBLogError(@"Out of bounds (%lld of %llu) when retrieving events by date", (long long)section, (unsigned long long)[eventDateStringsInOrder count]);
        return 0;
    }
    
    NSString * dateString = eventDateStringsInOrder[section];
    return [eventsByDateString[dateString] count];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ZNGCalendarEventHeaderView * header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:HeaderCellId];
    
    if (section > [eventDateStringsInOrder count]) {
        SBLogError(@"Out of bounds (%lld of %llu) when retrieving events by date", (long long)section, (unsigned long long)[eventDateStringsInOrder count]);
        header.todayLabel = nil;
        return header;
    }
    
    NSString * dateString = eventDateStringsInOrder[section];
    header.dateLabel.text = dateString;
    header.dateLabel.font = [UIFont latoFontOfSize:14.0];
    
    if ([dateString isEqualToString:todayString]) {
        header.todayLabel.hidden = NO;
        header.todayBottomBorder.hidden = NO;
    }
    
    return header;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGContactEventTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:EventCellId forIndexPath:indexPath];
    cell.leftnessConstraint.constant = LeftMarginSize;
    
    if (indexPath.section > [eventDateStringsInOrder count]) {
        SBLogError(@"Out of bounds (%lld of %llu) when retrieving events by date", (long long)indexPath.section, (unsigned long long)[eventDateStringsInOrder count]);
        
        cell.eventNameLabel.text = nil;
        cell.dayLabel.text = nil;
        cell.monthLabel.text = nil;
        cell.timeLabel.text = nil;
        return cell;
    }
    
    NSString * dateString = eventDateStringsInOrder[indexPath.section];
    NSArray<ZNGCalendarEvent *> * eventsThisDay = eventsByDateString[dateString];
    
    if (indexPath.row > [eventsThisDay count]) {
        SBLogError(@"Out of bounds (%lld of %llu) when retrieving event on %@", (long long)indexPath.row, (unsigned long long)[eventsThisDay count], dateString);
        
        cell.eventNameLabel.text = nil;
        cell.dayLabel.text = nil;
        cell.monthLabel.text = nil;
        cell.timeLabel.text = nil;
        return cell;
    }
    
    ZNGCalendarEvent * event = eventsThisDay[indexPath.row];
    
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
