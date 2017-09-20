//
//  DFMineViewController.m
//  DFPlayer
//
//  Created by Faroe on 2017/8/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFMineViewController.h"
#import "DFPlayerManager.h"
#import "NSObject+Alert.h"
@interface DFMineViewController ()

@end

@implementation DFMineViewController
{
    UILabel *currentLabel;
    UILabel *allLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    currentLabel = [[UILabel alloc] init];
    currentLabel.frame = CGRectMake(30, 100, 150, 40);
    currentLabel.backgroundColor = [UIColor yellowColor];
    currentLabel.textAlignment = NSTextAlignmentCenter;
    currentLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:currentLabel];
    
    UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
    button.frame = CGRectMake(200, 100, 150, 40);
    button.backgroundColor = [UIColor yellowColor];
    button.tag = 100;
    [button setTitle:@"清除当前用户缓存" forState:(UIControlStateNormal)];
    [button addTarget:self action:@selector(clearCache:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button];
    
    allLabel = [[UILabel alloc] init];
    allLabel.frame = CGRectMake(30, 220, 150, 40);
    allLabel.backgroundColor = [UIColor yellowColor];
    allLabel.textAlignment = NSTextAlignmentCenter;
    allLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:allLabel];
    
    UIButton *button1 = [UIButton buttonWithType:(UIButtonTypeSystem)];
    button1.frame = CGRectMake(200, 220, 150, 40);
    button1.backgroundColor = [UIColor yellowColor];
    button1.tag = 200;
    [button1 setTitle:@"清除所有缓存" forState:(UIControlStateNormal)];
    [button1 addTarget:self action:@selector(clearCache:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button1];
    
    
    
    
    
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    allLabel.text = [NSString stringWithFormat:@"所有cache:%.2lfM",[DFPlayerManager df_playerCountCacheSizeForCurrentUser:NO]];
    currentLabel.text = [NSString stringWithFormat:@"当前cache:%.2lfM",[DFPlayerManager df_playerCountCacheSizeForCurrentUser:YES]];
    
}

- (void)clearCache:(UIButton *)sender{
    NSInteger tag = sender.tag;
    BOOL isCurrentUser = YES;
    if (tag == 200) {
        isCurrentUser = NO;
    }
    
    [DFPlayerManager df_playerClearCacheForCurrentUser:isCurrentUser block:^(BOOL isSuccess, NSError *error) {
        [self shAlertViewWithTitle:@"清除成功"];
        currentLabel.text = [NSString stringWithFormat:@"当前cache:%.2lfM",[DFPlayerManager df_playerCountCacheSizeForCurrentUser:YES]];
        allLabel.text = [NSString stringWithFormat:@"所有cache:%.2lfM",[DFPlayerManager df_playerCountCacheSizeForCurrentUser:NO]];
    }];
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
