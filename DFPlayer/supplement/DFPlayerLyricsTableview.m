//
//  DFPlayerLyricsTableview.m
//  DFPlayer
//
//  Created by HDF on 2017/8/16.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayerLyricsTableview.h"
#import "DFPlayer.h"
@interface DFPlayerLyricsTableViewCell : UITableViewCell
@property (nonatomic, strong) UILabel *backgroundLrcLabel;
@property (nonatomic, strong) UILabel *foregroundLrcLabel;
@property (nonatomic, strong) CALayer *lrcMasklayer;
@end
@implementation DFPlayerLyricsTableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundLrcLabel = [[UILabel alloc] init];
        self.backgroundLrcLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.backgroundLrcLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.backgroundLrcLabel];
        
        self.foregroundLrcLabel = [[UILabel alloc] init];
        self.foregroundLrcLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.foregroundLrcLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.foregroundLrcLabel];
        
        self.lrcMasklayer = [CALayer layer];
        self.lrcMasklayer.anchorPoint = CGPointMake(0, 0.5);
        self.foregroundLrcLabel.layer.mask = self.lrcMasklayer;
    }
    return self;
}
@end

static NSString *DFPlayerLyricStateKey = @"state";
static NSString *DFPlayerLyricCurrentTimeKey = @"currentTime";
static NSString *DFPlayerLyricCurrentAudioInfoModelKey = @"currentAudioInfoModel";
static NSString *DFPlayerLyricConstMark = @"####";

static NSString *DFPlayerlyricNoticeStr_zh_unavailable = @"暂无可用歌词";
static NSString *DFPlayerlyricNoticeStr_en_unavailable = @"Unavailable Data";

#define DF_FONTSIZE(size) ((size)/1334.0)*DF_SCREEN_HEIGHT
#define DF_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface DFPlayerLyricsTableview ()
<UITableViewDelegate,
UITableViewDataSource,
UIScrollViewDelegate>
/**歌词数组*/
@property (nonatomic, strong) NSMutableArray *lyricArray;
/**时间数组*/
@property (nonatomic, strong) NSMutableArray *timeArray;
/**解析临时字典*/
@property (nonatomic, strong) NSMutableDictionary *tempLrcDictionary;
/**提示View*/
@property (nonatomic, strong) UILabel *noticeLabel;
/**当前AudioUrl*/
@property (nonatomic, strong) NSURL *audioUrl;

/**歌词当前行Index数组*/
@property (nonatomic, strong) NSMutableArray *currentIndexArray;
/**歌词当前行标记*/
@property (nonatomic, assign) NSInteger currentIndex;
/**歌词当前行IndexPath*/
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
/**标记*/
@property (nonatomic, assign) NSInteger lastIndex;
/**歌词上一行IndexPath*/
@property (nonatomic, strong) NSIndexPath *lastIndexPath;
/**等待恢复行的indexpath*/
@property (nonatomic, assign) NSIndexPath *waitResetIndexpath;
/**是否已经恢复恢复等待行*/
@property (nonatomic, assign) BOOL isResetWaitIndexpath;
/**是否拖拽歌词*/
@property (nonatomic, assign) BOOL isDraging;
/**是否继续滚动*/
@property (nonatomic, assign) BOOL isDecelerate;
/**是否拖拽进度结束*/
@property (nonatomic, assign) BOOL isProgressSliderDragEnd;
/**遮罩*/
@property (nonatomic, strong) CALayer *maskLayer;
/**偏移时间。首次进入和拖拽后设置*/
@property (nonatomic, assign) CGFloat timeOffset;

@end

