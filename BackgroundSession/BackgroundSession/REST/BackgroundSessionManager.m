//
//  BackgroundSessionManager.m
//  xiaoqin
//
//  Created by 马明晗 on 15/6/10.
//  Copyright (c) 2015年 马明晗. All rights reserved.
//

#import "BackgroundSessionManager.h"
#import "AFNetworking.h"
#import "LDRLogger.h"
#import "PHBHttpRequestSerializer.h"
#import "PHBMultipartFormData.h"

static NSString * const kBackgroundSessionIdentifier = @"cn.maminghan.backgroundsession";

@implementation BackgroundSessionManager {
    AFURLSessionManager *bgSessionManager;
}

+ (instancetype)sharedManager
{
    static id sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype) init {
    
    NSURLSessionConfiguration *sessionConfiguration;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0f) {
        sessionConfiguration =[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundSessionIdentifier];
    } else {
        sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:kBackgroundSessionIdentifier];
    }
    
    sessionConfiguration.sessionSendsLaunchEvents = YES;
    sessionConfiguration.allowsCellularAccess = NO;
    
    bgSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
    bgSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [bgSessionManager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition (NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential) {
        return NSURLSessionAuthChallengePerformDefaultHandling;
    }];
    
    typeof(self) __weak weakSelf = self;
    [bgSessionManager setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        DDLogInfo(@"DidFinishEventsForBackgroundURLSessionBlock");
        if (weakSelf.backgroundSessionCompletionHandler) {
            void (^completionHandler)() = weakSelf.backgroundSessionCompletionHandler;
            weakSelf.backgroundSessionCompletionHandler = nil;
            
            completionHandler();
        }
    }];

    return self;
}

- (void)setEnteredBackground {
    
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = backgroundTaskIdentifier;
    }];
}

#pragma mark - Public Method

- (void)cancleAllDownload {
    NSArray *downloads = [bgSessionManager downloadTasks];
    for (NSURLSessionDownloadTask *downloadTask in downloads) {
        [downloadTask cancel];
    }
}

- (void)cancleAllUploading {
    NSArray *uploads = [bgSessionManager uploadTasks];
    for (NSURLSessionUploadTask *uploadTask in uploads) {
        [uploadTask cancel];
    }
}

- (NSInteger)uploadTaskSize {
    NSArray *uploadTasks = [bgSessionManager uploadTasks];
    return uploadTasks.count;
}

- (void)startTask {
    NSArray *uploadTasks = [bgSessionManager uploadTasks];
    for (NSURLSessionUploadTask *uploadTask in uploadTasks) {
        [uploadTask resume];
    }
}

#pragma mark - BatchDate

- (void) sendBatchDataRequestByPostBody:(NSDictionary*)postBody
                                   data:(NSData*)data
                                   date:(double)date
                            finishBlock:(void (^)(NSString* request))completionHandler
                              failBlock:(void (^)(NSInteger errorCode))failedHandler
{
    NSString *url = @"http://test.maminghan.cn/upload.php";
    
    NSProgress *progress = nil;

    PHBHttpRequestSerializer *requestSerializer = [PHBHttpRequestSerializer serializerWithBoundary:@"------------------------7BFA9292F0DA32DC"];
    
    NSData *bodyData = [requestSerializer multipartDataWithParameters:postBody
                                            constructingBodyWithBlock:^(PHBMultipartFormData *formData) {
                                                [formData appendPartWithFileData:data
                                                                            name:@"file"
                                                                        fileName:@"file"
                                                                        mimeType:@"application/octet-stream"];
                                            }];
    
    id path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"upload.date.%.0f", date]];
    [bodyData writeToFile:path atomically:YES];
    
    NSURLRequest *request = [requestSerializer requestWithMethod:@"POST" URLString:url];
    
    [[bgSessionManager uploadTaskWithRequest:request
                                    fromFile:[NSURL fileURLWithPath:path]
                                     progress:&progress
                            completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                DDLogInfo(@"session completion : %@", error);
                                //删除对应的文件
                                if (error) {
                                    failedHandler(error.code);
                                } else {
                                    NSString *str = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                            
                                    completionHandler(str);
                                    
                                }
                            }] resume];
    
}

@end
