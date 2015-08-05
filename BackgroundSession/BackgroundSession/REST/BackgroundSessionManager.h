//
//  BackgroundSessionManager.h
//  xiaoqin
//
//  Created by 马明晗 on 15/6/10.
//  Copyright (c) 2015年 马明晗. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BackgroundSessionManager : NSObject

@property (nonatomic, copy) void (^backgroundSessionCompletionHandler)(void);

+ (instancetype)sharedManager;

- (void)setEnteredBackground;
- (void)cancleAllDownload;
- (void)cancleAllUploading;
- (NSInteger)uploadTaskSize;
- (void)startTask;

- (void) sendBatchDataRequestByPostBody:(NSDictionary*)postBody
                                   data:(NSData*)data
                                   date:(double)date
                            finishBlock:(void (^)(NSString* request))completionHandler
                              failBlock:(void (^)(NSInteger errorCode))failedHandler;


@end
