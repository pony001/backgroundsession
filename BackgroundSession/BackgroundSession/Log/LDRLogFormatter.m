//
//  LDRLogFormatter.m
//  Runner
//
//  Created by Lei on 6/9/15.
//  Copyright (c) 2015 Ledongli. All rights reserved.
//

#import "LDRLogFormatter.h"
#import <libkern/OSAtomic.h>

@interface LDRLogFormatter () {
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}

@end

@implementation LDRLogFormatter

- (NSString *)stringFromDate:(NSDate *)date {
    int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);
    
    if (loggerCount <= 1) {
        // Single-threaded mode.
        
        if (threadUnsafeDateFormatter == nil) {
            threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [threadUnsafeDateFormatter setDateFormat:@"MM-dd-HH:mm:ss.SSS"];
        }
        return [threadUnsafeDateFormatter stringFromDate:date];
    } else {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"LDRLogFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM-dd-HH:mm:ss.SSS"];
            
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logLevel;
    switch (logMessage->_flag) {
        case DDLogFlagError    : logLevel = @"E"; break;
        case DDLogFlagWarning  : logLevel = @"W"; break;
        case DDLogFlagInfo     : logLevel = @"I"; break;
        case DDLogFlagDebug    : logLevel = @"D"; break;
        default                : logLevel = @"V"; break;
    }
    
    NSString *dateTime = [self stringFromDate:logMessage.timestamp];
    
    NSString *addition;
    
#ifdef DEBUG
    addition = [NSString stringWithFormat:@"%@ [line %lu]", logMessage.function, (unsigned long)logMessage.line];
#else
    addition = nil;
#endif
    
    return [NSString stringWithFormat:@"%@ %@ %@ %@ \n", logLevel, dateTime, addition, logMessage.message];
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    OSAtomicIncrement32(&atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    OSAtomicDecrement32(&atomicLoggerCount);
}

@end
