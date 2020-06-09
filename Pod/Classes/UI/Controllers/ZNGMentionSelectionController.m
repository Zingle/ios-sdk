//
//  ZNGMentionSelectionController.m
//  ZingleSDK
//
//  Created by Jason Neel on 6/4/20.
//

#import "ZNGMentionSelectionController.h"
#import "ZingleAccountSession.h"
#import "ZNGTeam.h"
#import "ZNGAvatarImageView.h"
#import "NSString+Initials.h"
#import "UIColor+ZingleSDK.h"
#import "UIFont+Lato.h"
#import "ZNGMentionSelectTableViewCell.h"

@import SBObjectiveCWrapper;

static NSString * const MentionSelectionCellId = @"mentionCell";

enum {
    ZNGMentionSectionUsers,
    ZNGMentionSectionTeams
};

@implementation ZNGMentionSelectionController
{
    NSArray<NSNumber *> * mentionSections;
    CGSize avatarSize;
    UIFont * avatarFont;
    UIColor * avatarBackgroundColor;
    
    NSArray<ZNGUser *> * filteredUsers;
    NSArray<ZNGTeam *> * filteredTeams;
}

- (id) initWithSelectionTable:(UITableView *)tableView session:(ZingleAccountSession *)session delegate:(__weak id <ZNGMentionSelectionDelegate>)delegate
{
    self = [super init];
    
    if (self != nil) {
        NSBundle * bundle = [NSBundle bundleForClass:[ZNGMentionSelectionController class]];
        mentionSections = @[@(ZNGMentionSectionTeams), @(ZNGMentionSectionUsers)];
        avatarSize = CGSizeMake(36.0, 36.0);
        avatarBackgroundColor = [UIColor colorNamed:@"ZNGOutboundBubbleBackground" inBundle:bundle compatibleWithTraitCollection:nil];
        avatarFont = [UIFont latoFontOfSize:15.0];

        self.tableView = tableView;
        tableView.dataSource = self;
        tableView.delegate = self;
        self.session = session;
        self.delegate = delegate;
        
        UINib * cellNib = [UINib nibWithNibName:NSStringFromClass([ZNGMentionSelectTableViewCell class]) bundle:bundle];
        [self.tableView registerNib:cellNib forCellReuseIdentifier:MentionSelectionCellId];
    }
    
    return self;
}

- (void) setMentionSearchText:(NSString *)mentionSearchText
{
    _mentionSearchText = mentionSearchText;
    
    [self updateFilteredUsersAndTeams];
    
    if (([filteredUsers count] > 0) || ([filteredTeams count] > 0)) {
        [self.tableView reloadData];
        self.tableView.hidden = NO;
    } else {
        self.tableView.hidden = YES;
    }
}

