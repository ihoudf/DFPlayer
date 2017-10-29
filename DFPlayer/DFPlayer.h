//
//  DFPlayer.h
//  DFPlayer
//
//  Created by HDF on 2017/7/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "DFPlayerModel.h"
#import "DFPlayerControlManager.h"
@class DFPlayer;
//errorMessage
static NSString *DFPlayerWarning_TypeError          = @"音频地址错误，支持NSURL类型";
static NSString *DFPlayerWarning_PlayError          = @"音频无法播放";
static NSString *DFPlayerWarning_UnknownError       = @"未知错误";
static NSString *DFPlayerWarning_UnavailableData    = @"无法获得该音频资源";
static NSString *DFPlayerWarning_UnavailableLinks   = @"无效的链接";
static NSString *DFPlayerWarning_UnavailableNewwork = @"没有网络连接";

//播放器类别
typedef NS_ENUM(NSInteger,DFPlayerAudioSessionCategory){
    DFPlayerAudioSessionCategoryAmbient,        //用于播放。随静音键和屏幕关闭而静音。不终止其它应用播放声音
    DFPlayerAudioSessionCategorySoloAmbient,    //用于播放。随静音键和屏幕关闭而静音。终止其它应用播放声音
    DFPlayerAudioSessionCategoryPlayback,       //用于播放。不随静音键和屏幕关闭而静音。终止其它应用播放声音
    DFPlayerAudioSessionCategoryPlayAndRecord,  //用于播放和录音。不随着静音键和屏幕关闭而静音。终止其他应用播放声音
    DFPlayerAudioSessionCategoryMultiRoute      //用于播放和录音。不随着静音键和屏幕关闭而静音。可多设备输出
};

//播放器状态
typedef NS_ENUM(NSInteger, DFPlayerState) {
    DFPlayerStateFailed,     // 播放失败
    DFPlayerStateBuffering,  // 缓冲中
    DFPlayerStatePlaying,    // 播放中
    DFPlayerStatePause,      // 暂停播放
    DFPlayerStateStopped     // 停止播放
};

//播放类型
typedef NS_ENUM(NSInteger, DFPlayerType){
    DFPlayerTypeOnlyOnce,       //单曲只播放一次
    DFPlayerTypeSingleCycle,    //单曲循环
    DFPlayerTypeOrderCycle,     //顺序循环
    DFPlayerTypeShuffleCycle    //随机循环
};

@protocol DFPlayerDataSource <NSObject>
@required
/**
 数据源1：音频model数组
 */
- (NSArray<DFPlayerModel *> *)df_playerModelArray;

@optional
/**
 数据源2：音频信息model
 当DFPlayer收到播放请求时，会调用此方法请求当前音频的信息
 根据player.currentAudioModel.audioId获取音频在数组中的位置,返回对应的音频信息model
 
 @param player DFPlayer音频播放管理器
 */
- (DFPlayerInfoModel *)df_playerAudioInfoModel:(DFPlayer *)player;

@end

@protocol DFPlayerDelegate <NSObject>
@optional

/**
 代理1：音频将要加入播放队列

 @param player DFPlayer音频播放管理器
 */
- (void)df_playerAudioWillAddToPlayQueue:(DFPlayer *)player;

/**
 代理2：WWAN网络状态代理（isObserveWWAN（默认NO）为YES，网络状态为WWAN，且当前播放音频无缓存时发起）
 
 @param player DFPlayer音频播放管理器
 */
- (void)df_playerNetworkDidChangeToWWAN:(DFPlayer *)player;

/**
 代理3：准备开始播放代理
 
 @param player DFPlayer音频播放管理器
 */
- (void)df_playerDidReadyToPlay:(DFPlayer *)player;

/**
 代理4：缓冲进度代理  (属性isObserveBufferProgress(默认YES)为YES时有效）
 
 @param player DFPlayer音频播放管理器
 @param bufferProgress 缓冲进度
 @param totalTime 音频总时长
 */
- (void)df_player:(DFPlayer *)player
   bufferProgress:(CGFloat)bufferProgress
        totalTime:(CGFloat)totalTime;

/**
 代理5：播放进度代理 （属性isObserveProgress(默认YES)为YES时有效）
 
 @param player DFPlayer音频播放管理器
 @param progress 播放进度
 @param currentTime 当前播放到的时间
 @param totalTime 音频总时长
 */
- (void)df_player:(DFPlayer *)player
         progress:(CGFloat)progress
      currentTime:(CGFloat)currentTime
        totalTime:(CGFloat)totalTime;

