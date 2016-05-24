//
//  AppDelegate.m
//  HelloIntilery
//
//  Copyright © 2016 Intilery.com Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "Intilery.h"

#define INTILERY_APP @"ios-test"
#define INTILERY_TOKEN @"NWlvcy0xNDUxMDI4OTpOZnpxS0lsVnRMOSQ="

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [Intilery sharedInstanceWithToken:INTILERY_APP withToken:INTILERY_TOKEN withLaunchOptions:launchOptions];
    
    // Tell iOS you want your app to receive push notifications
    // This code will work in iOS 8.0 xcode 6.0 or later:
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    // This code will work in iOS 7.0 and below:
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeNewsstandContentAvailability| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[Intilery sharedInstance] addPushDeviceToken:deviceToken];
}


- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSString *message = [[userInfo objectForKey:@"aps"]
                         objectForKey:@"alert"];
    
    NSLog(@"Recieved push message: %@", userInfo);
    
    [[Intilery sharedInstance] trackPushNotification:userInfo];
    
    // Show alert for push notifications recevied while the
    // app is running
    if ([UIAlertController class]) // iOS 9 and above
    {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Hello Intilery"
                                    message:message
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction
                            actionWithTitle:@"OK"
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                                [alert dismissViewControllerAnimated:YES completion:nil];
                            }];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                 }];
        
        [alert addAction:ok];
        [alert addAction:cancel];
        
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    } else { // iOS 8 and below
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Hello"
                              message:message
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        
        [alert show];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
