//
//  DFPlayerLyricsTableview.m
//  DFPlayer
//
//  Created by ihoudf on 2017/8/16.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import "DFPlayerLyricsTableview.h"
#import "DFPlayer.h"
#import "DFPlayerTool.h"

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

static NSString *DFPlayerLyricsStateKey = @"state";
static NSString *DFPlayerLyricsCurrentTimeKey = @"currentTime";
static NSString *DFPlayerLyricsCurrentAudioInfoModelKey = @"currentAudioInfoModel";
static NSString *DFPlayerLyricsConstMark = @"####";


@interface DFPlayerLyricsTableview ()
<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate>
{
    NSIndexPath *_currentIndexPath; // 歌词当前行IndexPath
    NSIndexPath *_lastIndexPath; // 歌词上一行IndexPath
    NSInteger _lastIndex; // 歌词上一行标记
    NSInteger _currentIndex; // 歌词当前行标记
    CGFloat _timeOffset; // 偏移时间。首次进入和拖拽后设置
    BOOL _isDraging; // 是否正在拖拽歌词tableView
    BOOL _isDecelerate; // 拖拽歌词tableView松手后tableView是否还在滚动
    BOOL _isSeekEnd; // 拖拽进度条是否结束
}
// 当前AudioUrl
@property (nonatomic, strong) NSURL *audioUrl;
// 时间数组
@property (nonatomic, strong) NSMutableArray <NSString *> *timeArray;
// 歌词数组
@property (nonatomic, strong) NSMutableArray <NSString *> *lyricsArray;
// 歌词frame数组——currentLineLrcFont
@property (nonatomic, strong) NSMutableArray *currentLyricsFrameArray;
// 歌词frame数组——otherLineLrcFont
@property (nonatomic, strong) NSMutableArray *otherLyricsFrameArray;
// 解析临时字典
@property (nonatomic, strong) NSMutableDictionary *tempLrcDictionary;
// 歌词当前行Index数组
@property (nonatomic, strong) NSMutableArray *currentIndexArray;
// 遮罩
@property (nonatomic, strong) CALayer *maskLayer;
// 等待恢复行的indexpath
@property (nonatomic, strong) NSIndexPath *waitResetIndexpath;

@end

@implementation DFPlayerLyricsTableview

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:DFPlayerNotificationSeekEnd];
    [[DFPlayer sharedPlayer] removeObserver:self forKeyPath:DFPlayerLyricsStateKey];
    [[DFPlayer sharedPlayer] removeObserver:self forKeyPath:DFPlayerLyricsCurrentTimeKey];
    [[DFPlayer sharedPlayer] removeObserver:self forKeyPath:DFPlayerLyricsCurrentAudioInfoModelKey];
}

- (NSMutableArray<NSString *> *)timeArray{
    if (!_timeArray) {
        _timeArray = [NSMutableArray array];
    }
    return _timeArray;
}

- (NSMutableArray<NSString *> *)lyricsArray{
    if (!_lyricsArray) {
        _lyricsArray = [NSMutableArray array];
    }
    return _lyricsArray;
}

- (NSMutableArray *)currentLyricsFrameArray{
    if (!_currentLyricsFrameArray) {
        _currentLyricsFrameArray = [NSMutableArray array];
    }
    return _currentLyricsFrameArray;
}

- (NSMutableArray *)otherLyricsFrameArray{
    if (!_otherLyricsFrameArray) {
        _otherLyricsFrameArray = [NSMutableArray array];
    }
    return _otherLyricsFrameArray;
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

- (instancetype)init{
    self = [super init];
    if (self) {
        _isDraging = NO;
        self.delegate = self;
        self.dataSource = self;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        if (@available(iOS 11.0,*)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_seekEnd) name:DFPlayerNotificationSeekEnd object:nil];
        
        NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial;
        [[DFPlayer sharedPlayer] addObserver:self forKeyPath:DFPlayerLyricsCurrentAudioInfoModelKey options:options context:nil];
        [[DFPlayer sharedPlayer] addObserver:self forKeyPath:DFPlayerLyricsCurrentTimeKey options:options context:nil];
        [[DFPlayer sharedPlayer] addObserver:self forKeyPath:DFPlayerLyricsStateKey options:options context:nil];
    }
    return self;
}

- (void)setStopUpdate:(BOOL)stopUpdate{
    _stopUpdate = stopUpdate;
    [self df_updateLyricsAnimated:YES];
}