@implementation DFPlayerLyricsTableview
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:DFPlayerNotificationProgressSliderDragEnd];
    [[DFPlayer shareInstance] removeObserver:self forKeyPath:DFPlayerLyricStateKey];
    [[DFPlayer shareInstance] removeObserver:self forKeyPath:DFPlayerLyricCurrentTimeKey];
    [[DFPlayer shareInstance] removeObserver:self forKeyPath:DFPlayerLyricCurrentAudioInfoModelKey];
}
- (NSMutableArray *)lyricArray{
    if (!_lyricArray) {
        _lyricArray = [NSMutableArray array];
    }
    return _lyricArray;
}
- (NSMutableArray *)timeArray{
    if (!_timeArray) {
        _timeArray = [NSMutableArray array];
    }
    return _timeArray;
}
- (NSMutableDictionary *)tempLrcDictionary{
    if (!_tempLrcDictionary) {
        _tempLrcDictionary = [NSMutableDictionary dictionary];
    }
    return _tempLrcDictionary;
}
- (NSMutableArray *)currentIndexArray{
    if (!_currentIndexArray) {
        _currentIndexArray = [NSMutableArray array];
    }
    return _currentIndexArray;
}
- (UILabel *)noticeLabel{
    if (!_noticeLabel) {
        _noticeLabel = [[UILabel alloc] init];
        _noticeLabel.frame = CGRectMake(self.frame.size.width, (self.frame.size.height-self.cellRowHeight)/2, self.frame.size.width, self.cellRowHeight);
        _noticeLabel.hidden = YES;
        if ([self isZhHansApplesLauguages]) {
            _noticeLabel.text = DFPlayerlyricNoticeStr_zh_unavailable;
        }else{
            _noticeLabel.text = DFPlayerlyricNoticeStr_en_unavailable;
        }
        _noticeLabel.backgroundColor = self.cellBackgroundColor;
        if (self.currentLineLrcForegroundTextColor) {
            _noticeLabel.textColor = self.currentLineLrcForegroundTextColor;
        }else{
            _noticeLabel.textColor = self.otherLineLrcBackgroundTextColor;
        }
        _noticeLabel.textAlignment = NSTextAlignmentCenter;
        _noticeLabel.font = self.otherLineLrcFont;
        [self.lrcTableViewSuperview addSubview:_noticeLabel];
        [self.lrcTableViewSuperview bringSubviewToFront:_noticeLabel];
    }
    return _noticeLabel;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.isDraging = NO;
        self.lastIndex = -1;
        self.delegate = self;
        self.dataSource = self;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        if (@available(iOS 11.0,*)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_progressSliderDragEnd) name:DFPlayerNotificationProgressSliderDragEnd object:nil];
        [[DFPlayer shareInstance] addObserver:self forKeyPath:DFPlayerLyricStateKey options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
        [[DFPlayer shareInstance] addObserver:self forKeyPath:DFPlayerLyricCurrentTimeKey options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
        [[DFPlayer shareInstance] addObserver:self forKeyPath:DFPlayerLyricCurrentAudioInfoModelKey options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
    }
    return self;
}


- (void)setIsStopUpdateLrc:(BOOL)isStopUpdateLrc{
    _isStopUpdateLrc = isStopUpdateLrc;
    [self df_updateLyricsTextWithAnimation:YES];
}
- (void)df_progressSliderDragEnd{
    self.isProgressSliderDragEnd = YES;
    [self df_updateLyricsTextWithAnimation:YES];
}
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == [DFPlayer shareInstance]) {
        if ([keyPath isEqualToString:DFPlayerLyricStateKey]) {
            if ([DFPlayer shareInstance].state == DFPlayerStatePlaying) {
                [self df_resumeLayer:self.maskLayer];
            }else{
                [self df_pauseLayer:self.maskLayer];
            }
        }else if ([keyPath isEqualToString:DFPlayerLyricCurrentTimeKey]){
            [self df_updateLyricsTextWithAnimation:YES];
            
        }else if ([keyPath isEqualToString:DFPlayerLyricCurrentAudioInfoModelKey]){
            [self df_lyricAnalyze];
        }
    }
}
#pragma mark - 更新歌词信息
- (void)df_updateLyricsTextWithAnimation:(BOOL)animation{
    //停止更新
    if (self.isStopUpdateLrc) {[self df_pauseLayer:self.maskLayer];return;}
    if (self.timeArray.count <= 0 || self.lyricArray.count <= 0) {return;}
    if (self.currentIndexArray.count > 0) {[self.currentIndexArray removeAllObjects];}
    self.timeOffset = 0;

    //获取当前行
    CGFloat currentTime = [DFPlayer shareInstance].currentTime;
    if (self.isProgressSliderDragEnd || !animation) {
        for (int i = 0; i < self.timeArray.count; i++) {
            int time = [self.timeArray[i] intValue];
            if (currentTime >= time) {
                self.currentIndex = i;
                //获取偏移时间
                if (self.currentLineLrcForegroundTextColor) {
                    self.timeOffset = currentTime - [self.timeArray[i] floatValue];
                }
            }
            if (time > currentTime) {break;}
        }
    }else{
        for (int i = 0; i < self.timeArray.count; i++) {
            int time = [self.timeArray[i] intValue];
            if (currentTime == time) {
                [self.currentIndexArray addObject:[NSString stringWithFormat:@"%d",i]];
                self.currentIndex = i;
            }
            if (time > currentTime) {break;}
        }
    }
 
    
    if (self.lastIndex == self.currentIndex) {return;}
    if (self.lastIndex >= 0) {self.lastIndexPath = [NSIndexPath indexPathForRow:self.lastIndex inSection:0];}
    self.lastIndex = self.currentIndex;
    
    if (self.isProgressSliderDragEnd) {//进度回滚，恢复正在播放的当前行
        [self resetOldCellIndexPath:self.currentIndexPath];        
    }
    self.currentIndexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    
    //当前行移动到中间
    if (self.isProgressSliderDragEnd || !animation) {
        [self df_scrollToMiddleCellAnimation:NO];
    }else{
        [self df_scrollToMiddleCellAnimation:YES];
    }
    
    //更新当前行
    [self updateCurrentCellUIWithAnimation:animation];
}

