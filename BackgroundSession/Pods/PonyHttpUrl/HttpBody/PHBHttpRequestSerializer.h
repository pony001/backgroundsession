//
//  PHBHttpRequestSerializer.h
//  PonyHttpBody
//
//  Created by 马明晗 on 15/8/4.
//  Copyright (c) 2015年 马明晗. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PHBMultipartFormData;

@interface PHBHttpRequestSerializer : NSObject

/**
 The string encoding used to serialize parameters. `NSUTF8StringEncoding` by default.
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;


@property (readonly, nonatomic, strong) NSDictionary *HTTPRequestHeaders;

/**
 Creates and returns a serializer with default configuration.
 */
+ (instancetype)serializer;

+ (instancetype)serializerWithBoundary:(NSString *)boundary;

- (NSData *)multipartDataWithParameters:(NSDictionary *)parameters
              constructingBodyWithBlock:(void (^)(PHBMultipartFormData *formData))block;

- (NSURLRequest *)requestWithMethod:(NSString *)method
                          URLString:(NSString *)URLString;

@end
