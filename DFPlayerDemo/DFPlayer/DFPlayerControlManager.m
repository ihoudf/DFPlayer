//
//  DFPlayerControlManager.m
//  DFPlayer
//
//  Created by Faroe on 2017/7/20.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayerControlManager.h"
#import "DFPlayerManager.h"
#import <objc/runtime.h>
#import "DFPlayerTool.h"
#import "DFPlayerLyricsTableview.h"

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
NSString * const DFPlayerLyricTableviewStopUpdateNotification = @"DFPlayerLyricTableviewStopUpdateNotification";
NSString * const DFPlayerLyricTableviewResumeUpdateNotification = @"DFPlayerLyricTableviewResumeUpdateNotification";

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

#pragma mark - AirPlayView

/**
 AirPlayView
 
 @param frame AirPlayView frame
 @param backgroundColor 背景颜色
 @param superView AirPlayView父视图
 @return AirPlayView
 */
- (UIView *)df_airPlayViewWithFrame:(CGRect)frame
                    backgroundColor:(UIColor *)backgroundColor
                          superView:(UIView *)superView{
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:frame];
    volumeView.backgroundColor = backgroundColor;
    volumeView.showsRouteButton = YES;
    volumeView.showsVolumeSlider = NO;
    for (UIView *item in volumeView.subviews) {
        if (![item isKindOfClass:NSClassFromString(@"MPButton")]) {
            [item removeFromSuperview];
        }
    }
    [superView addSubview:volumeView];
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
- (UIButton *)df_playPauseBtnWithFrame:(CGRect)frame
                             superView:(UIView *)superView
                                 block:(void(^)(void))block
{
    self.playBtn    = [self btnWithFrame:frame superView:superView];
    self.playImage  = DFPlayerImage(@"dfplayer_play");
    self.pauseImage = DFPlayerImage(@"dfplayer_pause");

    if ([DFPlayerManager shareInstance].state == DFPlayerStatePlaying) {
        [self.playBtn setBackgroundImage:self.playImage forState:(UIControlStateNormal)];
    }else{
        [self.playBtn setBackgroundImage:self.pauseImage forState:(UIControlStateNormal)];
    }
    [[DFPlayerManager shareInstance] addObserver:self forKeyPath:DFStateKey options:NSKeyValueObservingOptionNew context:nil];
    self.playBtn.handleJFEventBlock = ^(UIButton *sender) {
        if ([DFPlayerManager shareInstance].currentAudioModel.audioUrl) {
            if ([DFPlayerManager shareInstance].state == DFPlayerStatePlaying) {
                [[DFPlayerManager shareInstance] df_audioPause];
            }else{
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"DFPlayerLoadPreviousAudioModelNotification" object:nil];
                });
                [[DFPlayerManager shareInstance] df_audioPlay];
            }
        }else{
            NSLog(@"--没有可播放的音频");
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
- (UIButton *)df_lastAudioBtnWithFrame:(CGRect)frame
                             superView:(UIView *)superView
                                 block:(void(^)(void))block
{
    UIButton *lastBtn = [self btnWithFrame:frame superView:superView];
    [lastBtn setBackgroundImage:DFPlayerImage(@"dfplayer_last") forState:(UIControlStateNormal)];
    lastBtn.handleJFEventBlock = ^(UIButton *sender) {
        [[DFPlayerManager shareInstance] df_audioLast];
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
- (UIButton *)df_nextAudioBtnWithFrame:(CGRect)frame
                             superView:(UIView *)superView
                                 block:(void(^)(void))block
{
    UIButton *nextBtn = [self btnWithFrame:frame superView:superView];
    [nextBtn setBackgroundImage:DFPlayerImage(@"dfplayer_next") forState:(UIControlStateNormal)];
    nextBtn.handleJFEventBlock = ^(UIButton *sender) {
        [[DFPlayerManager shareInstance] df_audioNext];
        if (block) {
            block();
        }
    };
    return nextBtn;
}

#pragma mark - 播放类型设置按钮
/**
 播放类型设置按钮(单曲循环，顺序循环，随机循环)
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 播放类型设置按钮
 
 * 注意：当设置了DFPlayer的播放类型以后，DFPlayer将为您记录用户的选择，并在下次启动app时选择用户设置的播放类型。
 如需每次启动都设置固定某一个播放类型，请在初始化播放器后，调用[DFPlayerManager shareInstance].type = XX;重置播放类型。
 */
- (UIButton *_Nullable)df_typeControlBtnWithFrame:(CGRect)frame
                                       superView:(UIView *_Nonnull)superView
                                            block:(void(^_Nullable)(void))block
{
    UIButton *button = [self btnWithFrame:frame superView:superView];
    switch ([DFPlayerManager shareInstance].type) {
        case DFPlayerTypeSingleCycle | DFPlayerTypeOnlyOnce:
            [button setBackgroundImage:DFPlayerImage(@"dfplayer_single") forState:(UIControlStateNormal)];
            break;
        case DFPlayerTypeOrderCycle:
            [button setBackgroundImage:DFPlayerImage(@"dfplayer_circle") forState:(UIControlStateNormal)];
            break;
        case DFPlayerTypeShuffleCycle:
            [button setBackgroundImage:DFPlayerImage(@"dfplayer_shuffle") forState:(UIControlStateNormal)];
            break;
        default:
            break;
    }
    button.handleJFEventBlock = ^(UIButton *sender) {
        switch ([DFPlayerManager shareInstance].type) {
            case DFPlayerTypeSingleCycle:
                [DFPlayerManager shareInstance].type = DFPlayerTypeOrderCycle;
                [sender setBackgroundImage:DFPlayerImage(@"dfplayer_circle") forState:(UIControlStateNormal)];
                break;
            case DFPlayerTypeOrderCycle:
                [DFPlayerManager shareInstance].type = DFPlayerTypeShuffleCycle;
                [sender setBackgroundImage:DFPlayerImage(@"dfplayer_shuffle") forState:(UIControlStateNormal)];
                break;
            case DFPlayerTypeShuffleCycle:
                [DFPlayerManager shareInstance].type = DFPlayerTypeSingleCycle;
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
- (UIProgressView *)df_bufferProgressViewWithFrame:(CGRect)frame
                                    trackTintColor:(UIColor *)trackTintColor
                                 progressTintColor:(UIColor *)progressTintColor
                                         superView:(UIView *)superView
{
    self.bufferProgressView = [[UIProgressView alloc] initWithFrame:frame];
    self.bufferProgressView.trackTintColor = trackTintColor;
    self.bufferProgressView.progressTintColor = progressTintColor;
    [superView addSubview:self.bufferProgressView];
    [[DFPlayerManager shareInstance] addObserver:self forKeyPath:DFBufferProgressKey options:NSKeyValueObservingOptionNew context:nil];
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
    if ([DFPlayerManager shareInstance].isObservePreviousAudioModel) {
        self.progressSlider.value = [DFPlayerManager shareInstance].previousAudioModel.progress;
    }
    self.progressSlider.minimumValue = 0;
    self.progressSlider.maximumValue = 1;
    self.progressSlider.minimumTrackTintColor = minimumTrackTintColor;
    self.progressSlider.maximumTrackTintColor = maximumTrackTintColor;
    [superView addSubview:self.progressSlider];
    
    [[DFPlayerManager shareInstance] addObserver:self forKeyPath:DFProgressKey options:NSKeyValueObservingOptionNew context:nil];
    
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
    if ([DFPlayerManager shareInstance].state == DFPlayerStateBuffering ||
        [DFPlayerManager shareInstance].state == DFPlayerStatePlaying) {
        [[DFPlayerManager shareInstance] df_seekToTimeWithValue:slider.value];
    }
}

- (void)progressSliderTouchBegan:(UISlider *)sender {
    self.isDraging = YES;
}

- (void)progressSliderValueChanged:(UISlider *)sender {
    NSInteger totalTime = (NSInteger)[DFPlayerManager shareInstance].totalTime;
    NSInteger currentTime = (totalTime * self.progressSlider.value);
    int seconds = currentTime % 60;
    int minutes = (currentTime / 60) % 60;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd",minutes,seconds];
    });
}

- (void)progressSliderTouchEnded:(UISlider *)sender {
    self.isDraging = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:DFPLayerNotificationDragStatus object:nil];
    [[DFPlayerManager shareInstance] df_seekToTimeWithValue:self.progressSlider.value];
    
}

- (void)tapSliderAction:(UITapGestureRecognizer *)tap {
    if ([tap.view isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)tap.view;
        CGPoint point    = [tap locationInView:slider];
        CGFloat length   = slider.frame.size.width;
        CGFloat tapValue = point.x / length;
        [[DFPlayerManager shareInstance] df_seekToTimeWithValue:tapValue];
    }
}

#pragma mark - 音频当前时间
/**
 音频当前时间label
 
 @param frame frame
 @param superView label父视图
 @return label
 */
- (UILabel *)df_currentTimeLabelWithFrame:(CGRect)frame
                                superView:(UIView *)superView{
    self.currentTimeLabel = [[UILabel alloc] init];
    self.currentTimeLabel.frame = frame;
    self.currentTimeLabel.textColor = [UIColor whiteColor];
    self.currentTimeLabel.font = [UIFont systemFontOfSize:DF_FONTSIZE(24)];
    self.currentTimeLabel.text = @"00:00";
    self.currentTimeLabel.textColor = DF_GREENCOLOR;
    self.currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    if ([DFPlayerManager shareInstance].isObservePreviousAudioModel) {
        CGFloat currentTime = [DFPlayerManager shareInstance].previousAudioModel.currentTime;
        [self setUpCurrentTimeLabelTextWithCurrentTime:currentTime];
    }
    [superView addSubview:self.currentTimeLabel];
    [[DFPlayerManager shareInstance] addObserver:self forKeyPath:DFCurrentTimeKey options:NSKeyValueObservingOptionNew context:nil];
    return self.currentTimeLabel;
}

#pragma mark - 音频总时长
/**
 音频总时长label
 
 @param frame frame
 @param superView label父视图
 @return label
 */
- (UILabel *)df_totalTimeLabelWithFrame:(CGRect)frame
                              superView:(UIView *)superView{
    
    self.totalTimeLabel = [[UILabel alloc] init];
    self.totalTimeLabel.frame = frame;
    self.totalTimeLabel.font = [UIFont systemFontOfSize:DF_FONTSIZE(24)];
    self.totalTimeLabel.text = @"00:00";
    self.totalTimeLabel.textColor = DF_GREENCOLOR;
    self.totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    if ([DFPlayerManager shareInstance].isObservePreviousAudioModel) {
        CGFloat totalTime = [DFPlayerManager shareInstance].previousAudioModel.totalTime;
        [self setUpTotalTimeLabelTextWithTotalTime:totalTime];
    }
    [superView addSubview:self.totalTimeLabel];
    [[DFPlayerManager shareInstance] addObserver:self forKeyPath:DFTotalTimeKey options:NSKeyValueObservingOptionNew context:nil];

    return self.totalTimeLabel;
}


#pragma mark - KVO
- (void)setUpCurrentTimeLabelTextWithCurrentTime:(CGFloat)currentTime{
    NSInteger time = floorf(currentTime);
    int seconds = time % 60;
    int minutes = (time / 60) % 60;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd",minutes,seconds];
    });
}

- (void)setUpTotalTimeLabelTextWithTotalTime:(CGFloat)totalTime{
    if (totalTime) {
        NSInteger time = ceilf(totalTime);
        int seconds = time % 60;
        int minutes = (time / 60) % 60;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.totalTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd",minutes,seconds];
        });
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == [DFPlayerManager shareInstance]) {
        if ([keyPath isEqualToString:DFStateKey]) {
            if (!self.isDraging) {
                if ([DFPlayerManager shareInstance].state == DFPlayerStateBuffering ||
                    [DFPlayerManager shareInstance].state == DFPlayerStatePlaying) {
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
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.bufferProgressView setProgress:[DFPlayerManager shareInstance].bufferProgress];
            });
            
        }else if ([keyPath isEqualToString:DFProgressKey]){
//            if ([DFPlayerManager shareInstance].state == DFPlayerStateBuffering ||
//                [DFPlayerManager shareInstance].state == DFPlayerStatePlaying) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.progressSlider.state != UIControlStateHighlighted) {
                        self.progressSlider.value = [DFPlayerManager shareInstance].progress;
                }
           });
