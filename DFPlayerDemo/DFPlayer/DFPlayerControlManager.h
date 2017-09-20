//
//  DFPlayerControlManager.h
//  DFPlayer
//
//  Created by HDF on 2017/7/20.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DFPlayerManager.h"
/**
 DFPlayer控制管理器
 */
@interface DFPlayerControlManager : NSObject

/**单利方法*/
+ (DFPlayerControlManager *_Nonnull)shareInstance;

/**
 AirPlayView

 @param frame AirPlayView frame
 @param backgroundColor 背景颜色
 @param superView AirPlayView父视图
 @return AirPlayView
 */
- (UIView *_Nonnull)df_airPlayViewWithFrame:(CGRect)frame
                    backgroundColor:(UIColor *_Nullable)backgroundColor
                          superView:(UIView *_Nonnull)superView;

/**
 播放暂停按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 播放暂停按钮
 */
- (UIButton *_Nonnull)df_playPauseBtnWithFrame:(CGRect)frame
                             superView:(UIView *_Nonnull)superView
                                 block:(void(^_Nullable)())block;

/**
 上一首按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)

 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 上一首按钮
 */
- (UIButton *_Nonnull)df_lastAudioBtnWithFrame:(CGRect)frame
                             superView:(UIView *_Nonnull)superView
                                 block:(void(^_Nullable)())block;

/**
 下一首按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 下一首按钮
 */
- (UIButton *_Nonnull)df_nextAudioBtnWithFrame:(CGRect)frame
                             superView:(UIView *_Nonnull)superView
                                 block:(void(^_Nullable)())block;

/**
 播放类型设置按钮(单曲循环，顺序循环，随机循环)
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 播放类型设置按钮
 
 * 注意：当设置了DFPlayer的播放类型以后，DFPlayer将为您记录用户的选择，并在下次启动app时选择用户设置的播放类型。
 如需每次启动都设置固定某一个播放类型，请在初始化播放器后，调用[DFPlayerManager shareInstance].type = XX;重置播放类型。
 */
- (UIButton *_Nonnull)df_typeControlBtnWithFrame:(CGRect)frame
                               superView:(UIView *_Nonnull)superView
                                   block:(void(^_Nullable)(DFPlayerType type))block;


/**
 缓冲进度条

 @param frame frame
 @param trackTintColor 未缓冲部分进度条颜色
 @param progressTintColor 已缓冲部分进度条颜色
 @param superView 进度条父视图
 @return 进度条
 */
- (UIProgressView *_Nonnull)df_bufferProgressViewWithFrame:(CGRect)frame
                                    trackTintColor:(UIColor *_Nonnull)trackTintColor
                                 progressTintColor:(UIColor *_Nonnull)progressTintColor
                                         superView:(UIView *_Nonnull)superView;

/**
 播放进度条

 @param frame frame
 @param minimumTrackTintColor 滑块左边滑动条的颜色
 @param maximumTrackTintColor 滑块右边滑动条的颜色
 @param trackHeight 滑动条的高度(长度采用frame的width)
 @param thumbSize 滑块的大小
 @param superView 进度条父视图
 @return 进度条
 */
- (UISlider *_Nonnull)df_sliderWithFrame:(CGRect)frame
                   minimumTrackTintColor:(UIColor *_Nonnull)minimumTrackTintColor
                   maximumTrackTintColor:(UIColor *_Nonnull)maximumTrackTintColor
                             trackHeight:(CGFloat)trackHeight
                               thumbSize:(CGSize)thumbSize
                               superView:(UIView *_Nonnull)superView;

/**
 音频当前时间label(向下取整)

 @param frame frame
 @param superView label父视图
 @return label
 */
- (UILabel *_Nonnull)df_currentTimeLabelWithFrame:(CGRect)frame
                                superView:(UIView *_Nonnull)superView;

/**
 音频总时长label(秒数向上取整)

 @param frame frame
 @param superView label父视图
 @return label
 */
- (UILabel *_Nonnull)df_totalTimeLabelWithFrame:(CGRect)frame
                              superView:(UIView *_Nonnull)superView;



/**
 歌词tableview采用lrc标准格式编写->"[分钟:秒.毫秒] 歌词" 或 "[分钟:秒] 歌词" 或 "[分钟:秒:毫秒] 歌词"

 @param frame tableview frame
 @param lrcRowHeight tableview 单行rowHeight。单句歌词长度超出一行时暂未处理。以...省略。
 @param lrcLabelFrame 显示歌词的label的frame
 @param cellBackgroundColor cell背景色
 @param currentLineLrcForegroundTextColor 当前行歌词文字前景色（此属性不为空时，采用卡拉OK模式显示）
 @param currentLineLrcBackgroundTextColor 当前行歌词文字背景色
 @param otherLineLrcBackgroundTextColor 其他行歌词文字颜色
 @param currentLineLrcFont 当前行歌词字体
 @param otherLineLrcFont 其他行歌词字体
 @param superView 父视图
 @return 歌词tableView
 */
- (UITableView *_Nonnull)df_lyricTableViewWithFrame:(CGRect)frame
                                       lrcRowHeight:(CGFloat)lrcRowHeight
                                      lrcLabelFrame:(CGRect)lrcLabelFrame
                                cellBackgroundColor:(UIColor *_Nullable)cellBackgroundColor
                  currentLineLrcForegroundTextColor:(UIColor *_Nullable)currentLineLrcForegroundTextColor
                  currentLineLrcBackgroundTextColor:(UIColor *_Nonnull)currentLineLrcBackgroundTextColor
                    otherLineLrcBackgroundTextColor:(UIColor *_Nonnull)otherLineLrcBackgroundTextColor
                                 currentLineLrcFont:(UIFont *_Nonnull)currentLineLrcFont
                                   otherLineLrcFont:(UIFont *_Nonnull)otherLineLrcFont
                                          superView:(UIView *_Nonnull)superView;

@end
