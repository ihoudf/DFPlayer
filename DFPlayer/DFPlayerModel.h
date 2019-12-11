//
//  DFPlayerModel.h
//  DFPlayer
//
//  Created by ihoudf on 2017/7/18.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 音频数据model类（必传）
 */
@interface DFPlayerModel : NSObject

// 音频Id（从0开始，仅标识当前音频在数组中的位置）
@property (nonatomic, assign) NSUInteger audioId;

// 音频地址
@property (nonatomic, strong) NSURL *audioUrl;

@end

/**
 音频信息model类（非必传）
 */
@interface DFPlayerInfoModel : NSObject

// 歌词
@property (nonatomic, nullable, copy) NSString *audioLyrics;

/* 正确传入以下属性时，DFPlayer将自动设置锁屏模式和控制中心的播放信息展示 */
// 音频名
@property (nonatomic, nullable, copy) NSString *audioName;

// 专辑名
@property (nonatomic, nullable, copy) NSString *audioAlbum;

// 歌手名
@property (nonatomic, nullable, copy) NSString *audioSinger;

// 音频配图
@property (nonatomic, nullable, copy) UIImage *audioImage;

@end

NS_ASSUME_NONNULL_END

