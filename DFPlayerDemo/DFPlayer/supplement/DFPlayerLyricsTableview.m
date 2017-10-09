//
//  DFPlayerLyricsTableview.m
//  DFPlayer
//
//  Created by HDF on 2017/8/16.
//  Copyright © 2017年 HDF. All rights reserved.
//


#import "DFPlayerLyricsTableview.h"
#import "DFPlayerManager.h"
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

static NSString *DFPlayerlyricCellId = @"lyricCellId";
static NSString *DFPlayerLyricStateKey = @"state";
static NSString *DFPlayerLyricCurrentTimeKey = @"currentTime";
static NSString *DFPlayerLyricCurrentAudioInfoModelKey = @"currentAudioInfoModel";
static NSString *DFPlayerLyricConstMark = @"####";

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
/**歌词当前行数*/
@property (nonatomic, assign) NSInteger currentIndex;
/**标记*/
@property (nonatomic, assign) NSInteger lastIndex;
/**歌词当前行IndexPath*/
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
/**歌词前行IndexPath*/
@property (nonatomic, strong) NSIndexPath *lastIndexPath;
/**等待恢复行的indexpath*/
@property (nonatomic, assign) NSIndexPath *waitResetIndexpath;
/**是否拖拽歌词*/
@property (nonatomic, assign) BOOL isDraging;
/**是否拖拽进度*/
@property (nonatomic, assign) BOOL isDragingProgress;
/**遮罩*/
@property (nonatomic, strong) CALayer *maskLayer;
/**偏移时间。首次进入和拖拽后设置*/
@property (nonatomic, assign) CGFloat timeOffset;
/**更新标记*/
@property (nonatomic, assign) BOOL isStopUpdateLrc;

@end

@implementation DFPlayerLyricsTableview
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[DFPlayerManager shareInstance] removeObserver:self forKeyPath:DFPlayerLyricStateKey];
    [[DFPlayerManager shareInstance] removeObserver:self forKeyPath:DFPlayerLyricCurrentTimeKey];
    [[DFPlayerManager shareInstance] removeObserver:self forKeyPath:DFPlayerLyricCurrentAudioInfoModelKey];
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

- (instancetype)init{
    self = [super init];
    if (self) {
        self.isDraging = NO;
        self.lastIndex = -1;
        self.isStopUpdateLrc = NO;
        self.backgroundColor = [UIColor whiteColor];
        self.delegate = self;
        self.dataSource = self;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_getDragStatus) name:DFPLayerNotificationDragStatus object:nil];
        [[DFPlayerManager shareInstance] addObserver:self forKeyPath:DFPlayerLyricStateKey options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
        [[DFPlayerManager shareInstance] addObserver:self forKeyPath:DFPlayerLyricCurrentTimeKey options:NSKeyValueObservingOptionNew context:nil];
        [[DFPlayerManager shareInstance] addObserver:self forKeyPath:DFPlayerLyricCurrentAudioInfoModelKey options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
    }
    return self;
}

