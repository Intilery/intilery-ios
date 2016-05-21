//
//  IntileryExceptionHandler.m
//  HelloIntilery
//
//  Created by Sam Green on 7/28/15.
//  Copyright (c) 2015 Mixpanel. All rights reserved.
//

#import "IntileryExceptionHandler.h"
#import "Intilery.h"
#import "MPLogger.h"

@interface IntileryExceptionHandler ()

@property (nonatomic) NSUncaughtExceptionHandler *defaultExceptionHandler;
@property (nonatomic, strong) NSHashTable *intileryInstances;

@end

@implementation IntileryExceptionHandler

+ (instancetype)sharedHandler {
    static IntileryExceptionHandler *gSharedHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gSharedHandler = [[IntileryExceptionHandler alloc] init];
    });
    return gSharedHandler;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Create a hash table of weak pointers to intilery instances
        _intileryInstances = [NSHashTable weakObjectsHashTable];
        
        // Save the existing exception handler
        _defaultExceptionHandler = NSGetUncaughtExceptionHandler();
        // Install our handler
        NSSetUncaughtExceptionHandler(&mp_handleUncaughtException);
    }
    return self;
}

- (void)addIntileryInstance:(Intilery *)instance {
    NSParameterAssert(instance != nil);
    
    [self.intileryInstances addObject:instance];
}

static void mp_handleUncaughtException(NSException *exception) {
    IntileryExceptionHandler *handler = [IntileryExceptionHandler sharedHandler];
    
    // Archive the values for each Intilery instance
    for (Intilery *instance in handler.intileryInstances) {
        // Since we're storing the instances in a weak table, we need to ensure the pointer hasn't become nil
        if (instance) {
            [instance archive];
        }
    }
    
    IntileryError(@"Encountered an uncaught exception. All Intilery instances were archived.");
    
    if (handler.defaultExceptionHandler) {
        // Ensure the existing handler gets called once we're finished
        handler.defaultExceptionHandler(exception);
    }
}

@end
