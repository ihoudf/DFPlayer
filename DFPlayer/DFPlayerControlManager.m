//
//  DFPlayerControlManager.m
//  DFPlayer
//
//  Created by HDF on 2017/7/20.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayerControlManager.h"
#import "DFPlayer.h"
#import <objc/runtime.h>
#import "DFPlayerTool.h"
#import "DFPlayerLyricsTableview.h"
#import <MediaPlayer/MediaPlayer.h>
static NSString * key_EventBlock = @"key_EventBlock";
#define WeakPointer(weakSelf) __weak __typeof(&*self)weakSelf = self
@interface UIButton (EBlock)
@property(copy, nonatomic) void(^ _Nullable handleJFEventBlock)(UIButton * _Nullable sender);
@end
@implementation UIButton(EBlock)
-(void)eventHandler{
    if (self.handleJFEventBlock) {
        self.handleJFEventBlock(self);
    }
}
-(void)setHandleJFEventBlock:(void (^)(UIButton *sender))eventBlock{
    objc_setAssociatedObject(self, (__bridge const void *)key_EventBlock, eventBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (eventBlock) {
        [self addTarget:self action:@selector(eventHandler) forControlEvents:UIControlEventTouchUpInside];
    }
}
-(void (^) (UIButton *)) handleJFEventBlock{
    return objc_getAssociatedObject(self, (__bridge const void *)key_EventBlock);
}
@end

#pragma mark - DFPlayerSlider
@interface DFPlayerSlider : UISlider
@property (nonatomic, assign) CGFloat trackHeight;
@end
@implementation DFPlayerSlider
- (CGRect)trackRectForBounds:(CGRect)bounds{
    return CGRectMake(0, (CGRectGetHeight(self.frame)-self.trackHeight)/2, CGRectGetWidth(self.frame), self.trackHeight);
}
@end

#pragma mark -  DFPlayer控制管理器
//KEY
NSString * const DFStateKey          = @"state";
NSString * const DFBufferProgressKey = @"bufferProgress";
NSString * const DFProgressKey       = @"progress";
NSString * const DFCurrentTimeKey    = @"currentTime";
NSString * const DFTotalTimeKey      = @"totalTime";

//NOTIFICATION

//DEFINE
#define DF_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define DF_FONTSIZE(size) ((size)/1334.0)*DF_SCREEN_HEIGHT
#define DF_GREENCOLOR [UIColor colorWithRed:66.0/255.0 green:196.0/255.0 blue:133.0/255.0 alpha:1]
// 图片路径
#define DFPlayerSrcName(file) [@"DFPlayer.bundle" stringByAppendingPathComponent:file]
#define DFPlayerFrameworkSrcName(file) [@"Frameworks/DFPlayer.framework/DFPlayer.bundle" stringByAppendingPathComponent:file]
#define DFPlayerImage(file) [UIImage imageNamed:DFPlayerSrcName(file)] ? :[UIImage imageNamed:DFPlayerFrameworkSrcName(file)]
@interface DFPlayerControlManager()
@property (nonatomic, strong) UIButton          *playBtn;
@property (nonatomic, strong) UIImage           *playImage;
@property (nonatomic, strong) UIImage           *pauseImage;
@property (nonatomic, strong) UIButton          *typeBtn;
@property (nonatomic, strong) UIProgressView    *bufferProgressView;
@property (nonatomic, strong) DFPlayerSlider    *progressSlider;
@property (nonatomic, strong) UILabel           *currentTimeLabel;
@property (nonatomic, strong) UILabel           *totalTimeLabel;
@property (nonatomic, assign) BOOL              isDraging;
@property (nonatomic, assign) BOOL              isStopUpdate;
@property (nonatomic, strong) DFPlayerLyricsTableview *lyricsTableView;
@end

@implementation DFPlayerControlManager
+ (DFPlayerControlManager *)shareInstance {
    static DFPlayerControlManager *instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (UIButton *)btnWithFrame:(CGRect)frame superView:(UIView *)superView{
    UIButton *btn = [UIButton buttonWithType:(UIButtonTypeSystem)];
    btn.frame = frame;
    [superView addSubview:btn];
    return btn;
}

/**调用该方法将停止更新与进度相关的UI控件的刷新*/
- (void)df_stopUpdateProgress{
    self.isStopUpdate = YES;
}

/**调用该方法将恢复更新与进度相关的UI控件的刷新*/
- (void)df_resumeUpdateProgress{
    self.isStopUpdate = NO;
}

#pragma mark - AirPlayView
/**(下面的方法可以显示出airplay按钮，若完善airplay功能需要用到私有API，故暂不开放此方法)
 AirPlay按钮（背景图片在DFPlayer.bundle中同名替换相应的图片即可）
 airplay按钮是系统按钮，当系统检测到airplay可用时才会显示。
 
 @param frame AirPlay按钮 frame
 @param backgroundColor 背景颜色
 @param superView AirPlayView父视图
 @return AirPlayView
 */
- (UIView *_Nullable)df_airPlayViewWithFrame:(CGRect)frame
                               backgroundColor:(UIColor *_Nonnull)backgroundColor
                                     superView:(UIView *_Nonnull)superView{
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:frame];
    volumeView.backgroundColor = backgroundColor;
    volumeView.showsRouteButton = YES;
    [volumeView setRouteButtonImage:DFPlayerImage(@"dfplayer_airplay") forState:UIControlStateNormal];
    volumeView.showsVolumeSlider = NO;
    [superView addSubview:volumeView];
    for (UIView *item in volumeView.subviews) {
        if (![item isKindOfClass:NSClassFromString(@"MPButton")]) {
            [item removeFromSuperview];
        }
    }
    return volumeView;
}

#pragma mark - 播放暂停按钮
/**
 播放暂停按钮
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 播放暂停按钮
 */
- (UIButton *_Nullable)df_playPauseBtnWithFrame:(CGRect)frame
                                      superView:(UIView *)superView
                                          block:(void(^)(void))block
{
    self.playBtn    = [self btnWithFrame:frame superView:superView];
    self.playImage  = DFPlayerImage(@"dfplayer_play");
    self.pauseImage = DFPlayerImage(@"dfplayer_pause");

    if ([DFPlayer shareInstance].state == DFPlayerStatePlaying) {
        [self.playBtn setBackgroundImage:self.playImage forState:(UIControlStateNormal)];
    }else{
        [self.playBtn setBackgroundImage:self.pauseImage forState:(UIControlStateNormal)];
    }
    [[DFPlayer shareInstance] addObserver:self forKeyPath:DFStateKey options:NSKeyValueObservingOptionNew context:nil];
    self.playBtn.handleJFEventBlock = ^(UIButton *sender) {
        if ([DFPlayer shareInstance].currentAudioModel.audioUrl) {
            if ([DFPlayer shareInstance].state == DFPlayerStatePlaying) {
                [[DFPlayer shareInstance] df_audioPause];
            }else{
                [[NSNotificationCenter defaultCenter] postNotificationName:DFPlayerCurrentAudioInfoModelPlayNotiKey object:nil];
                [[DFPlayer shareInstance] df_audioPlay];
            }
         
        }else{
            NSLog(@"-- DFPlayer： 没有可播放的音频");
        }
        if (block) {
            block();
        }
    };
    return self.playBtn;
}

#pragma mark - 上一首按钮
/**
 上一首按钮
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 上一首按钮
 */
- (UIButton *_Nullable)df_lastAudioBtnWithFrame:(CGRect)frame
                                      superView:(UIView *)superView
                                          block:(void(^)(void))block
{
    UIButton *lastBtn = [self btnWithFrame:frame superView:superView];
    [lastBtn setBackgroundImage:DFPlayerImage(@"dfplayer_last") forState:(UIControlStateNormal)];
    lastBtn.handleJFEventBlock = ^(UIButton *sender) {
        [[DFPlayer shareInstance] df_audioLast];
        if (block) {
            block();
        }
    };
    return lastBtn;
}

#pragma mark - 下一首按钮
/**
 下一首按钮
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 下一首按钮
 */
- (UIButton *_Nullable)df_nextAudioBtnWithFrame:(CGRect)frame
                                      superView:(UIView *)superView
                                          block:(void(^)(void))block
{
    UIButton *nextBtn = [self btnWithFrame:frame superView:superView];
    [nextBtn setBackgroundImage:DFPlayerImage(@"dfplayer_next") forState:(UIControlStateNormal)];
    nextBtn.handleJFEventBlock = ^(UIButton *sender) {
        [[DFPlayer shareInstance] df_audioNext];
        if (block) {
            block();
        }
    };
    return nextBtn;
}

#pragma mark - 播放模式设置按钮
/**
 播放模式设置按钮(单曲循环，顺序循环，随机循环)
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 播放模式设置按钮
 
 * 注意：当设置了DFPlayer的播放模式以后，DFPlayer将为您记录用户的选择，并在下次启动app时选择用户设置的播放模式。
 如需每次启动都设置固定某一个播放模式，请在初始化播放器后，调用[DFPlayer shareInstance].playMode = XX;重置播放模式。
 */
- (UIButton *_Nullable)df_typeControlBtnWithFrame:(CGRect)frame
                                       superView:(UIView *_Nonnull)superView
                                            block:(void(^_Nullable)(void))block
{
    UIButton *button = [self btnWithFrame:frame superView:superView];
  
    switch ([DFPlayer shareInstance].playMode) {
        case DFPlayerModeSingleCycle:
            [button setBackgroundImage:DFPlayerImage(@"dfplayer_single") forState:(UIControlStateNormal)];
            break;
        case DFPlayerModeOrderCycle:
            [button setBackgroundImage:DFPlayerImage(@"dfplayer_circle") forState:(UIControlStateNormal)];
            break;
        case DFPlayerModeShuffleCycle:
            [button setBackgroundImage:DFPlayerImage(@"dfplayer_shuffle") forState:(UIControlStateNormal)];
            break;
        default:
            break;
    }
    button.handleJFEventBlock = ^(UIButton *sender) {
        switch ([DFPlayer shareInstance].playMode) {
            case DFPlayerModeSingleCycle:
                [DFPlayer shareInstance].playMode = DFPlayerModeOrderCycle;
                [sender setBackgroundImage:DFPlayerImage(@"dfplayer_circle") forState:(UIControlStateNormal)];
                break;
            case DFPlayerModeOrderCycle:
                [DFPlayer shareInstance].playMode = DFPlayerModeShuffleCycle;
                [sender setBackgroundImage:DFPlayerImage(@"dfplayer_shuffle") forState:(UIControlStateNormal)];
                break;
            case DFPlayerModeShuffleCycle:
                [DFPlayer shareInstance].playMode = DFPlayerModeSingleCycle;
                [sender setBackgroundImage:DFPlayerImage(@"dfplayer_single") forState:(UIControlStateNormal)];
                break;
            default:
                break;
        }
        if (block) {
            block();
        }
    };
    return button;
}

#pragma mark - 缓冲进度条
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
                                                  superView:(UIView *_Nonnull)superView
{
    self.bufferProgressView = [[UIProgressView alloc] initWithFrame:frame];
    self.bufferProgressView.trackTintColor = trackTintColor;
    self.bufferProgressView.progressTintColor = progressTintColor;
    [superView addSubview:self.bufferProgressView];
    [[DFPlayer shareInstance] addObserver:self forKeyPath:DFBufferProgressKey options:NSKeyValueObservingOptionNew context:nil];
    return self.bufferProgressView;
}

#pragma mark - 播放进度条
/**
 播放进度条
 
 @param frame frame
 @param minimumTrackTintColor 滑块左边的颜色
 @param maximumTrackTintColor 滑块右边的颜色
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
                               superView:(UIView *_Nonnull)superView
{
    self.progressSlider = [[DFPlayerSlider alloc] initWithFrame:frame];
    self.progressSlider.trackHeight = trackHeight;
    UIImage *img = [DFPlayerImage(@"dfplayer_oval") imageByResizeToSize:thumbSize];
    [self.progressSlider setThumbImage:img forState:UIControlStateNormal];
    self.progressSlider.minimumValue = 0;
    self.progressSlider.maximumValue = 1;
    self.progressSlider.minimumTrackTintColor = minimumTrackTintColor;
    self.progressSlider.maximumTrackTintColor = maximumTrackTintColor;
    [superView addSubview:self.progressSlider];
    
    [[DFPlayer shareInstance] addObserver:self forKeyPath:DFProgressKey options:NSKeyValueObservingOptionNew context:nil];
    
    [self.progressSlider addTarget:self action:@selector(changeProgress:) forControlEvents:UIControlEventTouchUpInside];
    //开始滑动
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    //滑动中
    [self.progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    //滑动结束
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents: UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    //点击slider
    UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSliderAction:)];
    [self.progressSlider addGestureRecognizer:sliderTap];
    return self.progressSlider;
}

- (void)changeProgress:(UISlider *)slider{
    if ([DFPlayer shareInstance].state == DFPlayerStateBuffering ||
        [DFPlayer shareInstance].state == DFPlayerStatePlaying) {
        [[DFPlayer shareInstance] df_seekToTimeWithValue:slider.value];
    }
}

- (void)progressSliderTouchBegan:(UISlider *)sender {
    self.isDraging = YES;
}

- (void)progressSliderValueChanged:(UISlider *)sender {
    NSInteger totalTime = (NSInteger)[DFPlayer shareInstance].totalTime;
    NSInteger currentTime = (totalTime * self.progressSlider.value);
    int seconds = currentTime % 60;
    int minutes = (currentTime / 60) % 60;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd",minutes,seconds];
    });
}

- (void)progressSliderTouchEnded:(UISlider *)sender {
    self.isDraging = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:DFPlayerNotificationProgressSliderDragEnd object:nil];
    [[DFPlayer shareInstance] df_seekToTimeWithValue:self.progressSlider.value];
}

- (void)tapSliderAction:(UITapGestureRecognizer *)tap {
    if ([tap.view isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)tap.view;
        CGPoint point    = [tap locationInView:slider];
        CGFloat length   = slider.frame.size.width;
        CGFloat tapValue = point.x / length;
        [[DFPlayer shareInstance] df_seekToTimeWithValue:tapValue];
    }
}

#pragma mark - 音频当前时间
/**
 音频当前时间label
 
 @param frame frame
 @param superView label父视图
 @return label
 */
- (UILabel *_Nullable)df_currentTimeLabelWithFrame:(CGRect)frame
                                         superView:(UIView *)superView{
    self.currentTimeLabel = [[UILabel alloc] init];
    self.currentTimeLabel.frame = frame;
    self.currentTimeLabel.textColor = [UIColor whiteColor];
    self.currentTimeLabel.font = [UIFont systemFontOfSize:DF_FONTSIZE(24)];
    self.currentTimeLabel.text = @"00:00";
    self.currentTimeLabel.textColor = DF_GREENCOLOR;
    self.currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    [superView addSubview:self.currentTimeLabel];
    [[DFPlayer shareInstance] addObserver:self forKeyPath:DFCurrentTimeKey options:NSKeyValueObservingOptionNew context:nil];
    return self.currentTimeLabel;
}

#pragma mark - 音频总时长
/**
 音频总时长label
 
 @param frame frame
 @param superView label父视图
 @return label
 */
- (UILabel *_Nullable)df_totalTimeLabelWithFrame:(CGRect)frame
                                       superView:(UIView *)superView{
    
    self.totalTimeLabel = [[UILabel alloc] init];
    self.totalTimeLabel.frame = frame;
    self.totalTimeLabel.font = [UIFont systemFontOfSize:DF_FONTSIZE(24)];
    self.totalTimeLabel.text = @"00:00";
    self.totalTimeLabel.textColor = DF_GREENCOLOR;
    self.totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    [superView addSubview:self.totalTimeLabel];
    [[DFPlayer shareInstance] addObserver:self forKeyPath:DFTotalTimeKey options:NSKeyValueObservingOptionNew context:nil];

    return self.totalTimeLabel;
}


#pragma mark - KVO
- (void)setUpCurrentTimeLabelTextWithCurrentTime:(CGFloat)currentTime{
    NSInteger time = currentTime;
    int seconds = time % 60;
    int minutes = (time / 60) % 60;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd",minutes,seconds];
    });
}