- (void)df_seekEnd{
    _isSeekEnd = YES;
    [self df_updateLyricsAnimated:YES];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == [DFPlayer sharedPlayer]) {
        if ([keyPath isEqualToString:DFPlayerLyricsCurrentAudioInfoModelKey]){
            [self df_analyzeLyrics];
        }else if ([keyPath isEqualToString:DFPlayerLyricsCurrentTimeKey]){
            [self df_updateLyricsAnimated:YES];
        }else if ([keyPath isEqualToString:DFPlayerLyricsStateKey]) {
            if ([DFPlayer sharedPlayer].state == DFPlayerStatePlaying) {
                [self df_resumeLayer:self.maskLayer];
            }else{
                [self df_pauseLayer:self.maskLayer];
            }
        }
    }
}

#pragma mark - 更新歌词信息
- (void)df_updateLyricsAnimated:(BOOL)animated{
    
    if (self.stopUpdate) {
        [self df_pauseLayer:self.maskLayer];
        return;
    }
    
    if (self.timeArray.count <= 0 || self.lyricsArray.count <= 0) {
        return;
    }
    
    _timeOffset = 0;
    [self.currentIndexArray removeAllObjects];
    
    BOOL scrollAnimated = _isSeekEnd || !animated;

    //获取当前行
    CGFloat currentTimeFloat = [DFPlayer sharedPlayer].currentTime;
    NSInteger currentTime = (NSInteger)currentTimeFloat;
    for (int i = 0; i < self.timeArray.count; i++) {
        NSInteger time = [self.timeArray[i] integerValue];
        if (scrollAnimated) {
            if (currentTime >= time) {
                _currentIndex = i;
                //获取偏移时间
                if (self.currentLineLrcForegroundTextColor) {
                    _timeOffset = currentTimeFloat - [self.timeArray[i] floatValue];
                }
            }
        }else{
            if (currentTime == time) {
                [self.currentIndexArray addObject:[NSString stringWithFormat:@"%d",i]];
                _currentIndex = i;
            }
        }
        if (time > currentTime) {
            break;
        }
    }
    
    if (_lastIndex == _currentIndex) {
        return;
    }
    if (_lastIndex >= 0) {
        _lastIndexPath = [NSIndexPath indexPathForRow:_lastIndex inSection:0];
    }
    _lastIndex = _currentIndex;
    _currentIndexPath = [NSIndexPath indexPathForRow:_currentIndex inSection:0];
    if (_isSeekEnd) {//进度回滚，恢复正在播放的当前行
        [self setOtherLineLyricsTextStatus:_currentIndexPath];
    }

    //返回当前行歌词
    if (self.lyricsDelegate && [self.lyricsDelegate respondsToSelector:@selector(df_lyricsTableview:onPlayingLyrics:)]) {
        NSString *lyrics = self.lyricsArray[_currentIndex];
        if ([lyrics isEqualToString:DFPlayerLyricsConstMark]) {
            lyrics = @"";
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.lyricsDelegate df_lyricsTableview:self onPlayingLyrics:lyrics];
        });
    }

    //当前行移动到中间
    [self df_scrollPositionMiddleAnimated:!scrollAnimated];
    
    //刷新当前行
    [self updateLyricsAnimated:animated];
}

