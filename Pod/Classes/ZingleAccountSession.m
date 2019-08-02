//
//  ZingleAccountSession.m
//  Pods
//
//  Created by Jason Neel on 6/14/16.
//
//

#import "ZingleAccountSession.h"
#import "ZNGAccount.h"
#import "ZNGService.h"
#import "ZNGAccountClient.h"
#import "ZNGEventClient.h"
#import "ZNGServiceClient.h"
#import "ZNGServiceToContactViewController.h"
#import "ZNGConversationDetailedEvents.h"
#import "ZNGConversationServiceToContact.h"
#import "ZNGAutomationClient.h"
#import "ZNGContactClient.h"
#import "ZNGLabelClient.h"
#import "ZNGUserAuthorizationClient.h"
#import "ZNGUserClient.h"
#import "ZNGContactEditViewController.h"
#import "ZNGAnalytics.h"
#import "ZNGSocketClient.h"
#import "ZNGNetworkLookout.h"
#import "ZNGContactGroup.h"
#import "ZNGInboxStatistician.h"
#import "ZNGInboxStatsEntry.h"
#import "ZNGAssignmentViewController.h"
#import "ZNGNotificationSettingsClient.h"
#import "ZNGTeam.h"
#import "ZNGUserSettings.h"
#import "ZNGJWTClient.h"

@import AFNetworking;
@import SBObjectiveCWrapper;

static NSString * const kSocketConnectedKeyPath = @"socketClient.connected";

NSString * const ZingleUserChangedDetailedEventsPreferenceNotification = @"ZingleUserChangedDetailedEventsPreferenceNotification";
NSString * const ZingleConversationDataArrivedNotification = @"ZingleConversationDataArrivedNotification";
NSString * const ZingleConversationNotificationContactIdKey = @"contactId";
NSString * const ZingleFeedListShouldBeRefreshedNotification = @"ZingleFeedListShouldBeRefreshedNotification";

// Override readonly properties with strong properties to get proper KVO
@interface ZingleAccountSession ()

@property (nonatomic, strong, nonnull) NSCache<NSString *, ZNGConversationServiceToContact *> * conversationCache;

@end

@implementation ZingleAccountSession
{
    dispatch_semaphore_t contactClientSemaphore;
    
    ZNGAccount * _account;
    ZNGService * _service;
    NSDate * serviceSetDate;
    
    dispatch_semaphore_t initialUserDataSemaphore;
    
    NSMutableSet<NSString *> * allLoadedConversationIds;    // List of all conversation IDs ever seen.  Conversations corresponding to these IDs may or may not exist in conversationCache.
    
    UIStoryboard * _storyboard;
}

- (id) initWithToken:(NSString *)token key:(NSString *)key
{
    self = [super initWithToken:token key:key];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (id) initWithJWT:(NSString *)jwt
{
    self = [super initWithJWT:jwt];
    
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (void) commonInit
{
    contactClientSemaphore = dispatch_semaphore_create(0);
    initialUserDataSemaphore = dispatch_semaphore_create(0);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyShowDetailedEventsPreferenceChanged:) name:ZingleUserChangedDetailedEventsPreferenceNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyBecameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyBadgeDataChanged:) name:ZNGInboxStatisticianDataChangedNotification object:nil];
    
    [self addObserver:self forKeyPath:kSocketConnectedKeyPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
    allLoadedConversationIds = [[NSMutableSet alloc] init];
    _conversationCache = [[NSCache alloc] init];
    _conversationCache.countLimit = 10;
    _conversationCache.delegate = self;
    
    self.inboxStatistician = [[ZNGInboxStatistician alloc] init];
    
    _automaticallyUpdateServiceWhenReturningFromBackground = YES;
}

- (void) dealloc
{
    [self.socketClient disconnect];
    
    [self removeObserver:self forKeyPath:kSocketConnectedKeyPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) connect
{
    [self connectWithCompletion:nil];
}

- (void) connectWithCompletion:(nullable ZNGAccountSessionCallback)completion
{
    [self connectWithAccountChooser:nil serviceChooser:nil completion:completion];
}

- (void) connectWithAccountChooser:(nullable ZNGAccountChooser)accountChooser serviceChooser:(nullable ZNGServiceChooser)serviceChooser completion:(nullable ZNGAccountSessionCallback)completion
{
    if (accountChooser != nil) {
        self.accountChooser = accountChooser;
    }
    
    if (serviceChooser != nil ) {
        self.serviceChooser = serviceChooser;
    }
    
    if (completion != nil) {
        self.completion = completion;
    }
    
    [self retrieveAvailableAccounts];
}

- (void) logout
{
    [_conversationCache removeAllObjects];
    [self.socketClient disconnect];
    [super logout];
}

- (void) cache:(NSCache *)cache willEvictObject:(id)obj
{
    ZNGConversationServiceToContact * conversation = obj;
    
    if ([conversation isKindOfClass:[ZNGConversationServiceToContact class]]) {
        [allLoadedConversationIds removeObject:conversation.contact.contactId];
    }
}

#pragma mark - Socket status
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:kSocketConnectedKeyPath]) {
        NSNumber * oldNumber = change[NSKeyValueChangeOldKey];
        NSNumber * newNumber = change[NSKeyValueChangeNewKey];
        BOOL wasConnected = ([oldNumber isKindOfClass:[NSNumber class]]) ? [oldNumber boolValue] : NO;
        BOOL connected = ([newNumber isKindOfClass:[NSNumber class]]) ? [newNumber boolValue] : NO;
        
        if ((!wasConnected) && (connected)) {
            [self.networkLookout recordSocketConnected];
        } else if ((wasConnected) && (!connected)) {
            [self.networkLookout recordSocketDisconnected];
        }
    }
}

