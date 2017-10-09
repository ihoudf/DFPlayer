//
//  DFPlayerRequestManager.m
//  DFPlayer
//
//  Created by HDF on 2017/7/31.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayerRequestManager.h"
#import "DFPlayerTool.h"
#import "DFPlayerFileManager.h"

@interface DFPlayerRequestModel : NSObject<NSCoding>
@property (nonatomic, copy) NSString *last_modified;
@property (nonatomic, copy) NSString *ETag;
@end
@implementation DFPlayerRequestModel
- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.last_modified forKey:@"last_modified"];
    [aCoder encodeObject:self.ETag          forKey:@"ETag"];
}
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self) {
        self.last_modified  = [aDecoder decodeObjectForKey:@"last_modified"];
        self.ETag           = [aDecoder decodeObjectForKey:@"ETag"];
    }
    return self;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
    
}
@end

@interface DFPlayerRequestManager()<NSURLSessionDataDelegate>
@property (nonatomic, strong) NSMutableURLRequest   *request;
@property (nonatomic, strong) NSURLSession          *session;
@property (nonatomic, strong) NSURLSessionDataTask  *dataTask;
@property (nonatomic, strong) NSURL                 *requestUrl;
@property (nonatomic, strong) NSMutableArray        *archiverArray;

@end

@implementation DFPlayerRequestManager
+ (instancetype)requestWithUrl:(NSURL *)url{
    return [[self alloc] initWithUrl:url];
}
- (instancetype)initWithUrl:(NSURL *)url{
    self = [super init];
    if (self) {
        [DFPlayerFileManager df_createTempFile];
        self.requestUrl = [DFPlayerTool originalUrlWithUrl:url];
    }
    return self;
}
- (void)requestStart{
    
    __block DFPlayerRequestModel *model = [[DFPlayerRequestModel alloc] init];
    if (self.isHaveCache) {//安全性判断。如果沙盒存在缓存文件，再去发起校验。沙盒没有，直接下载缓存
        if (self.isObserveLastModified) {
            NSMutableDictionary *dic = [DFPlayerArchiverManager df_hasArchivedFileDictionary];
            [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([key isEqualToString:self.requestUrl.absoluteString]) {
                    NSLog(@"--已经存在归档");
                    model = (DFPlayerRequestModel *)obj;
                    *stop = YES;
                }
            }];
        }
    }
    
    //直接请求源端数据
    self.request = [NSMutableURLRequest requestWithURL:self.requestUrl
                                           cachePolicy:(NSURLRequestReloadIgnoringCacheData)
                                       timeoutInterval:20.0];
    if (model.ETag) {
        [self.request addValue:model.ETag forHTTPHeaderField:@"If-None-Match"];
    }
    if (model.last_modified) {
        [self.request addValue:model.last_modified forHTTPHeaderField:@"If-Modified-Since"];
    }
    if (self.requestOffset > 0) {
        NSString *value = [NSString stringWithFormat:@"bytes=%ld-%ld", (unsigned long)self.requestOffset, self.fileLength - 1];
        [self.request addValue:value forHTTPHeaderField:@"Range"];
    }
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.dataTask = [self.session dataTaskWithRequest:self.request];
    [self.dataTask resume];
}

- (void)setCancel:(BOOL)cancel {
    _cancel = cancel;
    [self.dataTask cancel];
    [self.session invalidateAndCancel];
}

#pragma mark - NSURLSessionDataDelegate
//服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if (self.cancel) return;
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

    NSString *contentLength = httpResponse.allHeaderFields[@"Content-Length"];
    self.fileLength = (long)[contentLength integerValue] > 0 ? (long)[contentLength integerValue] : (long)[response expectedContentLength];
    
    NSInteger statusCode = httpResponse.statusCode;    
    if (statusCode == 200) {
        DFPlayerRequestModel *model = [DFPlayerRequestModel new];
        model.last_modified = httpResponse.allHeaderFields[@"Last-Modified"];
        model.ETag          = httpResponse.allHeaderFields[@"Etag"];
        
        [DFPlayerArchiverManager df_archiveValue:model forKey:self.requestUrl.absoluteString];
        
        //如果没归档成功 如果本地有缓存则还是播放网络文件
//        NSLog(@"归档是否成功=======%d",isSuccess);
    }else if(statusCode == 206){//带有Range请求头的返回
        
    }else{
        self.cancel = YES;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestManagerDidReceiveResponseWithStatusCode:)]) {
        [self.delegate requestManagerDidReceiveResponseWithStatusCode:statusCode];
    }
 
}

//服务器返回数据 可能会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (self.cancel) return;
    [DFPlayerFileManager df_writeDataToAudioFileTempPathWithData:data];
    self.cacheLength += data.length;
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestManagerDidReceiveData)]) {
        [self.delegate requestManagerDidReceiveData];
    }
}

//请求完成会调用该方法，请求失败则error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (self.cancel) {
        NSLog(@"--下载取消");
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestManagerDidCompleteWithError:isCached:)]) {
            [self.delegate requestManagerDidCompleteWithError:nil isCached:NO];
        }
    }else {
        if (error) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(requestManagerDidCompleteWithError:isCached:)]) {
                [self.delegate requestManagerDidCompleteWithError:[error localizedDescription] isCached:NO];
            }
        }else {
            //可以缓存则保存文件
            [DFPlayerFileManager df_moveAudioFileFromTempPathToCachePath:self.requestUrl blcok:^(BOOL isSuccess,NSError *error) {
                if (isSuccess) {
                    NSLog(@"--保存成功");
                }else{
                    NSLog(@"--保存失败：%@",[error localizedDescription]);
                }
                if (self.delegate && [self.delegate respondsToSelector:@selector(requestManagerDidCompleteWithError:isCached:)]) {
                    [self.delegate requestManagerDidCompleteWithError:[error localizedDescription] isCached:isSuccess];
                }
            }];
        }
    }
}

@end