/**刷新当前行*/
- (void)updateCurrentCellUIWithAnimation:(BOOL)animation{
    //同一分同一秒存在两句以上歌词
    if (self.currentIndexArray.count > 1) {
        for (int i = 0; i < self.currentIndexArray.count-1; i++) {
            int index = [self.currentIndexArray[i] intValue];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                DFPlayerLyricsTableViewCell *cell = (DFPlayerLyricsTableViewCell *)[self cellForRowAtIndexPath:indexPath];
                cell.foregroundLrcLabel.hidden = YES;
                if (self.currentLineLrcForegroundTextColor) {//卡拉ok模式
                    cell.backgroundLrcLabel.textColor = self.currentLineLrcForegroundTextColor;
                    cell.backgroundLrcLabel.font = self.currentLineLrcFont;
                }else{
                    cell.backgroundLrcLabel.textColor   = self.currentLineLrcBackgroundTextColor;
                    cell.backgroundLrcLabel.font        = self.currentLineLrcFont;
                }
                if (self.currentLineLrcFont.pointSize != self.otherLineLrcFont.pointSize) {
                    CGRect currentLabelRect = [self fitLrcLabelSizeWithLabel:cell.backgroundLrcLabel];
                    cell.foregroundLrcLabel.frame = cell.backgroundLrcLabel.frame = currentLabelRect;
                }
            });
            [self performSelector:@selector(resetOldCellWithCurrentIndexArray:) withObject:indexPath afterDelay:0.2];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        //当前行
        DFPlayerLyricsTableViewCell *cell = (DFPlayerLyricsTableViewCell *)[self cellForRowAtIndexPath:self.currentIndexPath];
        if (!self.isProgressSliderDragEnd) {
            //如果当前行无歌词，记录位置并返回
            NSString *noNilStr = [self removeNilWithStr:cell.foregroundLrcLabel.text];
            if (noNilStr.length == 0 || [noNilStr isEqualToString:DFPlayerLyricConstMark]) {
                if (!self.isResetWaitIndexpath) {
                    [self resetOldCellIndexPath:self.waitResetIndexpath];
                }
                self.isResetWaitIndexpath = NO;
                self.waitResetIndexpath = self.lastIndexPath;return;
            }
        }
        self.isProgressSliderDragEnd = NO;

        //还原旧行
        [self resetOldCellIndexPath:self.lastIndexPath];
        //还原等待恢复行
        if (self.waitResetIndexpath) {
            self.isResetWaitIndexpath = YES;
            [self resetOldCellIndexPath:self.waitResetIndexpath];
            self.waitResetIndexpath = nil;
        }

        //设置当前行
        cell.backgroundLrcLabel.textColor   = self.currentLineLrcBackgroundTextColor;
        cell.backgroundLrcLabel.font        = self.currentLineLrcFont;
        if (self.currentLineLrcFont.pointSize != self.otherLineLrcFont.pointSize) {
            CGRect currentLabelRect = [self fitLrcLabelSizeWithLabel:cell.backgroundLrcLabel];
            cell.foregroundLrcLabel.frame = cell.backgroundLrcLabel.frame = currentLabelRect;
        }
        //如果是卡拉OK模式
        if (self.currentLineLrcForegroundTextColor) {
            cell.foregroundLrcLabel.hidden      =  NO;
            cell.foregroundLrcLabel.textColor   = self.currentLineLrcForegroundTextColor;
            cell.foregroundLrcLabel.font        = self.currentLineLrcFont;
            cell.lrcMasklayer.position          = CGPointMake(0, self.cellRowHeight/2);
            cell.lrcMasklayer.bounds            = CGRectMake(0, 0, 0, self.cellRowHeight);
            cell.lrcMasklayer.backgroundColor   = [UIColor whiteColor].CGColor;
            self.maskLayer                      = cell.lrcMasklayer;
            
            CGFloat duration = 0;
            if (self.timeArray.count == 0 || self.lyricArray.count == 0) {return;}//安全性判断
            if (self.currentIndex < self.timeArray.count - 1) {
                duration = fabsf([self.timeArray[self.currentIndex+1] floatValue]-[self.timeArray[self.currentIndex] floatValue]);
            }else{//最后一句歌词
                if (![self IsNilWithStr:self.lyricArray.lastObject]) {//如果最后一句不为空
                    duration = fabs([DFPlayer shareInstance].totalTime - [self.timeArray[self.currentIndex] floatValue]-0.2);
                }
            }
            
            if (duration != 0) {
                CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"bounds.size.width"];
                NSNumber *end = [NSNumber numberWithFloat:cell.foregroundLrcLabel.frame.size.width];
                anim.values = @[@(0),end];
                anim.keyTimes = @[@(0),@(1)];
                anim.duration = duration;
                anim.timeOffset = self.timeOffset;
                anim.calculationMode = kCAAnimationLinear;
                anim.fillMode = kCAFillModeForwards;
                anim.removedOnCompletion = NO;
                anim.autoreverses = NO;
                [self.maskLayer addAnimation:anim forKey:@"Animation"];
                if (!animation) {self.maskLayer.speed = 0.0;}
//                CGFloat tt = duration - self.timeOffset;
            }
        }else{
            cell.foregroundLrcLabel.hidden = YES;
        }
    });
}

