//
//  main.m
//  DFPlayerDemo
//
//  Created by HDF on 2017/9/20.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "DFPlayer.h"
int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, [[DFPlayer shareInstance] remoteControlClass], NSStringFromClass([AppDelegate class]));
    }
}