- (void) notifyBadgeDataChanged:(NSNotification *)notification
{
    BOOL assignmentDisabled = !([self.service allowsAssignment]);
    BOOL countUnassigned = ((assignmentDisabled) || ([self.userAuthorization.settings.showUnassignedConversations boolValue]));
    ZNGInboxStatsEntry * totalStats = [self.inboxStatistician combinedStatsForUser:self.userAuthorization teams:[self teamsToWhichCurrentUserBelongs] includeUnassigned:countUnassigned];
    
    if (self.totalUnreadCount != totalStats.unreadCount) {
        SBLogDebug(@"Badge count changed from %llu to %llu", (unsigned long long)self.totalUnreadCount, (unsigned long long)totalStats.unreadCount);
        self.totalUnreadCount = totalStats.unreadCount;
    }
}

#pragma mark - Push testing
- (void) requestAPushNotification
{
    if (self.service.serviceId == nil) {
        SBLogWarning(@"%s was called, but there is no active service.  Ignoring.", __PRETTY_FUNCTION__);
        return;
    }
    
    [self _registerForPushNotificationsForServiceIds:@[self.service.serviceId] removePreviousSubscriptions:NO];
}

#pragma mark - Service/Account setters
- (void) setAccount:(ZNGAccount *)account
{
    if ((_account != nil) && (![_account isEqual:account])) {
        SBLogError(@"Account was already set to %@ but is being changed to %@ without creating a new session object.  This may have undesired effects.  A new session object should be created.", _account ,account);
        [self willChangeValueForKey:NSStringFromSelector(@selector(service))];
        [self willChangeValueForKey:NSStringFromSelector(@selector(available))];
        _service = nil;
        self.available = NO;
        [self didChangeValueForKey:NSStringFromSelector(@selector(available))];
        [self didChangeValueForKey:NSStringFromSelector(@selector(service))];
    }
    
    _account = account;
    
    if (_account != nil) {
        [self updateStateForNewAccountOrService];
    }
}

- (ZNGAccount *)account
{
    if (_account != nil) {
        return _account;
    }
    
    if ([self.availableAccounts count] == 1) {
        return [self.availableAccounts firstObject];
    }
    
    return nil;
}

- (ZNGService *)service
{
    if (_service != nil) {
        return _service;
    }
    
    if ([self.availableServices count] == 1) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(service))];
        _service = self.availableServices[0];
        serviceSetDate = [NSDate date];
        [self didChangeValueForKey:NSStringFromSelector(@selector(service))];
        return _service;
    }
    
    return nil;
}

- (void) setAvailable:(BOOL)available
{
    BOOL justConnected = !(self.available) && available;
    
    [super setAvailable:available];
    [self.networkLookout recordLogin];
    
    if ((self.completion != nil) && (justConnected)) {
        self.completion(self.service, nil);
        self.completion = nil;
    }
}

- (void) setMostRecentError:(ZNGError *)mostRecentError
{
    [super setMostRecentError:mostRecentError];
    
    if (self.completion != nil) {
        self.completion(nil, mostRecentError);
        self.completion = nil;
    }
}

- (void) setService:(ZNGService *)service
{
    if (service == nil) {
        _service = nil;
        serviceSetDate = nil;
        return;
    }
    
    serviceSetDate = [NSDate date];
    
    if (_service != nil) {
        if ([_service isEqual:service]) {
            // We are simply updating our current service.  Do it and return.
            _service = service;
            return;
        } else {
            SBLogError(@"Service was already set to %@ but is being changed to %@ without creating a new session object.  This may have undesired effects.  A new session object should be created.", _service ,service);
        }
    }
    
    NSUInteger serviceIndex = [self.availableServices indexOfObject:service];
    
    if (serviceIndex == NSNotFound) {
        SBLogError(@"setService was called with service ID %@, but it does not exist within our %lld available services.  Ignoring.", service.serviceId, (unsigned long long)[self.availableServices count]);

        ZNGError * error = [[ZNGError alloc] initWithDomain:kZingleErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : @"Selected service is not available" }];
        self.mostRecentError = error;
        
        return;
    }
    
    _service = self.availableServices[serviceIndex];
 
    if (_service != nil) {
        [self updateStateForNewAccountOrService];
    }
}

