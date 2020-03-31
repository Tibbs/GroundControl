// NSUserDefaults+GroundControl.m
//
// Copyright (c) 2012 Mattt Thompson (http://mattt.me/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSUserDefaults+GroundControl.h"
#import "AFHTTPSessionManager.h"
#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"

#import <objc/runtime.h>

@interface NSUserDefaults (_GroundControl)
+ (NSOperationQueue *)gc_sharedPropertyListRequestOperationQueue;
@end

@implementation NSUserDefaults (GroundControl)

+ (NSOperationQueue *)gc_sharedPropertyListRequestOperationQueue {
    static NSOperationQueue *_sharedPropertyListRequestOperationQueue = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedPropertyListRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_sharedPropertyListRequestOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    });
    
    return _sharedPropertyListRequestOperationQueue;
}

- (id <AFURLRequestSerialization>)requestSerializer {
    return objc_getAssociatedObject(self, @selector(requestSerializer));
}

- (void)setRequestSerializer:(id <AFURLRequestSerialization>)requestSerializer {
    objc_setAssociatedObject(self, @selector(requestSerializer), requestSerializer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id <AFURLResponseSerialization>)responseSerializer {
    return objc_getAssociatedObject(self, @selector(responseSerializer));
}

- (void)setResponseSerializer:(id <AFURLResponseSerialization>)responseSerializer {
    objc_setAssociatedObject(self, @selector(responseSerializer), responseSerializer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)registerDefaultsWithURL:(NSURL *)url {
    [self registerDefaultsWithURL:url success:nil failure:nil];
}

- (void)registerDefaultsWithURL:(NSURL *)url
                        success:(void (^)(NSDictionary *defaults))success
                        failure:(void (^)(NSError *error))failure
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.responseSerializer = self.responseSerializer ? self.responseSerializer : [AFPropertyListResponseSerializer serializer];
    [manager GET:url.absoluteString parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self setValuesForKeysWithDictionary:responseObject];
        [self synchronize];
        
        if (success) {
            success(responseObject);
        }
        [manager invalidateSessionCancelingTasks:YES resetSession:YES];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
        [manager invalidateSessionCancelingTasks:YES resetSession:YES];
    }];

    
     /*
    [manager GET:url.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        [self setValuesForKeysWithDictionary:responseObject];
        [self synchronize];
        
        if (success) {
            success(responseObject);
        }
        [manager invalidateSessionCancelingTasks:YES];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
        [manager invalidateSessionCancelingTasks:YES];
    }];
      */
}

@end
