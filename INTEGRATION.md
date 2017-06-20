# Integrating Events into your App

## Initialisation

Import `Intilery.h` into your `AppDelegate.m` and add the following lines of code:
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [Intilery sharedInstanceWithToken:INTILERY_APP withToken:INTILERY_TOKEN withIntileryURL:@"https://www.intilery-analytics.com"];
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
