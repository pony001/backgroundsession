//
//  BackgroundSessionManager.m
//  xiaoqin
//
//  Created by 马明晗 on 15/6/10.
//  Copyright (c) 2015年 马明晗. All rights reserved.
//

#import "BackgroundSessionManager.h"
#import "AFNetworking.h"
#import "OMGHTTPURLRQ.h"
#import "LDRLogger.h"

static NSString * const kBackgroundSessionIdentifier = @"cn.ledongli.backgroundsession";

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
    sessionConfiguration.allowsCellularAccess = YES;
    
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

#pragma mark - BatchDate

- (void) sendBatchDataRequestByPostBody:(NSMutableDictionary*)postBody
                                   data:(NSData*)data
                                   date:(double)date
                            finishBlock:(void (^)(NSString* request))completionHandler
                              failBlock:(void (^)(NSInteger errorCode))failedHandler
{
    NSString *url = @"http://test.maminghan.cn/upload.php";
    
    NSProgress *progress = nil;
    OMGMultipartFormData *multipartFormData = [OMGMultipartFormData new];
    [multipartFormData addFile:data parameterName:@"data" filename:@"file" contentType:@"application/octet-stream"];
    [multipartFormData addParameters:postBody];
    
    NSURLRequest *request = [OMGHTTPURLRQ POST:url:multipartFormData];
    
    id path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"upload.date.%.0f", date]];
    [request.HTTPBody writeToFile:path atomically:YES];
    
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

#pragma mark - download

//- (void) sendDownloadRequestByBody:(NSMutableDictionary*)body
//                       finishBlock:(void (^)(NSData* data, RESTResponse* request))finishHandler
//                         failBlock:(void (^)(NSInteger errorCode))failHandler {
//    if (![VerifyNetEnable verifyPostEnableWithParam:body withData:Nil]) {
//        return;
//    }
//    
//    NSString *url = ( NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, ( CFStringRef)SERVERDAILYSTORAGE_DOWN, nil, CFSTR(""), kCFStringEncodingUTF8));
//
//    NSURLRequest *request = [OMGHTTPURLRQ GET:url:body];
//    
//    [TrafficManager statisticsNetworkTrafficWithURLRequest:request];
//    
//    NSURLSessionDownloadTask *downloadTask = [bgSessionManager downloadTaskWithRequest:request
//                                                                               progress:nil
//                                                                            destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
//                                                                                DDLogInfo(@"destination");
//                                                                                NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
//                                                                                return [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@",[NSDate date]]];
//                                                                            } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//                                                                                [TrafficManager statisticsNetworkTrafficWithURLResponse:response];
//                                                                                
//                                                                                DDLogInfo(@"File downloaded");
//                                                                                if (error) {
//                                                                                    failHandler(0);
//                                                                                } else {
//                                                                                    finishHandler([NSData dataWithContentsOfURL:filePath], nil);
//                                                                                    [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
//                                                                                }
//                                                                            }];
//    [downloadTask resume];
//}

@end
