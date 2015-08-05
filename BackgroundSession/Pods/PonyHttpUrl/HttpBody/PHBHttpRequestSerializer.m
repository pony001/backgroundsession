//
//  PHBHttpRequestSerializer.m
//  PonyHttpBody
//
//  Created by 马明晗 on 15/8/4.
//  Copyright (c) 2015年 马明晗. All rights reserved.
//

#import "PHBHttpRequestSerializer.h"
#import <UIKit/UIKit.h>
#import "PHBMultipartFormData.h"

@interface PHBHttpRequestSerializer () {
    PHBMultipartFormData *multipartFormData;
    NSString *boundary;
}

@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableHTTPRequestHeaders;
@end

@implementation PHBHttpRequestSerializer

+ (instancetype)serializer {
    return [[self alloc] init];
}

+ (instancetype)serializerWithBoundary:(NSString *)boundary {
    PHBHttpRequestSerializer *httpRequestSerializer = [[self alloc] init];
    [httpRequestSerializer setBoundary:boundary];
    return httpRequestSerializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.stringEncoding = NSUTF8StringEncoding;
    
    self.mutableHTTPRequestHeaders = [NSMutableDictionary dictionary];
    
    // Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
    [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        float q = 1.0f - (idx * 0.1f);
        [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g", obj, q]];
        *stop = q <= 0.5f;
    }];
    [self setValue:[acceptLanguagesComponents componentsJoinedByString:@", "] forHTTPHeaderField:@"Accept-Language"];
    
    NSString *userAgent = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    userAgent = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif
#pragma clang diagnostic pop
    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                userAgent = mutableUserAgent;
            }
        }
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
   
    [self setBoundary:[NSString stringWithFormat:@"Boundary-%08X%08X", arc4random(), arc4random()]];
    
    return self;
}

- (void)setBoundary:(NSString *)str {
    boundary = str;
}

- (NSData *)multipartDataWithParameters:(NSDictionary *)parameters
              constructingBodyWithBlock:(void (^)(PHBMultipartFormData *formData))block {
    __block PHBMultipartFormData *formData = [[PHBMultipartFormData alloc] init];
    if (boundary) {
       [formData setBoundary:boundary];
    }
    
    if (parameters) {
        
        NSArray *keys = [parameters allKeys];
        for (int i=0; i<[keys count]; i++) {
            NSString *name = [keys objectAtIndex:i];
            id valueObj = [parameters objectForKey:name];
            
            NSData *data = nil;
            if ([valueObj isKindOfClass:[NSData class]]) {
                data = valueObj;
            } else if ([valueObj isEqual:[NSNull null]]) {
                data = [NSData data];
            } else {
                data = [[valueObj description] dataUsingEncoding:self.stringEncoding];
            }
            
            if (valueObj) {
                [formData appendPartWithFormData:valueObj name:name];
            }
        }
    }
    
    if (block) {
        block(formData);
    }
   
    [formData appendLastboundary];
    
    multipartFormData = formData;
    
    return formData.httpBody;
}

- (NSURLRequest *)requestWithMethod:(NSString *)method
                          URLString:(NSString *)URLString {
    NSParameterAssert(method);
    NSParameterAssert(![method isEqualToString:@"GET"] && ![method isEqualToString:@"HEAD"]);
    
    NSMutableURLRequest *mutableRequest = [self requestWithMethod:method
                                                        URLString:URLString
                                                       parameters:nil];
    
    [mutableRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    if (multipartFormData) {
        [mutableRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)multipartFormData.httpBody.length] forHTTPHeaderField:@"Content-Length"];
    }
    
    return mutableRequest;
}

#pragma mark -

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters {
    NSParameterAssert(method);
    NSParameterAssert(URLString);
    
    NSURL *url = [NSURL URLWithString:URLString];
    
    NSParameterAssert(url);
    
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    mutableRequest.HTTPMethod = method;
   
    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![mutableRequest valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];
    
    return mutableRequest;
}

#pragma mark -

- (void)setValue:(NSString *)value
forHTTPHeaderField:(NSString *)field {
    [self.mutableHTTPRequestHeaders setValue:value forKey:field];
}

@end