- (void) updateFilteredUsersAndTeams
{
    NSString * searchText = self.mentionSearchText;
    
    // A nil search term means no matches. Note that an empty search term instead means *all* teams/users.
    if (searchText == nil) {
        filteredUsers = nil;
        filteredTeams = nil;
        return;
    }
    
    // Remove preceding '@' from search text, if present
    if (([searchText length] > 0) && ([searchText characterAtIndex:0] == '@')) {
        searchText = [searchText substringFromIndex:1];
    }
    
    NSPredicate * userPredicate;
    NSPredicate * teamPredicate;
    
    if ([searchText length] == 0) {
        // Empty search string means all users/teams
        userPredicate = [NSPredicate predicateWithValue:YES];
        teamPredicate = [NSPredicate predicateWithValue:YES];
    } else {
        userPredicate = [NSPredicate predicateWithBlock:^BOOL(ZNGUser * user, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ([[user fullName] rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
        }];
        
        teamPredicate = [NSPredicate predicateWithBlock:^BOOL(ZNGTeam * team, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ([[team displayNameWithEmoji] rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
        }];
    }
    
    NSArray<ZNGUser *> * users = [[self.session.users filteredArrayUsingPredicate:userPredicate] sortedArrayUsingSelector:@selector(fullName)];
    NSArray<ZNGTeam *> * teams = [[[self.session teamsVisibleToCurrentUser] filteredArrayUsingPredicate:teamPredicate] sortedArrayUsingSelector:@selector(displayName)];
    
    filteredUsers = users;
    filteredTeams = teams;
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [mentionSections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section >= [mentionSections count]) {
        SBLogError(@"Out of bounds in mention type-ahead sections table (%d)", (int)section);
        return 0;
    }
    
    int thisSection = [mentionSections[section] intValue];
    
    switch (thisSection) {
        case ZNGMentionSectionTeams:
            return [filteredTeams count];
            
        case ZNGMentionSectionUsers:
            return [filteredUsers count];
            
        default:
            SBLogError(@"Unknown section in mention type-ahead controller.");
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZNGMentionSelectTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:MentionSelectionCellId forIndexPath:indexPath];
    cell.nameLabel.text = nil;
    cell.teamEmojiLabel.text = nil;
    [cell.avatarView removeFromSuperview];
    cell.avatarView = nil;
    
    if (indexPath.section >= [mentionSections count]) {
        SBLogError(@"Out of bounds in mention type-ahead sections table (%d/%d)", (int)indexPath.section, (int)[mentionSections count]);
        return 0;
    }
    
    int thisSection = [mentionSections[indexPath.section] intValue];
    
    switch (thisSection) {
        case ZNGMentionSectionTeams:
        {
            if (indexPath.row > [filteredTeams count]) {
                SBLogError(@"Out of bounds in mention type-ahead teams list (%d/%d)", (int)indexPath.row, (int)[filteredTeams count]);
            }
            
            ZNGTeam * team = filteredTeams[indexPath.row];
            cell.nameLabel.text = team.displayName;
            cell.teamEmojiLabel.text = team.emoji;
            
            break;
        }
            
        case ZNGMentionSectionUsers:
        {
            if (indexPath.row > [filteredUsers count]) {
                SBLogError(@"Out of bounds in mention type-ahead users list (%d/%d)", (int)indexPath.row, (int)[filteredUsers count]);
                return cell;
            }
            
            ZNGUser * user = filteredUsers[indexPath.row];
            ZNGAvatarImageView * avatar = [[ZNGAvatarImageView alloc] initWithAvatarUrl:user.avatarUri
                                                                               initials:[[user fullName] initials]
                                                                                   size:avatarSize
                                                                        backgroundColor:avatarBackgroundColor
                                                                              textColor:[UIColor whiteColor]
                                                                                   font:avatarFont];
            cell.nameLabel.text = [user fullName];
            cell.avatarView = avatar;
            [cell.avatarContainer addSubview:avatar];
            [self pinAvatar:avatar toContainer:cell.avatarContainer];
            
            break;
        }
            
        default:
            SBLogError(@"Unknown section in mention type-ahead controller.");
    }
    
    return cell;
}
- (void) pinAvatar:(UIView *)avatar toContainer:(UIView *)container
{
    NSString * verticalPin = @"V:|[avatar]|";
    NSString * horizontalPin = @"H:|[avatar]|";
    
    NSArray<NSLayoutConstraint *> * vertical = [NSLayoutConstraint constraintsWithVisualFormat:verticalPin options:0 metrics:nil views:@{@"avatar": avatar}];
    NSArray<NSLayoutConstraint *> * horizontal = [NSLayoutConstraint constraintsWithVisualFormat:horizontalPin options:0 metrics:nil views:@{@"avatar": avatar}];
    [container addConstraints:horizontal];
    [container addConstraints:vertical];
    
    [container layoutIfNeeded];
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= [mentionSections count]) {
        SBLogError(@"Out of bounds in mention type-ahead sections table (%d)", (int)indexPath.section);
        return;
    }
    
    int thisSection = [mentionSections[indexPath.section] intValue];
    
    switch (thisSection) {
        case ZNGMentionSectionTeams:
        {
            if (indexPath.row > [filteredTeams count]) {
                SBLogError(@"Out of bounds in mention type-ahead teams list (%d/%d)", (int)indexPath.row, (int)[filteredTeams count]);
            }
            
            ZNGTeam * team = filteredTeams[indexPath.row];
            SBLogInfo(@"User selected team %@ in mention type-ahead", team.displayName);
            [self.delegate mentionSelectionController:self didSelectTeam:team];
            
            return;
        }
            
        case ZNGMentionSectionUsers:
        {
            if (indexPath.row > [filteredUsers count]) {
                SBLogError(@"Out of bounds in mention type-ahead users list (%d/%d)", (int)indexPath.row, (int)[filteredUsers count]);
                return;
            }
            
            ZNGUser * user = filteredUsers[indexPath.row];
            SBLogInfo(@"User selected user %@ in mention type-ahead", [user fullName]);
            [self.delegate mentionSelectionController:self didSelectUser:user];
            
            return;
        }
            
        default:
            SBLogError(@"Unknown section in mention type-ahead controller.");
    }
}

@end
