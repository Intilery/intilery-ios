#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol IntileryDelegate;

NS_ASSUME_NONNULL_BEGIN

/*!
 @class
 Intilery API.
 
 @abstract
 The primary interface for integrating Intilery with your app.
 
 @discussion
 Use the Intilery class to set up your project and track events in Intilery
 Engagement.
 
 <pre>
 // Initialize the API
 Intilery *intilery = [Intilery sharedInstanceWithToken:@"YOUR APP NAME" withToken:@"YOUR API TOKEN"];
 
 // Track an event in Intilery Engagement
 [intilery track:@"event action" properties:@{@"Entity.Property":@"Value"} withName:@"Event Name" withPath:@"Page Path"];
 
 </pre>
 
 For more advanced usage, please see the <a
 href="https://docs.intilery-analytics.com">Intilery Documenation</a>.
 */
@interface Intilery : NSObject

#pragma mark Properties

/*!
 @property
 
 @abstract
 The distinct ID of the current user.
 
 @discussion
 A distinct ID is a string that uniquely identifies one of your users.
 Typically, this is the user ID from your database.
 */
@property (atomic, readonly, copy) NSString *distinctId;


/*!
 @property
 
 @abstract
 The base URL used for Intilery API requests.
 
 @discussion
 Useful if you need to proxy Intilery requests. Defaults to
 https://www.intilery-analytics.com
 */
@property (atomic, copy) NSString *serverURL;

/*!
 @property
 
 @abstract
 Flush timer's interval.
 
 @discussion
 Setting a flush interval of 0 will turn off the flush timer.
 */
@property (atomic) NSUInteger flushInterval;


/*!
 @property
 
 @abstract
 Controls whether to show spinning network activity indicator when flushing
 data to the Intilery servers.
 
 @discussion
 Defaults to YES.
 */
@property (atomic) BOOL showNetworkActivityIndicator;

/*!
 @property
 
 @abstract
 Controls whether to automatically send the client IP Address as part of
 event tracking. With an IP address, geo-location is possible down to neighborhoods
 within a city, although the Intilery Dashboard will just show you city level location
 specificity. For privacy reasons, you may be in a situation where you need to forego
 effectively having access to such granular location information via the IP Address.
 
 @discussion
 Defaults to YES.
 */
@property (atomic) BOOL useIPAddressForGeoLocation;

/*!
 @property
 
 @abstract
 The IntileryDelegate object that can be used to assert fine-grain control
 over Intilery network activity.
 
 @discussion
 Using a delegate is optional. See the documentation for IntileryDelegate
 below for more information.
 */
@property (atomic, weak) id<IntileryDelegate> delegate; // allows fine grain control over uploading (optional)

#pragma mark Tracking

/*!
 @method
 
 @abstract
 Initializes and returns a singleton instance of the API.
 
 @discussion
 If you are only going to send data to a single Intilery project from your app,
 as is the common case, then this is the easiest way to use the API. This
 method will set up a singleton instance of the <code>Intilery</code> class for
 you using the given project token. When you want to make calls to Intilery
 elsewhere in your code, you can use <code>sharedInstance</code>.
 
 <pre>
 [[Intilery sharedInstance] track:@"Something Happened"]];
 </pre>
 
 If you are going to use this singleton approach,
 <code>sharedInstanceWithToken:</code> <b>must be the first call</b> to the
 <code>Intilery</code> class, since it performs important initializations to
 the API.
 
 @param appName          your app name
 @param apiToken        your project token
 */

+ (Intilery *)sharedInstanceWithToken:(NSString *)appName withToken:(NSString *)apiToken;

+ (Intilery *)sharedInstanceWithToken:(NSString *)appName withToken:(NSString *)apiToken withIntileryURL:(NSString *)intileryURL;

