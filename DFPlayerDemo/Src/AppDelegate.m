//
//  AppDelegate.m
//  DFPlayer
//
//  Created by ihoudf on 2017/7/18.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import "AppDelegate.h"
#import "NSObject+Extentions.h"
#import "DFPlayerViewController.h"
#import "DFCacheViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    UINavigationController *nav1 = [self nav:[DFPlayerViewController class] title:@"音频"];
    UINavigationController *nav3 = [self nav:[DFCacheViewController class] title:@"缓存"];
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName:DFGreenColor}
                                             forState:UIControlStateNormal];
    UITabBarController *tabbarVC = [[UITabBarController alloc] init];
    tabbarVC.viewControllers = @[nav1,nav3];
    
    self.window.rootViewController = tabbarVC;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}

- (UINavigationController *)nav:(Class)viewController title:(NSString *)title{
    UIViewController *vc = (UIViewController *)[[viewController alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];
    vc.title = title;
    return [[UINavigationController alloc] initWithRootViewController:vc];
}

@end