#pragma mark - Service updating
/**
 *  Refreshes our current service object if the data is older than ten minutes old.
 */
- (void) updateServiceIfOldData
{
    if (self.service == nil) {
        return;
    }
    
    BOOL shouldRefresh = NO;
    
    if (serviceSetDate == nil) {
        SBLogError(@"Our service object is set, but we do not have a timestamp of our last update.  Refreshing.");
        shouldRefresh = YES;
    } else {
        NSTimeInterval timeSinceUpdate = [[NSDate date] timeIntervalSinceDate:serviceSetDate];
        NSTimeInterval tenMinutes = (10.0 * 60.0);
        shouldRefresh = (timeSinceUpdate > tenMinutes);
    }
    
    if (shouldRefresh) {
        [self updateCurrentService];
    }
}

- (void) updateCurrentService
{
    if (self.service == nil) {
        SBLogInfo(@"updateCurrentService was called, but we do not have a service selected.");
        return;
    }
    
    [self.serviceClient serviceWithId:self.service.serviceId success:^(ZNGService *service, ZNGStatus *status) {
        if (service != nil) {
            
            NSUInteger serviceIndex = [self.availableServices indexOfObject:service];
            
            if (serviceIndex == NSNotFound) {
                SBLogWarning(@"Successfully refreshed our current service, but it does not appear in our %llu availableServices.  This is odd.", (unsigned long long)[self.availableServices count]);
            } else {
                NSMutableArray<ZNGService *> * newAvailableServices = [self mutableArrayValueForKey:NSStringFromSelector(@selector(availableServices))];
                [newAvailableServices replaceObjectAtIndex:serviceIndex withObject:service];
            }
            
            self.service = service;
            
            for (NSString * conversationId in self->allLoadedConversationIds) {
                ZNGConversationServiceToContact * conversation = [self.conversationCache objectForKey:conversationId];
                conversation.service = service;
            }
        } else {
            SBLogError(@"Service update request returned 200 but no service object.  Help.");
        }
    } failure:^(ZNGError *error) {
        SBLogError(@"Failed to refresh current service of %@ (%@): %@", self.service.displayName, self.service.serviceId, error);
        self.mostRecentError = error;
    }];
}

- (BOOL) notificationRelevantToCurrentService:(NSNotification *)notification
{
    NSString * serviceId = notification.userInfo[@"aps"][@"service"];
    return [serviceId isEqual:self.service.serviceId];
}

- (void) notifyBecameActive:(NSNotification *)notification
{
    if (self.automaticallyUpdateServiceWhenReturningFromBackground) {
        [self updateServiceIfOldData];
    }
}

- (void) setAvailableAccounts:(NSArray<ZNGAccount *> * _Nullable)availableAccounts
{
    _availableAccounts = availableAccounts;
}

- (void) setAvailableServices:(NSArray<ZNGService *> * _Nullable)availableServices
{
    // Note: There is a distinction between a nil array (services have not been requested) and an empty array (no services are available)
    //  that we must preserve here.
    if (availableServices == nil) {
        _availableServices = nil;
        return;
    }
    
    NSMutableArray<ZNGService *> * nonTextRelayServices = [[NSMutableArray alloc] initWithCapacity:[availableServices count]];
    
    for (ZNGService * service in availableServices) {
        if (![service isTextRelay]) {
            [nonTextRelayServices addObject:service];
        }
    }
    
    _availableServices = [nonTextRelayServices sortedArrayUsingComparator:^NSComparisonResult(ZNGService * _Nonnull service1, ZNGService * _Nonnull service2) {
        return [service1.displayName compare:service2.displayName options:NSCaseInsensitiveSearch];
    }];
}

