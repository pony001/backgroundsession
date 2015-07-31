//
//  LDRLogger.m
//  Runner
//
//  Created by Lei on 6/4/15.
//  Copyright (c) 2015 Ledongli. All rights reserved.
//

#import "LDRLogger.h"
#import "LDRLogFormatter.h"

@implementation LDRLogger

+ (void)configureLogger {
    setenv("XcodeColors", "YES", 0);

    LDRLogFormatter *logFormatter = [[LDRLogFormatter alloc] init];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.logFormatter = logFormatter;
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    
#ifdef DEBUG
    [[DDASLLogger sharedInstance] setLogFormatter:logFormatter];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setLogFormatter:logFormatter];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor grayColor]
                                     backgroundColor:nil
                                             forFlag:DDLogFlagVerbose];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithRed:42/255.0 green:92/255.0 blue:170/255.0 alpha:1]
                                     backgroundColor:nil
                                             forFlag:DDLogFlagDebug];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithRed:0 green:121/255.0 blue:71/255.0 alpha:1]
                                     backgroundColor:nil
                                             forFlag:DDLogFlagInfo];
    [DDLog addLogger:fileLogger];
#else 
    [DDLog addLogger:fileLogger withLevel:DDLogLevelDebug];
#endif
}

+ (void)flushLog {
    [DDLog flushLog];
}

@end
