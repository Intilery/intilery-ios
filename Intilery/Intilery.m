#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#include <arpa/inet.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/socket.h>
#include <sys/sysctl.h>

#import "Intilery.h"
#import "MPLogger.h"
#import "MPFoundation.h"

#define VERSION @"0.0.5"
#define INTILERY_URL @"https://www.intilery-analytics.com"


@interface Intilery ()

{
    NSUInteger _flushInterval;
}

// re-declare internally as readwrite
@property (atomic, copy) NSString *distinctId;

@property (nonatomic, copy) NSString *apiToken;
@property (nonatomic, copy) NSString *appName;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic) NSTimeInterval networkRequestsAllowedAfterTime;
@property (nonatomic) NSUInteger networkConsecutiveFailures;

@end

@implementation Intilery

static Intilery *sharedInstance = nil;
+ (Intilery *)sharedInstanceWithToken:(NSString *)appName withToken:(NSString *)apiToken withLaunchOptions:(NSDictionary *)launchOptions withIntileryURL:(NSString *)intileryURL
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
#if defined(DEBUG)
        const NSUInteger flushInterval = 1;
#else
        const NSUInteger flushInterval = 60;
#endif
        
        sharedInstance = [[super alloc] initWithToken:appName withToken:apiToken withLaunchOptions:launchOptions andFlushInterval:flushInterval withIntileryURL:intileryURL];
    });
    return sharedInstance;
}

+ (Intilery *)sharedInstanceWithToken:(NSString *)appName withToken:(NSString *)apiToken
{
    return [Intilery sharedInstanceWithToken:appName withToken:apiToken withIntileryURL:INTILERY_URL];
}


+ (Intilery *)sharedInstanceWithToken:(NSString *)appName withToken:(NSString *)apiToken withIntileryURL:(NSString *)intileryURL
{
    return [Intilery sharedInstanceWithToken:appName withToken:apiToken withLaunchOptions:nil withIntileryURL:intileryURL];
}


+ (Intilery *)sharedInstanceWithToken:(NSString *)appName withToken:(NSString *)apiToken withLaunchOptions:(NSDictionary *)launchOptions
{
    return [Intilery sharedInstanceWithToken:appName withToken:apiToken withLaunchOptions:launchOptions withIntileryURL:INTILERY_URL];
}

+ (Intilery *)sharedInstance
{
    if (sharedInstance == nil) {
        IntileryDebug(@"warning sharedInstance called before sharedInstanceWithToken:");
    }
    return sharedInstance;
}

- (instancetype)initWithToken:(NSString *)appName withToken:(NSString *)apiToken withLaunchOptions:(NSDictionary *)launchOptions andFlushInterval:(NSUInteger)flushInterval withIntileryURL:(NSString *)intileryURL
{
    if (apiToken == nil) {
        apiToken = @"";
    }
    if ([apiToken length] == 0) {
        IntileryDebug(@"%@ warning empty api token", self);
    }
    if (self = [self init]) {
        self.networkRequestsAllowedAfterTime = 0;
        self.apiToken = apiToken;
        self.appName = appName;
        _flushInterval = flushInterval;
        self.showNetworkActivityIndicator = YES;
        self.useIPAddressForGeoLocation = YES;
        
        self.serverURL = intileryURL;
        
        self.distinctId = [self defaultDistinctId];
        self.eventsQueue = [NSMutableArray array];
        
        NSString *label = [NSString stringWithFormat:@"com.intilery.%@.%p", apiToken, (void *)self];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB_POSIX"]];
        
        [self unarchive];
        
        if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
            [self trackPushNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] withEvent:@"App Open"];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Encoding/decoding utilities


- (NSData *)JSONSerializeObject:(id)obj
{
    id coercedObj = [self JSONSerializableObjectForObject:obj];
    NSError *error = nil;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:coercedObj options:(NSJSONWritingOptions)0 error:&error];
    }
    @catch (NSException *exception) {
        IntileryError(@"%@ exception encoding api data: %@", self, exception);
    }
    if (error) {
        IntileryError(@"%@ error encoding api data: %@", self, error);
    }
    return data;
}

- (id)JSONSerializableObjectForObject:(id)obj
{
    // valid json types
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    // recurse on containers
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *a = [NSMutableArray array];
        for (id i in obj) {
            [a addObject:[self JSONSerializableObjectForObject:i]];
        }
        return [NSArray arrayWithArray:a];
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *stringKey;
            if (![key isKindOfClass:[NSString class]]) {
                stringKey = [key description];
                IntileryDebug(@"%@ warning: property keys should be strings. got: %@. coercing to: %@", self, [key class], stringKey);
            } else {
                stringKey = [NSString stringWithString:key];
            }
            id v = [self JSONSerializableObjectForObject:obj[key]];
            d[stringKey] = v;
        }
        return [NSDictionary dictionaryWithDictionary:d];
    }
    // some common cases
    if ([obj isKindOfClass:[NSDate class]]) {
        return [self.dateFormatter stringFromDate:obj];
    } else if ([obj isKindOfClass:[NSURL class]]) {
        return [obj absoluteString];
    }
    // default to sending the object's description
    NSString *s = [obj description];
    IntileryDebug(@"%@ warning: property values should be valid json types. got: %@. coercing to: %@", self, [obj class], s);
    return s;
}

