//
//  DFPlayerFileManager.m
//  DFPlayer
//
//  Created by ihoudf on 2017/7/30.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import "DFPlayerFileManager.h"
#import "DFPlayerTool.h"

static NSString *DFPlayer_UserId = @"DFPlayerUserId";

static NSString * DFCachePath(BOOL currentUser){
    // 所有缓存文件都放在了沙盒Cache文件夹下DFPlayerCache文件夹里,然后再根据userId分文件夹缓存
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"DFPlayerCache"];
    if (currentUser) {
        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:DFPlayer_UserId];
        NSString *name = [NSString stringWithFormat:@"user_%@",userId];
        path = [path stringByAppendingPathComponent:name];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    }
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return success ? path : nil;
}

static NSString * DFTempPath(){
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"MusicTemp.mp4"];
}

static NSString * DFArchiverPath(){
    return [DFCachePath(YES) stringByAppendingPathComponent:@"DFPlayer.archiver"];
}


@implementation DFPlayerFileManager

+ (void)df_saveUserId:(NSString *)userId{
    NSString *ids = @"public";
    if (![userId df_isEmpty]) {
        ids = userId;
    }
    [[NSUserDefaults standardUserDefaults] setObject:ids forKey:DFPlayer_UserId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)df_createTempFile{
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSString *path = DFTempPath();
    if ([mgr fileExistsAtPath:path]) {
        [mgr removeItemAtPath:path error:nil];
    }
    return [mgr createFileAtPath:path contents:nil attributes:nil];
}

+ (void)df_writeDataToAudioFileTempPathWithData:(NSData *)data{
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:DFTempPath()];
    [handle seekToEndOfFile];
    [handle writeData:data];
}

+ (NSData *)df_readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:DFTempPath()];
    [handle seekToFileOffset:offset];
    return [handle readDataOfLength:length];
}

+ (BOOL)df_moveAudioFileFromTempPathToCachePath:(NSURL *)audioUrl{
    NSString *path = [DFPlayerFileManager audioCachedPath:audioUrl];
    NSFileManager *mgr = [NSFileManager defaultManager];
    if (![mgr fileExistsAtPath:path]) {
        NSNumber *numberId = [NSNumber numberWithInt:[DFPlayer_UserId intValue]];
        [mgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{NSFileOwnerAccountID:numberId} error:nil];
    }
    NSString *audioName = [audioUrl.path lastPathComponent];
    NSString *cachePath = [path stringByAppendingPathComponent:audioName];
    NSError *error;
    BOOL success = [mgr moveItemAtPath:DFTempPath() toPath:cachePath error:&error];
    if (!success) {//安全性处理 如果没有保存成功，删除归档文件中的对应键值对
        [DFPlayerArchiverManager deleteKeyValueIfHaveArchivedWithUrl:audioUrl];
    }
    return success;
}

+ (NSString *)df_cachePath:(NSURL *)audioUrl{
    NSString *path = [DFPlayerFileManager audioCachedPath:audioUrl];
    NSString *audioName = [audioUrl.path lastPathComponent];
    NSString *cachePath = [path stringByAppendingPathComponent:audioName];
    return [[NSFileManager defaultManager] fileExistsAtPath:cachePath] ? cachePath : nil;
}

+ (NSString *)audioCachedPath:(NSURL *)audioUrl{
    NSString *backStr = [[audioUrl.absoluteString componentsSeparatedByString:@"//"].lastObject stringByDeletingLastPathComponent];
    return [DFCachePath(YES) stringByAppendingPathComponent:backStr];
}

+ (CGFloat)df_cacheSize:(BOOL)currentUser{
    NSString *path = DFCachePath(currentUser);
    NSArray *fileArray = [[NSFileManager defaultManager] subpathsAtPath:path];
    CGFloat size = 0;
    for (NSString *file in fileArray) {
        NSString *filePath = [path stringByAppendingPathComponent:file];
        size += [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil].fileSize;
    }
    return size / 1000.0 / 1000.0;
}

+ (BOOL)df_clearAudioCache:(NSURL *)audioUrl{
    NSString *path = [self df_cachePath:audioUrl];
    return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

+ (BOOL)df_clearUserCache:(BOOL)currentUser{
    return [[NSFileManager defaultManager] removeItemAtPath:DFCachePath(currentUser) error:nil];
}

@end

@implementation DFPlayerArchiverManager

+ (NSMutableDictionary *)df_hasArchivedFileDictionary{
    _archiverDic = [NSKeyedUnarchiver unarchiveObjectWithFile:DFArchiverPath()];
    if (!_archiverDic){
        _archiverDic = [NSMutableDictionary dictionary];
    }
    return _archiverDic;
}

+ (BOOL)df_archiveValue:(id)value forKey:(NSString *)key{
    NSMutableDictionary *dic = [DFPlayerArchiverManager df_hasArchivedFileDictionary];
    [dic setValue:value forKey:key];
    return [NSKeyedArchiver archiveRootObject:dic toFile:DFArchiverPath()];
}

+ (void)deleteKeyValueIfHaveArchivedWithUrl:(NSURL *)url{
    NSMutableDictionary *dic = [DFPlayerArchiverManager df_hasArchivedFileDictionary];
    __block BOOL isHave = NO;
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:url.absoluteString]) {
            [dic removeObjectForKey:key];
            isHave = YES;
            *stop = YES;
        }
    }];
    if (isHave) {
        [NSKeyedArchiver archiveRootObject:dic toFile:DFArchiverPath()];
    }
}

@end


