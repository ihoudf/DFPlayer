//
//  AppDelegate.m
//  DFPlayer
//
//  Created by HDF on 2017/7/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "AppDelegate.h"
#import "DFNetAudioViewController.h"
#import "DFCacheViewController.h"
#import "DFPlayer.h"
#import "DFMacro.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    DFNetAudioViewController *remoteVC = [[DFNetAudioViewController alloc] init];
    UINavigationController *remoteNav = [[UINavigationController alloc] initWithRootViewController:remoteVC];
    remoteVC.title = @"音频";
    
    DFCacheViewController *mineVC = [[DFCacheViewController alloc] init];
    UINavigationController *mineNav = [[UINavigationController alloc] initWithRootViewController:mineVC];
    mineVC.title = @"缓存";
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName:HDFGreenColor} forState:UIControlStateNormal];
    UITabBarController *tabbarVC = [[UITabBarController alloc] init];

    tabbarVC.viewControllers = @[remoteNav,mineNav];
    
    self.window.rootViewController = tabbarVC;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}


@end
