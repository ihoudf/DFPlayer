//
//  DFRemoteAudioViewController.m
//  DFPlayer
//
//  Created by Faroe on 2017/8/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFRemoteAudioViewController.h"
#import "DFPlayer.h"
#import "YourDataModel.h"
#import "DFMacro.h"
#import "NSObject+Alert.h"
#import "UIImage+Blur.h"
static NSString *cellId = @"cellId";

@interface DFRemoteAudioViewController ()
<UITableViewDelegate,
UITableViewDataSource,
DFPlayerDelegate,DFPlayerDataSource>

@property (nonatomic, strong) NSMutableArray    *dataArray;
@property (nonatomic, strong) NSMutableArray    *df_ModelArray;
@property (nonatomic, strong) NSArray           *addArray;

@property (nonatomic, assign) NSInteger         currentId;
@property (nonatomic, assign) NSInteger         addIndex;//添加音频数组标识

@property (nonatomic, strong) UITableView       *tableView;
@property (nonatomic, strong) UIImageView       *controlView;
@property (nonatomic, strong) UILabel           *titleLabel;

@end

@implementation DFRemoteAudioViewController

#pragma mark - 数据
- (NSMutableArray *)dataArray{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
        NSString *path1 = [[NSBundle mainBundle] pathForResource:@"remoteAudio" ofType:@"plist"];
        NSMutableArray *arr = [[NSMutableArray alloc] initWithContentsOfFile:path1];
        for (int i = 0; i < arr.count; i++) {
            YourDataModel *model = [self setDataModelWithDic:arr[i]];
            [_dataArray addObject:model];
        }
    }
    return _dataArray;
}

- (YourDataModel *)setDataModelWithDic:(NSDictionary *)dic{
    YourDataModel *model = [[YourDataModel alloc] init];
    model.yourUrl       = [dic objectForKey:@"audioUrl"];
    model.yourName      = [dic objectForKey:@"audioName"];
    model.yourSinger    = [dic objectForKey:@"audioSinger"];
    model.yourAlbum     = [dic objectForKey:@"audioAlbum"];
    model.yourImage     = [dic objectForKey:@"audioImage"];
    model.yourLyric     = [dic objectForKey:@"audioLyric"];
    return model;
}

#pragma mark - 添加音频数据
- (NSArray *)addArray{
    if (_addArray == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"addAudio" ofType:@"plist"];
        NSMutableArray *addData = [[NSMutableArray alloc] initWithContentsOfFile:path];
        _addArray = [NSArray arrayWithArray:addData];
    }
    return _addArray;
}
- (void)addSongAction{
    if (self.addIndex >= self.addArray.count) {
        [self showAlertWithTitle:@"添加完毕，已无更多音频" message:nil yesBlock:nil];
        return;
    }
    YourDataModel *yourModel = [self setDataModelWithDic:self.addArray[self.addIndex]];
    [self.dataArray insertObject:yourModel atIndex:0];//这里将数据加到第一个
    [self.tableView reloadData];
    self.addIndex++;
    
    //更新DFPlayer的音频数据
    [[DFPlayerManager shareInstance] df_reloadData];
}

#pragma mark - 加载视图
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"😆😁-----:%@",NSHomeDirectory());
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemAdd) target:self action:@selector(addSongAction)];
    self.addIndex = 0;
    self.currentId = -100;
    
    //UI
    [self initUI];
    //初始化DFPlayer
    [self initDFPlayer];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - UI
- (void)initUI{
    self.tableView              = [[UITableView alloc] init];
    self.tableView.frame        = [UIScreen mainScreen].bounds;
    self.tableView.delegate     = self;
    self.tableView.dataSource   = self;
    self.tableView.rowHeight    = CountHeight(100);
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.tableView];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, CountHeight(280), 0);
    
    self.controlView = [[UIImageView alloc] init];
    self.controlView.frame = CGRectMake(0, self.view.frame.size.height-49-CountHeight(280), self.view.frame.size.width, CountHeight(280));
    self.controlView.backgroundColor = LCRGBAColor(105, 105, 105, 0.5);
    self.controlView.image = [[UIImage imageNamed:@"dfplayer_control_skin.jpg"] blurImageUseCoreImageWithBlurLevel:25];
    self.controlView.userInteractionEnabled = YES;
    [self.view addSubview:self.controlView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.frame = CGRectMake(0, CountHeight(230), SCREEN_WIDTH, CountHeight(40));
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.controlView addSubview:self.titleLabel];
    self.titleLabel.text = [DFPlayerManager shareInstance].previousAudioModel.audioName;

}

