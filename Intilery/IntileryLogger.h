//
//  IntileryLogger.h
//  HelloIntilery
//
//  Created by Alex Hofsteede on 7/11/14.
//  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef IntileryLogger_h
#define IntileryLogger_h

static inline void IntileryLog(NSString *format, ...) {
    __block va_list arg_list;
    va_start (arg_list, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    va_end(arg_list);
    NSLog(@"[Intilery] %@", formattedString);
}

#ifdef INTILERY_ERROR
#define IntileryError(...) IntileryLog(__VA_ARGS__)
#else
#define IntileryError(...)
#endif

#ifdef INTILERY_DEBUG
#define IntileryDebug(...) IntileryLog(__VA_ARGS__)
#else
#define IntileryDebug(...)
#endif

#ifdef INTILERY_MESSAGING_DEBUG
#define MessagingDebug(...) IntileryLog(__VA_ARGS__)
#else
#define MessagingDebug(...)
#endif

#endif
