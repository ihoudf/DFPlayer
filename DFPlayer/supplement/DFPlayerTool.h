//
//  DFPlayerTool.h
//  DFPlayer
//
//  Created by HDF on 2017/7/30.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
static NSString *DFPlayerCurrentAudioInfoModelPlayNotiKey = @"DFPlayerCurrentAudioInfoModelPlayNotiKey";

#define kWeakSelf __weak __typeof(&*self)weakSelf = self;
//网络状态
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

//链接
+ (NSURL *)customUrlWithUrl:(NSURL *)url;
+ (NSURL *)originalUrlWithUrl:(NSURL *)url;
//判断是否是本地音频
+ (BOOL)isLocalWithUrl:(NSURL *)url;
+ (BOOL)isLocalWithUrlString:(NSString *)urlString;

//网络
+ (DFPlayerTool *)shareInstance;
- (void)startMonitoringNetworkStatus:(void(^)(void))block;
@property (nonatomic, assign) DFPlayerNetworkStatus networkStatus;
@end
@interface UIImage (DFImage)

//裁剪图片
- (UIImage *)imageByResizeToSize:(CGSize)size;
@end
