//
//  DFCacheViewController.m
//  DFPlayerDemo
//
//  Created by HDF on 2017/10/7.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFCacheViewController.h"
#import "DFPlayer.h"
#import "NSObject+Alert.h"
#import "DFMacro.h"
@interface DFCacheViewController ()

@end
@implementation DFCacheViewController
{
    UILabel *currentLabel;
    UILabel *allLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    currentLabel = [[UILabel alloc] init];
    currentLabel.frame = CGRectMake(25, 200, 160, 40);
    currentLabel.backgroundColor = HDFGreenColor;
    currentLabel.textColor = [UIColor whiteColor];
    currentLabel.textAlignment = NSTextAlignmentCenter;
    currentLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:currentLabel];
    
    UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
    button.frame = CGRectMake(200, 200, 150, 40);
    button.backgroundColor = HDFGreenColor;
    button.tag = 100;
    [button setTitle:@"清除当前用户缓存" forState:(UIControlStateNormal)];
    [button setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    [button addTarget:self action:@selector(clearCache:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button];
    
    allLabel = [[UILabel alloc] init];
    allLabel.frame = CGRectMake(25, 320, 160, 40);
    allLabel.backgroundColor = HDFGreenColor;
    allLabel.textColor = [UIColor whiteColor];
    allLabel.textAlignment = NSTextAlignmentCenter;
    allLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:allLabel];
    
    UIButton *button1 = [UIButton buttonWithType:(UIButtonTypeSystem)];
    button1.frame = CGRectMake(200, 320, 150, 40);
    button1.backgroundColor = HDFGreenColor;
    button1.tag = 200;
    [button1 setTitle:@"清除所有用户缓存" forState:(UIControlStateNormal)];
    [button1 setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    [button1 addTarget:self action:@selector(clearCache:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button1];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];    
    allLabel.text = [NSString stringWithFormat:@"所有用户缓存:%.2lfM",[DFPlayer df_playerCountCacheSizeForCurrentUser:NO]];
    currentLabel.text = [NSString stringWithFormat:@"当前用户缓存:%.2lfM",[DFPlayer df_playerCountCacheSizeForCurrentUser:YES]];
}

- (void)clearCache:(UIButton *)sender{
    NSInteger tag = sender.tag;
    BOOL isCurrentUser = YES;
    if (tag == 200) {
        isCurrentUser = NO;
    }
    
    [DFPlayer df_playerClearCacheForCurrentUser:isCurrentUser block:^(BOOL isSuccess, NSError *error) {
        [self shAlertViewWithTitle:@"清除成功"];
        currentLabel.text = [NSString stringWithFormat:@"当前cache:%.2lfM",[DFPlayer df_playerCountCacheSizeForCurrentUser:YES]];
        allLabel.text = [NSString stringWithFormat:@"所有cache:%.2lfM",[DFPlayer df_playerCountCacheSizeForCurrentUser:NO]];
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
