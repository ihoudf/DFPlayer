//
//  DFPlayerUIManager.h
//  DFPlayer
//
//  Created by ihoudf on 2017/7/20.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 DFPlayer控制管理器
 */
@interface DFPlayerUIManager : NSObject

/**
 单利
 */
+ (DFPlayerUIManager *)sharedManager;

/**
 停止所有进度类控件的刷新
 */
- (void)df_stopUpdate;

/**
 恢复所有进度类控件的刷新
 */
- (void)df_resumeUpdate;

/**
 播放暂停按钮
 
 @param frame 按钮frame
 @param playImage 播放状态时显示的image
 @param pauseImage 暂停播放时显示的image
 @param superView 按钮父视图
 @param block 按钮action
 @return 播放暂停按钮
 */
- (UIButton *)df_playPauseBtnWithFrame:(CGRect)frame
                             playImage:(UIImage *)playImage
                            pauseImage:(UIImage *)pauseImage
                             superView:(UIView *)superView
                                 block:(nullable void (^)(void))block;

/**
 上一首按钮
 
 @param frame 按钮frame
 @param image 按钮image
 @param superView 按钮父视图
 @param block 按钮action
 @return 上一首按钮
 */
- (UIButton *)df_lastBtnWithFrame:(CGRect)frame
                            image:(UIImage *)image
                        superView:(UIView *)superView
                            block:(nullable void (^)(void))block;

/**
 下一首按钮
 
 @param frame 按钮frame
 @param image 按钮image
 @param superView 按钮父视图
 @param block 按钮action
 @return 下一首按钮
 */
- (UIButton *)df_nextBtnWithFrame:(CGRect)frame
                            image:(UIImage *)image
                        superView:(UIView *)superView
                            block:(nullable void (^)(void))block;

/**
 播放模式按钮(DFPlayerMode不是DFPlayerModeOnlyOnce时有效。）
 
 @param frame 按钮frame
 @param singleImage 按钮singleImage
 @param circleImage 按钮circleImage
 @param shuffleImage 按钮shuffleImage
 @param superView 按钮父视图
 @param block 按钮action,若无其他操作需求，传nil即可
 @return 播放模式按钮
 */
- (UIButton *)df_typeBtnWithFrame:(CGRect)frame
                      singleImage:(UIImage *)singleImage
                      circleImage:(UIImage *)circleImage
                     shuffleImage:(UIImage *)shuffleImage
                        superView:(UIView *)superView
                            block:(nullable void (^)(void))block;

/**
 缓冲条
 
 @param frame frame
 @param trackTintColor 未缓冲部分进度条颜色
 @param progressTintColor 已缓冲部分进度条颜色
 @param superView 进度条父视图
 @return 进度条
 */
- (UIProgressView *)df_bufferViewWithFrame:(CGRect)frame
                            trackTintColor:(UIColor *)trackTintColor
                         progressTintColor:(UIColor *)progressTintColor
                                 superView:(UIView *)superView;

/**
 播放进度条
 
 @param frame frame
 @param minimumTrackTintColor 滑块左边滑动条的颜色
 @param maximumTrackTintColor 滑块右边滑动条的颜色
 @param trackHeight 滑动条的高度(长度采用frame的width)
 @param thumbImage 滑块图片
 @param superView 进度条父视图
 @return 进度条
 */
- (UISlider *)df_sliderWithFrame:(CGRect)frame
           minimumTrackTintColor:(UIColor *)minimumTrackTintColor
           maximumTrackTintColor:(UIColor *)maximumTrackTintColor
                     trackHeight:(CGFloat)trackHeight
                      thumbImage:(UIImage *)thumbImage
                       superView:(UIView *)superView;

/**
 音频当前时间label
 
 @param frame frame
 @param textColor textColor
 @param textAlignment textAlignment
 @param font font
 @param superView label父视图
 @return label
 */
- (UILabel *)df_currentTimeLabelWithFrame:(CGRect)frame
                                textColor:(UIColor *)textColor
                            textAlignment:(NSTextAlignment)textAlignment
                                     font:(UIFont *)font
                                superView:(UIView *)superView;

/**
 音频总时长label
 
 @param frame frame
 @param textColor textColor
 @param textAlignment textAlignment
 @param font font
 @param superView label父视图
 @return label
 */
- (UILabel *)df_totalTimeLabelWithFrame:(CGRect)frame
                              textColor:(UIColor *)textColor
                          textAlignment:(NSTextAlignment)textAlignment
                                   font:(UIFont *)font
                              superView:(UIView *)superView;

/**
 歌词tableview
 ①采用lrc标准格式编写，即"[00:00.00]歌词" 或 "[00:00]歌词" 或 "[00:00:00]歌词"
 ②根据lrc歌词软件开发标准，凡具有“[*:*]”形式的都应认为是标签（注意：其中的冒号并非全角字符“：”）。凡是标签都不应显示。
 ③支持单句歌词多个时间的格式，如“[00:10.00][00:50.00][00:70.00]歌词”
 ④lrc歌词文件单行只有时间标签，没有歌词内容的，将被认作为上一个相邻时间内歌词的结束时间,并不做空行显示处理。比如
 [00:11.11]歌词
 [00:22.22] （22秒22毫米，该时间下无歌词显示，将被认作为上一个相邻时间歌词的演唱结束时间。此处的相邻不是位置的相邻，而是时间大小的相邻）
 ⑤如果歌词中需要空行，DFPlayer默认时间标签后的“####”是空行标志，如“[00:11.11]####”，DFPlayer将在解析到歌词为####时做空行显示
 详情查看demo中”许嵩(Vae)-有何不可.lrc“文件
 ⑥DFPlayer认为每个时间标签都是一个单元格。只不过时间标签后无歌词时，DFPlayer将该单元格隐藏。
 ⑦DFPlayer不对单句歌词做换行处理，所以单行歌词长度尽量不要超过tableview的宽度，当超出时，DFPlayer用末尾省略号处理。
 
 @param frame  tableview frame
 @param cellRowHeight  tableview 单行rowHeight
 @param cellBackgroundColor cell背景色
 @param currentLineLrcForegroundTextColor 当前行歌词文字前景色（此属性不为nil时，采用卡拉OK模式显示）
 @param currentLineLrcBackgroundTextColor 当前行歌词文字背景色
 @param otherLineLrcBackgroundTextColor 其他行歌词文字颜色
 @param currentLineLrcFont 当前行歌词字体
 @param otherLineLrcFont 其他行歌词字体
 @param superView 父视图
 @param block 返回当前正在播放的歌词
 @return 歌词tableView
 */

- (UITableView *)df_lyricTableViewWithFrame:(CGRect)frame
                              cellRowHeight:(CGFloat)cellRowHeight
                        cellBackgroundColor:(UIColor *)cellBackgroundColor
          currentLineLrcForegroundTextColor:(nullable UIColor *)currentLineLrcForegroundTextColor
          currentLineLrcBackgroundTextColor:(UIColor *)currentLineLrcBackgroundTextColor
            otherLineLrcBackgroundTextColor:(UIColor *)otherLineLrcBackgroundTextColor
                         currentLineLrcFont:(UIFont *)currentLineLrcFont
                           otherLineLrcFont:(UIFont *)otherLineLrcFont
                                  superView:(UIView *)superView
                                      block:(nullable void (^)(NSString * onPlayingLyrics))block;



@end

NS_ASSUME_NONNULL_END

