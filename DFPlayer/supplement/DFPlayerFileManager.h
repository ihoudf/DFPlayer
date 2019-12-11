//
//  DFPlayerFileManager.h
//  DFPlayer
//
//  Created by ihoudf on 2017/7/30.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 DFPlayer缓存文件管理器
 */
@interface DFPlayerFileManager : NSObject

+ (void)df_saveUserId:(NSString *)userId;

// 创建临时文件
+ (BOOL)df_createTempFile;

// 往临时文件写入数据
+ (void)df_writeDataToAudioFileTempPathWithData:(NSData *)data;

// 读取临时文件数据
+ (NSData *)df_readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length;

// 保存临时文件到缓存文件夹
+ (BOOL)df_moveAudioFileFromTempPathToCachePath:(NSURL *)audioUrl;

// 音频缓存路径
+ (NSString *)df_cachePath:(NSURL *)audioUrl;

// 缓存大小
+ (CGFloat)df_cacheSize:(BOOL)currentUser;

// 清除音频缓存
+ (BOOL)df_clearAudioCache:(NSURL *)audioUrl;

// 清除用户缓存
+ (BOOL)df_clearUserCache:(BOOL)currentUser;

@end

static NSMutableDictionary *_archiverDic;
/**
 DFPlayer归档管理器
 */
@interface DFPlayerArchiverManager : NSObject

// 已经归档的数据
+ (NSMutableDictionary *)df_hasArchivedFileDictionary;

// 归档
+ (BOOL)df_archiveValue:(id)value forKey:(NSString *)key;

// 如果已经归档则删除该路径归档
+ (void)deleteKeyValueIfHaveArchivedWithUrl:(NSURL *)url;

@end