- (void)updateLyricsAnimated:(BOOL)animated{

    //同一分同一秒（只有毫秒数不同时）有两句以上歌词
    if (self.currentIndexArray.count > 1) {
        for (int i = 0; i < self.currentIndexArray.count-1; i++) {
            NSInteger index = [self.currentIndexArray[i] integerValue];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                DFPlayerLyricsTableViewCell *cell = (DFPlayerLyricsTableViewCell *)[self cellForRowAtIndexPath:indexPath];
                cell.foregroundLrcLabel.hidden = YES;
                [self setCurrentLineLyricsTextStatus:cell.backgroundLrcLabel
                                           textColor:self.currentLineLrcForegroundTextColor ? : self.currentLineLrcBackgroundTextColor];
            });
            [self performSelector:@selector(setOtherLineLyricsTextStatus:) withObject:indexPath afterDelay:0.2];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        //当前行
        DFPlayerLyricsTableViewCell *cell = (DFPlayerLyricsTableViewCell *)[self cellForRowAtIndexPath:self->_currentIndexPath];

        if (!self->_isSeekEnd) {
            //如果当前行无歌词，记录位置并返回

            NSString *lyrics = [cell.foregroundLrcLabel.text df_removeEmpty];

            if ([lyrics df_isEmpty] || [lyrics isEqualToString:DFPlayerLyricsConstMark]) {
                if (self.waitResetIndexpath) {

                    [self setOtherLineLyricsTextStatus:self.waitResetIndexpath];
                }
                self.waitResetIndexpath = self->_lastIndexPath;
                return;
            }
        }
        self->_isSeekEnd = NO;

        //设置其他行
        [self setOtherLineLyricsTextStatus:self->_lastIndexPath];
        
        //还原等待恢复行
        if (self.waitResetIndexpath) {
            [self setOtherLineLyricsTextStatus:self.waitResetIndexpath];
            self.waitResetIndexpath = nil;
        }

        //设置当前行
        cell.foregroundLrcLabel.hidden = !self.currentLineLrcForegroundTextColor;

        [self setCurrentLineLyricsTextStatus:cell.backgroundLrcLabel
                                   textColor:self.currentLineLrcBackgroundTextColor];
        
        
        //如果是卡拉OK模式
        if (self.currentLineLrcForegroundTextColor) {
            [self setCurrentLineLyricsTextStatus:cell.foregroundLrcLabel
                                       textColor:self.currentLineLrcForegroundTextColor];
            
            cell.lrcMasklayer.position          = CGPointMake(0, self.cellRowHeight/2);
            cell.lrcMasklayer.bounds            = CGRectMake(0, 0, 0, self.cellRowHeight);
            cell.lrcMasklayer.backgroundColor   = [UIColor whiteColor].CGColor;
            self.maskLayer                      = cell.lrcMasklayer;
            
            if (self.timeArray.count == 0 || self.lyricsArray.count == 0) {//安全性判断
                return;
            }
            
            CGFloat duration = 0;
            if (self->_currentIndex < self.timeArray.count - 1) {
                duration = fabsf([self.timeArray[self->_currentIndex+1] floatValue]-[self.timeArray[self->_currentIndex] floatValue]);
            }else{//最后一句歌词
                if (![self.lyricsArray.lastObject df_isEmpty]) {//如果最后一句不为空
                    duration = fabs([DFPlayer sharedPlayer].totalTime - [self.timeArray[self->_currentIndex] floatValue]-0.2);
                }
            }
            if (duration != 0) {
                CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"bounds.size.width"];
                NSNumber *end = [NSNumber numberWithFloat:CGRectGetWidth(cell.foregroundLrcLabel.frame)];
                anim.values = @[@(0),end];
                anim.keyTimes = @[@(0),@(1)];
                anim.duration = duration;
                anim.timeOffset = self->_timeOffset;
                anim.calculationMode = kCAAnimationLinear;
                anim.fillMode = kCAFillModeForwards;
                anim.removedOnCompletion = NO;
                anim.autoreverses = NO;
                [self.maskLayer addAnimation:anim forKey:@"Animation"];
                if (!animated) {
                    self.maskLayer.speed = 0.0;
                }
            }
        }
    });
}

// 设置当前行歌词状态
- (void)setCurrentLineLyricsTextStatus:(UILabel *)label textColor:(UIColor *)textColor{
    label.textColor = textColor;
    label.font = self.currentLineLrcFont;
    label.frame = [self.currentLyricsFrameArray[_currentIndexPath.row] CGRectValue];
}

// 设置其他行歌词状态
- (void)setOtherLineLyricsTextStatus:(id)value{
    NSIndexPath *indexPath = (NSIndexPath *)value;
    DFPlayerLyricsTableViewCell *cell = (DFPlayerLyricsTableViewCell *)[self cellForRowAtIndexPath:indexPath];
    [self setOtherLineLyricsTextStatus:cell indexPath:indexPath];
}

- (void)setOtherLineLyricsTextStatus:(DFPlayerLyricsTableViewCell *)cell indexPath:(NSIndexPath *)indexPath{
    if (indexPath.row >= self.otherLyricsFrameArray.count) {
        return;
    }
    cell.foregroundLrcLabel.hidden = YES;
    cell.backgroundLrcLabel.textColor = self.otherLineLrcBackgroundTextColor;
    cell.backgroundLrcLabel.font = self.otherLineLrcFont;
    cell.backgroundLrcLabel.frame = [self.otherLyricsFrameArray[indexPath.row] CGRectValue];
}

// cell移动到当前行歌词
- (void)df_scrollPositionMiddleAnimated:(BOOL)animated{
    if (!_isDraging && _currentIndex < self.lyricsArray.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToRowAtIndexPath:self->_currentIndexPath
                        atScrollPosition:(UITableViewScrollPositionMiddle)
                                animated:animated];
        });
    }
}

// 暂停恢复
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

