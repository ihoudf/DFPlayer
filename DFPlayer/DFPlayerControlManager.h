//
//  DFPlayerControlManager.h
//  DFPlayer
//
//  Created by HDF on 2017/7/20.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/**
 DFPlayer控制管理器
 */
@interface DFPlayerControlManager : NSObject

/**单利方法*/
+ (DFPlayerControlManager *_Nullable)shareInstance;

/**调用该方法将停止更新与进度相关的UI控件（除了歌词tableview）的刷新*/
- (void)df_stopUpdateProgress;

/**调用该方法将恢复更新与进度相关的UI控件（除了歌词tableview）的刷新*/
- (void)df_resumeUpdateProgress;

/**(下面的方法可以显示出airplay按钮，若完善airplay功能需要用到私有API，故不建议使用)
 AirPlay按钮（背景图片在DFPlayer.bundle中同名替换相应的图片即可）
 airplay按钮是系统按钮，当系统检测到airplay可用时才会显示。
 
 @param frame AirPlay按钮 frame
 @param backgroundColor 背景颜色
 @param superView AirPlayView父视图
 @return AirPlayView
 */
- (UIView *_Nullable)df_airPlayViewWithFrame:(CGRect)frame
                             backgroundColor:(UIColor *_Nonnull)backgroundColor
                                   superView:(UIView *_Nonnull)superView;

/**
 播放暂停按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 播放暂停按钮
 */
- (UIButton *_Nullable)df_playPauseBtnWithFrame:(CGRect)frame
                                      superView:(UIView *_Nonnull)superView
                                          block:(void(^_Nullable)(void))block;

/**
 上一首按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)

 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 上一首按钮
 */
- (UIButton *_Nullable)df_lastAudioBtnWithFrame:(CGRect)frame
                                      superView:(UIView *_Nonnull)superView
                                          block:(void(^_Nullable)(void))block;

/**
 下一首按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 下一首按钮
 */
- (UIButton *_Nullable)df_nextAudioBtnWithFrame:(CGRect)frame
                                      superView:(UIView *_Nonnull)superView
                                          block:(void(^_Nullable)(void))block;

/**
 播放模式按钮(单曲循环，顺序循环，随机循环) （DFPlayerMode为DFPlayerModeOnlyOnce时此按钮会隐藏）
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 播放模式设置按钮
 
 * 注意：当设置了DFPlayer的播放模式以后，DFPlayer将为您记录用户的选择，并在下次启动app时选择用户设置的播放模式。
 如需每次启动都设置固定某一个播放模式，请在初始化播放器后，调用[DFPlayer shareInstance].playMode = XX;重置播放模式。
 */
- (UIButton *_Nullable)df_typeControlBtnWithFrame:(CGRect)frame
                                        superView:(UIView *_Nonnull)superView
                                            block:(void(^_Nullable)(void))block;

/**
 缓冲进度条

 @param frame frame
 @param trackTintColor 未缓冲部分进度条颜色
 @param progressTintColor 已缓冲部分进度条颜色
 @param superView 进度条父视图
 @return 进度条
 */
- (UIProgressView *_Nullable)df_bufferProgressViewWithFrame:(CGRect)frame
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
- (UISlider *_Nullable)df_sliderWithFrame:(CGRect)frame
                   minimumTrackTintColor:(UIColor *_Nonnull)minimumTrackTintColor
                   maximumTrackTintColor:(UIColor *_Nonnull)maximumTrackTintColor
                             trackHeight:(CGFloat)trackHeight
                               thumbSize:(CGSize)thumbSize
                               superView:(UIView *_Nonnull)superView;

/**
 音频当前时间label

 @param frame frame
 @param superView label父视图
 @return label
 */
- (UILabel *_Nullable)df_currentTimeLabelWithFrame:(CGRect)frame
                                superView:(UIView *_Nonnull)superView;

/**
 音频总时长label

 @param frame frame
 @param superView label父视图
 @return label
 */
- (UILabel *_Nullable)df_totalTimeLabelWithFrame:(CGRect)frame
                              superView:(UIView *_Nonnull)superView;

#pragma mark - 歌词tableView相关
/**
 lyricTableview
 ①采用lrc标准格式编写，即"[00:00.00]歌词" 或 "[00:00]歌词" 或 "[00:00:00]歌词"
 ②根据lrc歌词软件开发标准，凡具有“[*:*]”形式的都应认为是标签（注意：其中的冒号并非全角字符“：”）。凡是标签都不应显示。
 ③支持单句歌词多个时间的格式，如“[00:10.00][00:50.00][00:70.00]歌词”
 ④lrc歌词文件单行只有时间标签，没有歌词内容的，将被认作为上一个相邻时间内歌词的结束时间,并不做空行显示处理。比如
 [00:11.11]歌词
 [00:22.22] （22秒22毫米，该时间下无歌词显示，将被认作为上一个相邻时间歌词的演唱结束时间，此处的相邻不是位置的相邻，而是时间大小的相邻）
 ⑤如果歌词中需要空行，DFPlayer默认时间标签后的“####”是空行标志，如“[00:11.11]####”，DFPlayer将在解析到歌词为####时做空行显示
 详情查看demo中”许嵩(Vae)-有何不可.lrc“文件
 ⑥DFPlayer认为每个时间标签都是一个单元格。只不过时间标签后无歌词时，DFPlayer将该单元格隐藏。
 ⑦DFPlayer不对单句歌词做换行处理，所以单行歌词长度尽量不要超过tableview的宽度，当超出时，DFPlayer用末尾省略号处理。
 
 @param frame  tableview frame
 @param contentInset  tableview contentInset
 @param cellRowHeight  tableview 单行rowHeight
 @param cellBackgroundColor cell背景色
 @param currentLineLrcForegroundTextColor 当前行歌词文字前景色（此属性不为nil时，采用卡拉OK模式显示）
 @param currentLineLrcBackgroundTextColor 当前行歌词文字背景色
 @param otherLineLrcBackgroundTextColor 其他行歌词文字颜色
 @param currentLineLrcFont 当前行歌词字体
 @param otherLineLrcFont 其他行歌词字体
 @param superView 父视图
 @param clickBlock 点击某个歌词cell。indexpath：该行cell的indexpath
 @return 歌词tableView
 */
- (UITableView *_Nullable)df_lyricTableViewWithFrame:(CGRect)frame
                                        contentInset:(UIEdgeInsets)contentInset
                                       cellRowHeight:(CGFloat)cellRowHeight
                                 cellBackgroundColor:(UIColor *_Nullable)cellBackgroundColor
                   currentLineLrcForegroundTextColor:(UIColor *_Nullable)currentLineLrcForegroundTextColor
                   currentLineLrcBackgroundTextColor:(UIColor *_Nonnull)currentLineLrcBackgroundTextColor
                     otherLineLrcBackgroundTextColor:(UIColor *_Nonnull)otherLineLrcBackgroundTextColor
                                  currentLineLrcFont:(UIFont *_Nonnull)currentLineLrcFont
                                    otherLineLrcFont:(UIFont *_Nonnull)otherLineLrcFont
                                           superView:(UIView *_Nonnull)superView
                                          clickBlock:(void(^_Nullable)(NSIndexPath * _Nullable indexpath))clickBlock;
/**DFPlayer不管理lyricTableview中歌词更新的暂停和恢复*/
/**停止更新lyricTableview中歌词的刷新*/
- (void)df_playerLyricTableviewStopUpdate;
/**恢复更新lyricTableview中歌词的刷新*/
- (void)df_playerLyricTableviewResumeUpdate;

@end
