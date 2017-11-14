//
//  DFPlayerTool.m
//  DFPlayer
//
//  Created by HDF on 2017/7/30.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayerTool.h"
#import "AFNetworkReachabilityManager.h"

@interface DFPlayerTool()


@end

@implementation DFPlayerTool

+ (NSURL *)customUrlWithUrl:(NSURL *)url{
    NSString *urlStr = [url absoluteString];
    if ([urlStr rangeOfString:@":"].location != NSNotFound) {
        NSString *scheme = [[urlStr componentsSeparatedByString:@":"] firstObject];
        if (scheme) {
            NSString *newScheme = [scheme stringByAppendingString:@"-streaming"];
            urlStr = [urlStr stringByReplacingOccurrencesOfString:scheme withString:newScheme];
            return [NSURL URLWithString:urlStr];
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

+ (NSURL *)originalUrlWithUrl:(NSURL *)url{
    NSURLComponents * components = [[NSURLComponents alloc] initWithURL:url
                                                resolvingAgainstBaseURL:NO];
    components.scheme = [components.scheme stringByReplacingOccurrencesOfString:@"-streaming" withString:@""];
    return [components URL];
}

+ (BOOL)isLocalWithUrl:(NSURL *)url{
    return [self isLocalWithUrlString:url.absoluteString];
}

+ (BOOL)isLocalWithUrlString:(NSString *)urlString{
    if ([urlString hasPrefix:@"http"]) {
        return NO;
    }
    return YES;
}

+ (DFPlayerTool *)shareInstance {
    static DFPlayerTool *instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}
- (void)startMonitoringNetworkStatus:(void(^)(void))block{
    AFNetworkReachabilityManager *mgr = [AFNetworkReachabilityManager sharedManager];
    [mgr setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"-- DFPlayer： 网络状态：%ld",(long)status);
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                self.networkStatus = DFPlayerNetworkStatusUnknown;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                self.networkStatus = DFPlayerNetworkStatusNotReachable;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                self.networkStatus = DFPlayerNetworkStatusReachableViaWWAN;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                self.networkStatus = DFPlayerNetworkStatusReachableViaWiFi;
                break;
        }
        if (block) {block();}
    }];
    [mgr startMonitoring];
}

@end

@implementation UIImage (DFImage)
- (UIImage *)imageByResizeToSize:(CGSize)size {
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end



