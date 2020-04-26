//
//  DFCacheViewController.m
//  DFPlayerDemo
//
//  Created by ihoudf on 2017/10/7.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import "DFCacheViewController.h"
#import "NSObject+Extentions.h"
#import "DFPlayer.h"

@interface DFCacheViewController ()
{
    UILabel *_currL;
    UILabel *_allL;
}
@end

@implementation DFCacheViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _currL = [self ui:200 tag:100 title:@"清除当前用户缓存"];
    _allL = [self ui:320 tag:200 title:@"清除所有用户缓存"];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self refreshData];
}

- (void)clearCache:(UIButton *)sender{
    BOOL currentUser = sender.tag == 200 ? NO : YES;
    if ([[DFPlayer sharedPlayer] df_clearUserCache:currentUser]) {
        [self showAlert:@"清除成功"];
        [self refreshData];
    }else{
        [self showAlert:@"清除失败"];
    }
}

- (void)refreshData{
    _currL.text = [NSString stringWithFormat:@"当前用户缓存:%.2lfM",[[DFPlayer sharedPlayer] df_cacheSize:YES]];
    _allL.text = [NSString stringWithFormat:@"所有用户缓存:%.2lfM",[[DFPlayer sharedPlayer] df_cacheSize:NO]];
}

- (UILabel *)ui:(CGFloat)Y tag:(NSInteger)tag title:(NSString *)title{
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(25, Y, 160, 40);
    label.backgroundColor = DFGreenColor;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:label];
    
    UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
    button.frame = CGRectMake(200, Y, 150, 40);
    button.backgroundColor = DFGreenColor;
    button.tag = tag;
    [button setTitle:title forState:(UIControlStateNormal)];
    [button addTarget:self action:@selector(clearCache:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button];
    return label;
}

@end
