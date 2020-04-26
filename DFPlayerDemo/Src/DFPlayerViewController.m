//
//  DFPlayerViewController.m
//  DFPlayerDemo
//
//  Created by ihoudf on 2017/10/7.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import "DFPlayerViewController.h"
#import "YourModel.h"
#import "NSObject+Extentions.h"

#import "DFPlayer.h"
#import "DFPlayerUIManager.h"

#define topH SCREEN_HEIGHT - self.tabBarController.tabBar.frame.size.height - DFHeight(270)

@interface DFPlayerViewController ()
<UITableViewDelegate,UITableViewDataSource,DFPlayerDelegate,DFPlayerDataSource>
{
    UIImageView *_bgView;
    UIScrollView *_scrollView;
    UITableView *_tableView;
    UITableView *_lyricsTableView;
    UILabel *_noticeLabel;
    BOOL _stopUpdate;
}

@property (nonatomic, strong) NSMutableArray<YourModel *> *yourModelArray;
@property (nonatomic, strong) NSArray<YourModel *> *yourModelAddArray;
@property (nonatomic, assign) NSInteger addIndex;
@property (nonatomic, strong) NSMutableArray<DFPlayerModel *> *dataArray;

@end

@implementation DFPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加音频" style:(UIBarButtonItemStylePlain) target:self action:@selector(handleRightBarButtonItemAction)];
    self.navigationItem.rightBarButtonItem.tintColor = DFGreenColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"暂停恢复" style:(UIBarButtonItemStylePlain) target:self action:@selector(handleLeftBarButtonItemAction)];
    self.navigationItem.leftBarButtonItem.tintColor = DFGreenColor;
    
    self.addIndex = 0;
    
    [self initData];
    [self initUI];
    [self initDFPlayer];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self tableViewReloadData];
}

- (void)handleRightBarButtonItemAction{
    if (self.addIndex >= self.yourModelAddArray.count) {
        [self showAlert:@"添加完毕，已无更多音频"];
        return;
    }
    YourModel *yourModel = self.yourModelAddArray[self.addIndex];
    [self.yourModelArray insertObject:yourModel atIndex:0];//这里将数据加到第一个
    self.addIndex++;
    [self tableViewReloadData];
    [[DFPlayer sharedPlayer] df_reloadData];
}

- (void)handleLeftBarButtonItemAction{
    if (_stopUpdate) {
        [[DFPlayerUIManager sharedManager] df_resumeUpdate];
        _stopUpdate = NO;
    }else{
        [[DFPlayerUIManager sharedManager] df_stopUpdate];
        _stopUpdate = YES;
    }
}

- (void)tableViewReloadData{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_tableView reloadData];
    });
}

- (void)initData{
    //这里是你从自己服务端请求的数据
    _yourModelArray = [self getYourModelArray]; // 主数据
    _yourModelAddArray = [self getYourModelAddArray];// 用于模拟添加数据
}

- (void)initUI{
    _bgView = [self bgView:self.view];
    
    CGRect rect = (CGRect){0, 0, SCREEN_WIDTH, topH};
    _scrollView = [[UIScrollView alloc] initWithFrame:rect];
    _scrollView.pagingEnabled = YES;
    _scrollView.contentSize = (CGSize){SCREEN_WIDTH*2, topH};
    _scrollView.showsHorizontalScrollIndicator = NO;
    [_bgView addSubview:_scrollView];
    
    _tableView = [[UITableView alloc] initWithFrame:rect];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = DFHeight(100);
    [_scrollView addSubview:_tableView];
    
    //歌词tableview
    _lyricsTableView =
    [[DFPlayerUIManager sharedManager] df_lyricTableViewWithFrame:(CGRect){SCREEN_WIDTH, 0, SCREEN_WIDTH, topH}
                                                    cellRowHeight:DFHeight(90)
                                              cellBackgroundColor:[UIColor clearColor]
                                currentLineLrcForegroundTextColor:DFGreenColor
                                currentLineLrcBackgroundTextColor:[UIColor whiteColor]
                                  otherLineLrcBackgroundTextColor:[UIColor whiteColor]
                                               currentLineLrcFont:DFSystemFont(18)
                                                 otherLineLrcFont:DFSystemFont(16)
                                                        superView:_scrollView
                                                            block:^(NSString * _Nonnull onPlayingLyrics) {
        self->_noticeLabel.text = onPlayingLyrics;
    }];
    _lyricsTableView.backgroundColor = [UIColor clearColor];
    _lyricsTableView.showsVerticalScrollIndicator = NO;
    CGFloat edgeInsets_top = (topH-DFHeight(90))/2;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(edgeInsets_top, 0, edgeInsets_top, 0);
    _lyricsTableView.contentInset = contentInset;

    _noticeLabel = [[UILabel alloc] init];
    _noticeLabel.frame = (CGRect){0, topH, SCREEN_WIDTH, DFHeight(70)};
    _noticeLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    _noticeLabel.textColor = DFGreenColor;
    _noticeLabel.textAlignment = NSTextAlignmentCenter;
    _noticeLabel.font = DFSystemFont(18);
    [_bgView addSubview:_noticeLabel];
    
    CGRect rateRect = (CGRect){SCREEN_WIDTH-DFWidth(103), topH+DFHeight(170), DFWidth(63), DFHeight(45)};
    UIButton *rateBtn = [UIButton buttonWithType:(UIButtonTypeSystem)];
    rateBtn.frame = rateRect;
    [rateBtn setTitle:@"倍速" forState:(UIControlStateNormal)];
    [rateBtn setTitleColor:DFGreenColor forState:(UIControlStateNormal)];
    [rateBtn addTarget:self action:@selector(rateAction) forControlEvents:(UIControlEventTouchUpInside)];
    [_bgView addSubview:rateBtn];
}
- (void)rateAction{
    [self showRateAlertSheetBlock:^(CGFloat rate) {
        [[DFPlayer sharedPlayer] df_setRate:rate];
    }];
}