- (void)setUpTotalTimeLabelTextWithTotalTime:(CGFloat)totalTime{
    NSInteger time = totalTime;
    int seconds = time % 60;
    int minutes = (time / 60) % 60;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.totalTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd",minutes,seconds];
    });
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == [DFPlayer shareInstance]) {
        if ([keyPath isEqualToString:DFStateKey]) {
            if (!self.isDraging) {
                if ([DFPlayer shareInstance].state == DFPlayerStateBuffering ||
                    [DFPlayer shareInstance].state == DFPlayerStatePlaying) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.playBtn setBackgroundImage:self.playImage forState:(UIControlStateNormal)];
                    });
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.playBtn setBackgroundImage:self.pauseImage forState:(UIControlStateNormal)];
                    });
                }
            }
        }else if ([keyPath isEqualToString:DFBufferProgressKey]){
            if (!self.isStopUpdate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.bufferProgressView setProgress:[DFPlayer shareInstance].bufferProgress];
                });
            }
        }else if ([keyPath isEqualToString:DFProgressKey]){
//            if ([DFPlayer shareInstance].state == DFPlayerStateBuffering ||
//                [DFPlayer shareInstance].state == DFPlayerStatePlaying) {
            if (!self.isStopUpdate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.progressSlider.state != UIControlStateHighlighted) {
                        self.progressSlider.value = [DFPlayer shareInstance].progress;
                    }
                });
            }
        