/**恢复旧行*/
- (void)resetOldCellWithCurrentIndexArray:(id)value{
    NSIndexPath *indexPath = (NSIndexPath *)value;
    [self resetOldCellIndexPath:indexPath];
}
- (void)resetOldCellIndexPath:(NSIndexPath *)indexPath{
    DFPlayerLyricsTableViewCell *cell   = (DFPlayerLyricsTableViewCell *)[self cellForRowAtIndexPath:indexPath];
    cell.backgroundLrcLabel.textColor   = self.otherLineLrcBackgroundTextColor;
    cell.backgroundLrcLabel.font        = self.otherLineLrcFont;
    cell.foregroundLrcLabel.hidden      = YES;
    if (self.currentLineLrcFont.pointSize != self.otherLineLrcFont.pointSize) {
        CGRect lastLabelRect = [self fitLrcLabelSizeWithLabel:cell.backgroundLrcLabel];
        cell.foregroundLrcLabel.frame = cell.backgroundLrcLabel.frame = lastLabelRect;
    }
}

/**cell移动*/
- (void)df_scrollToMiddleCellAnimation:(BOOL)aniamtion{
    if (!self.isDraging && self.currentIndex < self.timeArray.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToRowAtIndexPath:self.currentIndexPath atScrollPosition:(UITableViewScrollPositionMiddle) animated:aniamtion];
        });
    }
}

