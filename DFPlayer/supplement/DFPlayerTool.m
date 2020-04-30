//
//  DFPlayerTool.m
//  DFPlayer
//
//  Created by ihoudf on 2017/7/30.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import "DFPlayerTool.h"
#import <objc/runtime.h>
#import "DFPlayer_AFNetworkReachabilityManager.h"

static DFPlayerNetworkStatus _networkStatus;

@implementation DFPlayerTool

+ (NSURL *)customURL:(NSURL *)URL{
    NSString *URLString = [URL absoluteString];
    if ([URLString rangeOfString:@":"].location != NSNotFound) {
        NSString *scheme = [[URLString componentsSeparatedByString:@":"] firstObject];
        if (scheme) {
            NSString *newScheme = [scheme stringByAppendingString:@"-streaming"];
            URLString = [URLString stringByReplacingOccurrencesOfString:scheme withString:newScheme];
            return [NSURL URLWithString:URLString];
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

+ (NSURL *)originalURL:(NSURL *)URL{
    NSURLComponents * components = [[NSURLComponents alloc] initWithURL:URL
                                                resolvingAgainstBaseURL:NO];
    components.scheme = [components.scheme stringByReplacingOccurrencesOfString:@"-streaming" withString:@""];
    return [components URL];
}

+ (BOOL)isLocalAudio:(NSURL *)URL{
    return [URL.absoluteString hasPrefix:@"http"] ? NO : YES;
}

+ (BOOL)isNSURL:(NSURL *)URL{
    return [URL isKindOfClass:[NSURL class]];
}

+ (void)startMonitoringNetworkStatus:(void (^)(DFPlayerNetworkStatus))block{
    AFNetworkReachabilityManager *mgr = [AFNetworkReachabilityManager sharedManager];
    [mgr setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                _networkStatus = DFPlayerNetworkStatusUnknown;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                _networkStatus = DFPlayerNetworkStatusNotReachable;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                _networkStatus = DFPlayerNetworkStatusReachableViaWWAN;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                _networkStatus = DFPlayerNetworkStatusReachableViaWiFi;
                break;
        }
        if (block) {
            block(_networkStatus);
        }
    }];
    [mgr startMonitoring];
}

+ (void)stopMonitoringNetwork{
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
}

+ (DFPlayerNetworkStatus)networkStatus{
    return _networkStatus;
}

@end

@implementation NSString (DFPlayerNSStringExtensions)

- (NSString *)df_removeEmpty{
    NSString *str = [NSString stringWithFormat:@"%@",self];
    return [str stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (BOOL)df_isEmpty{
    if(!self || [self isEqualToString:@"(null)"] || [self isKindOfClass:[NSNull class]] || [self isEqual:[NSNull null]]){
        return YES;
    }
    return [self df_removeEmpty].length == 0;
}

- (BOOL)df_isContainLetter{
    NSRegularExpression *numberRegular = [NSRegularExpression regularExpressionWithPattern:@"[A-Za-z]" options:NSRegularExpressionCaseInsensitive error:nil];
    NSInteger count = [numberRegular numberOfMatchesInString:self options:NSMatchingReportProgress range:NSMakeRange(0, self.length)];
    return count > 0;
}


@end


static NSString * key_ActionBlock = @"key_ActionBlock";

@implementation UIButton(DFPlayerUIButtonExtensions)

- (void)setHandleButtonActionBlock:(void (^)(UIButton * _Nullable))handleButtonActionBlock{
    objc_setAssociatedObject(self, (__bridge const void *)key_ActionBlock, handleButtonActionBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (handleButtonActionBlock) {
        [self addTarget:self action:@selector(actionHandler) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)actionHandler{
    if (self.handleButtonActionBlock) {
        self.handleButtonActionBlock(self);
    }
}

-  (void (^)(UIButton * _Nullable))handleButtonActionBlock{
    return objc_getAssociatedObject(self, (__bridge const void *)key_ActionBlock);
}

@end