#pragma mark  - tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.lyricsArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [self.otherLyricsFrameArray[indexPath.row] CGRectValue].size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *identifier = [NSString stringWithFormat:@"DFPLayerLyricsTableViewCell%ld%ld", (long)indexPath.section, (long)indexPath.row];
    DFPlayerLyricsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[DFPlayerLyricsTableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:identifier];
        cell.backgroundColor = self.cellBackgroundColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    
    if (indexPath == _currentIndexPath) {//当前行
        cell.foregroundLrcLabel.hidden = YES;
        [self setCurrentLineLyricsTextStatus:cell.backgroundLrcLabel
                                   textColor:self.currentLineLrcForegroundTextColor ? : self.currentLineLrcBackgroundTextColor];
    }else{//其他行
        if (indexPath == self.waitResetIndexpath) {
            cell.foregroundLrcLabel.hidden = YES;
            cell.backgroundLrcLabel.textColor = self.currentLineLrcForegroundTextColor ? : self.currentLineLrcBackgroundTextColor;
            cell.backgroundLrcLabel.font = self.currentLineLrcFont;
            cell.backgroundLrcLabel.frame = [self.currentLyricsFrameArray[indexPath.row] CGRectValue];
        }else{
            [self setOtherLineLyricsTextStatus:cell indexPath:indexPath];
        }
    }
    
    if (indexPath.row < self.lyricsArray.count) {//安全性判断
        NSString *lrc = self.lyricsArray[indexPath.row];
        cell.hidden = [lrc df_isEmpty];
        if([[lrc df_removeEmpty] isEqualToString:DFPlayerLyricsConstMark]){
            lrc = @"";
        }
        cell.foregroundLrcLabel.text = cell.backgroundLrcLabel.text = lrc;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

#pragma mark - 歌词解析
- (void)df_analyzeLyrics{
    
    _currentIndexPath = nil;
    self.waitResetIndexpath = nil;
    _lastIndex = -1;
    _currentIndex = -1;

    NSURL *url = [DFPlayer sharedPlayer].currentAudioModel.audioUrl;
    if ([self.audioUrl.absoluteString isEqualToString:url.absoluteString]) {
        [self checkLyricsAvailability]; // 没有换新音频时，直接复位
    }else{
        [self.tempLrcDictionary removeAllObjects];
        [self.timeArray removeAllObjects];
        [self.lyricsArray removeAllObjects];
        [self.currentLyricsFrameArray removeAllObjects];
        [self.otherLyricsFrameArray removeAllObjects];

        NSString *lyrics = [DFPlayer sharedPlayer].currentAudioInfoModel.audioLyrics;
        if (!url || [lyrics df_isEmpty]) { // 不可用时，直接复位
            [self checkLyricsAvailability];
            return;
        }
        
        self.audioUrl = url;
        [self analyzeLyrics:lyrics];//解析歌词
    }
}

- (void)analyzeLyrics:(NSString *)lyrics{
    //将每句歌词分割
    dispatch_async(DFPlayerDefaultGlobalQueue, ^{
        NSArray <NSString *> *arr = [lyrics componentsSeparatedByString:@"\n"];
        [arr enumerateObjectsUsingBlock:^(NSString * _Nonnull lrc, NSUInteger idx, BOOL * _Nonnull stop) {
            //如果该行为空不继续解析
            if ([lrc df_isEmpty]) {
                return;
            }
            //开始解析（这里只解析时间信息，不解析音频头部信息，如：ar：ti：等）
            NSArray *lineArray = [NSArray array];
            if ([lrc rangeOfString:@"]"].location != NSNotFound) {
                lineArray = [lrc componentsSeparatedByString:@"]"];
                if (lineArray.count > 2) {//多个时间
                    NSMutableArray *tempTimeArray = [NSMutableArray array];
                    for (int j = 0; j < lineArray.count - 1; j++) {
                        CGFloat seconds = [self getLyricsTime:lineArray[j]];
                        if (seconds >= 0) {
                            [tempTimeArray addObject:[NSNumber numberWithFloat:seconds]];
                        }
                    }
                    if (tempTimeArray.count > 0) {
                        for (NSNumber *number in tempTimeArray) {
                            [self addObjectWithKey:[number floatValue]
                                             value:lineArray.lastObject];
                        }
                    }
                }else{//单个时间
                    CGFloat seconds = [self getLyricsTime:lineArray.firstObject];
                    if (seconds >= 0) {
                        [self addObjectWithKey:seconds
                                         value:lineArray.lastObject];
                    }
                }
            }
        }];
        
        //排序
        [self.timeArray addObjectsFromArray:self.tempLrcDictionary.allKeys];
        [self.timeArray sortUsingComparator: ^NSComparisonResult (NSString *str1, NSString *str2) {
            return [str1 floatValue] > [str2 floatValue];
        }];
        for (NSString *key in self.timeArray) {
            [self.lyricsArray addObject:[self.tempLrcDictionary valueForKey:key]];
        }
        
        //提前计算每句歌词的frame
        [self getLyricsFrameArray];
        
        //重置
        [self checkLyricsAvailability];
        
        //得到数据调用一次更新信息
        [self df_updateLyricsAnimated:NO];
    });
}

// 检查是否有可用歌词。有则移动到首行
- (void)checkLyricsAvailability{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
        if (self.lyricsArray && self.lyricsArray.count > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self scrollToRowAtIndexPath:indexPath atScrollPosition:(UITableViewScrollPositionTop) animated:NO];
        }
    });
}