/**暂停恢复*/
-(void)df_pauseLayer:(CALayer*)layer{
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}
-(void)df_resumeLayer:(CALayer*)layer{
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

#pragma mark - 歌词解析
- (void)df_lyricAnalyze{
    if (self.currentIndexPath) {self.currentIndexPath = nil;}
    if (self.waitResetIndexpath) {self.waitResetIndexpath = nil;}
    self.lastIndex = -1;
    self.currentIndex = -1;

    NSURL *url = [DFPlayer shareInstance].currentAudioModel.audioUrl;
    if ([self.audioUrl.absoluteString isEqualToString:url.absoluteString]) {
        [self resetLyricTableView];//如果没有换新音频 直接复位
    }else{
        self.audioUrl = url;
        if (self.tempLrcDictionary.count != 0) {[self.tempLrcDictionary removeAllObjects];}
        if (self.timeArray.count != 0) {[self.timeArray removeAllObjects];}
        if (self.lyricArray.count != 0) {[self.lyricArray removeAllObjects];}
        NSString *lyric = [DFPlayer shareInstance].currentAudioInfoModel.audioLyric;
        if (!lyric || lyric.length <= 0) {
            [self showNoticeLabel];
            [self tableViewReloadData];
            return;
        }
        [self lyricAnalyze:lyric];//解析歌词
    }
}
- (void)lyricAnalyze:(NSString *)lyric{
    //这里先将每句歌词分割
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *arr = [lyric componentsSeparatedByString:@"\n"];
        for (int i = 0; i < arr.count; i++) {
            NSString *lrc = arr[i];
            //如果该行为空不继续解析
            if ([self IsNilWithStr:lrc]) {continue;}
            //开始解析（这里只解析时间信息，不解析音频头部信息，如：ar：ti：等）
            NSArray *lineArray = [NSArray array];
            if ([lrc rangeOfString:@"]"].location != NSNotFound) {
                lineArray = [lrc componentsSeparatedByString:@"]"];
                if (lineArray.count > 2) {//多个时间
                    NSMutableArray *tempTimeArray = [NSMutableArray array];
                    for (int j = 0; j < lineArray.count-1; j++) {
                        CGFloat seconds = [self getLyricTimeWithTimeStr:lineArray[j]];
                        if (seconds >= 0) {
                            [tempTimeArray addObject:[NSNumber numberWithFloat:seconds]];
                        }
                    }
                    if (tempTimeArray.count > 0) {
                        for (NSNumber *number in tempTimeArray) {
                            [self addObjectWithKey:[number floatValue] value:lineArray.lastObject];
                        }
                    }
                }else{//单个时间
                    CGFloat seconds = [self getLyricTimeWithTimeStr:lineArray.firstObject];
                    if (seconds >= 0) {
                        [self addObjectWithKey:seconds value:lineArray.lastObject];
                    }
                }
            }
        }
        //排序
        [self.timeArray addObjectsFromArray:self.tempLrcDictionary.allKeys];
        [self.timeArray sortUsingComparator: ^NSComparisonResult (NSString *str1, NSString *str2) {
            return [str1 floatValue] > [str2 floatValue];
        }];
        for (NSString *key in self.timeArray) {
            [self.lyricArray addObject:[self.tempLrcDictionary valueForKey:key]];
        }
        //重置
        [self resetLyricTableView];
        //得到数据调用一次更新信息
        [self df_updateLyricsTextWithAnimation:NO];
    });
}
/**位置复原*/
- (void)resetLyricTableView{
    if (self.timeArray.count > 0) {[self hideNoticeLabel];}
    //刷新
    [self tableViewReloadData];
    
    if (self.lyricArray.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self scrollToRowAtIndexPath:indexPath atScrollPosition:(UITableViewScrollPositionTop) animated:NO];
        });
    }else{
        [self showNoticeLabel];
    }
}
/**时间转换*/
- (CGFloat)getLyricTimeWithTimeStr:(NSString *)timeStr{
    if ([self isHasLetterWithStr:timeStr]) {
        return -1;
    }
    if ([timeStr rangeOfString:@"["].location != NSNotFound) {
        timeStr = [timeStr componentsSeparatedByString:@"["].lastObject;
        timeStr = [self removeNilWithStr:timeStr];
    }
    //时间转换成秒
    CGFloat second = -1.0;
    //[00:00.00]和[00:00:00]（分钟:秒.毫秒）
    if (timeStr.length == 8) {
        NSString *str = [timeStr substringWithRange:NSMakeRange(5, 1)];
        if ([str isEqualToString:@":"]) {
            timeStr = [timeStr stringByReplacingOccurrencesOfString:@":" withString:@"." options:(NSAnchoredSearch) range:(NSMakeRange(5, 1))];
        }
        NSString *minutes = [timeStr substringWithRange:NSMakeRange(0, 2)];
        NSString *seconds = [timeStr substringWithRange:NSMakeRange(3, 2)];
        NSString *msec = [timeStr substringWithRange:NSMakeRange(6, 2)];
        second = minutes.floatValue*60 + seconds.floatValue + msec.floatValue/1000;
    }
    //[00:00]（分钟:秒）
    if (timeStr.length == 6) {
        NSString *minutes = [timeStr substringWithRange:NSMakeRange(0, 2)];
        NSString *seconds = [timeStr substringWithRange:NSMakeRange(3, 2)];
        second = minutes.floatValue*60 + seconds.floatValue;
    }
    return second;
}
/**加入临时字典*/
- (NSMutableDictionary *)addObjectWithKey:(CGFloat)timeKey value:(id)value{
    NSString *K = [NSString stringWithFormat:@"%lf",timeKey];
    NSString *V = [NSString stringWithFormat:@"%@",value];
    [self.tempLrcDictionary setValue:V forKey:K];
    return self.tempLrcDictionary;
}