//            }
        }else if ([keyPath isEqualToString:DFCurrentTimeKey]){
            if (!self.isStopUpdate) {
                if (!self.isDraging) {
                    CGFloat currentTime = [DFPlayer shareInstance].currentTime;
                    [self setUpCurrentTimeLabelTextWithCurrentTime:currentTime];
                }
            }
        }else if ([keyPath isEqualToString:DFTotalTimeKey]){
            if (!self.isStopUpdate) {
                NSInteger totalTime = [DFPlayer shareInstance].totalTime;
                [self setUpTotalTimeLabelTextWithTotalTime:totalTime];
            }
        }
    }
}

- (void)dealloc{
    [[DFPlayer shareInstance] removeObserver:self forKeyPath:DFStateKey];
    [[DFPlayer shareInstance] removeObserver:self forKeyPath:DFBufferProgressKey];
    [[DFPlayer shareInstance] removeObserver:self forKeyPath:DFProgressKey];
    [[DFPlayer shareInstance] removeObserver:self forKeyPath:DFCurrentTimeKey];
    [[DFPlayer shareInstance] removeObserver:self forKeyPath:DFTotalTimeKey];
}


#pragma mark - 歌词tableView
/**
歌词tableview

@param frame tableview frame
@param contentInset  tableview contentInset
@param cellRowHeight tableview 单行rowHeight
@param cellBackgroundColor cell背景色
@param currentLineLrcForegroundTextColor 当前行歌词文字前景色（此属性不为空时，采用卡拉OK模式显示）
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
                                          clickBlock:(void(^_Nullable)(NSIndexPath * _Nullable indexpath))clickBlock{
    self.lyricsTableView.frame                             = frame;
    self.lyricsTableView.contentInset                      = contentInset;
    self.lyricsTableView.backgroundColor                   = cellBackgroundColor;
    self.lyricsTableView.showsVerticalScrollIndicator      = NO;
    self.lyricsTableView.cellRowHeight                     = cellRowHeight;
    self.lyricsTableView.cellBackgroundColor               = cellBackgroundColor;
    self.lyricsTableView.currentLineLrcForegroundTextColor = currentLineLrcForegroundTextColor;
    self.lyricsTableView.currentLineLrcBackgroundTextColor = currentLineLrcBackgroundTextColor;
    self.lyricsTableView.otherLineLrcBackgroundTextColor   = otherLineLrcBackgroundTextColor;
    self.lyricsTableView.currentLineLrcFont                = currentLineLrcFont;
    self.lyricsTableView.otherLineLrcFont                  = otherLineLrcFont;
    self.lyricsTableView.lrcTableViewSuperview             = superView;
    [superView addSubview:self.lyricsTableView];
    self.lyricsTableView.clickBlock = ^(NSIndexPath *indexPath) {
        if (clickBlock) {
            clickBlock(indexPath);
        }
    };
    return self.lyricsTableView;
}

/**停止更新lyricTableview中歌词的刷新*/
- (void)df_playerLyricTableviewStopUpdate{
    self.lyricsTableView.isStopUpdateLrc = YES;
}
/**恢复更新lyricTableview中歌词的刷新*/
- (void)df_playerLyricTableviewResumeUpdate{
    self.lyricsTableView.isStopUpdateLrc = NO;
}
- (DFPlayerLyricsTableview *)lyricsTableView{
    if (!_lyricsTableView) {
        _lyricsTableView = [[DFPlayerLyricsTableview alloc] init];
    }
    return _lyricsTableView;
}
@end
