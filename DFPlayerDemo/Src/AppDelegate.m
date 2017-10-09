//
//  AppDelegate.m
//  DFPlayer
//
//  Created by HDF on 2017/7/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "AppDelegate.h"
#import "DFNetAudioViewController.h"
#import "DFLocalAudioViewController.h"
#import "DFCacheViewController.h"
#import "DFPlayer.h"
#import "DFMacro.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[DFPlayerManager shareInstance] initPlayerWithUserId:nil];

    
    DFNetAudioViewController *remoteVC = [[DFNetAudioViewController alloc] init];
    UINavigationController *remoteNav = [[UINavigationController alloc] initWithRootViewController:remoteVC];
    remoteVC.title = @"网络音频";
    
    DFLocalAudioViewController *localVC = [[DFLocalAudioViewController alloc] init];
    UINavigationController *localNav = [[UINavigationController alloc] initWithRootViewController:localVC];
    localVC.title = @"本地音频";
    
    DFCacheViewController *mineVC = [[DFCacheViewController alloc] init];
    UINavigationController *mineNav = [[UINavigationController alloc] initWithRootViewController:mineVC];
    mineVC.title = @"缓存相关";
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName:HDFGreenColor} forState:UIControlStateNormal];
    UITabBarController *tabbarVC = [[UITabBarController alloc] init];

    tabbarVC.viewControllers = @[remoteNav,localNav,mineNav];
    
    self.window.rootViewController = tabbarVC;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}


@end
