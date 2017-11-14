//
//  DFPlayerResourceLoader.h
//  DFPlayer
//
//  Created by HDF on 2017/7/30.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DFPlayerRequestManager.h"
#define MimeType @"video/mp4"

@class DFPlayerResourceLoader;
@protocol DFPlayerResourceLoaderDelegate <NSObject>

- (void)loader:(DFPlayerResourceLoader *)loader isCached:(BOOL)isCached;

- (void)loader:(DFPlayerResourceLoader *)loader requestError:(NSInteger)errorCode;
@end
/**
 DFPlayer资源加载器
 */
@interface DFPlayerResourceLoader : NSObject<AVAssetResourceLoaderDelegate,DFPlayerRequestDelegate>

@property (nonatomic, weak) id<DFPlayerResourceLoaderDelegate> delegate;
@property (nonatomic, copy) void(^checkStatusBlock)(NSInteger statusCode);
@property (nonatomic, assign) BOOL isHaveCache;//是否有缓存
@property (nonatomic, assign) BOOL isObserveFileModifiedTime;//是否观察修改时间
/**退出播放器和切换歌曲时调用该方法*/
- (void)stopLoading;

@end