/*!
 @method
 
 @abstract
 Initializes a singleton instance of the API, uses it to track launchOptions information,
 and then returns it.
 
 @discussion
 This is the preferred method for creating a sharedInstance with a intilery
 like above. With the launchOptions parameter, Intilery can track referral
 information created by push notifications.
 
 @param appName         your app name
 @param apiToken        your project token
 @param launchOptions   your application delegate's launchOptions
 
 */
+ (Intilery *)sharedInstanceWithToken:(NSString *)appName withToken:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions;

+ (Intilery *)sharedInstanceWithToken:(NSString *)appName withToken:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions withIntileryURL:(NSString *)intileryURL;

/*!
 @method
 
 @abstract
 Returns the previously instantiated singleton instance of the API.
 
 @discussion
 The API must be initialized with <code>sharedInstanceWithToken:</code> before
 calling this class method.
 */
+ (Intilery *)sharedInstance;

/*!
 @method
 
 @abstract
 Initializes an instance of the API with the given project token.
 
 @discussion
 Returns the a new API object. This allows you to create more than one instance
 of the API object, which is convenient if you'd like to send data to more than
 one Intilery project from a single app. If you only need to send data to one
 project, consider using <code>sharedInstanceWithToken:</code>.
 
 @param appName         your app name
 @param apiToken        your project token
 @param launchOptions   optional app delegate launchOptions
 @param flushInterval   interval to run background flushing
 */
- (instancetype)initWithToken:(NSString *)appName withToken:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions andFlushInterval:(NSUInteger)flushInterval withIntileryURL:(NSString *)intileryURL;

/*!
 @property
 
 @abstract
 Sets the distinct ID of the current user.
 
 @discussion
 Intilery will choose a default distinct ID based on
 whether you are using the AdSupport.framework or not.
 
 If you are not using the AdSupport Framework (iAds), then we use the
 <code>[UIDevice currentDevice].identifierForVendor</code> (IFV) string as the
 default distinct ID.  This ID will identify a user across all apps by the same
 vendor, but cannot be used to link the same user across apps from different
 vendors.
 
 If you are showing iAds in your application, you are allowed use the iOS ID
 for Advertising (IFA) to identify users. If you have this framework in your
 app, Intilery will use the IFA as the default distinct ID. If you have
 AdSupport installed but still don't want to use the IFA, you can define the
 <code>INTILERY_NO_IFA</code> preprocessor flag in your build settings, and
 Intilery will use the IFV as the default distinct ID.
 
 If we are unable to get an IFA or IFV, we will fall back to generating a
 random persistent UUID.
 
 @param distinctId string that uniquely identifies the current user
 */
- (void)identify:(NSString *)distinctId;

/*!
 @method
 
 @abstract
 Tracks an event.
 
 @param event           event action
 */
- (void)track:(NSString *)event;

/*!
 @method
 
 @abstract
 Tracks an event with properties.
 
 @discussion
 Properties will allow you to pass entity.property data with your events.
 Property keys must be <code>NSString</code> objects and values must be
 <code>NSString</code>, <code>NSNumber</code>, <code>NSNull</code>,
 <code>NSArray</code>, <code>NSDictionary</code>, <code>NSDate</code> or
 <code>NSURL</code> objects.
 
 @param event           event action
 @param properties      properties dictionary
 @param eventName       event name
 @param path            path
 */

- (void)track:(NSString *)event properties:(nullable NSDictionary *)properties withName:(NSString *)eventName withPath:(NSString *)path;

- (void)track:(NSString *)event properties:(nullable NSDictionary *)properties withPath:(NSString *)path;

- (void)track:(NSString *)event properties:(nullable NSDictionary *)properties withName:(NSString *)eventName;

- (void)track:(NSString *)event properties:(nullable NSDictionary *)properties;

- (void)track:(NSString *)event withPath:(NSString *)path;
/*!
 @method
 
 @abstract
 Sets visitor/customer properties.
 
 @param properties     visitor properties
 @param eventFunction  name of update function to apply with event
 */
- (void)setVisitorProperties:(NSDictionary *)properties withFunction:(nullable NSString *)eventFunction;