#pragma mark  - tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  self.lyricArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    DFPlayerLyricsTableViewCell *cell = (DFPlayerLyricsTableViewCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell.frame.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%ld%ld", (long)indexPath.section, (long)indexPath.row];
    DFPlayerLyricsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[DFPlayerLyricsTableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:CellIdentifier];
        cell.backgroundColor = self.cellBackgroundColor?self.cellBackgroundColor:[UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect LabelRect = [self fitLrcLabelSizeWithLabel:cell.backgroundLrcLabel];
        cell.foregroundLrcLabel.frame = cell.backgroundLrcLabel.frame = LabelRect;
    });
    
    if (indexPath.row == self.currentIndex) {//当前行
        cell.foregroundLrcLabel.hidden      = NO;
        cell.backgroundLrcLabel.textColor   = self.currentLineLrcBackgroundTextColor;
        cell.backgroundLrcLabel.font        = cell.foregroundLrcLabel.font = self.currentLineLrcFont;
    }else{//其他行
        cell.foregroundLrcLabel.hidden      = YES;
        if (indexPath == self.waitResetIndexpath) {
            cell.backgroundLrcLabel.textColor   = self.currentLineLrcForegroundTextColor;
            cell.backgroundLrcLabel.font        = self.currentLineLrcFont;
        }else{
            cell.backgroundLrcLabel.textColor   = self.otherLineLrcBackgroundTextColor;
            cell.backgroundLrcLabel.font        = self.otherLineLrcFont;
        }
    }    
    CGFloat height = self.cellRowHeight;
    if (indexPath.row < self.lyricArray.count) {//安全性判断
        NSString *lrc = self.lyricArray[indexPath.row];
        NSString *noNilLrc = [self removeNilWithStr:lrc];
        if (noNilLrc.length == 0) {
            height = 0;
        }else if([noNilLrc isEqualToString:DFPlayerLyricConstMark]){
            lrc = @"";
        }
        cell.foregroundLrcLabel.text = cell.backgroundLrcLabel.text = lrc;
    }
    
    CGRect cellFrame = cell.frame;
    cellFrame.size.height = height;
    cell.frame = cellFrame;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.clickBlock) {self.clickBlock(indexPath);}
}

- (CGRect)fitLrcLabelSizeWithLabel:(UILabel *)label{
    [label sizeToFit];
    CGFloat foreW = label.frame.size.width;
    CGFloat foreX = self.frame.size.width - foreW;
    if (foreX >= 0) {
        foreX = foreX/2;
    }else{
        foreW = self.frame.size.width;
        foreX = 0;
    }
    return CGRectMake(foreX, 0, foreW, self.cellRowHeight);
}

#pragma mark - scrollview delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isDraging = YES;
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    self.isDecelerate = decelerate;
    if (!self.isDecelerate) {
        [self performSelector:@selector(delayToReset) withObject:nil afterDelay:1];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (self.isDecelerate) {
        [self performSelector:@selector(delayToReset) withObject:nil afterDelay:0.8];
    }
}

- (void)delayToReset{
    self.isDraging = NO;
    [self df_scrollToMiddleCellAnimation:YES];
}

#pragma mark - action
//字符串去空字符
- (NSString *)removeNilWithStr:(NSString *)str{
    NSString *string = [NSString stringWithFormat:@"%@",str];
    return [string stringByReplacingOccurrencesOfString:@" " withString:@""];
}
/**判断是否为空*/
- (BOOL)IsNilWithStr:(NSString *)str{
    NSString *string = [self removeNilWithStr:str];
    if (string.length == 0)
        return YES;
    return NO;
}
/**是否包含字母*/
- (BOOL)isHasLetterWithStr:(NSString *)str{
    NSRegularExpression *numberRegular = [NSRegularExpression regularExpressionWithPattern:@"[A-Za-z]" options:NSRegularExpressionCaseInsensitive error:nil];
    NSInteger count = [numberRegular numberOfMatchesInString:str options:NSMatchingReportProgress range:NSMakeRange(0, str.length)];
    if (count > 0) {
        return YES;
    }
    return NO;
}
/**刷新tableview*/
- (void)tableViewReloadData{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
    });
}

- (BOOL)isZhHansApplesLauguages{
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    if ([currentLanguage rangeOfString:@"zh-Hans"].location != NSNotFound) {//简体中文
        return YES;
    }else{
        return NO;
    }
}

- (void)showNoticeLabel{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.noticeLabel.hidden = NO;
    });
}
- (void)hideNoticeLabel{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.noticeLabel.hidden = YES;
    });
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
