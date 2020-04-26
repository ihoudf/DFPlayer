//
//  DFPlayerTool.h
//  DFPlayer
//
//  Created by ihoudf on 2017/7/30.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *DFPlayerNotificationSeekEnd = @"DFPlayerNotificationSeekEnd";

#define DFPlayerWeakSelf __weak __typeof(&*self) wSelf = self;
#define DFPlayerStrongSelf __strong __typeof(&*self) sSelf = wSelf;

#define DFPlayerHighGlobalQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
#define DFPlayerDefaultGlobalQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

// 网络状态
typedef NS_ENUM(NSInteger, DFPlayerNetworkStatus) {
    DFPlayerNetworkStatusUnknown          = -1, //未知
    DFPlayerNetworkStatusNotReachable     = 0,  //无网络链接
    DFPlayerNetworkStatusReachableViaWWAN = 1,  //2G/3G/4G
    DFPlayerNetworkStatusReachableViaWiFi = 2   //WIFI
};

/**
 DFPlayer工具类
 */
@interface DFPlayerTool : NSObject

// 链接
+ (NSURL *)customURL:(NSURL *)URL;
+ (NSURL *)originalURL:(NSURL *)URL;

// 是否是本地音频
+ (BOOL)isLocalAudio:(NSURL *)URL;

// 是否是NSURL类型
+ (BOOL)isNSURL:(NSURL *)URL;

// 网络
+ (void)startMonitoringNetworkStatus:(void (^)(DFPlayerNetworkStatus networkStatus))block;

+ (void)stopMonitoringNetwork;

+ (DFPlayerNetworkStatus)networkStatus;


@end

@interface NSString (DFPlayerStringExtensions)

// 字符串去空字符
- (NSString *)df_removeEmpty;

// 判断是否为空
- (BOOL)df_isEmpty;

// 是否包含字母
- (BOOL)df_isContainLetter;

@end