/*!
 @method
 
 @abstract
 Sets visitor/customer properties.
 
 @param properties     visitor properties
 */
- (void)setVisitorProperties:(NSDictionary *)properties;

/*!
 @method
 
 @abstract
 Gets visitor/customer properties.
 
 @param properties      Array of properties to return
 @param handler         Block with which to process the returned properties
 */
- (void)getVisitorProperties:(NSArray *)properties callback:(void (^)(NSDictionary *))handler;

/*!
 @method
 
 @abstract
 Track a push notification using its payload sent from Intilery.
 
 @param userInfo         remote notification payload dictionary
 */
- (void)trackPushNotification:(NSDictionary *)userInfo;


/*!
 @method
 
 @abstract
 Track a push notification using its payload sent from Intilery.
 
 @param userInfo         remote notification payload dictionary
 @param link             link the user selected from the payload
 */
- (void)trackPushNotification:(NSDictionary *)userInfo link:(NSString*)link;


/*!
 @method
 
 @abstract
 Uploads queued data to the Intilery server.
 
 @discussion
 By default, queued data is flushed to the Intilery servers every minute (the
 default for <code>flushInterval</code>), and on background (since
 <code>flushOnBackground</code> is on by default). You only need to call this
 method manually if you want to force a flush at a particular moment.
 */
- (void)flush;

/*!
 @method
 
 @abstract
 Calls flush, then optionally archives and calls a handler when finished.
 
 @discussion
 When calling <code>flush</code> manually, it is sometimes important to verify
 that the flush has finished before further action is taken. This is
 especially important when the app is in the background and could be suspended
 at any time if protocol is not followed. Delegate methods like
 <code>application:didReceiveRemoteNotification:fetchCompletionHandler:</code>
 are called when an app is brought to the background and require a handler to
 be called when it finishes.
 */
- (void)flushWithCompletion:(nullable void (^)())handler;

/*!
 @method
 
 @abstract
 Writes current project info, including distinct ID, and pending event
 record queues to disk.
 
 @discussion
 This state will be recovered when the app is launched again if the Intilery
 library is initialized with the same project token. <b>You do not need to call
 this method</b>. The library listens for app state changes and handles
 persisting data as needed. It can be useful in some special circumstances,
 though, for example, if you'd like to track app crashes from main.m.
 */
- (void)archive;

- (NSString *)libVersion;
+ (NSString *)libVersion;



/*!
 @method
 
 @abstract
 Register the given device to receive push notifications.
 
 @discussion
 This will associate the device token with the current customer,
 which will allow you to send push notifications to the user from the Intilery
 web interface. You should call this method with the <code>NSData</code>
 token passed to
 <code>application:didRegisterForRemoteNotificationsWithDeviceToken:</code>.

 @param deviceToken     device token as returned <code>application:didRegisterForRemoteNotificationsWithDeviceToken:</code>
 */
- (void)addPushDeviceToken:(NSData *)deviceToken;

/*!
 @method
 
 @abstract
 Unregister the given device to track push notification unsubscribes.
 
 @discussion
 This will disassociate the device token with the current customer,
 which will prevent the sending of further push notifications to the device.
 */
- (void)removePushDeviceToken;

@end

/*!
 @protocol
 
 @abstract
 Delegate protocol for controlling the Intilery API's network behavior.
 
 @discussion
 Creating a delegate for the Intilery object is entirely optional. It is only
 necessary when you want full control over when data is uploaded to the server,
 beyond simply calling stop: and start: before and after a particular block of
 your code.
 */
@protocol IntileryDelegate <NSObject>
@optional

/*!
 @method
 
 @abstract
 Asks the delegate if data should be uploaded to the server.
 
 @discussion
 Return YES to upload now, NO to defer until later.
 
 @param intilery        Intilery API instance
 */
- (BOOL)intileryWillFlush:(Intilery *)intilery;

@end
NS_ASSUME_NONNULL_END
