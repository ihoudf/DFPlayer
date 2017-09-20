//
//  DFPlayerLyricsTableview.m
//  DFPlayer
//
//  Created by HDF on 2017/8/16.
//  Copyright © 2017年 HDF. All rights reserved.
//


#import "DFPlayerLyricsTableview.h"
#import "DFPlayerManager.h"

@implementation DFPlayerLyricsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundLrcLabel = [[UILabel alloc] init];
        self.backgroundLrcLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.backgroundLrcLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.backgroundLrcLabel];
        
        self.ForegroundLrcLabel = [[UILabel alloc] init];
        self.ForegroundLrcLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.ForegroundLrcLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.ForegroundLrcLabel];
        
        self.lrcMasklayer = [CALayer layer];
        self.lrcMasklayer.anchorPoint = CGPointMake(0, 0.5);
        self.ForegroundLrcLabel.layer.mask = self.lrcMasklayer;
    }
    return self;
}

@end


static NSString *lyricCellId = @"lyricCellId";
NSString * const DFPlayerLyricStateKey = @"state";
NSString * const DFPlayerLyricCurrentTimeKey = @"currentTime";

@interface DFPlayerLyricsTableview ()
<UITableViewDelegate,
UITableViewDataSource,
UIScrollViewDelegate>
/**歌词数组*/
@property (nonatomic, strong) NSMutableArray *lyricArray;
/**时间数组*/
@property (nonatomic, strong) NSMutableArray *timeArray;
/**歌词当前行数*/
@property (nonatomic, assign) NSInteger currentIndex;
/**标记*/
@property (nonatomic, assign) NSInteger lastIndex;
/**歌词当前行IndexPath*/
@property (nonatomic, strong) NSIndexPath *currentIndexPath;
/**是否拖拽*/
@property (nonatomic, assign) BOOL isDraging;
@end

@implementation DFPlayerLyricsTableview
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

- (instancetype)init{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.isDraging = NO;
        self.delegate = self;
        self.dataSource = self;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        [[DFPlayerManager shareInstance] addObserver:self forKeyPath:DFPlayerLyricStateKey options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
        [[DFPlayerManager shareInstance] addObserver:self forKeyPath:DFPlayerLyricCurrentTimeKey options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

#pragma mark  - tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  self.lyricArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DFPlayerLyricsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:lyricCellId];
    if (cell == nil) {
        cell = [[DFPlayerLyricsTableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:lyricCellId];
        cell.backgroundColor = self.cellBackgroundColor?self.cellBackgroundColor:[UIColor whiteColor];
    }
    cell.ForegroundLrcLabel.frame = self.lrcLabelFrame;
    cell.backgroundLrcLabel.frame = self.lrcLabelFrame;
    [cell.ForegroundLrcLabel sizeToFit];
    [cell.backgroundLrcLabel sizeToFit];

    if (cell.ForegroundLrcLabel.frame.size.width > self.frame.size.width) {
        cell.ForegroundLrcLabel.frame = CGRectMake(cell.ForegroundLrcLabel.frame.origin.x, cell.ForegroundLrcLabel.frame.origin.y, self.frame.size.width, cell.ForegroundLrcLabel.frame.size.height);
    }
    
    if (cell.backgroundLrcLabel.frame.size.width > self.frame.size.width) {
        cell.backgroundLrcLabel.frame = CGRectMake(cell.backgroundLrcLabel.frame.origin.x, cell.backgroundLrcLabel.frame.origin.y, self.frame.size.width, cell.backgroundLrcLabel.frame.size.height);
    }
    
    cell.ForegroundLrcLabel.backgroundColor = [UIColor brownColor];
    
    if (indexPath == self.currentIndexPath) {//当前行
        cell.backgroundLrcLabel.textColor   = self.currentLineLrcBackgroundTextColor;
        cell.backgroundLrcLabel.font        = self.currentLineLrcFont;
    }else{//其他行
        cell.ForegroundLrcLabel.hidden      = YES;
        cell.backgroundLrcLabel.textColor   = self.otherLineLrcBackgroundTextColor;
        cell.backgroundLrcLabel.font        = self.otherLineLrcFont;
    }
    cell.ForegroundLrcLabel.text = self.lyricArray[indexPath.row];
    cell.backgroundLrcLabel.text = self.lyricArray[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - scrollview delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isDraging = YES;
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self performSelector:@selector(delayToReset) withObject:nil afterDelay:0.2];
}
- (void)delayToReset{
    self.isDraging = NO;
}

#pragma mark - kvc
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == [DFPlayerManager shareInstance]) {
        if ([keyPath isEqualToString:DFPlayerLyricStateKey]) {
            if ([DFPlayerManager shareInstance].state == DFPlayerStatePlaying) {
                [self analyzeLyric];
            }
        }else if ([keyPath isEqualToString:DFPlayerLyricCurrentTimeKey]){
            [self updateLyricsText];
        }
    }
}

- (void)updateLyricsText{
    if (self.timeArray.count <= 0 || self.lyricArray.count <= 0) {return;}
    CGFloat currentTime = [DFPlayerManager shareInstance].currentTime;
    for (int i = 0; i < self.timeArray.count; i++) {
        NSLog(@"-----------------------------------------:%lf----------%lf",currentTime,[self.timeArray[i] floatValue]);
        if ([self.timeArray[i] floatValue] < currentTime) {
            self.currentIndex = i;
        }else{
            break;
        }
    }
    
    NSLog(@"--lastindex:%ld----------currentIndex:%ld",(long)self.lastIndex,(long)self.currentIndex);
    if (self.lastIndex == self.currentIndex) {return;}
    self.lastIndex = self.currentIndex;
    
    NSLog(@"--self.currentIndex:%ld",(long)self.currentIndex);
    self.currentIndexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    
    if (!self.isDraging) {
        if (self.currentIndex < self.timeArray.count) {//安全性判断
            [self scrollToRowAtIndexPath:self.currentIndexPath
                        atScrollPosition:(UITableViewScrollPositionMiddle)
                                animated:YES];
        }
    }
    
    DFPlayerLyricsTableViewCell *cell = (DFPlayerLyricsTableViewCell *)[self cellForRowAtIndexPath:self.currentIndexPath];
    if (self.currentLineLrcForegroundTextColor) {//卡拉OK模式
        cell.ForegroundLrcLabel.textColor = self.currentLineLrcForegroundTextColor;
        cell.ForegroundLrcLabel.font = self.currentLineLrcFont;
        cell.ForegroundLrcLabel.hidden = NO;
        cell.lrcMasklayer.position = CGPointMake(0, self.lrcLabelFrame.size.height/2);
        cell.lrcMasklayer.bounds = CGRectMake(0, 0, 0, self.lrcLabelFrame.size.height);
        cell.lrcMasklayer.backgroundColor = [UIColor brownColor].CGColor;
        
        CGFloat duration = 0;
        if (self.currentIndex < self.timeArray.count - 1) {
            duration = [self.timeArray[self.currentIndex+1] floatValue]-[self.timeArray[self.currentIndex] floatValue];
        }else{
            duration = [DFPlayerManager shareInstance].totalTime - [self.timeArray[self.currentIndex] floatValue];
        }
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"bounds.size.width"];
        animation.values = @[@(0),@(355)];
        animation.keyTimes = @[@(0),@(1)];
        animation.duration = duration;
        animation.calculationMode = kCAAnimationLinear;
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        [cell.lrcMasklayer addAnimation:animation forKey:@"Animation"];
    }else{
        cell.ForegroundLrcLabel.hidden = YES;
    }
    [self reloadData];
}