/**
 代理6：当前音频缓存结果代理
 
 @param player FPlayer音频播放管理器
 @param isCached 是否缓存成功
 */
- (void)df_player:(DFPlayer *)player isCached:(BOOL)isCached;

/**
 代理7：播放结束代理
 
 @param player FPlayer音频播放管理器
 */
- (void)df_playerDidPlayToEndTime:(DFPlayer *)player;

/**
 代理8：播放失败代理

 @param player DFPlayer音频播放管理器
 @param errorMessage 错误信息
 */
- (void)df_player:(DFPlayer *)player didFailWithErrorMessage:(NSString *)errorMessage;

/**
 代理9：播放器被系统打断代理
 （DFPlayer默认被系统打断暂停播放，打断结束检测能够播放则恢复播放，如果实现此代理，打断逻辑由您处理）

 @param player DFPlayer音频播放管理器
 @param isInterruptedBegin YES:被系统打断开始  NO:被系统打断结束
 */
- (void)df_player:(DFPlayer *)player isInterruptedBegin:(BOOL)isInterruptedBegin;

/**
 代理10：监听耳机插入拔出代理

 @param player DFPlayer音频播放管理器
 @param isHeadphone YES:插入 NO:拔出
 */
- (void)df_player:(DFPlayer *)player isHeadphone:(BOOL)isHeadphone;

@end

/**
 DFPlayer音频播放管理器
 */
@interface DFPlayer : NSObject

@property (nonatomic, weak) id<DFPlayerDelegate>    delegate;
@property (nonatomic, weak) id<DFPlayerDataSource>  dataSource;

#pragma mark - 设置类
/**播放器类型，默认DFPlayerAudioSessionCategorySoloAmbient*/
@property (nonatomic, assign) DFPlayerAudioSessionCategory category;
/**
 播放类型，首次默认DFPlayerTypeSingleCycle。设置播放类型后，DFPlayer将为您记录用户的选择。
 如需每次启动都设置固定某一个播放类型，请在初始化播放器后，调用[DFPlayer shareInstance].type = XX;重置播放类型。
 */
@property (nonatomic, assign) DFPlayerType type;
/**是否监听播放进度，默认YES*/
@property (nonatomic, assign) BOOL isObserveProgress;
/**是否监听缓冲进度，默认YES*/
@property (nonatomic, assign) BOOL isObserveBufferProgress;
/**是否需要缓存，默认YES*/
@property (nonatomic, assign) BOOL isNeedCache;
/**是否需要耳机线控功能，默认YES*/
@property (nonatomic, assign) BOOL isRemoteControl;
/**是否监测上次关闭app时的音频信息，默认NO*/
@property (nonatomic, assign) BOOL isObservePreviousAudioModel;
/**
 在单曲循环模式下，点击下一首(上一首)按钮(或使用线控播放下一首、上一首)是重新开始播放当前音频还是播放下一首（上一首）
 移动版QQ音乐是播放下一首（上一首），PC版QQ音乐是重新开始播放当前音频
 DFPlayer默认YES，即采用移动版QQ音乐设置。设置为NO时，重新开始播放当前音频
 */
@property (nonatomic, assign) BOOL isManualToPlay;
/**
 当currentAudioModel存在时，是否插入耳机音频自动恢复播放，默认NO
 当您没有实现代理10的情况下，DFPlaye默认拨出耳机音频自动停止，插入耳机音频不会自动恢复。你可通过此属性控制插入耳机时音频是否可自动恢复
 当您实现代理10时，耳机插入拔出时的播放暂停逻辑由您处理。
 */
@property (nonatomic, assign) BOOL isHeadPhoneAutoPlay;
/**
 是否监测WWAN无线广域网（2g/3g/4g）,默认NO。
 播放本地音频（工程目录和沙盒文件）不监测。
 播放网络音频时，DFPlayer为您实现wifi下自动播放，无网络有缓存播放缓存，无网络无缓存返回无网络错误码。
 基于播放器具有循环播放的功能，开启该属性，无线广域网（WWAN）网络状态通过代理2返回。
 */
