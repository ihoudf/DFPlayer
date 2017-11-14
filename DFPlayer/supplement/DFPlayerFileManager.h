//
//  DFPlayerFileManager.h
//  DFPlayer
//
//  Created by HDF on 2017/7/30.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 DFPlayer缓存文件管理器
 */
@interface DFPlayerFileManager : NSObject

/**cache文件夹创建用户缓存目录*/
+ (void)df_playerCreateCachePathWithId:(NSString *)Id;

/**当前用户Id缓存文件夹地址*/
+ (NSString *)df_playerUserCachePath;

/**创建临时文件*/
+ (BOOL)df_createTempFile;

/**往临时文件写入数据*/
+ (void)df_writeDataToAudioFileTempPathWithData:(NSData *)data;

/**读取临时文件数据*/
+ (NSData *)df_readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length;

/**保存临时文件到缓存文件夹*/
+ (void)df_moveAudioFileFromTempPathToCachePath:(NSURL *)url blcok:(void(^)(BOOL isSuccess,NSError *error))block;

/**是否存在缓存文件 存在：返回文件路径 不存在：返回nil*/
+ (NSString *)df_isExistAudioFileWithURL:(NSURL *)url;

/**清除url对应的本地缓存*/
+ (void)df_playerClearCacheWithUrl:(NSURL *)url block:(void(^)(BOOL isSuccess, NSError *error))block;

/**计算缓存大小*/
+ (CGFloat)df_countCacheSizeForCurrentUser:(BOOL)isCurrentUser;

/**清除缓存*/
+ (void)df_clearCacheForCurrentUser:(BOOL)isClearCurrentUser block:(void(^)(BOOL isSuccess, NSError *error))block;

/**计算系统磁盘空间 剩余可用空间*/
+ (void)df_countSystemSizeBlock:(void(^)(CGFloat totalSize,CGFloat freeSize))block;


@end

static NSMutableDictionary *_archiverDic;
UIKIT_EXTERN NSString * const DFPlayerCurrentAudioInfoModelAudioUrl;
UIKIT_EXTERN NSString * const DFPlayerCurrentAudioInfoModelCurrentTime;
UIKIT_EXTERN NSString * const DFPlayerCurrentAudioInfoModelTotalTime;
UIKIT_EXTERN NSString * const DFPlayerCurrentAudioInfoModelProgress;
/**
 DFPlayer归档管理器
 */
@interface DFPlayerArchiverManager : NSObject

/**已经归档的数据*/
+ (NSMutableDictionary *)df_hasArchivedFileDictionary;

/**归档*/
+ (BOOL)df_archiveValue:(id)value forKey:(NSString *)key;

/**如果已经归档则删除该路径归档*/
+ (void)deleteKeyValueIfHaveArchivedWithUrl:(NSURL *)url;


#pragma mark - infoModel归档
/**解档infoModel*/
+ (NSDictionary *)df_unarchiveInfoModelDictionary;

/**归档infoModel*/
+ (BOOL)df_archiveInfoModelWithAudioUrl:(NSURL *)audioUrl
                            currentTime:(CGFloat)currentTime
                              totalTime:(CGFloat)totalTime
                               progress:(CGFloat)progress;

@end




