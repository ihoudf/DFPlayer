//
//  DFPlayer.h
//  DFPlayer
//
//  Created by ihoudf on 2017/7/18.
//  Copyright © 2017年 ihoudf. All rights reserved.
//
//
//  DFPlayer当前版本：2.0.3
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DFPlayerModel.h"

//播放器状态
typedef NS_ENUM(NSInteger, DFPlayerState) {
    DFPlayerStateFailed,     // 播放失败
    DFPlayerStateBuffering,  // 缓冲中
    DFPlayerStatePlaying,    // 播放中
    DFPlayerStatePause,      // 暂停播放
    DFPlayerStateStopped     // 停止播放
};

//播放模式
typedef NS_ENUM(NSInteger, DFPlayerMode){
    DFPlayerModeOnlyOnce,       //单曲只播放一次，默认
    DFPlayerModeSingleCycle,    //单曲循环
    DFPlayerModeOrderCycle,     //顺序循环
    DFPlayerModeShuffleCycle    //随机循环
};

//状态码
typedef NS_ENUM(NSUInteger, DFPlayerStatusCode) {
    
    DFPlayerStatusNoNetwork = 2100, //未缓存的网络音频，点击播放时若无网络会返回该状态码。缓冲完成前若断网也会返回该状态码。（PS：DFPlayer支持运行时断点续传，即缓冲时网络从无到有，可以断点续传，而某音频没缓冲完就退出app，再进入app没做断点续传，以上特点与QQ音乐一致）
    DFPlayerStatusViaWWAN = 2101, //WWAN网络状态（注意：属性isObserveWWAN（默认NO）为YES时，对于未缓存的网络音频，点击该音频时开始缓冲时返回该状态码。而音频正在缓冲时，网络状态由wifi到wwan并不会返回该状态码，以上特点与QQ音乐一致）
    
    DFPlayerStatusTimeOut = 2200, //音频请求超时（根据服务器返回的状态码）
    
    DFPlayerStatusFailed = 2300, //音频无法播放（AVPlayerItemStatusFailed）
    DFPlayerStatusUnknown = 2301, //未知错误（AVPlayerItemStatusUnknown）
    
    DFPlayerStatusCacheFail = 2400, //当前音频缓存失败
    DFPlayerStatusCacheSucc = 2401  //当前音频缓存成功
};


@class DFPlayer;

@protocol DFPlayerDataSource <NSObject>

@required

/**
 数据源1：音频数组
 
 @param player DFPlayer
 */
- (NSArray<DFPlayerModel *> *)df_audioDataForPlayer:(DFPlayer *)player;

@optional

/**
 数据源2：音频信息
 调用df_playWithAudioId时，DFPlayer会调用此方法请求当前音频的信息
 根据player.currentAudioModel.audioId获取音频在数组中的位置,传入对应的音频信息model
 
 @param player DFPlayer
 */
- (DFPlayerInfoModel *)df_audioInfoForPlayer:(DFPlayer *)player;

@end


@protocol DFPlayerDelegate <NSObject>

@optional
/**
 代理1：音频已经加入播放队列
 
 @param player DFPlayer
 */
- (void)df_playerAudioAddToPlayQueue:(DFPlayer *)player;

/**
 代理2：准备播放
 
 @param player DFPlayer
 */
- (void)df_playerReadyToPlay:(DFPlayer *)player;

/**
 代理3：缓冲进度代理  (属性isObserveBufferProgress(默认YES)为YES时有效）
 
 @param player DFPlayer
 @param bufferProgress 缓冲进度
 */
- (void)df_player:(DFPlayer *)player bufferProgress:(CGFloat)bufferProgress;

/**
 代理4：播放进度代理 （属性isObserveProgress(默认YES)为YES时有效）
 
 @param player DFPlayer
 @param progress 播放进度
 @param currentTime 当前播放到的时间
 */
- (void)df_player:(DFPlayer *)player progress:(CGFloat)progress currentTime:(CGFloat)currentTime;

/**
 代理5：播放结束代理（默认播放结束后调用df_next。如果实现此代理，播放结束逻辑由您处理）
 
 @param player FPlayer
 */
- (void)df_playerDidPlayToEndTime:(DFPlayer *)player;

/**
 代理6：播放状态码代理(统一在主线程返回)
 
 @param player DFPlayer
 @param statusCode 状态码
 */
- (void)df_player:(DFPlayer *)player didGetStatusCode:(DFPlayerStatusCode)statusCode;

/**
 代理7：播放器被系统打断代理（默认被系统打断暂停播放，打断结束检测能够播放则恢复播放。如果实现此代理，打断逻辑由您处理）
 
 @param player DFPlayer
 @param isInterrupted YES:被系统打断开始  NO:被系统打断结束
 */
- (void)df_player:(DFPlayer *)player isInterrupted:(BOOL)isInterrupted;

/**
 代理8：监听耳机插入拔出代理（默认拨出耳机暂停播放，插入耳机不恢复播放。如果实现此代理，耳机插拔逻辑由您处理）
 
 @param player DFPlayer
 @param isHeadphone YES:插入 NO:拔出
 */
- (void)df_player:(DFPlayer *)player isHeadphone:(BOOL)isHeadphone;

@end

/**
 DFPlayer播放管理器
 */
@interface DFPlayer : NSObject

#pragma mark - 初始化和操作

@property (nonatomic, weak) id<DFPlayerDataSource> dataSource;

