//
//  IntileryExceptionHandler.h
//  HelloIntilery
//
//  Created by Sam Green on 7/28/15.
//  Copyright (c) 2015 Mixpanel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Intilery;

@interface IntileryExceptionHandler : NSObject

+ (instancetype)sharedHandler;
- (void)addIntileryInstance:(Intilery *)instance;

@end
