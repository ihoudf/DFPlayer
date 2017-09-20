//
//  DFPLayerMacro.h
//  DFPlayer
//
//  Created by HDF on 2017/8/6.
//  Copyright © 2017年 HDF. All rights reserved.
//

#define kWeakSelf    __weak __typeof(&*self)weakSelf = self;

// 图片路径
#define DFPlayerSrcName(file) [@"DFPlayer.bundle" stringByAppendingPathComponent:file]
#define DFPlayerFrameworkSrcName(file) [@"Frameworks/DFPlayer.framework/DFPlayer.bundle" stringByAppendingPathComponent:file]
#define DFPlayerImage(file) [UIImage imageNamed:DFPlayerSrcName(file)] ? :[UIImage imageNamed:DFPlayerFrameworkSrcName(file)]

//自定义打印
#define DFLog( format, ... ) {\
if ([DFPlayerTool logEnable]) {\
NSLog( @"%@", [NSString stringWithFormat:(format), ##__VA_ARGS__] );}\
}\
//不同模式下需要切换的参数
#ifdef DEBUG_MODE
#define DFLog( format, ... )
#else
#endif