@property (nonatomic, assign) BOOL isObserveWWAN;
/**
 是否监听服务器文件修改时间，默认NO。
 在播放网络音频且需要DFPlayer的缓存功能的情况下，开启该属性，不必频繁更换服务端文件名来更新客户端播放内容。
 比如，你的服务器上有audioname.mp3资源，若更改音频内容而需重新上传音频时，您不必更改文件名以保证客户端获取最新资源，本属性为YES即可完成。
 第一次请求某资源时，DFPlayer缓存文件的同时会记录文件在服务器端的修改时间。
 开启该属性，以后播放该资源时，DFPlayer会判断服务端文件是否修改过，修改过则加载新资源，没有修改过则播放缓存文件。
 关闭此属性，有缓存时将直接播放缓存，不做更新校验，在弱网环境下播放响应速度更快。但您可自行实现每隔多少天或在哪一天检测的逻辑。
 无网络连接时，有缓存直接播放缓存文件。
 */
@property (nonatomic, assign) BOOL isObserveFileModifiedTime;

#pragma mark - 状态类
/**播放器状态*/
@property (nonatomic, readonly, assign) DFPlayerState           state;
/**当前正在播放的音频model*/
@property (nonatomic, readonly, strong) DFPlayerModel           *currentAudioModel;
/**当前正在播放的音频信息model*/
@property (nonatomic, readonly, strong) DFPlayerInfoModel       *currentAudioInfoModel;
/**当前音频缓冲进度*/
@property (nonatomic, readonly, assign) CGFloat                 bufferProgress;
/**当前音频播放进度*/
@property (nonatomic, readonly, assign) CGFloat                 progress;
/**当前音频当前时间*/
@property (nonatomic, readonly, assign) CGFloat                 currentTime;
/**当前音频总时长*/
@property (nonatomic, readonly, assign) CGFloat                 totalTime;
/**上次关闭app时播放的音频信息。(属性isObservePreviousAudioModel（默认NO）为YES时有效)*/
@property (nonatomic, readonly, strong) DFPlayerPreviousAudioModel *previousAudioModel;

#pragma mark - 初始化和操作
/**单例方法*/
+ (DFPlayer *)shareInstance;

/**
 初始化播放器
 
 @param userId 用户唯一Id。
 isNeedCache（默认YES）为YES时，若同一设备登录不同账号：
 1.userId存在时，DFPlayer将为每位用户建立不同的缓存文件目录。例如，user_001,user_002...
 2.userId为nil或@""时，统一使用DFPlayerCache文件夹下的user_public文件夹作为缓存目录。
 isNeedCache为NO时,userId设置无效，此时不会在沙盒创建缓存目录
 */
- (void)initPlayerWithUserId:(NSString *)userId;

/**刷新数据源数据*/
- (void)df_reloadData;

/**选择audioId对应的音频开始播放*/
- (void)df_playerPlayWithAudioId:(NSUInteger)audioId;

/**播放*/
- (void)df_audioPlay;

/**暂停*/
- (void)df_audioPause;

/**下一首*/
- (void)df_audioNext;

/**上一首*/
- (void)df_audioLast;

/**音频跳转，value：时间百分比*/
- (void)df_seekToTimeWithValue:(CGFloat)value;

/**释放播放器，还原其他播放器*/ 
- (void)df_dellecPlayer;

/**实现远程线控功能，需替换main.m中UIApplicationMain函数的第三个参数。*/
- (NSString *)remoteControlClass;

#pragma mark - 缓存相关
/**
 url对应音频是否已经在本地缓存
 
 @param url 网络音频url
 @return 有缓存返回缓存地址，无缓存返回nil
 */
+ (NSString *)df_playerCheckIsCachedWithUrl:(NSURL *)url;

 /**
 清除url对应的本地缓存

 @param url 网络音频url
 @param block 是否清除成功 错误信息
 */
+ (void)df_playerClearCacheWithUrl:(NSURL *)url block:(void(^)(BOOL isSuccess, NSError *error))block;

/**
 计算DFPlayer的缓存大小

 @param isCurrentUser YES:计算当前用户缓存大小  NO:计算所有用户缓存大小
 @return 大小
 */
+ (CGFloat)df_playerCountCacheSizeForCurrentUser:(BOOL)isCurrentUser;

/**
 清除DFPlayer产生的缓存

 @param isClearCurrentUser YES:清除当前用户缓存  NO:清除所有用户缓存
 @param block 是否清除成功 错误信息
 */
+ (void)df_playerClearCacheForCurrentUser:(BOOL)isClearCurrentUser
                                    block:(void(^)(BOOL isSuccess, NSError *error))block;

/**计算系统磁盘空间 剩余可用空间*/
+ (void)df_countSystemSizeBlock:(void(^)(CGFloat totalSize,CGFloat freeSize,BOOL isSuccess))block;

@end