//            }
        }else if ([keyPath isEqualToString:DFCurrentTimeKey]){
            if (!self.isDraging) {
                CGFloat currentTime = [DFPlayerManager shareInstance].currentTime;
                [self setUpCurrentTimeLabelTextWithCurrentTime:currentTime];
            }
        }else if ([keyPath isEqualToString:DFTotalTimeKey]){
            NSInteger totalTime = [DFPlayerManager shareInstance].totalTime;
            [self setUpTotalTimeLabelTextWithTotalTime:totalTime];
        }
    }
}

- (void)dealloc{
    [[DFPlayerManager shareInstance] removeObserver:self forKeyPath:DFStateKey];
    [[DFPlayerManager shareInstance] removeObserver:self forKeyPath:DFBufferProgressKey];
    [[DFPlayerManager shareInstance] removeObserver:self forKeyPath:DFProgressKey];
    [[DFPlayerManager shareInstance] removeObserver:self forKeyPath:DFCurrentTimeKey];
    [[DFPlayerManager shareInstance] removeObserver:self forKeyPath:DFTotalTimeKey];
}


#pragma mark - 歌词tableView
/**
歌词tableview

@param frame tableview frame
@param cellRowHeight tableview 单行rowHeight
@param cellBackgroundColor cell背景色
@param currentLineLrcForegroundTextColor 当前行歌词文字前景色（此属性不为空时，采用卡拉OK模式显示）
@param currentLineLrcBackgroundTextColor 当前行歌词文字背景色
@param otherLineLrcBackgroundTextColor 其他行歌词文字颜色
@param currentLineLrcFont 当前行歌词字体
@param otherLineLrcFont 其他行歌词字体
@param superView 父视图
@param block 点击某个歌词cell。indexpath：该行cell的indexpath
@return 歌词tableView
*/
- (UITableView *_Nullable)df_lyricTableViewWithFrame:(CGRect)frame
                                       cellRowHeight:(CGFloat)cellRowHeight
                                 cellBackgroundColor:(UIColor *_Nullable)cellBackgroundColor
                   currentLineLrcForegroundTextColor:(UIColor *_Nullable)currentLineLrcForegroundTextColor
                   currentLineLrcBackgroundTextColor:(UIColor *_Nonnull)currentLineLrcBackgroundTextColor
                     otherLineLrcBackgroundTextColor:(UIColor *_Nonnull)otherLineLrcBackgroundTextColor
                                  currentLineLrcFont:(UIFont *_Nonnull)currentLineLrcFont
                                    otherLineLrcFont:(UIFont *_Nonnull)otherLineLrcFont
                                           superView:(UIView *_Nonnull)superView
                                               block:(void(^_Nullable)(NSIndexPath * _Nullable indexpath))block{
    self.lyricsTableView.frame                             = frame;
    self.lyricsTableView.cellRowHeight                     = cellRowHeight;
    CGFloat insets = frame.size.height/2-cellRowHeight/2;
    self.lyricsTableView.contentInset                      = UIEdgeInsetsMake(insets, 0, insets, 0);
    self.lyricsTableView.cellBackgroundColor               = cellBackgroundColor;
    self.lyricsTableView.currentLineLrcForegroundTextColor = currentLineLrcForegroundTextColor;
    self.lyricsTableView.currentLineLrcBackgroundTextColor = currentLineLrcBackgroundTextColor;
    self.lyricsTableView.otherLineLrcBackgroundTextColor   = otherLineLrcBackgroundTextColor;
    self.lyricsTableView.currentLineLrcFont                = currentLineLrcFont;
    self.lyricsTableView.otherLineLrcFont                  = otherLineLrcFont;
    self.lyricsTableView.DFPlayerLyricTableviewStopUpdateNotification = DFPlayerLyricTableviewStopUpdateNotification;
    self.lyricsTableView.DFPlayerLyricTableviewResumeUpdateNotification = DFPlayerLyricTableviewResumeUpdateNotification;
    [superView addSubview:self.lyricsTableView];
    self.lyricsTableView.block = ^(NSIndexPath *indexPath) {
        if (block) {
            block(indexPath);
        }
    };
    return self.lyricsTableView;
}
- (DFPlayerLyricsTableview *)lyricsTableView{
    if (!_lyricsTableView) {
        _lyricsTableView = [[DFPlayerLyricsTableview alloc] init];
    }
    return _lyricsTableView;
}
@end
