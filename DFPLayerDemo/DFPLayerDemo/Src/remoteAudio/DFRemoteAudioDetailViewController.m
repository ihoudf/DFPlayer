//
//  DFRemoteAudioDetailViewController.m
//  DFPlayer
//
//  Created by Faroe on 2017/9/19.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFRemoteAudioDetailViewController.h"
#import "DFPlayer.h"
#import "DFMacro.h"
@interface DFRemoteAudioDetailViewController ()

@end

@implementation DFRemoteAudioDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    

  


}

- (void)initDFPlayerControllUI{
    DFPlayerControlManager *manager = [DFPlayerControlManager shareInstance];
    
//    CGRect typeRect = CGRectMake(CountWidth(40), CountHeight(120), CountWidth(63), CountHeight(45));
//    [manager df_typeControlBtnWithFrame:typeRect superView:self.controlView block:nil];
//    //airplay按钮
//    CGRect airRect  = CGRectMake(CountWidth(650), CountHeight(120), CountWidth(63), CountHeight(50));
//    [manager df_airPlayViewWithFrame:airRect backgroundColor:[UIColor clearColor] superView:self.controlView];
//    //播放暂停按钮
//    CGRect playRect = CGRectMake(CountWidth(320), CountHeight(90), CountWidth(110), CountWidth(110));
//    [manager df_playPauseBtnWithFrame:playRect superView:self.controlView block:nil];
//    //下一首按钮
//    CGRect nextRext = CGRectMake(CountWidth(490), CountHeight(104), CountWidth(80), CountWidth(80));
//    [manager df_nextAudioBtnWithFrame:nextRext superView:self.controlView block:nil];
//    //上一首按钮
//    CGRect lastRect = CGRectMake(CountWidth(180), CountHeight(104), CountWidth(80), CountWidth(80));
//    [manager df_lastAudioBtnWithFrame:lastRect superView:self.controlView block:nil];
//    //缓冲条
//    CGRect buffRect = CGRectMake(CountWidth(104), CountHeight(38), CountWidth(542), CountHeight(4));
//    [manager df_bufferProgressViewWithFrame:buffRect trackTintColor:[UIColor clearColor] progressTintColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5] superView:self.controlView];
//    //进度条
//    CGRect proRect  = CGRectMake(CountWidth(104), CountHeight(20), CountWidth(542), CountHeight(40));
//    [manager df_sliderWithFrame:proRect minimumTrackTintColor:HDFGreenColor maximumTrackTintColor:[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.0] trackHeight:CountHeight(4) thumbSize:(CGSizeMake(CountWidth(34), CountWidth(34))) superView:self.controlView];
//    //当前时间
//    CGRect currRect = CGRectMake(CountWidth(15), CountHeight(20), CountWidth(80), CountHeight(40));
//    UILabel *currentTimeLabel = [manager df_currentTimeLabelWithFrame:currRect superView:self.controlView];
//    currentTimeLabel.textColor = HDFGreenColor;
//    //总时间
//    CGRect totalRect = CGRectMake(SCREEN_WIDTH-CountWidth(95), CountHeight(20), CountWidth(80), CountHeight(40));
//    UILabel *totalTimeLabel = [manager df_totalTimeLabelWithFrame:totalRect superView:self.controlView];
//    totalTimeLabel.textColor = HDFGreenColor;
    UITableView *tableview = [manager df_lyricTableViewWithFrame:(CGRectMake( 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT))
                                                    lrcRowHeight:CountHeight(100)
                                                   lrcLabelFrame:(CGRectMake(0, 0, SCREEN_WIDTH, CountHeight(100)))
                                             cellBackgroundColor:nil
                               currentLineLrcForegroundTextColor:[UIColor blueColor]
                               currentLineLrcBackgroundTextColor:[UIColor greenColor]
                                 otherLineLrcBackgroundTextColor:[UIColor redColor]
                                              currentLineLrcFont:HDFSystemFontOfSize(20)
                                                otherLineLrcFont:HDFSystemFontOfSize(20)
                                                       superView:self.view];
    tableview.backgroundColor = [UIColor redColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