- (NSString *)encodeAPIData:(NSArray *)array
{
    if ([array count] == 1) {
        NSData *data = [self JSONSerializeObject:[array firstObject]];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        NSData *data = [self JSONSerializeObject:array];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
}

#pragma mark - Tracking

+ (void)assertPropertyTypes:(NSDictionary *)properties
{
    for (id __unused k in properties) {
        NSAssert([k isKindOfClass: [NSString class]], @"%@ property keys must be NSString. got: %@ %@", self, [k class], k);
        // would be convenient to do: id v = [properties objectForKey:k]; but
        // when the NSAssert's are stripped out in release, it becomes an
        // unused variable error. also, note that @YES and @NO pass as
        // instances of NSNumber class.
        NSAssert([properties[k] isKindOfClass:[NSString class]] ||
                 [properties[k] isKindOfClass:[NSNumber class]] ||
                 [properties[k] isKindOfClass:[NSNull class]] ||
                 [properties[k] isKindOfClass:[NSArray class]] ||
                 [properties[k] isKindOfClass:[NSDictionary class]] ||
                 [properties[k] isKindOfClass:[NSDate class]] ||
                 [properties[k] isKindOfClass:[NSURL class]],
                 @"%@ property values must be NSString, NSNumber, NSNull, NSArray, NSDictionary, NSDate or NSURL. got: %@ %@", self, [properties[k] class], properties[k]);
    }
}

- (NSString *)defaultDistinctId
{
    NSString *distinctId = [self IFA];
    
    if (!distinctId && NSClassFromString(@"UIDevice")) {
        distinctId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    if (!distinctId) {
        IntileryDebug(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [[NSUUID UUID] UUIDString];
    }
    return distinctId;
}


- (void)identify:(NSString *)distinctId
{
    if (distinctId == nil || distinctId.length == 0) {
        IntileryDebug(@"%@ cannot identify blank distinct id: %@", self, distinctId);
        return;
    }
    
    dispatch_async(self.serialQueue, ^{
        self.distinctId = distinctId;
    });
}

- (void)track:(NSString *)event
{
    [self track:event properties:nil withName:event];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{
    [self track:event properties:properties withName:event];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties withName:(NSString *)eventName
{
    if (event == nil || [event length] == 0) {
        IntileryError(@"%@ intilery track called with empty event parameter. using '_event'", self);
        event = @"_event";
    }
    
    if (eventName == nil || [eventName length] == 0) {
        eventName = event;
    }
    
    properties = [properties copy];
    [Intilery assertPropertyTypes:properties];
    
    NSTimeInterval epochInterval = [[NSDate date] timeIntervalSince1970];
    NSNumber *epochSeconds = @(round(epochInterval));
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *p = [NSMutableDictionary dictionary];
        if (properties) {
            [p addEntriesFromDictionary:properties];
        }
        
        NSDictionary *e = @{ @"Visit" : @{@"VisitorID":self.distinctId},
                             @"EventAction": event, @"EventName": eventName,
                             @"UserAgent": self.appName, @"HappenedAt": epochSeconds,
                             @"EventData": [NSDictionary dictionaryWithDictionary:p]} ;
        
        IntileryDebug(@"%@ queueing event: %@", self, e);
        [self.eventsQueue addObject:e];
        if ([self.eventsQueue count] > 5000) {
            [self.eventsQueue removeObjectAtIndex:0];
        }
        
        // Always archive
        [self archiveEvents];
    });
    [self flush];
}

- (void)setVisitorProperties:(NSDictionary *)properties {
    [self setVisitorProperties:properties withFunction:nil];
}

- (void)setVisitorProperties:(NSDictionary *)properties withFunction:(NSString *)eventFunction
{
    NSMutableDictionary *vp = [NSMutableDictionary dictionary];
    if (properties) {
        for (NSString *key in properties) {
            NSString *value = [properties objectForKey:key];
            [vp setObject:value forKey:[NSString stringWithFormat:@"Visitor.%@", key]];
        }
    }
    
    if (eventFunction) {
        [vp setObject:eventFunction forKey:@"Visitor._eventFunction"];
    }
    
    [self track:@"Set Visitor Property" properties:vp];
}

- (void)getVisitorProperties:(NSArray *)properties callback:(void (^)(NSDictionary *))handler
{
    NSMutableArray *encodedProperties = [[NSMutableArray alloc] init];
    [properties enumerateObjectsUsingBlock:^(NSString *object, NSUInteger idx, BOOL *stop) {
        [encodedProperties addObject:[object stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
    }];
    
    NSString *endpoint = [NSString stringWithFormat:@"/api/visitor/%@/properties?properties=%@", self.distinctId,
                          [encodedProperties componentsJoinedByString:@","]];
    
    NSURL *URL = [NSURL URLWithString:[self.serverURL stringByAppendingString:endpoint] ];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:[NSString stringWithFormat:@"Basic %@", self.apiToken] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];
    
    dispatch_async(self.serialQueue, ^{
        NSError *error = nil;
        NSHTTPURLResponse *urlResponse = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
        
        BOOL success = [self handleNetworkResponse:urlResponse withError:error];
        if (error || !success) {
            IntileryError(@"%@ network failure: %@", self, error);
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {handler(json);});
        }
    });
}


- (void)trackPushNotification:(NSDictionary *)userInfo withEvent:(NSString *)event
{
    if (userInfo && userInfo[@"it"]) {
        NSDictionary *payload = userInfo[@"it"];
        if ([payload isKindOfClass:[NSDictionary class]] && payload[@"id"]) {
            [self track:event properties:@{@"_Push.ID":payload[@"id"]}];
        }
    }
}

- (void)trackPushNotification:(NSDictionary *)userInfo
{
    [self trackPushNotification:userInfo withEvent:@"push open"];
}


- (void)reset
{
    dispatch_async(self.serialQueue, ^{
        self.distinctId = [self defaultDistinctId];
        self.eventsQueue = [NSMutableArray array];
        [self archive];
    });
}

#pragma mark - Network control

- (NSUInteger)flushInterval
{
    @synchronized(self) {
        return _flushInterval;
    }
}

- (void)setFlushInterval:(NSUInteger)interval
{
    @synchronized(self) {
        _flushInterval = interval;
    }
    [self flush];
    [self startFlushTimer];
}

- (void)startFlushTimer
{
    [self stopFlushTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.flushInterval > 0) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.flushInterval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
            IntileryDebug(@"%@ started flush timer: %@", self, self.timer);
        }
    });
}