#pragma mark - Account/Service state management
- (void) updateStateForNewAccountOrService
{
    // Do we need to select an account?
    if (self.account == nil) {
        if (self.availableAccounts == nil) {
            // We have no available accounts.  Go request them.
            [self retrieveAvailableAccounts];
        } else if (self.accountChooser != nil) {
            // We have just gotten a list of available accounts.
            
            // If there is anything in the list (other than the obvious case of a single available account,) we will ask our chooser to pick one
            if ([self.availableAccounts count] != 1) {
                self.account = self.accountChooser(self.availableAccounts);
            }
            
            self.accountChooser = nil;
        }
        return;
    }
    
    // Do we need to select a service?
    if (self.service == nil) {
        if (self.availableServices == nil) {
            // We have no available services.  Go request them.
            [self retrieveAvailableServices];
        } else if (self.serviceChooser != nil) {
            // We have just gotten a list of services
            
            // If there is anything in the list (other than the obvious case of a single available service,) we will ask our chooser to pick one
            if ([self.availableServices count] != 1) {
                self.service = self.serviceChooser(self.availableServices);
            }
            
            self.serviceChooser = nil;
        }
        return;
    }
    
    // Sanity check to prevent https://fabric.io/zingle/ios/apps/com.zingleme.zingle/issues/582f5a410aeb16625b04605e
    if (self.service.serviceId == nil) {
        SBLogError(@"We have selected a service with a null service ID.  This is irrecoverable.");
        self.account = nil;
        self.service = nil;
        ZNGError * error = [[ZNGError alloc] initWithDomain:kZingleErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : @"No service ID could be found on the selected service." }];
        self.mostRecentError = error;
        return;
    }
    
    // We now have both an account and a service selected.
    
    // Do they want/need a JWT?
    if ([self.jwt length] == 0) {
        if (self.jwtClient.requestPending) {
            SBLogError(@"updateStateForNewAccountOrService was called while a JWT request is already over the wire.  Ignoring this call.");
            return;
        }
        
        // Only make a new JWT client if needed.  This also allows mocking during testing.
        NSURLComponents * desiredUrlComponents = (self.sessionManager.baseURL != nil) ? [NSURLComponents componentsWithURL:self.sessionManager.baseURL resolvingAgainstBaseURL:YES] : nil;
        NSURLComponents * currentUrlComponents = (self.jwtClient != nil) ? [NSURLComponents componentsWithURL:self.jwtClient.url resolvingAgainstBaseURL:YES] : nil;
        
        // Note that we only create a new client if `desiredUrlComponents` is non nil, but we continue on if it _is_ nil.  This
        //  allows unit testing to easily work with a mocked `ZNGJWTClient`.
        if ((desiredUrlComponents != nil) && (![currentUrlComponents.host isEqualToString:desiredUrlComponents.host])) {
            self.jwtClient = [[ZNGJWTClient alloc] initWithZingleURL:self.sessionManager.baseURL];
        }
        
        [self.jwtClient acquireJwtForUser:self.token password:self.key success:^(NSString * _Nonnull jwt) {
            SBLogInfo(@"Received a JWT.  Swapping in for basic auth.");
            self.jwt = jwt;  // This setter automatically swaps older credentials with an Authorization: Bearer header.
            [self updateStateForNewAccountOrService];
        } failure:^(NSError * _Nonnull error) {
            SBLogError(@"Unable to acquire a JWT.  Unable to login.");
        }];
        
        return;
    }
    
    [self initializeAllClients];
    
    if (self.users != nil) {
        // We already have user data.  Go ahead and signal the semaphore so it does not block us below.
        dispatch_semaphore_signal(initialUserDataSemaphore);
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDate * before = [NSDate date];
        dispatch_time_t tenSecondTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC));

        [self synchronouslyRetrieveUserData];
        
        long waitResult = dispatch_semaphore_wait(self->initialUserDataSemaphore, tenSecondTimeout);
        
        if (waitResult == 0) {
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:before];
            SBLogDebug(@"Waited %.2f seconds for user/team data on login", (float)duration);
        } else {
            SBLogError(@"Timed out waiting for user and team data on initial login.  Assignment functionality may be broken until this arrives.");
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.available = YES;
        });
    });
}

- (void) initializeAllClients
{
    NSString * serviceId = self.service.serviceId;
    
    self.automationClient = [[ZNGAutomationClient alloc] initWithSession:self serviceId:serviceId];
    self.contactClient = [[ZNGContactClient alloc] initWithSession:self serviceId:serviceId];
    dispatch_semaphore_signal(contactClientSemaphore);
    self.labelClient = [[ZNGLabelClient alloc] initWithSession:self serviceId:serviceId];
    self.eventClient = [[ZNGEventClient alloc] initWithSession:self serviceId:serviceId];
    self.messageClient = [[ZNGMessageClient alloc] initWithSession:self serviceId:serviceId];
    self.notificationSettingsClient = [[ZNGNotificationSettingsClient alloc] initWithSession:self serviceId:serviceId];
    
    // A lazy way to keep us from overwriting a mocked client in unit tests.
    // This is a bit of a code smell :(
    if (![self.userClient.accountId isEqualToString:self.account.accountId]) {
        self.userClient = [[ZNGUserClient alloc] initWithSession:self accountId:self.account.accountId];
    }
    
    self.networkLookout = [[ZNGNetworkLookout alloc] init];
    self.networkLookout.session = self;
    
    self.socketClient = [[ZNGSocketClient alloc] initWithSession:self];
    [self.socketClient connect];
    
    [self _registerForPushNotificationsForServiceIds:@[serviceId] removePreviousSubscriptions:YES];
}

