//
//  DFPlayerModel.h
//  DFPlayer
//
//  Created by HDF on 2017/7/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/**
 数据model类 - IMPORTANT
 */
@interface DFPlayerModel : NSObject
/**音频Id，必传属性
 说明：鉴于音频播放器有顺序播放、随机播放等功能，DFPLayer需要一次性知道全部数据。
 而在删除、增加音频后需要调用[[DFPlayerManager shareInstance] df_reloadData];刷新数据。
 此处audioId仅是标识当前音频在数组中的位置。详见demo。
 */
@property (nonatomic, assign) NSUInteger            audioId;
/**音频地址，必传属性*/
@property (nonatomic, nonnull, strong) NSURL        *audioUrl;
/**歌词*/
@property (nonatomic, nullable, copy) NSString      *audioLyric;
/*当您正确传入以下属性时，DFPlayer将自动为您设置锁屏模式和后台模式的播放信息展示*/
/**音频名*/
@property (nonatomic, nullable, copy) NSString      *audioName;
/**专辑名*/
@property (nonatomic, nullable, copy) NSString      *audioAlbum;
/**歌手名*/
@property (nonatomic, nullable, copy) NSString      *audioSinger;
/**音频配图*/
@property (nonatomic, nullable, strong) UIImage     *audioImage;

@end

UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelAudioId;
UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelAudioUrl;
UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelAudioLyric;
UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelAudioName;
UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelAudioAlbum;
UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelAudioSinger;
UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelAudioImage;
UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelIsCached;
UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelCurrentTime;
UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelTotalTime;
UIKIT_EXTERN NSString * _Nullable const DFPlayerCurrentAudioInfoModelProgress;
/**
 此model主要用于重新进入app时获取上次播放的音频信息
 */
@interface DFPlayerPreviousAudioModel : NSObject

/**音频Id，对应传入的audioId*/
@property (nonatomic, readonly, assign) NSUInteger          audioId;
/**音频地址，对应传入的audioUrl*/
@property (nonatomic, readonly, nonnull, strong) NSURL      *audioUrl;
/**歌词，对应传入的audioLyric*/
@property (nonatomic, readonly, nullable, copy) NSString    *audioLyric;
/**音频名，对应传入的audioName*/
@property (nonatomic, readonly, nullable, copy) NSString    *audioName;
/**专辑名，对应传入的audioAlbum*/
@property (nonatomic, readonly, nullable, copy) NSString    *audioAlbum;
/**歌手名，对应传入的audioSinger*/
@property (nonatomic, readonly, nullable, copy) NSString    *audioSinger;
/**音频配图，对应传入的audioImage*/
@property (nonatomic, readonly, nullable, strong) UIImage   *audioImage;
/**音频是否缓存*/
@property (nonatomic, readonly, assign) BOOL                isCached;
/**音频当前播放到的时间*/
@property (nonatomic, readonly, assign) CGFloat             currentTime;
/**音频总时长*/
@property (nonatomic, readonly, assign) CGFloat             totalTime;
/**音频播放进度*/
@property (nonatomic, readonly, assign) CGFloat             progress;

@end