- (void)stopFlushTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
            IntileryDebug(@"%@ stopped flush timer: %@", self, self.timer);
        }
        self.timer = nil;
    });
}

- (void)flush
{
    [self flushWithCompletion:nil];
}

- (void)flushWithCompletion:(void (^)())handler
{
    dispatch_async(self.serialQueue, ^{
        IntileryDebug(@"%@ flush starting", self);
        
        __strong id<IntileryDelegate> strongDelegate = self.delegate;
        if (strongDelegate && [strongDelegate respondsToSelector:@selector(intileryWillFlush:)]) {
            if (![strongDelegate intileryWillFlush:self]) {
                IntileryDebug(@"%@ flush deferred by delegate", self);
                return;
            }
        }
        
        [self flushEvents];
        [self archive];
        
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), handler);
        }
        
        IntileryDebug(@"%@ flush complete", self);
    });
}

- (void)flushEvents
{
    [self flushQueue:_eventsQueue
            endpoint:@"/api/event"];
}


- (void)flushQueue:(NSMutableArray *)queue endpoint:(NSString *)endpoint
{
    if ([[NSDate date] timeIntervalSince1970] < self.networkRequestsAllowedAfterTime) {
        IntileryDebug(@"Attempted to flush to %@, when we still have a timeout. Ignoring flush.", endpoint);
        return;
    }
    
    while ([queue count] > 0) {
        NSUInteger batchSize = 1; // TODO no batching of events for now... ([queue count] > 50) ? 50 : [queue count];
        NSArray *batch = [queue subarrayWithRange:NSMakeRange(0, batchSize)];
        
        NSString *postBody = [self encodeAPIData:batch];
        IntileryDebug(@"%@ flushing %lu of %lu to %@: %@", self, (unsigned long)[batch count], (unsigned long)[queue count], endpoint, queue);
        NSURLRequest *request = [self apiRequestWithEndpoint:endpoint andBody:postBody];
        NSError *error = nil;
        
        NSHTTPURLResponse *urlResponse = nil;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
        
        BOOL success = [self handleNetworkResponse:urlResponse withError:error];
        if (error || !success) {
            IntileryError(@"%@ network failure: %@", self, error);
            break;
        }
        
        [queue removeObjectsInArray:batch];
    }
}

