//
//  DFAudioViewController.m
//  DFPlayerDemo
//
//  Created by ihoudf on 2017/10/7.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import "DFAudioViewController.h"
#import "DFPlayer.h"
#import "YourModel.h"
#import "NSObject+Extentions.h"

static NSString *cellId = @"cellId";
#define topH SCREEN_HEIGHT - self.tabBarController.tabBar.frame.size.height-DFHeight(200)

@interface DFAudioViewController ()
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

@implementation DFAudioViewController

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

- (void)initData{
    //这里是你从自己服务端请求的数据
    _yourModelArray = [self getYourModelArray]; // 主数据
    _yourModelAddArray = [self getYourModelAddArray];// 用于模拟添加数据
}

- (void)initUI{
    _bgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _bgView.backgroundColor = [UIColor whiteColor];
    _bgView.image = [UIImage imageNamed:@"default_bg.jpg"];
    _bgView.userInteractionEnabled = YES;
    [self.view addSubview:_bgView];
    if (@available(iOS 8.0,*)) {
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        effectView.frame = _bgView.frame;
        [_bgView addSubview:effectView];
    }
    
    CGFloat noticeLabel_H = DFHeight(70);
    CGFloat H = topH - noticeLabel_H;
    CGRect rect = (CGRect){0, 0, SCREEN_WIDTH, H};
    _scrollView = [[UIScrollView alloc] initWithFrame:rect];
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.contentSize = (CGSize){SCREEN_WIDTH*2, H};
    _scrollView.showsHorizontalScrollIndicator = NO;
    [_bgView addSubview:_scrollView];
    
    _tableView = [[UITableView alloc] initWithFrame:rect];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = DFHeight(100);
    [_scrollView addSubview:_tableView];
    
    //歌词tableview
    _lyricsTableView =
    [[DFPlayerControlManager sharedManager] df_lyricTableViewWithFrame:(CGRect){SCREEN_WIDTH, 0, SCREEN_WIDTH, H}
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
    CGFloat edgeInsets_top = (H-DFHeight(90))/2;
    UIEdgeInsets contentInset = UIEdgeInsetsMake(edgeInsets_top, 0, edgeInsets_top, 0);
    _lyricsTableView.contentInset = contentInset;

    _noticeLabel = [[UILabel alloc] init];
    _noticeLabel.frame = (CGRect){0, H, SCREEN_WIDTH, noticeLabel_H};
    _noticeLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    _noticeLabel.textColor = DFGreenColor;
    _noticeLabel.textAlignment = NSTextAlignmentCenter;
    _noticeLabel.font = DFSystemFont(18);
    [_bgView addSubview:_noticeLabel];
}
#pragma mark  - tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _yourModelArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor clearColor];
    }
    YourModel *model = _yourModelArray[indexPath.row];
    NSString *audioType = @"网络音频";
    if (![model.yourUrl hasPrefix:@"http"]) {
        audioType = @"本地音频";
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%ld--%@-%@(%@)",(long)indexPath.row,audioType,model.yourName,model.yourSinger];
    NSURL *url = [self getAvailableURL:model.yourUrl];
    if ([[DFPlayer sharedPlayer] df_cachePath:url]) {
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

#pragma mark - 初始化DFPlayer
- (void)initDFPlayer{
    [[DFPlayer sharedPlayer] df_initPlayerWithUserId:nil];
    [DFPlayer sharedPlayer].dataSource  = self;
    [DFPlayer sharedPlayer].delegate    = self;
    [DFPlayer sharedPlayer].category    = AVAudioSessionCategoryPlayback;
    [DFPlayer sharedPlayer].isObserveWWAN = YES;
    [DFPlayer sharedPlayer].playMode    = DFPlayerModeSingleCycle;
//    [DFPlayer sharedPlayer].isNeedCache = YES;
//    [DFPlayer sharedPlayer].isManualToPlay = NO;
    [[DFPlayer sharedPlayer] df_reloadData];//需在传入数据源后调用
    
    CGRect buffRect = (CGRect){DFWidth(104), topH+DFHeight(28), DFWidth(542), DFHeight(4)};
    CGRect proRect  = (CGRect){DFWidth(104), topH+DFHeight(10), DFWidth(542), DFHeight(40)};
    CGRect currRect = (CGRect){DFWidth(10), topH+DFHeight(10), DFWidth(90), DFHeight(40)};
    CGRect totaRect = (CGRect){SCREEN_WIDTH-DFWidth(100), topH+DFWidth(10), DFWidth(90), DFHeight(40)};
    CGRect playRect = (CGRect){DFWidth(320), topH+DFHeight(70), DFWidth(110), DFWidth(110)};
    CGRect nextRext = (CGRect){DFWidth(490), topH+DFHeight(84), DFWidth(80), DFWidth(80)};
    CGRect lastRect = (CGRect){DFWidth(180), topH+DFHeight(84), DFWidth(80), DFWidth(80)};
    CGRect typeRect = (CGRect){DFWidth(40), topH+DFHeight(100), DFWidth(63), DFHeight(45)};

    CGRect rateRect = (CGRect){SCREEN_WIDTH -DFWidth(103), topH+DFHeight(100), DFWidth(63), DFHeight(45)};

    DFPlayerControlManager *mgr = [DFPlayerControlManager sharedManager];
    //缓冲条
    [mgr df_bufferProgressViewWithFrame:buffRect trackTintColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.5] progressTintColor:[UIColor colorWithWhite:1 alpha:0.5] superView:_bgView];
    //进度条
    [mgr df_sliderWithFrame:proRect minimumTrackTintColor:DFGreenColor maximumTrackTintColor:DFRGBAColor(204.0, 204.0, 204.0, 0.0) trackHeight:DFHeight(4) thumbSize:(CGSize){DFWidth(34), DFWidth(34)} superView:_bgView];
    //当前时间
    UILabel *curLabel = [mgr df_currentTimeLabelWithFrame:currRect superView:_bgView];
    curLabel.textColor = [UIColor whiteColor];
    //总时间
    UILabel *totLabel = [mgr df_totalTimeLabelWithFrame:totaRect superView:_bgView];
    totLabel.textColor = [UIColor whiteColor];
    //播放模式按钮
    [mgr df_typeControlBtnWithFrame:typeRect superView:_bgView block:nil];
    //播放暂停按钮
    [mgr df_playPauseBtnWithFrame:playRect superView:_bgView block:nil];
    //下一首按钮
    [mgr df_nextAudioBtnWithFrame:nextRext superView:_bgView block:nil];
    //上一首按钮
    [mgr df_lastAudioBtnWithFrame:lastRect superView:_bgView block:nil];
    
    UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
    button.frame = rateRect;
    [button setTitle:@"倍速" forState:(UIControlStateNormal)];
    [button setTitleColor:DFGreenColor forState:(UIControlStateNormal)];
    [button addTarget:self action:@selector(rateAction) forControlEvents:(UIControlEventTouchUpInside)];
    [_bgView addSubview:button];
}

- (void)rateAction{
    [self showRateAlertSheetBlock:^(NSString *rate) {
        [[DFPlayer sharedPlayer] df_setRate:[rate floatValue]];
    }];
}

#pragma mark - DFPLayer dataSource
- (NSArray<DFPlayerModel *> *)df_audioDataForPlayer:(DFPlayer *)player{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }else{
        [_dataArray removeAllObjects];
    }
    for (int i = 0; i < _yourModelArray.count; i++) {
        YourModel *yourModel = _yourModelArray[i];
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
    return _dataArray;
}
- (DFPlayerInfoModel *)df_audioInfoForPlayer:(DFPlayer *)player{
    YourModel *yourModel = _yourModelArray[player.currentAudioModel.audioId];
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
        UIImage *audioImage = player.currentAudioInfoModel.audioImage;
        if (audioImage) {
            CGFloat imgW = audioImage.size.height*SCREEN_WIDTH/SCREEN_HEIGHT;
            CGRect imgRect = CGRectMake((audioImage.size.width-imgW)/2, 0, imgW, audioImage.size.height);
            audioImage = [audioImage getSubImage:imgRect];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *audioName = player.currentAudioInfoModel.audioName;
            self.navigationItem.title = audioName;
            self->_bgView.image = audioImage;
            self->_noticeLabel.text = player.currentAudioInfoModel.audioLyrics ? @"" : @"无可用歌词";
        });
    });
}

//缓冲进度代理
- (void)df_player:(DFPlayer *)player bufferProgress:(CGFloat)bufferProgress totalTime:(CGFloat)totalTime{
    [self congfigCell:player.currentAudioModel.audioId
      detailTextLabel:[NSString stringWithFormat:@"正在缓冲%lf",bufferProgress]];
}

//播放进度代理
- (void)df_player:(DFPlayer *)player progress:(CGFloat)progress currentTime:(CGFloat)currentTime totalTime:(CGFloat)totalTime{
    [self congfigCell:player.currentAudioModel.audioId
      detailTextLabel:[NSString stringWithFormat:@"当前进度%lf--当前时间%.0f--总时长%.0f",progress,currentTime,totalTime]];
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

#pragma mark - action
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
        [[DFPlayerControlManager sharedManager] df_resumeUpdate];
        _stopUpdate = NO;
    }else{
        [[DFPlayerControlManager sharedManager] df_stopUpdate];
        _stopUpdate = YES;
    }
}

- (void)tableViewReloadData{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_tableView reloadData];
    });
}


@end