#pragma mark  - tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  self.dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor whiteColor];
    }
    YourDataModel *model = self.dataArray[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld-%@--%@",(long)indexPath.row,self.title,model.yourName];
    
    NSURL *url = [self turnChineseCharacterToAvailableStrWtihUrlStr:model.yourUrl];
    if ([[DFPlayerManager shareInstance] df_playerCheckIsCachedWithUrl:url]) {
        cell.tintColor = HDFGreenColor;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (indexPath.row == self.currentId+self.addIndex) {
        cell.detailTextLabel.hidden = NO;
    }else{
        cell.detailTextLabel.hidden = YES;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    DFPlayerModel *model = self.df_ModelArray[indexPath.row];
//    [[DFPlayerManager shareInstance] df_playerDidSelectWithAudioId:model.audioId];
    [[DFPlayerManager shareInstance] df_playerDidSelectWithAudioId:indexPath.row];
}

#pragma mark - DFPlayer
- (void)initDFPlayer{
    //播放器
    [DFPlayerManager shareInstance].isEnableLog = YES;
    //    [[DFPlayerManager shareInstance] initPlayerWithUserId:nil];
    [DFPlayerManager shareInstance].delegate    = self;
    [DFPlayerManager shareInstance].dataSource  = self;
    [DFPlayerManager shareInstance].category    = DFPlayerAudioSessionCategoryPlayback;
    [DFPlayerManager shareInstance].isObservePreviousAudioModel = YES;
    [DFPlayerManager shareInstance].isObserveWWAN = YES;
    [[DFPlayerManager shareInstance] df_reloadData];//必须在设置数据源（[DFPlayerManager shareInstance].dataSource = self;）后调用
    
    //进入页面不需要点击就开始播放
//    DFPlayerModel *model = self.dataArray[2];
//    [[DFPlayerManager shareInstance] df_playerDidSelectWithAudioId:model.audioId];
    
    //类型按钮
    DFPlayerControlManager *manager = [DFPlayerControlManager shareInstance];
    
    CGRect typeRect = CGRectMake(CountWidth(40), CountHeight(120), CountWidth(63), CountHeight(45));
    [manager df_typeControlBtnWithFrame:typeRect superView:self.controlView block:nil];
    //airplay按钮
    CGRect airRect  = CGRectMake(CountWidth(650), CountHeight(120), CountWidth(63), CountHeight(50));
    [manager df_airPlayViewWithFrame:airRect backgroundColor:[UIColor clearColor] superView:self.controlView];
    //播放暂停按钮
    CGRect playRect = CGRectMake(CountWidth(320), CountHeight(90), CountWidth(110), CountWidth(110));
    [manager df_playPauseBtnWithFrame:playRect superView:self.controlView block:nil];
    //下一首按钮
    CGRect nextRext = CGRectMake(CountWidth(490), CountHeight(104), CountWidth(80), CountWidth(80));
    [manager df_nextAudioBtnWithFrame:nextRext superView:self.controlView block:nil];
    //上一首按钮
    CGRect lastRect = CGRectMake(CountWidth(180), CountHeight(104), CountWidth(80), CountWidth(80));
    [manager df_lastAudioBtnWithFrame:lastRect superView:self.controlView block:nil];
    //缓冲条
    CGRect buffRect = CGRectMake(CountWidth(104), CountHeight(38), CountWidth(542), CountHeight(4));
    [manager df_bufferProgressViewWithFrame:buffRect trackTintColor:[UIColor clearColor] progressTintColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5] superView:self.controlView];
    //进度条
    CGRect proRect  = CGRectMake(CountWidth(104), CountHeight(20), CountWidth(542), CountHeight(40));
    [manager df_sliderWithFrame:proRect minimumTrackTintColor:HDFGreenColor maximumTrackTintColor:[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.0] trackHeight:CountHeight(4) thumbSize:(CGSizeMake(CountWidth(34), CountWidth(34))) superView:self.controlView];
    //当前时间
    CGRect currRect = CGRectMake(CountWidth(15), CountHeight(20), CountWidth(80), CountHeight(40));
    UILabel *currentTimeLabel = [manager df_currentTimeLabelWithFrame:currRect superView:self.controlView];
    currentTimeLabel.textColor = HDFGreenColor;
    //总时间
    CGRect totalRect = CGRectMake(SCREEN_WIDTH-CountWidth(95), CountHeight(20), CountWidth(80), CountHeight(40));
    UILabel *totalTimeLabel = [manager df_totalTimeLabelWithFrame:totalRect superView:self.controlView];
    totalTimeLabel.textColor = HDFGreenColor;
}

#pragma mark - DFPLayer dataSource
- (NSArray<DFPlayerModel *> *)df_playerModelArray{
    _df_ModelArray = [NSMutableArray array];
    for (int i = 0; i < self.dataArray.count; i++) {
        YourDataModel *yourModel    = [[YourDataModel alloc] init];
        yourModel                   = self.dataArray[i];
        DFPlayerModel *model        = [self setDFPlayerModelWithYourDataModel:yourModel];
        model.audioId               = i;//****重要。audioId标识音频在数组中的位置。
        [_df_ModelArray addObject:model];
    }
    return self.df_ModelArray;
}

- (DFPlayerModel *)setDFPlayerModelWithYourDataModel:(YourDataModel *)yourModel{
    DFPlayerModel *model = [[DFPlayerModel alloc] init];
    model.audioUrl      = [self turnChineseCharacterToAvailableStrWtihUrlStr:yourModel.yourUrl];
    model.audioName     = yourModel.yourName;
    model.audioSinger   = yourModel.yourSinger;
    model.audioAlbum    = yourModel.yourAlbum;
    //歌词
    NSString *lyricPath = [[NSBundle mainBundle] pathForResource:yourModel.yourLyric ofType:nil];
    NSString *lyricStr  = [NSString stringWithContentsOfFile:lyricPath encoding:NSUTF8StringEncoding error:nil];
    model.audioLyric    = lyricStr;
    //配图
    NSURL *imageUrl     = [NSURL URLWithString:yourModel.yourImage];
    NSData *imageData   = [NSData dataWithContentsOfURL:imageUrl];
    model.audioImage    = [UIImage imageWithData: imageData];
    return model;
}

- (NSURL *)turnChineseCharacterToAvailableStrWtihUrlStr:(NSString *)yourUrl{
    //如果链接中存在中文或某些特殊字符，需要通过以下代码转译
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)yourUrl, (CFStringRef)@"!NULL,'()*+,-./:;=?@_~%#[]", NULL, kCFStringEncodingUTF8));
    //        NSString *str = [ss stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:encodedString];
}
#pragma mark - DFPlayer delegate
//加入播放队列
- (void)df_playerAudioWillAddToPlayQueue:(DFPlayerManager *)playerManager{
    self.titleLabel.text = playerManager.currentAudioModel.audioName;
    self.currentId = playerManager.currentAudioModel.audioId;
     NSLog(@"--currentId====================:%ld",self.currentId);
    UIImage *bgImage = playerManager.currentAudioModel.audioImage;
    if (bgImage) {
        CGRect rect = CGRectMake(bgImage.size.width/3, bgImage.size.height/3, bgImage.size.width/3, bgImage.size.height/3);
        UIImage *image = [playerManager.currentAudioModel.audioImage getSubImage:rect];
        self.controlView.image = [image blurImageUseCoreImageWithBlurLevel:3];
    }
    [self.tableView reloadData];
}
//缓冲进度代理
- (void)df_player:(DFPlayerManager *)playerManager bufferProgress:(CGFloat)bufferProgress totalTime:(CGFloat)totalTime{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentId inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"正在缓冲%lf",bufferProgress];
}
//播放进度代理
- (void)df_player:(DFPlayerManager *)playerManager progress:(CGFloat)progress currentTime:(CGFloat)currentTime totalTime:(CGFloat)totalTime{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentId inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"当前进度%lf--当前时间%.0f--总时长%.0f",progress,ceilf(currentTime),ceilf(totalTime)];
}
//缓存情况代理
- (void)df_player:(DFPlayerManager *)playerManager isCached:(BOOL)isCached{
    if (isCached) {[self.tableView reloadData];}
}
//错误信息代理
- (void)df_player:(DFPlayerManager *)playerManager didFailWithErrorMessage:(NSString *)errorMessage{
    [self showAlertWithTitle:errorMessage message:nil yesBlock:nil];
}
//网络状态监测代理
- (void)df_playerNetworkDidChangeToWWAN:(DFPlayerManager *)playerManager{
    [self showAlertWithTitle:@"当前无WiFi网络，继续试听将产生流量费用" message:nil noBlock:^{
        
    } yseBlock:^{
        [DFPlayerManager shareInstance].isObserveWWAN = NO;
        [[DFPlayerManager shareInstance] df_playerDidSelectWithAudioId:playerManager.currentAudioModel.audioId];
    }];
}



/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