@property (nonatomic, weak) id<DFPlayerDelegate> delegate;

/**
 播放器类型，默认AVAudioSessionCategoryPlayback
 Tips:AVAudioSessionCategoryPlayback，需在工程里设置targets->capabilities->选择backgrounds modes->勾选audio,airplay,and picture in picture
 */
@property (nonatomic, assign) AVAudioSessionCategory category;

/**
 播放模式，默认DFPlayerModeOnlyOnce。
 */
@property (nonatomic, assign) DFPlayerMode playMode;

/**
 是否监听播放进度，默认YES
 */
@property (nonatomic, assign) BOOL isObserveProgress;

/**
 是否监听缓冲进度，默认YES
 */
@property (nonatomic, assign) BOOL isObserveBufferProgress;

/**
 是否需要缓存，默认YES
 */
@property (nonatomic, assign) BOOL isNeedCache;

/**
 是否监测WWAN无线广域网（2g/3g/4g）,默认NO。
 播放本地音频（工程目录和沙盒文件）不监测。
 播放网络音频时，DFPlayer为您实现无网络有缓存播放缓存，无网络无缓存返回无网络错误码，wifi下自动播放。开启该属性，当网络为WWAN时，通过代理6返回状态码DFPlayerStatusViaWWAN。
 */
@property (nonatomic, assign) BOOL isObserveWWAN;

/**
 是否监听服务器文件修改时间，默认NO。
 第一次请求某资源时，DFPlayer缓存文件的同时会记录文件在服务器端的修改时间。
 开启该属性，以后播放该资源时，DFPlayer会判断服务端文件是否修改过，修改过则加载新资源，没有修改过则播放缓存文件。
 关闭此属性，有缓存时将直接播放缓存，不做更新校验，在弱网环境下播放响应速度更快。
 无网络连接时，有缓存直接播放缓存文件。
 */
@property (nonatomic, assign) BOOL isObserveFileModifiedTime;

/**
 单例
 */
+ (DFPlayer *)sharedPlayer;

/**
 初始化播放器
 
 @param userId 用户Id。
 isNeedCache（默认YES）为YES时，若同一设备登录不同账号：
 1.userId不为空时，DFPlayer将为每位用户建立不同的缓存文件目录。例如，user_001,user_002...
 2.userId为nil或@""时，统一使用DFPlayerCache文件夹下的user_public作为缓存目录。
 isNeedCache为NO时,userId设置无效，此时不会在沙盒创建缓存目录。
 */
- (void)df_initPlayerWithUserId:(NSString *)userId;

/**
 刷新数据源数据
 */
- (void)df_reloadData;

/**
 选择audioId对应的音频开始播放。
 说明：DFPlayer通过数据源方法提前获取数据，通过df_playWithAudioId选择对应音频播放。
 而在删除、增加音频后需要调用[[DFPlayer shareInstance] df_reloadData];刷新数据。
 */
- (void)df_playWithAudioId:(NSUInteger)audioId;

/**
 播放
 */
- (void)df_play;

/**
 暂停
 */
- (void)df_pause;

/**
 下一首
 */
- (void)df_next;

/**
 上一首
 */
- (void)df_last;

/**
 音频跳转
 
 @param value 时间百分比（要跳转到的时间/总时间）
 @param completionBlock seek结束
 */
- (void)df_seekToTime:(CGFloat)value completionBlock:(void(^)(void))completionBlock;

/**
 倍速播放（iOS10之后系统支持的倍速常数有0.50, 0.67, 0.80, 1.0, 1.25, 1.50和2.0）
 @param rate 倍速
 */
- (void)df_setRate:(CGFloat)rate;

/**
 释放播放器，还原其他播放器
 */
- (void)df_deallocPlayer;


#pragma mark - 状态类

/**
 播放器状态
 */
@property (nonatomic, readonly, assign) DFPlayerState state;

/**
 当前正在播放的音频model
 */
@property (nonatomic, readonly, strong) DFPlayerModel *currentAudioModel;

/**
 当前正在播放的音频信息model
 */
@property (nonatomic, readonly, strong) DFPlayerInfoModel *currentAudioInfoModel;

/**
 当前音频缓冲进度
 */
@property (nonatomic, readonly, assign) CGFloat bufferProgress;

/**
 当前音频播放进度
 */
@property (nonatomic, readonly, assign) CGFloat progress;

/**
 当前音频当前时间
 */
@property (nonatomic, readonly, assign) CGFloat currentTime;

/**
 当前音频总时长
 */
@property (nonatomic, readonly, assign) CGFloat totalTime;

#pragma mark - 缓存相关
/**
 audioUrl对应的音频在本地的缓存地址
 
 @param audioUrl 网络音频url
 @return 无缓存时返回nil
 */
- (NSString *)df_cachePath:(NSURL *)audioUrl;

/**
 DFPlayer的缓存大小
 
 @param currentUser YES:当前用户  NO:所有用户
 @return 缓存大小
 */
- (CGFloat)df_cacheSize:(BOOL)currentUser;

/**
 清除音频缓存
 
 @param audioUrl 网络音频url
 @return 是否清除成功（无缓存时返回YES）
 */
- (BOOL)df_clearAudioCache:(NSURL *)audioUrl;

/**
 清除用户缓存
 
 @param currentUser YES:清除当前用户缓存  NO:清除所有用户缓存
 @return 是否清除成功（无缓存时返回YES）
 */
- (BOOL)df_clearUserCache:(BOOL)currentUser;

@end




