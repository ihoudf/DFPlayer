//
//  AppDelegate.m
//  DFPlayer
//
//  Created by HDF on 2017/7/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "AppDelegate.h"
#import "DFRemoteAudioViewController.h"
#import "DFLocalAudioViewController.h"
#import "DFMineViewController.h"
#import "DFPlayerManager.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[DFPlayerManager shareInstance] initPlayerWithUserId:nil];

    
    DFRemoteAudioViewController *remoteVC = [[DFRemoteAudioViewController alloc] init];
    UINavigationController *remoteNav = [[UINavigationController alloc] initWithRootViewController:remoteVC];
    remoteVC.title = @"网络音频";
    
    DFLocalAudioViewController *localVC = [[DFLocalAudioViewController alloc] init];
    UINavigationController *localNav = [[UINavigationController alloc] initWithRootViewController:localVC];
    localVC.title = @"本地音频";
    
    DFMineViewController *mineVC = [[DFMineViewController alloc] init];
    UINavigationController *mineNav = [[UINavigationController alloc] initWithRootViewController:mineVC];
    mineVC.title = @"设置";
    
    UITabBarController *tabbarVC = [[UITabBarController alloc] init];
    tabbarVC.viewControllers = @[remoteNav,localNav,mineNav];
    
    self.window.rootViewController = tabbarVC;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}


@end
