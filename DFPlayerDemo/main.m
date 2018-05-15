//
//  main.m
//  DFPlayerDemo
//
//  Created by ihoudf on 2017/9/20.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "DFPlayer.h"
int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, [[DFPlayer shareInstance] df_remoteControlClass], NSStringFromClass([AppDelegate class]));
    }
}
