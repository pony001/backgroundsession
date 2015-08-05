//
//  PHBMultipartFormData.m
//  PonyHttpBody
//
//  Created by 马明晗 on 15/8/4.
//  Copyright (c) 2015年 马明晗. All rights reserved.
//

#import "PHBMultipartFormData.h"

NSString * const PHBURLRequestSerializationErrorDomain = @"cn.maminghan.error.serialization.request";

@implementation PHBMultipartFormData {
    NSMutableData *httpBody;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        httpBody = [NSMutableData data];
        _boundary = [NSString stringWithFormat:@"Boundary-%08X%08X", arc4random(), arc4random()];
    }
    return self;
}

- (NSData *)httpBody {
    return httpBody;
}

#pragma mark - PHBDataMultipartFormData

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    
    NSString *fileName = [fileURL lastPathComponent];
    NSString *mimeType = AFContentTypeForPathExtension([fileURL pathExtension]);
    
    return [self appendPartWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType error:error];
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    
    if (![fileURL isFileURL]) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"Expected URL to be a file URL", @"PHBHttpBody", nil)};
        if (error) {
            *error = [[NSError alloc] initWithDomain:PHBURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        
        return NO;
    } else if ([fileURL checkResourceIsReachableAndReturnError:error] == NO) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"File URL not reachable.", @"PHBHttpBody", nil)};
        if (error) {
            *error = [[NSError alloc] initWithDomain:PHBURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        
        return NO;
    }
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:error];
    if (!fileAttributes) {
        return NO;
    }
    
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];

    [self appendPartWithHeaders:mutableHeaders body:[NSData dataWithContentsOfURL:fileURL]];
    
    return YES;
}

- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType
{
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name
{
    NSParameterAssert(name);
    
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body
{
    NSParameterAssert(body);
    
    NSString *header = [PHBMultipartFormData stringWithDictionary:headers];
    
    id boundary = [NSString stringWithFormat:@"--%@\r\n", _boundary];
    
    [httpBody appendData:[boundary dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:body];
    [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)appendLastboundary {
    if (httpBody.length > 0) {
        id lastLine = [NSString stringWithFormat:@"--%@", _boundary];
        [httpBody appendData:[lastLine dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

static inline NSString * AFContentTypeForPathExtension(NSString *extension) {
#ifdef __UTTYPE__
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
#else
#pragma unused (extension)
    return @"application/octet-stream";
#endif
}

#pragma mark - util

+(NSString *) stringWithDictionary:(NSDictionary *)dictionary {
    NSArray *keys = [dictionary allKeys];
    NSMutableString *reString = [NSMutableString string];
    NSMutableArray *keyValues = [NSMutableArray array];
    for (int i=0; i<[keys count]; i++) {
        NSString *name = [keys objectAtIndex:i];
        id valueObj = [dictionary objectForKey:name];
          if (valueObj) {
            [keyValues addObject:[NSString stringWithFormat:@"%@: %@",name,valueObj]];
        }
    }
    [reString appendFormat:@"%@",[keyValues componentsJoinedByString:@"\r\n"]];
    [reString appendString:@"\r\n"];
    return reString;
}

@end