- (void) setUsers:(NSArray<ZNGUser *> *)users
{
    // Sort users by online status and then first name
    NSSortDescriptor * activeStatus = [NSSortDescriptor sortDescriptorWithKey:@"isOnline" ascending:NO];
    NSSortDescriptor * firstName = [NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    
    _users = [users sortedArrayUsingDescriptors:@[activeStatus, firstName]];
    dispatch_semaphore_signal(initialUserDataSemaphore);
}

- (void) setUserAuthorization:(ZNGUserAuthorization *)userAuthorization
{
    ZNGUserSettings * oldSettings = self.userAuthorization.settings;
    
    _userAuthorization = userAuthorization;
    
    // If "show unassigned" has changed, we need to refresh the badge count
    if ([oldSettings.showUnassignedConversations boolValue] != [userAuthorization.settings.showUnassignedConversations boolValue]) {
        SBLogInfo(@"Re-calculating badge count due to a change in the user's view unassigned setting.");
        [self notifyBadgeDataChanged:nil];
    }
}

- (void) updateUserData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self synchronouslyRetrieveUserData];
    });
}

/**
 *  Retrieve ZNGUserAuthorization object.  Method returns once the request completes.
 */
- (void) synchronouslyRetrieveUserData
{
    if ([[NSThread currentThread] isMainThread]) {
        SBLogError(@"%s called on main thread.  Returning without fetching user data to prevent deadlock.", __PRETTY_FUNCTION__);
        return;
    }
    
    if (self.userAuthorizationClient == nil) {
        return;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.userAuthorizationClient userAuthorizationWithSuccess:^(ZNGUserAuthorization * theUserAuthorization, ZNGStatus *status) {
        self.userAuthorization = theUserAuthorization;
        
        [[ZNGAnalytics sharedAnalytics] trackLoginSuccessWithToken:theUserAuthorization.username andUserAuthorizationObject:theUserAuthorization];
        dispatch_semaphore_signal(semaphore);
    } failure:^(ZNGError *error) {
        SBLogError(@"Unable to retrieve current user info from the root URL: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_time_t tenSecondTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(semaphore, tenSecondTimeout);
}

- (void) notifyShowDetailedEventsPreferenceChanged:(NSNotification *)notification
{
    NSNumber * number = notification.object;
    
    if ([number isKindOfClass:[NSNumber class]]) {
        self.showDetailedEvents = [number boolValue];
    }
}

#pragma mark - Account retrieval
- (void) retrieveAvailableAccounts
{
    [self.accountClient getAccountListWithSuccess:^(NSArray *accounts, ZNGStatus *status) {
        // This is always our very first request.  If it succeeds, we can set our successful user authorization flag.
        self.userHasBeenAuthenticated = YES;
        
        if ([accounts count] == 0) {
            self.availableAccounts = @[];   // This ensures that we will set our list explicitly to an empty array instead of just nil if there is no data
        } else {
            self.availableAccounts = accounts;
        }
        
        // Clear our services since we may have just picked a new account.
        self.availableServices = nil;
        
        [self updateStateForNewAccountOrService];
    } failure:^(ZNGError *error) {
        self.availableAccounts = @[];
        self.availableServices = nil;
    }];
}

#pragma mark - Service retrieval
- (void) retrieveAvailableServices
{
    [self.serviceClient serviceListUnderAccountId:self.account.accountId success:^(NSArray *services, ZNGStatus *status) {
        if ([services count] == 0) {
            self.availableServices = @[];
        } else {
            self.availableServices = services;
        }
        
        [self updateStateForNewAccountOrService];
    } failure:^(ZNGError *error) {
        self.availableServices = @[];
    }];
}

#pragma mark - Teams
- (NSArray<ZNGTeam *> * _Nonnull) teamsVisibleToCurrentUser
{
    // Return all teams if this user has sufficient privilege
    if ([self.userAuthorization canMonitorAllTeamsOnService:self.service]) {
        return self.service.teams;
    }
    
    return [self teamsToWhichCurrentUserBelongs];
}

- (NSArray<ZNGTeam *> * _Nonnull) teamsToWhichUserBelongsWithId:(NSString * _Nonnull)userId
{
    NSPredicate * oneOfHisTeams = [NSPredicate predicateWithFormat:@"%@ IN userIds", userId];
    return [self.service.teams filteredArrayUsingPredicate:oneOfHisTeams];
}

- (NSArray<ZNGTeam *> * _Nonnull) teamsToWhichCurrentUserBelongs
{
    // We cannot return anything meaningful if we are not yet logged in
    if (self.userAuthorization == nil) {
        SBLogWarning(@"%s called before a userAuthorization object is available.  Returning empty array.", __PRETTY_FUNCTION__);
        return @[];
    }
    
    return [self teamsToWhichUserBelongsWithId:self.userAuthorization.userId];
}

#pragma mark - Users
- (NSArray<ZNGUser *> * _Nonnull) usersIncludingSelf:(BOOL)includeSelf
{
    if (includeSelf) {
        return self.users;
    }
    
    NSMutableArray<ZNGUser *> * filteredUsers = [[NSMutableArray alloc] init];
    
    for (ZNGUser * dude in self.users) {
        if (![dude.userId isEqualToString:self.userAuthorization.userId]) {
            [filteredUsers addObject:dude];
        }
    }
    
    return filteredUsers;
}

- (NSArray<ZNGUser *> * _Nonnull) usersOnCommonTeamsIncludingSelf:(BOOL)includeSelf
{
    if (![self.service allowsTeamAssignment]) {
        return @[];
    }
    
    NSArray<ZNGTeam *> * currentUserTeams = [self teamsToWhichCurrentUserBelongs];
    NSMutableArray<ZNGUser *> * filteredUsers = [[NSMutableArray alloc] init];
    
    for (ZNGUser * dude in self.users) {
        if ([dude.userId isEqualToString:self.userAuthorization.userId]) {
            // This is the current user
            if (includeSelf) {
                [filteredUsers addObject:dude];
            }
        } else {
            // This is someone else.  Do they have any of our teams in common?
            for (ZNGTeam * team in currentUserTeams) {
                if ([team.userIds containsObject:dude.userId]) {
                    [filteredUsers addObject:dude];
                    break;
                }
            }
        }
    }
    
    return filteredUsers;
}

- (ZNGUser * _Nullable) userWithId:(NSString *)userId
{
    for (ZNGUser * user in self.users) {
        if ([user.userId isEqualToString:userId]) {
            return user;
        }
    }
    
    // Just in case user data is missing/unavailable and userId corresponds to the current user, we can send
    //  that same data from our user auth.
    if ([self.userAuthorization.userId isEqualToString:userId]) {
        return self.userAuthorization;
    }
    
    return nil;
}

#pragma mark - Messaging
- (void) contactChanged:(ZNGContact *)contact
{
    NSString * contactId = contact.contactId;
    
    if ([contactId length] == 0) {
        SBLogWarning(@"%s called with no contact ID supplied.", __PRETTY_FUNCTION__);
        return;
    }
    
    ZNGConversationServiceToContact * conversation = [self.conversationCache objectForKey:contactId];
    
    if ((conversation != nil) && ([contact changedSince:conversation.contact])) {
        conversation.contact = contact;
    }
}

- (ZNGConversationServiceToContact *) conversationWithContact:(ZNGContact *)contact;
{
    // Do we have a cached version of this conversation already?
    ZNGConversationServiceToContact * conversation = [self.conversationCache objectForKey:contact.contactId];
    
    if (conversation == nil) {
        conversation = [[ZNGConversationServiceToContact alloc] initFromService:self.service
                                                                      toContact:contact
                                                              withCurrentUserId:self.userAuthorization.userId
                                                                   usingChannel:nil
                                                              withMessageClient:self.messageClient
                                                                    eventClient:self.eventClient
                                                                  contactClient:self.contactClient
                                                                   socketClient:self.socketClient];
        [allLoadedConversationIds addObject:contact.contactId];
    }
    
    // Do we need to switch from detailed events to non detailed events or vice versa?
    BOOL isDetailedEvents = ([conversation isKindOfClass:[ZNGConversationDetailedEvents class]]);
    
    if ((!self.showDetailedEvents) && (isDetailedEvents)) {
        conversation = [[ZNGConversationServiceToContact alloc] initWithConversation:conversation];
    } else if ((self.showDetailedEvents) && (!isDetailedEvents)) {
        conversation = [[ZNGConversationDetailedEvents alloc] initWithConversation:conversation];
    }
    
    // This may or may not actually have an effect, depending on if we initialized a new conversation or switched types above.q
    [self.conversationCache setObject:conversation forKey:contact.contactId];

    self.socketClient.activeConversation = conversation;
    
    [conversation loadRecentEventsErasingOlderData:NO];
    return conversation;
}

- (void) conversationWithContactId:(NSString *)contactId completion:(void (^)(ZNGConversationServiceToContact *))completion
{
    // Do we have a cached version of this conversation already?
    ZNGConversationServiceToContact * conversation = [self.conversationCache objectForKey:contactId];
    
    if (conversation != nil) {
        BOOL isDetailedEvents = [conversation isKindOfClass:[ZNGConversationDetailedEvents class]];
        BOOL correctType = (self.showDetailedEvents == isDetailedEvents);
        
        if (correctType) {
            self.socketClient.activeConversation = conversation;
            [conversation loadRecentEventsErasingOlderData:NO];
            completion(conversation);
            return;
        }
    }
    
    void (^success)(ZNGContact *, ZNGStatus *) = ^(ZNGContact *contact, ZNGStatus *status) {
        if (contact == nil) {
            SBLogWarning(@"No contact could be retrieved with the ID of %@", contactId);
            return;
        }
        
        contact.contactClient = self.contactClient;
        ZNGConversationServiceToContact * conversation = [self conversationWithContact:contact];
        completion(conversation);
    };
    
    void (^failure)(ZNGError *) = ^(ZNGError *error) {
        SBLogWarning(@"Unable to retrieve contact with ID of %@.", contactId);
        completion(nil);
    };

    // If we have a contact client, full steam ahead
    if (self.contactClient != nil) {
        [self.contactClient contactWithId:contactId success:success failure:failure];
        return;
    }
    
    // We do not yet have a contact client.  Let's hang out and wait for one.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_time_t fiveSeconds = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC));
        long semaphoreValue = dispatch_semaphore_wait(self->contactClientSemaphore, fiveSeconds);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ((semaphoreValue) || (self.contactClient == nil)) {
                SBLogWarning(@"We waited for a contact client before attempting to retrieve contact data for contact #%@, but we never got a contact client :(", contactId);
                completion(nil);
                return;
            }
            
            [self.contactClient contactWithId:contactId success:success failure:failure];
        });
    });
}

