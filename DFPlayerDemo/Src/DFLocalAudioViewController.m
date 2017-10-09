//
//  DFLocalAudioViewController.m
//  DFPlayer
//
//  Created by Faroe on 2017/8/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFLocalAudioViewController.h"
#import "DFPlayer.h"
#import "YourDataModel.h"
#import "DFMacro.h"

static NSString *cellId = @"cellId";
@interface DFLocalAudioViewController ()
<UITableViewDelegate,UITableViewDataSource,DFPlayerDelegate,DFPlayerDataSource>

@property (nonatomic, strong) NSMutableArray    *dataArray;
@property (nonatomic, strong) UITableView       *tableView;
@property (nonatomic, assign) NSInteger         currentId;

@end

@implementation DFLocalAudioViewController
- (NSMutableArray *)dataArray{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
        NSString *path2 = [[NSBundle mainBundle] pathForResource:@"localAudio" ofType:@"plist"];
        NSMutableArray *localData = [[NSMutableArray alloc] initWithContentsOfFile:path2];
        for (int i = 0; i < localData.count; i++) {
            YourDataModel *model = [[YourDataModel alloc] init];
            model.yourUrl       = [localData[i] objectForKey:@"audioUrl"];
            model.yourName      = [localData[i] objectForKey:@"audioName"];
            model.yourSinger    = [localData[i] objectForKey:@"audioSinger"];
            model.yourAlbum     = [localData[i] objectForKey:@"audioAlbum"];
            model.yourImage     = [localData[i] objectForKey:@"audioImage"];
            [_dataArray addObject:model];
        }
    }
    return _dataArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentId = -100;
    
    [self initUI];
    [self initDFPlayer];
}

- (void)initUI{
    self.tableView              = [[UITableView alloc] init];
    self.tableView.frame        = [UIScreen mainScreen].bounds;
    self.tableView.delegate     = self;
    self.tableView.dataSource   = self;
    self.tableView.rowHeight    = CountHeight(100);
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    
    
//    
//    self.titleLabel = [[UILabel alloc] init];
//    self.titleLabel.frame = CGRectMake(0, CountHeight(230), SCREEN_WIDTH, CountHeight(40));
//    self.titleLabel.textAlignment = NSTextAlignmentCenter;
//    self.titleLabel.numberOfLines = 0;
//    self.titleLabel.textColor = [UIColor blackColor];
//    self.titleLabel.font = [UIFont systemFontOfSize:15];
//    [self.controlView addSubview:self.titleLabel];
//    self.titleLabel.text = [DFPlayerManager shareInstance].previousAudioModel.audioName;
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showTableView)];
//    [self.controlView addGestureRecognizer:tap];
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
    cell.textLabel.text = [NSString stringWithFormat:@"%@%ld-%@",self.title,(long)indexPath.row,model.yourName];
    if (indexPath.row == self.currentId) {
        cell.detailTextLabel.hidden = NO;
    }else{
        cell.detailTextLabel.hidden = YES;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    DFPlayerModel *model = [[DFPlayerModel alloc] init];
    model = [self df_playerModelArray][indexPath.row];
    [[DFPlayerManager shareInstance] df_playerPlayWithAudioId:model.audioId];
    
}

#pragma mark - DFPlayer 初始化
- (void)initDFPlayer{
    //播放器
//    [DFPlayerManager shareInstance].delegate    = self;
//    [DFPlayerManager shareInstance].dataSource  = self;
//    [DFPlayerManager shareInstance].category    = DFPlayerAudioSessionCategoryPlayback;
//    [DFPlayerManager shareInstance].type        = DFPlayerTypeOnlyOnce;
//    [[DFPlayerManager shareInstance] df_reloadData];
}
//#pragma mark - DFPlayer 数据源
//- (NSArray<DFPlayerModel *> *)df_playerModelArray{
//    NSMutableArray *modelArray  = [NSMutableArray array];
//
//    //将音频地址、音频名、歌手、专辑名、音频配图等信息赋值给DFPlayerModel
//    for (int i = 0; i < self.dataArray.count; i++) {
//        YourDataModel *yourModel    = [[YourDataModel alloc] init];
//        DFPlayerModel *model        = [[DFPlayerModel alloc] init];
//        yourModel           = self.dataArray[i];
//        NSString *path      = [[NSBundle mainBundle] pathForResource:yourModel.yourUrl ofType:@""];
//        model.audioUrl      = [NSURL fileURLWithPath:path]; //必传
//        model.audioId       = i;                            //必传
//        model.audioName     = yourModel.yourName;
//        model.audioSinger   = yourModel.yourSinger;
//        model.audioAlbum    = yourModel.yourAlbum;
//        model.audioImage    = [UIImage imageNamed:yourModel.yourImage];
//        [modelArray addObject:model];
//    }
//    return modelArray;
//}
//#pragma mark - DFPlayer 代理
//- (void)df_playerDidReadyToPlay:(DFPlayerManager *)playerManager{
//    self.currentId = playerManager.currentAudioModel.audioId;
//    [self.tableView reloadData];
//}
//- (void)df_player:(DFPlayerManager *)playerManager
//         progress:(CGFloat)progress
//      currentTime:(CGFloat)currentTime
//        totalTime:(CGFloat)totalTime{
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentId inSection:0];
//    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"当前进度%lf--当前时间%.0f--总时长%.0f",progress,ceilf(currentTime),ceilf(totalTime)];
//}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
