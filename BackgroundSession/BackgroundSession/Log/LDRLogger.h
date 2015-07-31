//
//  LDRLogger.h
//  Runner
//
//  Created by Lei on 6/4/15.
//  Copyright (c) 2015 Ledongli. All rights reserved.
//

#define LOG_LEVEL_DEF DDLogLevelAll

#import <CocoaLumberjack/CocoaLumberjack.h>

@interface LDRLogger : NSObject

+ (void)configureLogger;

+ (void)flushLog;

@end