#pragma mark - UI
- (UIStoryboard *)storyboard
{
    // Lazy initializer
    if (_storyboard == nil) {
        NSBundle * bundle = [NSBundle bundleForClass:[self class]];
        _storyboard = [UIStoryboard storyboardWithName:@"ZNGConversation" bundle:bundle];
    }
    
    return _storyboard;
}

- (ZNGServiceToContactViewController *) conversationViewControllerForConversation:(ZNGConversationServiceToContact *)conversation
{
    if (conversation == nil) {
        SBLogError(@"Attempted to display view controller for a nil conversation.");
        return nil;
    }
    
    ZNGServiceToContactViewController * vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"conversation"];
    vc.conversation = conversation;
    return vc;
}

- (ZNGContactEditViewController *) contactEditViewControllerForNewContact
{
    ZNGContactEditViewController * vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"editContact"];
    vc.service = self.service;
    vc.contactClient = self.contactClient;
    return vc;
}

- (ZNGAssignmentViewController *) assignmentViewControllerForContact:(ZNGContact *)contact;
{
    ZNGAssignmentViewController * vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"assignment"];
    vc.session = self;
    vc.contact = contact;
    return vc;
}

- (void) sendMessage:(nullable NSString *)body
 imageAttachmentData:(nullable NSArray<NSData *> *)attachments
            withUUID:(nullable NSString *)uuid
          toContacts:(nullable NSArray<ZNGContact *> *)contacts
              labels:(nullable NSArray<ZNGLabel *> *)labels
              groups:(nullable NSArray<ZNGContactGroup *> *)groups
        phoneNumbers:(nullable NSArray<NSString *> *)phoneNumbers
          completion:(void (^_Nullable)(BOOL succeeded))completion;
{
    NSUInteger typeCount = MIN([contacts count], 1) + MIN([labels count], 1) + MIN([groups count], 1) + MIN([phoneNumbers count], 1);
        
    if (typeCount == 0) {
        SBLogError(@"No recipients provided to sendMessage:.  Ignoring.");
        
        if (completion != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
        
        return;
    }
    
    if ([self _freshOutgoingMessageWithUUID:uuid] == nil) {
        SBLogError(@"Unable to generate a clean outgoing message.");

        if (completion != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
        
        return;
    }
    
    // Since message PUT requires a recipient type for the entire message (contact vs. label,) we will have to send
    //  multiple messages if we have multiple recipient types.
    NSMutableArray<ZNGNewMessage *> * messages = [[NSMutableArray alloc] initWithCapacity:typeCount];
    
    if ([contacts count] > 0) {
        [messages addObject:[self _messageToContacts:contacts withUUID:uuid]];
    }
    
    if ([labels count] > 0) {
        [messages addObject:[self _messageToLabels:labels withUUID:uuid]];
    }
    
    if ([groups count] > 0) {
        [messages addObject:[self _messageToGroups:groups withUUID:uuid]];
    }
    
    if ([phoneNumbers count] > 0) {
        [messages addObject:[self _messageToPhoneNumbers:phoneNumbers withUUID:uuid]];
    }
    
    int64_t tenSeconds = 10 * NSEC_PER_SEC;
    
    // Loop through the sending of each message on a background thread, using a semaphore to wait for success between each message.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block BOOL failed = NO;

        for (ZNGNewMessage * message in messages) {
            message.body = body;
            
            for (NSData * imageData in attachments) {
                [message attachImageData:imageData withMaximumSize:CGSizeZero removingExisting:NO];
            }
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.messageClient sendMessage:message success:^(ZNGNewMessageResponse *message, ZNGStatus *status) {
                    // This one sent.  Cool.
                    dispatch_semaphore_signal(semaphore);
                } failure:^(ZNGError *error) {
                    SBLogError(@"Failed to send message: %@", error);
                
                    failed = YES;
                    dispatch_semaphore_signal(semaphore);
                }];
            });
            
            NSDate * date = [NSDate date];
            dispatch_time_t tenSecondsFromNow = dispatch_time(DISPATCH_TIME_NOW, tenSeconds);
            long returnValue = dispatch_semaphore_wait(semaphore, tenSecondsFromNow);
            
            if (returnValue != 0) {
                SBLogError(@"Timed out after %.0f seconds waiting for response from message send.", [[NSDate date] timeIntervalSinceDate:date]);
                failed = YES;
            }
            
            if (failed) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
                return;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(YES);
        });
        
        if ([contacts count] == 1) {
            [[ZNGAnalytics sharedAnalytics] trackSentMessage:body toContact:[contacts firstObject]];
        } else if ([contacts count] > 1) {
            [[ZNGAnalytics sharedAnalytics] trackSentMessage:body toMultipleContacts:contacts];
        }
        
        if ([labels count] > 0) {
            [[ZNGAnalytics sharedAnalytics] trackSentMessage:body toLabels:labels];
        }
        
        if ([groups count] > 0) {
            [[ZNGAnalytics sharedAnalytics] trackSentMessage:body toGroups:groups];
        }
        
        if ([phoneNumbers count] > 0) {
            [[ZNGAnalytics sharedAnalytics] trackSentMessage:body toPhoneNumbers:phoneNumbers];
        }
    });
}

