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
 数据model类（必传属性） - IMPORTANT
 */
@interface DFPlayerModel : NSObject
/**音频Id。从0开始，仅标识当前音频在数组中的位置*/
@property (nonatomic, assign) NSUInteger audioId;
/**音频地址*/
@property (nonatomic, nonnull, strong) NSURL *audioUrl;
@end


/**
 音频信息model类（非必传属性）
 */
@interface DFPlayerInfoModel : NSObject
/**歌词*/
@property (nonatomic, nullable, copy) NSString *audioLyric;
/*正确传入以下属性时，DFPlayer将自动设置锁屏模式和控制中心的播放信息展示*/
/**音频名*/
@property (nonatomic, nullable, copy) NSString *audioName;
/**专辑名*/
@property (nonatomic, nullable, copy) NSString *audioAlbum;
/**歌手名*/
@property (nonatomic, nullable, copy) NSString *audioSinger;
/**音频配图*/
@property (nonatomic, nullable, copy) UIImage *audioImage;
@end

/**
 此model用于获取上次播放的音频信息
 */
@interface DFPlayerPreviousAudioModel : NSObject

/**网络音频地址或本地音频名*/
@property (nonatomic, readonly, nonnull, copy) NSString *audioUrlAbsoluteString;
/**音频总时长*/
@property (nonatomic, readonly, assign) CGFloat totalTime;
/**以下属性只有缓存过或者本地音频才会配置该属性 */
/**音频当前播放到的时间*/
@property (nonatomic, readonly, assign) CGFloat currentTime;
/**音频播放进度*/
@property (nonatomic, readonly, assign) CGFloat progress;

@end