#pragma mark  - tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.yourModelArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellId"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:@"cellId"];
    }
    YourModel *model = self.yourModelArray[indexPath.row];
    
    NSString *type = [model.yourUrl hasPrefix:@"http"] ? @"网络音频" : @"本地音频";
    cell.textLabel.text = [NSString stringWithFormat:@"%ld--%@-%@(%@)",(long)indexPath.row,type,model.yourName,model.yourSinger];

    if ([[DFPlayer sharedPlayer] df_cachePath:[self getAvailableURL:model.yourUrl]]) {
        cell.tintColor = DFGreenColor;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.detailTextLabel.hidden = YES;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.dataArray.count > indexPath.row) {
        [_scrollView setContentOffset:(CGPointMake(SCREEN_WIDTH, 0)) animated:YES];
        DFPlayerModel *model = self.dataArray[indexPath.row];
        [[DFPlayer sharedPlayer] df_playWithAudioId:model.audioId];
    }
}

#pragma mark - 以下代码与DFPlayer库有关
#pragma mark - 初始化DFPlayer
- (void)initDFPlayer{
    [[DFPlayer sharedPlayer] df_initPlayerWithUserId:nil];
    [DFPlayer sharedPlayer].dataSource  = self;
    [DFPlayer sharedPlayer].delegate    = self;
    [DFPlayer sharedPlayer].playMode    = DFPlayerModeSingleCycle;
    [DFPlayer sharedPlayer].isObserveWWAN = YES;
    [[DFPlayer sharedPlayer] df_reloadData];//需在传入数据源后调用
    
    CGRect buffRect = (CGRect){DFWidth(104), topH+DFHeight(98), DFWidth(542), DFHeight(4)};
    CGRect proRect  = (CGRect){DFWidth(104), topH+DFHeight(80), DFWidth(542), DFHeight(40)};
    CGRect currRect = (CGRect){DFWidth(10), topH+DFHeight(80), DFWidth(90), DFHeight(40)};
    CGRect totaRect = (CGRect){SCREEN_WIDTH-DFWidth(100), topH+DFWidth(80), DFWidth(90), DFHeight(40)};
    CGRect playRect = (CGRect){DFWidth(320), topH+DFHeight(140), DFWidth(110), DFWidth(110)};
    CGRect nextRext = (CGRect){DFWidth(490), topH+DFHeight(154), DFWidth(80), DFWidth(80)};
    CGRect lastRect = (CGRect){DFWidth(180), topH+DFHeight(154), DFWidth(80), DFWidth(80)};
    CGRect typeRect = (CGRect){DFWidth(40), topH+DFHeight(170), DFWidth(63), DFHeight(45)};
    
    UIImage *nextImage = [UIImage imageNamed:@"dfplayer_next"];
    UIImage *lastImage = [UIImage imageNamed:@"dfplayer_last"];
    UIImage *playImage = [UIImage imageNamed:@"dfplayer_play"];
    UIImage *pauseImage = [UIImage imageNamed:@"dfplayer_pause"];
    UIImage *singleImage = [UIImage imageNamed:@"dfplayer_single"];
    UIImage *circleImage = [UIImage imageNamed:@"dfplayer_circle"];
    UIImage *shuffleImage = [UIImage imageNamed:@"dfplayer_shuffle"];
    UIImage *ovalImage = [UIImage imageNamed:@"dfplayer_oval"];

    DFPlayerUIManager *mgr = [DFPlayerUIManager sharedManager];
    //缓冲条
    [mgr df_bufferViewWithFrame:buffRect
                 trackTintColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.5]
              progressTintColor:[UIColor colorWithWhite:1 alpha:0.5]
                      superView:_bgView];
    //进度条
    [mgr df_sliderWithFrame:proRect
      minimumTrackTintColor:DFGreenColor
      maximumTrackTintColor:DFGrayColor
                trackHeight:DFHeight(4)
                 thumbImage:[ovalImage imageByResizeToSize:(CGSize){DFWidth(34),DFHeight(34)}]
                  superView:_bgView];
    //当前时间
    [mgr df_currentTimeLabelWithFrame:currRect
                            textColor:[UIColor whiteColor]
                        textAlignment:(NSTextAlignmentCenter)
                                 font:DFSystemFont(14)
                            superView:_bgView];
    //总时间
    [mgr df_totalTimeLabelWithFrame:totaRect
                          textColor:[UIColor whiteColor]
                      textAlignment:(NSTextAlignmentCenter)
                               font:DFSystemFont(14)
                          superView:_bgView];
    //播放模式按钮
    [mgr df_typeBtnWithFrame:typeRect singleImage:singleImage circleImage:circleImage shuffleImage:shuffleImage superView:_bgView block:nil];
    //播放暂停按钮
    [mgr df_playPauseBtnWithFrame:playRect playImage:playImage pauseImage:pauseImage superView:_bgView block:nil];
    //下一首按钮
    [mgr df_nextBtnWithFrame:nextRext image:nextImage superView:_bgView block:nil];
    //上一首按钮
    [mgr df_lastBtnWithFrame:lastRect image:lastImage superView:_bgView block:nil];
}