- (ZNGNewMessage *) _freshOutgoingMessageWithUUID:(NSString *)uuid
{
    ZNGNewMessage * message = [[ZNGNewMessage alloc] init];
    
    ZNGChannelType * phoneNumberChannelType = [self.service phoneNumberChannelType];
    
    if (phoneNumberChannelType == nil) {
        SBLogError(@"Unable to send outgoing messages.  No phone number channel type exists.  This server is unhappy :(");
        return nil;
    }
    
    ZNGChannel * phoneNumberChannel = [self.service defaultPhoneNumberChannel];
    
    if (phoneNumberChannel == nil) {
        SBLogError(@"Unable to send outgoing message.  This service does not have an outgoing phone number channel configured.");
        return nil;
    }
    
    message.channelTypeIds = @[phoneNumberChannelType.channelTypeId];
    
    ZNGParticipant * sender = [[ZNGParticipant alloc] init];
    sender.participantId = self.service.serviceId;
    sender.channelValue = phoneNumberChannel.value;

    message.sender = sender;
    message.senderType = ZNGConversationParticipantTypeService;
    message.uuid = uuid;
    
    return message;
}

- (ZNGNewMessage *) _messageToContacts:(NSArray<ZNGContact *> *)contacts withUUID:(NSString *)uuid
{
    ZNGNewMessage * message = [self _freshOutgoingMessageWithUUID:uuid];
    message.recipientType = ZNGConversationParticipantTypeContact;
    
    NSMutableArray<ZNGParticipant *> * recipients = [[NSMutableArray alloc] initWithCapacity:[contacts count]];
    for (ZNGContact * contact in contacts) {
        ZNGChannel * channel = [contact phoneNumberChannel];
        
        if (channel == nil) {
            SBLogError(@"Unable to find a phone number channel for %@ (%@).", [contact fullName], contact.contactId);
            continue;
        }
        
        ZNGParticipant * recipient = [[ZNGParticipant alloc] init];
        recipient.participantId = contact.contactId;
        recipient.channelValue = channel.value;
        
        [recipients addObject:recipient];
    }
    
    message.recipients = recipients;
    return message;
}