// 时间转换
- (CGFloat)getLyricsTime:(NSString *)time{
    if ([time df_isContainLetter]) {
        return -1;
    }
    if ([time rangeOfString:@"["].location != NSNotFound) {
        time = [[time componentsSeparatedByString:@"["].lastObject df_removeEmpty];
    }
    //时间转换成秒
    CGFloat second = -1.0;
    //[00:00.00]和[00:00:00]（分钟:秒.毫秒）
    
    if (time.length == 8) {
        NSString *str = [time substringWithRange:NSMakeRange(5, 1)];
        if ([str isEqualToString:@":"]) {
            time = [time stringByReplacingOccurrencesOfString:@":" withString:@"." options:(NSAnchoredSearch) range:(NSMakeRange(5, 1))];
        }
        NSString *minutes = [time substringWithRange:NSMakeRange(0, 2)];
        NSString *seconds = [time substringWithRange:NSMakeRange(3, 2)];
        NSString *msec = [time substringWithRange:NSMakeRange(6, 2)];
        second = minutes.floatValue * 60 + seconds.floatValue + msec.floatValue/1000;
    }
    //[00:00]（分钟:秒）
    if (time.length == 6) {
        NSString *minutes = [time substringWithRange:NSMakeRange(0, 2)];
        NSString *seconds = [time substringWithRange:NSMakeRange(3, 2)];
        second = minutes.floatValue * 60 + seconds.floatValue;
    }
    return second;
}

// 加入临时字典
- (NSMutableDictionary *)addObjectWithKey:(CGFloat)timeKey value:(id)value{
    NSString *K = [NSString stringWithFormat:@"%lf",timeKey];
    NSString *V = [NSString stringWithFormat:@"%@",value];
    [self.tempLrcDictionary setValue:V forKey:K];
    return self.tempLrcDictionary;
}

#pragma mark - 计算歌词frame
- (void)getLyricsFrameArray{
    [self.lyricsArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGRect otherFrame = [self getLyricsFrame:obj font:self.otherLineLrcFont];
            [self.otherLyricsFrameArray addObject:@(otherFrame)];
            
            if (self.currentLineLrcFont == self.otherLineLrcFont) {
                [self.currentLyricsFrameArray addObject:@(otherFrame)];
            }else{
                CGRect currentFrame = [self getLyricsFrame:obj font:self.currentLineLrcFont];
                [self.currentLyricsFrameArray addObject:@(currentFrame)];
            }
        });
    }];
}

- (CGRect)getLyricsFrame:(NSString *)lyrics font:(UIFont *)font{
    if ([lyrics df_isEmpty]) {
        return CGRectZero;
    }
    CGFloat W = [lyrics boundingRectWithSize:(CGSize){MAXFLOAT, self.cellRowHeight}
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{NSFontAttributeName : font}
                                     context:nil].size.width;
    W = MIN(W, CGRectGetWidth(self.frame));
    CGFloat X = (CGRectGetWidth(self.frame) - W) / 2;
    return (CGRect){X, 0, W, self.cellRowHeight};
}

#pragma mark - scrollview delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    _isDraging = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    _isDecelerate = decelerate;
    if (!_isDecelerate) {
        [self performSelector:@selector(delayToReset) withObject:nil afterDelay:1.25];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (_isDecelerate) {
        [self performSelector:@selector(delayToReset) withObject:nil afterDelay:1.25];
    }
}

- (void)delayToReset{
    _isDraging = NO;
    [self df_scrollPositionMiddleAnimated:YES];
}

@end
