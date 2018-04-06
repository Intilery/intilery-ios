# Integrating Events into your App

For a working example of how to integrate, look [here](https://github.com/Intilery/intilery-ios-example)

## Initialisation

From your application configuration in the Intilery Console, you should be able to get the following information and add it to the `AppDelegate.m`
```
#define INTILERY_APP @"<your app name>"
#define INTILERY_TOKEN @"<your app token>"
#define INTILERY_API_HOST @"<api to call if not the default>"  // only needed if you have a custom install of the Intilery Marketing Cloud
```

Import `Intilery.h` into your `AppDelegate.m` and add the following lines of code:

If you are on the standard Intilery Marketing Cloud:
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [Intilery sharedInstanceWithToken:INTILERY_APP withToken:INTILERY_TOKEN;
    return YES;    
}
```

If you are an enterprise user with your own installation:
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [Intilery sharedInstanceWithToken:INTILERY_APP withToken:INTILERY_TOKEN withIntileryURL:INTILERY_API_HOST];
    return YES;    
}
```

## Event Tracking

To track an event, with the `Intilery.h` included in the `ViewController` and the initialisation done as above,
you pass a dictionary of `Entity.Property` `Value` to the track method. If you don't pass an `event name`, the
name matches the `event action`.

```ObjectiveC
    Intilery *intilery = [Intilery sharedInstance];
    [intilery track:@"<event action>" properties:@{@"<Entity>.<Property>":@"<Value>"} withName:@"<event name>"];
```

## Register for Push Notifications

To associate the visitor with a token to use with push notifications you first of all need to generate a token.
See the example [AppDelegate.m](EXAMPLE.md).

Once you have the token you can register the device to receive push messages
```ObjectiveC
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[Intilery sharedInstance] addPushDeviceToken:deviceToken];
}
```

## Tracking Events
```ObjectiveC
[[Intilery sharedInstance] track:@"<event action>" properties:@{@"<Entity>.<Property>":@"<Value>"} withName:@"<event name>"]
```

Where `event data` is a map containing `key : value` pairs where each `key` is a `entity.property`.


### Tracking Actions from Push Notifications
When a push notification triggers an action in an application we have some standard events defined that can be used to 
track the interactions. Due to legacy reasons the event data that is passed uses `_email` as the `entity`.

Each push notication comes with an `it.id` as part of the meta data that uniquely identifies that push notifcation.

For an iOS application, you can handle the receipt of a push notification when the app is in the foreground, or
if the app is in the background you only get a notifcation if the user uses the push to open the app.

Use the examples below in the `AppDelegate.m`

#### Handling a notification when the app is in the foreground
Send a `_push view` event:

```ObjectiveC
//Called when a notification is delivered to a foreground app.
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    NSLog(@"Foreground User Info : %@",notification.request.content.userInfo);
    completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
    
    NSString *value = notification.request.content.userInfo[@"it"][@"id"];
    [[Intilery sharedInstance] track:@"push view" properties:@{@"_Email.Reference":value}];
 }
```

If you do not want to differentiate between the app being open or in the background, it is recommended to only use the `_push open` event action.

#### Handling a notification when the app is in the background
Send a `_push open` event:

```ObjectiveC
//Called to let your app know which action was selected by the user for a given notification.
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
    NSLog(@"Background User Info : %@",response.notification.request.content.userInfo);
    completionHandler();
    
    NSString *value = response.notification.request.content.userInfo[@"it"][@"id"];
    [[Intilery sharedInstance] track:@"push open" properties:@{@"_Email.Reference":value}];
}
```

If a specific link/click action was used, then you can specify the link by passing the link value in an `_Email.Link` property.


## Set Visitor Properties
```ObjectiveC
[[Intilery sharedInstance] setVisitorProperties:@{@"key":@"value"}];
```

Where `visitor data` is a map containing `key : value` pairs where each `key` is a visitor or customer `property`.

e.g.
```ObjectiveC
[[Intilery sharedInstance] setVisitorProperties:@{@"Favourite Colour": [self.colour text], @"Favourite Film": [self.film text]}];
```

If you are interacting with a visitor function, pass the name of the function too:
```ObjectiveC
[[Intilery sharedInstance] setVisitorProperties:@{@"key":@"value"} withFunction:@"functionName"];
```

## Get Visitor Properties
```ObjectiveC
[[Intilery sharedInstance] getVisitorProperties:@[@"property"] callback:^(NSDictionary * properties) {}];
```

Where `property list` is a list of visitor properties, and you pass a block to execute on the result.

The resulting dictionary is a Dictionary containing each property asked for with a dictionary containing `value` and `typedValue` keys.

e.g.
```ObjectiveC
[[Intilery sharedInstance] getVisitorProperties:@[@"Favourite Colour", @"Favourite Film"] callback:
     ^(NSDictionary * properties) {
         [self.properties setText:[NSString stringWithFormat:@"Film: %@, Colour: %@",
                                   [properties valueForKeyPath:@"Favourite Film.value"],
                                   [properties valueForKeyPath:@"Favourite Colour.value"]]];
     }];
```

[github]:https://github.com/Intilery/intilery-ios