- (ZNGNewMessage *) _messageToLabels:(NSArray<ZNGLabel *> *)labels withUUID:(NSString *)uuid
{
    ZNGNewMessage * message = [self _freshOutgoingMessageWithUUID:uuid];
    message.recipientType = ZNGConversationParticipantTypeLabel;
    
    NSMutableArray<ZNGParticipant *> * recipients = [[NSMutableArray alloc] initWithCapacity:[labels count]];
    for (ZNGLabel * label in labels) {
        ZNGParticipant * recipient = [[ZNGParticipant alloc] init];
        recipient.participantId = label.labelId;
        [recipients addObject:recipient];
    }
    
    message.recipients = recipients;
    return message;
}

- (ZNGNewMessage *) _messageToGroups:(NSArray<ZNGContactGroup *> *)groups withUUID:(NSString *)uuid
{
    ZNGNewMessage * message = [self _freshOutgoingMessageWithUUID:uuid];
    message.recipientType = ZNGConversationParticipantTypeGroup;
    
    NSMutableArray<ZNGParticipant *> * recipients = [[NSMutableArray alloc] initWithCapacity:[groups count]];
    
    for (ZNGContactGroup * group in groups) {
        ZNGParticipant * recipient = [[ZNGParticipant alloc] init];
        recipient.participantId = group.groupId;
        [recipients addObject:recipient];
    }
    
    message.recipients = recipients;
    return message;
}

- (ZNGNewMessage *) _messageToPhoneNumbers:(NSArray<NSString *> *)phoneNumbers withUUID:(NSString *)uuid
{
    ZNGNewMessage * message = [self _freshOutgoingMessageWithUUID:uuid];
    message.recipientType = ZNGConversationParticipantTypeContact;
    
    NSMutableArray<ZNGParticipant *> * recipients = [[NSMutableArray alloc] initWithCapacity:[phoneNumbers count]];
    for (NSString * phoneNumber in phoneNumbers) {
        ZNGParticipant * recipient = [[ZNGParticipant alloc] init];
        recipient.channelValue = phoneNumber;
        [recipients addObject:recipient];
    }
    
    message.recipients = recipients;
    return message;
}

@end
