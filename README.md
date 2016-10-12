<!--[![Build Status](https://travis-ci.org/intilery/intilery-ios.svg)](https://travis-ci.org/intilery/intilery-ios)
[![CocoaPods Version](http://img.shields.io/cocoapods/v/Intilery.svg?style=flat)](https://intilery.com)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Apache License](http://img.shields.io/cocoapods/l/Intilery.svg?style=flat)](https://intilery.com)
-->

**Want to Contribute?**

The Intilery library for iOS is an open source project, and we'd love to see your contributions!

# Painless Installation (CocoaPods)

Intilery supports `CocoaPods` for easy installation.

`pod 'Intilery'`

<!--
# Carthage

Intilery also supports `Carthage` to package your dependencies as a framework.
Check out the **[Carthage docs »](https://github.com/Carthage/Carthage)** for more info.
-->

# Manual Installation

To help users stay up to date with the latests version of our iOS SDK, we always recommend integrating our SDK via CocoaPods, which simplifies version updates and dependency management. However, there are cases where users can't use CocoaPods. Not to worry, just follow these manual installation steps and you'll be all set.

##Step 1: Clone the SDK

Git clone the latest version of "intilery-ios" to your local machine using the following code in your terminal:

```
git clone https://github.com/intilery/intilery-ios.git
```

If you don't have git installed, get it [here](http://git-scm.com/downloads).

##Step 2: Add the SDK to your app!

Add the "Intilery" folder from the "intilery-ios" to your Xcode project's folder.

And drag and drop the Intilery folder into your Xcode Project Workspace.

##Step 3: Import All dependencies

Add all dependencies of the Intilery SDK to your app. The full list of necessary frameworks and libraries on lines 16-17 in the "Intilery.podspec" file in the "intilery-ios" directory: 

## Step 4: Integrate!

Import `Intilery.h` into your `AppDelegate.m` and add the following lines of code:
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [Intilery sharedInstanceWithToken:INTILERY_APP withToken:INTILERY_TOKEN];
}
```

See [Integration Guide](INTEGRATION.md) for more details.

## Start tracking

You're done! You've successfully integrated the Intilery SDK into your app. 

Have any questions? Reach out to [support@intilery.com](mailto:support@intilery.com) to speak to someone.