- (void)df_getDragStatus{
    self.isDragingProgress = YES;
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
    DFPlayerLyricsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DFPlayerlyricCellId];
    if (cell == nil) {
        cell = [[DFPlayerLyricsTableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:DFPlayerlyricCellId];
        cell.backgroundColor = self.cellBackgroundColor?self.cellBackgroundColor:[UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect LabelRect = [self fitLrcLabelSizeWithLabel:cell.backgroundLrcLabel];
        cell.foregroundLrcLabel.frame = cell.backgroundLrcLabel.frame = LabelRect;
    });

    if (indexPath == self.currentIndexPath) {//当前行
        cell.backgroundLrcLabel.textColor   = cell.foregroundLrcLabel.textColor = self.currentLineLrcBackgroundTextColor;
        cell.backgroundLrcLabel.font        = cell.foregroundLrcLabel.font = self.currentLineLrcFont;
    }else{//其他行
        cell.foregroundLrcLabel.hidden      = YES;
        cell.backgroundLrcLabel.textColor   = self.otherLineLrcBackgroundTextColor;
        cell.backgroundLrcLabel.font        = self.otherLineLrcFont;
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
    if (self.block) {
        self.block(indexPath);
    }
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
#pragma mark - kvc
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == [DFPlayerManager shareInstance]) {
        if ([keyPath isEqualToString:DFPlayerLyricStateKey]) {
            if ([DFPlayerManager shareInstance].state == DFPlayerStatePlaying) {
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
- (void)df_updateLyricsTextWithAnimation:(BOOL)aniamtion{
    //停止更新
    if (self.isStopUpdateLrc) {[self df_pauseLayer:self.maskLayer];return;}
    //获取位置
    if (self.timeArray.count <= 0 || self.lyricArray.count <= 0) {return;}
    CGFloat currentTime = [DFPlayerManager shareInstance].currentTime;
    
    self.timeOffset = 0;
    for (int i = 0; i < self.timeArray.count; i++) {
        CGFloat time = [self.timeArray[i] floatValue];
        if (currentTime >= time) {
            self.currentIndex = i;
            //获取偏移时间
            if (!aniamtion || self.isDragingProgress) {
                self.timeOffset = currentTime - time;
                if (self.timeOffset < 0) {self.timeOffset = 0;}
                NSLog(@"timeoffset====:%lf",self.timeOffset);
            }
        }else{
            break;
        }
    }
    
    if (self.lastIndex == self.currentIndex) {return;}
    if (self.lastIndex >= 0) {
        self.lastIndexPath = [NSIndexPath indexPathForRow:self.lastIndex inSection:0];
    }
    self.lastIndex = self.currentIndex;
    self.currentIndexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    
    //移动到中间
    if (!aniamtion || self.isDragingProgress) {
        self.isDragingProgress = NO;
        [self df_scrollToMiddleCellAnimation:NO];
    }else{
        [self df_scrollToMiddleCellAnimation:YES];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        //当前行
        DFPlayerLyricsTableViewCell *cell = (DFPlayerLyricsTableViewCell *)[self cellForRowAtIndexPath:self.currentIndexPath];
        NSString *noNilStr = [self removeNilWithStr:cell.foregroundLrcLabel.text];
        //如果当前行无歌词，记录位置并返回
        if (noNilStr.length == 0 || [noNilStr isEqualToString:DFPlayerLyricConstMark]) {
            self.waitResetIndexpath = self.lastIndexPath;
            return;
        }
        //还原旧行
        [self resetOldCellIndexPath:self.lastIndexPath];
        //还原等待恢复行
        if (self.waitResetIndexpath != nil) {
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
            cell.lrcMasklayer.position  = CGPointMake(0, self.cellRowHeight/2);
            cell.lrcMasklayer.bounds    = CGRectMake(0, 0, 0, self.cellRowHeight);
            cell.lrcMasklayer.backgroundColor = [UIColor whiteColor].CGColor;
            self.maskLayer = cell.lrcMasklayer;
            CGFloat duration = 0;

            if (self.timeArray.count == 0 || self.lyricArray.count == 0) {return;}//安全性判断
            NSLog(@"currentindex:%ld-------------count:%ld",self.currentIndex,self.timeArray.count);
            if (self.currentIndex < self.timeArray.count - 1) {
                duration = fabsf([self.timeArray[self.currentIndex+1] floatValue]-[self.timeArray[self.currentIndex] floatValue]);
            }else{//最后一句歌词
                if (![self IsNilWithStr:self.lyricArray.lastObject]) {//如果最后一句不为空
                    duration = fabs([DFPlayerManager shareInstance].totalTime - [self.timeArray[self.currentIndex] floatValue]-0.2);
                }
            }
            if (duration != 0) {
                CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"bounds.size.width"];
                NSNumber *end = [NSNumber numberWithFloat:cell.foregroundLrcLabel.frame.size.width];
                animation.values = @[@(0),end];
                animation.keyTimes = @[@(0),@(1)];
                animation.duration = duration;
                animation.timeOffset = self.timeOffset;
                animation.calculationMode = kCAAnimationLinear;
                animation.fillMode = kCAFillModeForwards;
                animation.removedOnCompletion = NO;
                animation.autoreverses = NO;
                [self.maskLayer addAnimation:animation forKey:@"Animation"];
                if (!aniamtion || self.isDragingProgress) {
                    self.maskLayer.speed = 0.0;
                }
            }
        }else{
            cell.foregroundLrcLabel.hidden = YES;
        }
    });
}

/**恢复旧行*/
- (void)resetOldCellIndexPath:(NSIndexPath *)indexPath{
    DFPlayerLyricsTableViewCell *cell = (DFPlayerLyricsTableViewCell *)[self cellForRowAtIndexPath:indexPath];
    cell.backgroundLrcLabel.textColor   = self.otherLineLrcBackgroundTextColor;
    cell.backgroundLrcLabel.font        = self.otherLineLrcFont;
    cell.foregroundLrcLabel.hidden      = YES;
    if (self.currentLineLrcFont.pointSize != self.otherLineLrcFont.pointSize) {
        CGRect lastLabelRect = [self fitLrcLabelSizeWithLabel:cell.backgroundLrcLabel];
        cell.foregroundLrcLabel.frame = cell.backgroundLrcLabel.frame = lastLabelRect;
    }
}

- (void)df_scrollToMiddleCellAnimation:(BOOL)aniamtion{
    if (!self.isDraging) {
        if (self.currentIndex < self.timeArray.count) {//安全性判断
            dispatch_async(dispatch_get_main_queue(), ^{
                [self scrollToRowAtIndexPath:self.currentIndexPath
                            atScrollPosition:(UITableViewScrollPositionNone)
                                    animated:aniamtion];
            });
        }
    }
}

#pragma mark - 歌词解析
- (void)df_lyricAnalyze{

    if (self.tempLrcDictionary.count != 0) {[self.tempLrcDictionary removeAllObjects];}
    if (self.timeArray.count != 0) {[self.timeArray removeAllObjects];}
    if (self.lyricArray.count != 0) {[self.lyricArray removeAllObjects];}
    
    NSString *lyric = [DFPlayerManager shareInstance].currentAudioInfoModel.audioLyric;
    if (!lyric || lyric.length <= 0) {
        [self tableViewReloadData];
        return;
    }
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
                        [tempTimeArray addObject:[NSNumber numberWithFloat:seconds]];
                    }
                    if (tempTimeArray.count > 0) {
                        for (NSNumber *number in tempTimeArray) {
                            [self addObjectWithKey:[number floatValue] value:lineArray.lastObject];
                        }
                    }
                }else{//单个时间
                    CGFloat seconds = [self getLyricTimeWithTimeStr:lineArray.firstObject];
                    [self addObjectWithKey:seconds value:lineArray.lastObject];
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
     
        [self tableViewReloadData];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_lyricsTableviewResumeUpdate) name:self.DFPlayerLyricTableviewResumeUpdateNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_lyricsTableviewStopUpdate) name:self.DFPlayerLyricTableviewStopUpdateNotification object:nil];
            //得到数据调用一次更新信息
            [self df_updateLyricsTextWithAnimation:NO];
        });
    });
}
/**时间转换*/
- (CGFloat)getLyricTimeWithTimeStr:(NSString *)timeStr{
    if ([timeStr rangeOfString:@"["].location != NSNotFound) {
        timeStr = [timeStr componentsSeparatedByString:@"["].lastObject;
        timeStr = [self removeNilWithStr:timeStr];
    }
    //时间转换成秒
    CGFloat second = 0;
    //[00:00.00]和[00:00:00]
    if (timeStr.length == 8) {
        NSString *str = [timeStr substringWithRange:NSMakeRange(5, 1)];
        if ([str isEqualToString:@":"]) {
            timeStr = [timeStr stringByReplacingOccurrencesOfString:@":" withString:@"." options:(NSAnchoredSearch) range:(NSMakeRange(5, 1))];
        }
        NSString *minutes = [timeStr substringWithRange:NSMakeRange(0, 2)];
        NSString *seconds = [timeStr substringWithRange:NSMakeRange(3, 5)];
        second = minutes.floatValue*60 + seconds.floatValue;
    }
    //[00:00]
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
#pragma mark - scrollview delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isDraging = YES;
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self performSelector:@selector(delayToReset) withObject:nil afterDelay:0.5];
}
- (void)delayToReset{
    self.isDraging = NO;
    [self df_scrollToMiddleCellAnimation:YES];
}

#pragma mark - action
/**停止更新*/
- (void)df_lyricsTableviewStopUpdate{
    self.isStopUpdateLrc = YES;
}
/**恢复更新*/
- (void)df_lyricsTableviewResumeUpdate{
    self.isStopUpdateLrc = NO;
}
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
/**刷新tableview*/
- (void)tableViewReloadData{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
    });
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
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
