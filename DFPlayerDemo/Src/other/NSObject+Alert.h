//
//  NSObject+Alert.h
//  ShouerHealth
//
//  Created by HDF on 2017/7/13.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^YesBlock)(void);
typedef void(^NoBlock)(void);

typedef void(^ActionSheetBlock1)(void);
typedef void(^ActionSheetBlock2)(void);

@interface NSObject (Alert)

/**
 alert 普通

 @param title 标题
 */
- (void)shAlertViewWithTitle:(NSString *)title;


/**
 alert certainPattern

 @param title 标题
 @param message 信息
 @param actionTitle 确定按钮标题
 @param yesBlock action
 */
- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               actionTitle:(NSString *)actionTitle
                  yesBlock:(YesBlock)yesBlock;


/**
 alert single action

 @param title 标题
 @param message 信息
 @param yesBlock action
 */
- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                  yesBlock:(YesBlock)yesBlock;


/**
 alert double action

 @param title 标题
 @param message 信息
 @param noBlock no Action
 @param yesBlock yes Action
 */
- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                   noBlock:(NoBlock)noBlock
                  yseBlock:(YesBlock)yesBlock;


/**
 ActionSheet

 @param title1 标题1
 @param block1 action1
 @param title2 标题2
 @param block2 action2
 */
- (void)showActionSheetWithTitle1:(NSString *)title1
                           block1:(ActionSheetBlock1)block1
                          title2:(NSString *)title2
                          block2:(ActionSheetBlock2)block2;

- (void)showAlertOfAlbum;
@end
