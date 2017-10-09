//
//  DFPlayerRequestManager.h
//  DFPlayer
//
//  Created by HDF on 2017/7/31.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol DFPlayerRequestDelegate <NSObject>
/**
 得到服务器响应
 
 @param statusCode 状态码
 */
- (void)requestManagerDidReceiveResponseWithStatusCode:(NSInteger)statusCode;

/**
 从服务器接收到数据
 */
- (void)requestManagerDidReceiveData;

/**
 接收数据完成

 @param errorDescription 如果出错则errorDescription不为nil
 @param isCached 是否完成了缓存
 */
- (void)requestManagerDidCompleteWithError:(NSString *)errorDescription isCached:(BOOL)isCached;

@end

/**
 DFPlayer请求管理器
 */
@interface DFPlayerRequestManager : NSObject
+ (instancetype)requestWithUrl:(NSURL *)url;
- (instancetype)initWithUrl:(NSURL *)url;
@property (nonatomic, weak) id<DFPlayerRequestDelegate> delegate;
@property (nonatomic, assign) NSInteger requestOffset;//请求起始位置
@property (nonatomic, assign) NSInteger fileLength;//文件长度
@property (nonatomic, assign) NSInteger cacheLength;//缓冲长度
@property (nonatomic, assign) BOOL cancel;//是否取消请求
@property (nonatomic, assign) BOOL isHaveCache;//是否有缓存
@property (nonatomic, assign) BOOL isObserveLastModified;//是否观察修改时间
- (void)requestStart;
@end
