//
//  DFMacro.h
//  DFPlayer
//
//  Created by HDF on 2017/8/13.
//  Copyright © 2017年 HDF. All rights reserved.
//

//屏幕相关
#define  SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width
#define  SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height
//有关距离、位置
#define CountWidth(w)  ((w)/750.0)*SCREEN_WIDTH
#define CountHeight(hh) ([UIScreen mainScreen].bounds.size.height==812.0?((hh)/1334.0)*667.0:((hh)/1334.0)*SCREEN_HEIGHT)


//圆角
#define SHCornerRadius(radius) (radius/750.0)*SCREEN_WIDTH
//颜色
#define LCRGBColor(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define LCRGBAColor(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
// 随机色
#define HDFRandomColor [UIColor colorWithRed:(arc4random_uniform(256))/255.0 green:(arc4random_uniform(256))/255.0 blue:(arc4random_uniform(256))/255.0 alpha:1.0]
//常用颜色
#define HDFBackgroundColor  [UIColor colorWithRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1]
#define HDFGreenColor  [UIColor colorWithRed:66.0/255.0 green:196.0/255.0 blue:133.0/255.0 alpha:1]

//字号
#define HDFFontSize(size) ((size)/1334.0)*SCREEN_HEIGHT
//系统字体
#define HDFSystemFontOfSize(size)  [UIFont systemFontOfSize:HDFFontSize(size)]