- (void)analyzeLyric{
    if (self.lyricArray.count != 0) {
        [self.lyricArray removeAllObjects];
        [self reloadData];
    }
    if (self.timeArray.count != 0) {
        [self.timeArray removeAllObjects];
    }
    NSString *lyric = [DFPlayerManager shareInstance].currentAudioModel.audioLyric;
    if (!lyric || lyric.length <= 0) {return;}
    //这里先将每句歌词已分割
    NSArray *arr = [lyric componentsSeparatedByString:@"\n"];
    
    for (int i = 0; i < arr.count; i++) {
        NSString *lrc = arr[i];
        if (lrc.length <= 0) {continue;}
        NSLog(@"--lrc:%@",lrc);
        if ([[lrc substringToIndex:1] isEqualToString:@"["]) {
            lrc = [lrc substringFromIndex:1];
        }
        NSArray *lineArray = [lrc componentsSeparatedByString:@"]"];
        if ([lineArray.firstObject hasPrefix:@"ar"] ||
            [lineArray.firstObject hasPrefix:@"ti"] ||
            [lineArray.firstObject hasPrefix:@"al"] ||
            [lineArray.firstObject hasPrefix:@"by"]){
            if ([lineArray.firstObject rangeOfString:@":"].location != NSNotFound){
                NSString *head = [lineArray.firstObject componentsSeparatedByString:@":"].lastObject;
                [self.lyricArray addObject:head];
            }
        }else{
            //时间转换成秒
            NSString *time = lineArray.firstObject;
            CGFloat second = 0;
            //[00:00.00]和[00:00:00]
            if (time.length == 8) {
                NSString *str = [time substringWithRange:NSMakeRange(5, 1)];
                if ([str isEqualToString:@":"]) {
                    time = [time stringByReplacingOccurrencesOfString:@":" withString:@"." options:(NSAnchoredSearch) range:(NSMakeRange(5, 1))];
                }
                NSString *minutes = [time substringWithRange:NSMakeRange(0, 2)];
                NSString *seconds = [time substringWithRange:NSMakeRange(3, 5)];
                second = minutes.floatValue*60 + seconds.floatValue;
            }
            //[00:00]
            if (time.length == 6) {
                NSString *minutes = [time substringWithRange:NSMakeRange(0, 2)];
                NSString *seconds = [time substringWithRange:NSMakeRange(3, 2)];
                second = minutes.floatValue*60 + seconds.floatValue;
            }
            [self.timeArray addObject:[NSNumber numberWithFloat:second]];
            
            //歌词
            [self.lyricArray addObject:lineArray.lastObject];
        }
    }
    [self reloadData];
}

- (void)dealloc{
    [[DFPlayerManager shareInstance] removeObserver:self forKeyPath:DFPlayerLyricStateKey];
    [[DFPlayerManager shareInstance] removeObserver:self forKeyPath:DFPlayerLyricCurrentTimeKey];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