- (NSURLRequest *)apiRequestWithEndpoint:(NSString *)endpoint andBody:(NSString *)body
{
    NSURL *URL = [NSURL URLWithString:[self.serverURL stringByAppendingString:endpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"Basic %@", self.apiToken] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    IntileryDebug(@"%@ http request: %@?%@", self, URL, body);
    return request;
}

- (BOOL)handleNetworkResponse:(NSHTTPURLResponse *)response withError:(NSError *)error
{
    BOOL success = NO;
    NSTimeInterval retryTime = [response.allHeaderFields[@"Retry-After"] doubleValue];
    
    IntileryDebug(@"HTTP Response: %@", response.allHeaderFields);
    IntileryDebug(@"HTTP Error: %@", error.localizedDescription);
    
    BOOL was5XX = (500 <= response.statusCode && response.statusCode <= 599) || (error != nil);
    if (was5XX) {
        self.networkConsecutiveFailures++;
    } else {
        success = YES;
        self.networkConsecutiveFailures = 0;
    }
    
    IntileryDebug(@"Consecutive network failures: %lu", self.networkConsecutiveFailures);
    
    if (self.networkConsecutiveFailures > 1) {
        // Exponential backoff
        retryTime = MAX(retryTime, [self retryBackOffTimeWithConsecutiveFailures:self.networkConsecutiveFailures]);
    }
    
    NSDate *retryDate = [NSDate dateWithTimeIntervalSinceNow:retryTime];
    self.networkRequestsAllowedAfterTime = [retryDate timeIntervalSince1970];
    
    IntileryDebug(@"Retry backoff time: %.2f - %@", retryTime, retryDate);
    
    return success;
}

- (NSTimeInterval)retryBackOffTimeWithConsecutiveFailures:(NSUInteger)failureCount
{
    NSTimeInterval time = pow(2.0, failureCount - 1) * 60 + arc4random_uniform(30);
    return MIN(MAX(60, time), 600);
}

#pragma mark - Persistence
- (NSString *)filePathFor:(NSString *)data
{
    NSString *filename = [NSString stringWithFormat:@"intilery-%@-%@.plist", self.apiToken, data];
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
}

- (NSString *)eventsFilePath
{
    return [self filePathFor:@"events"];
}

- (void)archive
{
    [self archiveEvents];
}

- (void)archiveEvents
{
    NSString *filePath = [self eventsFilePath];
    NSMutableArray *eventsQueueCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
    IntileryDebug(@"%@ archiving events data to %@: %@", self, filePath, eventsQueueCopy);
    if (![NSKeyedArchiver archiveRootObject:eventsQueueCopy toFile:filePath]) {
        IntileryError(@"%@ unable to archive events data", self);
    }
}

- (void)unarchive
{
    [self unarchiveEvents];
}

- (id)unarchiveFromFile:(NSString *)filePath
{
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        IntileryDebug(@"%@ unarchived data from %@: %@", self, filePath, unarchivedData);
    }
    @catch (NSException *exception) {
        IntileryError(@"%@ unable to unarchive data in %@, starting fresh", self, filePath);
        // Reset un archived data
        unarchivedData = nil;
        // Remove the (possibly) corrupt data from the disk
        NSError *error = NULL;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!removed) {
            IntileryError(@"%@ unable to remove archived file at %@ - %@", self, filePath, error);
        }
    }
    return unarchivedData;
}

- (void)unarchiveEvents
{
    self.eventsQueue = (NSMutableArray *)[self unarchiveFromFile:[self eventsFilePath]];
    if (!self.eventsQueue) {
        self.eventsQueue = [NSMutableArray array];
    }
}

#pragma mark - Application Helpers

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Intilery: %p %@>", (void *)self, self.apiToken];
}

- (NSString *)deviceModel
{
    NSString *results = nil;
    @try {
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char answer[size];
        sysctlbyname("hw.machine", answer, &size, NULL, 0);
        results = @(answer);
    }
    @catch (NSException *exception) {
        IntileryError(@"Failed fetch hw.machine from sysctl. Details: %@", exception);
    }
    return results;
}

- (NSString *)IFA
{
    NSString *ifa = nil;
#if !defined(INTILERY_NO_IFA)
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        ifa = [uuid UUIDString];
    }
#endif
    return ifa;
}

- (NSString *)libVersion
{
    return [Intilery libVersion];
}

+ (NSString *)libVersion
{
    return VERSION;
}

- (void)addPushDeviceToken:(NSData *)deviceToken
{
    const unsigned char *buffer = (const unsigned char *)[deviceToken bytes];
    if (!buffer) {
        return;
    }
    NSMutableString *hex = [NSMutableString stringWithCapacity:(deviceToken.length * 2)];
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [hex appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)buffer[i]]];
    }
    //NSArray *tokens = @[[NSString stringWithString:hex]];
    NSString *token = [NSString stringWithString:hex];
    NSDictionary *properties = @{@"Register App.appCode": self.appName,
                                 @"Register App.deviceID": token};
    [self track:@"Set Device ID" properties:properties];
}

@end