#pragma mark - DFPLayer dataSource
- (NSArray<DFPlayerModel *> *)df_audioDataForPlayer:(DFPlayer *)player{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }else{
        [_dataArray removeAllObjects];
    }
    for (int i = 0; i < self.yourModelArray.count; i++) {
        YourModel *yourModel = self.yourModelArray[i];
        DFPlayerModel *model = [[DFPlayerModel alloc] init];
        model.audioId = i;//****重要。AudioId从0开始，仅标识当前音频在数组中的位置。
        if ([yourModel.yourUrl hasPrefix:@"http"]) {//网络音频
            model.audioUrl = [self getAvailableURL:yourModel.yourUrl];
        }else{//本地音频
            NSString *path = [[NSBundle mainBundle] pathForResource:yourModel.yourUrl ofType:@""];
            if (path) {
                model.audioUrl = [NSURL fileURLWithPath:path];
            }
        }
        [_dataArray addObject:model];
    }
    return [_dataArray copy];
}
- (DFPlayerInfoModel *)df_audioInfoForPlayer:(DFPlayer *)player{
    YourModel *yourModel = self.yourModelArray[player.currentAudioModel.audioId];
    NSString *lyricPath = [[NSBundle mainBundle] pathForResource:yourModel.yourLyric ofType:nil];
    NSURL *imageUrl = [NSURL URLWithString:yourModel.yourImage];
    NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
    DFPlayerInfoModel *infoModel = [[DFPlayerInfoModel alloc] init];
    infoModel.audioName = yourModel.yourName;
    infoModel.audioSinger = yourModel.yourSinger;
    infoModel.audioAlbum = yourModel.yourAlbum;
    infoModel.audioLyrics = [NSString stringWithContentsOfFile:lyricPath encoding:NSUTF8StringEncoding error:nil];
    infoModel.audioImage = [UIImage imageWithData:imageData];
    return infoModel;
}

#pragma mark - DFPlayer delegate
//加入播放队列
- (void)df_playerAudioAddToPlayQueue:(DFPlayer *)player{
    [self tableViewReloadData];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.title = player.currentAudioInfoModel.audioName;
            self->_bgView.image = [self getBackgroundImage:player.currentAudioInfoModel.audioImage];
            self->_noticeLabel.text = player.currentAudioInfoModel.audioLyrics ? @"" : @"无可用歌词";
        });
    });
}

//缓冲进度代理
- (void)df_player:(DFPlayer *)player bufferProgress:(CGFloat)bufferProgress{
    [self congfigCell:player.currentAudioModel.audioId
      detailTextLabel:[NSString stringWithFormat:@"正在缓冲%lf",bufferProgress]];
}

//播放进度代理
- (void)df_player:(DFPlayer *)player progress:(CGFloat)progress currentTime:(CGFloat)currentTime{
    [self congfigCell:player.currentAudioModel.audioId
      detailTextLabel:[NSString stringWithFormat:@"当前进度%lf--当前时间%.0f",progress,currentTime]];
}

//状态信息代理
- (void)df_player:(DFPlayer *)player didGetStatusCode:(DFPlayerStatusCode)statusCode{
    if (statusCode == DFPlayerStatusNoNetwork) {
        [self showAlert:@"没有网络连接"];
    }else if(statusCode == DFPlayerStatusViaWWAN){
        [self showAlert:@"继续播放将产生流量费用" okBlock:^{
            [DFPlayer sharedPlayer].isObserveWWAN = NO;
            [[DFPlayer sharedPlayer] df_playWithAudioId:player.currentAudioModel.audioId];
        }];
    }else if(statusCode == DFPlayerStatusTimeOut){
        [self showAlert:@"请求超时"];
    }else if(statusCode == DFPlayerStatusCacheSucc){
        [self tableViewReloadData];
        return;
    }else{
        NSLog(@"状态码:%lu",(unsigned long)statusCode);
    }
}

- (void)congfigCell:(NSInteger)row detailTextLabel:(NSString *)text{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = text;
    cell.detailTextLabel.hidden = NO;
}

@end
