//
//  NSObject+Alert.m
//  ShouerHealth
//
//  Created by HDF on 2017/7/13.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "NSObject+Alert.h"
#import <UIKit/UIKit.h>
@implementation NSObject (Alert)


- (void)shAlertViewWithTitle:(NSString *)title
{
    // 保证在主线程上执行
    if ([NSThread isMainThread]) {
        [[[UIAlertView alloc]initWithTitle:title
                                   message:nil
                                  delegate:nil
                         cancelButtonTitle:@"确定"
                         otherButtonTitles:nil, nil] show];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc]initWithTitle:title
                                       message:nil
                                      delegate:nil
                             cancelButtonTitle:@"确定"
                             otherButtonTitles:nil, nil] show];
        });
    }
    
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               actionTitle:(NSString *)actionTitle
                  yesBlock:(YesBlock)yesBlock{
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:(UIAlertControllerStyleAlert)];
    if (actionTitle == nil) {
        actionTitle = @"确定";
    }
    UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitle
                                                     style:(UIAlertActionStyleDefault)
                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                       if (yesBlock) {
                                                           yesBlock();
                                                       }
                                                   }];
    
    [alertcontroller addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                  yesBlock:(YesBlock)yesBlock{
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定"
                                                     style:(UIAlertActionStyleDefault)
                                                   handler:^(UIAlertAction * _Nonnull action) {
        if (yesBlock) {
            yesBlock();
        }
    }];
    
    [alertcontroller addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertcontroller animated:YES completion:nil];
}


- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                   noBlock:(NoBlock)noBlock
                  yseBlock:(YesBlock)yesBlock{
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定"
                                                     style:(UIAlertActionStyleDefault)
                                                   handler:^(UIAlertAction * _Nonnull action) {
        if (yesBlock) {
            yesBlock();
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:(UIAlertActionStyleCancel)
                                                         handler:^(UIAlertAction * _Nonnull action) {
        if (noBlock) {
            noBlock();
        }
    }];
    [alertcontroller addAction:action];
    [alertcontroller addAction:cancelAction];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertcontroller animated:YES completion:nil];
}

- (void)showActionSheetWithTitle1:(NSString *)title1
                           block1:(ActionSheetBlock1)block1
                           title2:(NSString *)title2
                           block2:(ActionSheetBlock2)block2{
    UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:title1 style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        if (block1) {
            block1();
        }
    }];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:title2 style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        if (block2) {
            block2();
        }
    }];
    [alertcontroller addAction:action];
    [alertcontroller addAction:action1];
    [alertcontroller addAction:action2];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertcontroller animated:YES completion:nil];
}



- (void)showAlertOfAlbum{
    [self showAlertWithTitle:@"本应用无访问相机的权限,是否前去设置？" message:nil noBlock:^{
        
    } yseBlock:^{
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }];
}

@end
