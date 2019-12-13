//
//  NSObject+Extentions.h
//  DFPlayerDemo
//
//  Created by ihoudf on 2019/1/30.
//  Copyright © 2019年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YourModel.h"


NS_ASSUME_NONNULL_BEGIN
//屏幕相关
#define  SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width
#define  SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height
//有关距离、位置
#define DFWidth(w)  ((w)/750.0)*SCREEN_WIDTH
#define DFHeight(hh) ([UIScreen mainScreen].bounds.size.height==812.0?((hh)/1334.0)*667.0:((hh)/1334.0)*SCREEN_HEIGHT)
//颜色
#define DFRGBAColor(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#define DFGreenColor  [UIColor colorWithRed:66.0/255.0 green:196.0/255.0 blue:133.0/255.0 alpha:1]
//系统字体
#define DFSystemFont(size)  [UIFont systemFontOfSize:size]

@interface NSObject (Extentions)

- (NSURL *)getAvailableURL:(NSString *)URLString;

- (NSMutableArray<YourModel *> *)getYourModelArray;

- (NSArray<YourModel *> *)getYourModelAddArray;

@end


@interface UIImage (Blur)

-(nullable UIImage *)getSubImage:(CGRect)rect;

@end

@interface UIViewController (Extensions)

- (void)showAlert:(NSString *)title;
- (void)showAlert:(NSString *)title okBlock:(void(^)(void))okBlock;
- (void)showRateAlertSheetBlock:(void(^)(NSString *rate))block;

@end
NS_ASSUME_NONNULL_END
