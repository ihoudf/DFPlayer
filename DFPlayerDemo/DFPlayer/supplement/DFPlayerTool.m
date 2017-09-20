//
//  DFPlayerTool.m
//  DFPlayer
//
//  Created by HDF on 2017/7/30.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayerTool.h"
#import "AFNetworkReachabilityManager.h"
static BOOL DFPlayer_Log_Switch = NO;
@implementation DFPlayerTool

+ (void)setLogEnabled:(BOOL)isNeedLog{
    DFPlayer_Log_Switch = isNeedLog;
}

+ (BOOL)logEnable {
    return DFPlayer_Log_Switch;
}

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

+ (void)checkNetworkReachable:(void(^)(NSInteger networkStatus))block
{
    AFNetworkReachabilityManager *mgr = [AFNetworkReachabilityManager sharedManager];
    [mgr setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                block(-1);
                break;
            case AFNetworkReachabilityStatusNotReachable:
                block(0);
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                block(1);
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                block(2);
                break;
        }
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



