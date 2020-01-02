//
//  DFPlayerRequestManager.m
//  DFPlayer
//
//  Created by ihoudf on 2017/7/31.
//  Copyright © 2017年 ihoudf. All rights reserved.
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
- (void)setValue:(id)value forUndefinedKey:(NSString *)key{}

@end

@interface DFPlayerRequestManager()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableURLRequest   *request;
@property (nonatomic, strong) NSURLSession          *session;
@property (nonatomic, strong) NSURLSessionDataTask  *dataTask;
@property (nonatomic, strong) NSURL                 *requestUrl;
@property (nonatomic, strong) NSMutableArray        *archiverArray;
@property (nonatomic, strong) NSOperationQueue      *operationQueue;
@property (nonatomic, assign) BOOL isNewAudio;

@end

@implementation DFPlayerRequestManager

+ (instancetype)requestWithUrl:(NSURL *)url{
    return [[self alloc] initWithUrl:url];
}

- (instancetype)initWithUrl:(NSURL *)url{
    self = [super init];
    if (self) {
        
        [DFPlayerTool startMonitoringNetworkStatus:^(DFPlayerNetworkStatus networkStatus) {
            if (!self.isNewAudio) {
                if (networkStatus != DFPlayerNetworkStatusUnknown ||
                    networkStatus != DFPlayerNetworkStatusNotReachable) {
                    self.requestOffset = self.cacheLength;
                    [self resumeRequestStart];
                }
            }
        }];
        
        [DFPlayerFileManager df_createTempFile];
        self.requestUrl = [DFPlayerTool originalURL:url];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)requestStart{
    __block DFPlayerRequestModel *model = [[DFPlayerRequestModel alloc] init];
    if (self.isHaveCache) {//安全性判断。如果沙盒存在缓存文件，再去发起校验。沙盒没有，直接下载缓存
        if (self.isObserveFileModifiedTime) {
            NSMutableDictionary *dic = [DFPlayerArchiverManager df_hasArchivedFileDictionary];
            [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([key isEqualToString:self.requestUrl.absoluteString]) {
                    model = (DFPlayerRequestModel *)obj;
                    *stop = YES;
                }
            }];
        }
    }
    
    self.isNewAudio = YES;
    //直接请求源端数据
    self.request = [NSMutableURLRequest requestWithURL:self.requestUrl
                                           cachePolicy:(NSURLRequestReloadIgnoringCacheData)
                                       timeoutInterval:10.0];
    if (model.ETag) {
        [self.request addValue:model.ETag forHTTPHeaderField:@"If-None-Match"];
    }
    if (model.last_modified) {
        [self.request addValue:model.last_modified forHTTPHeaderField:@"If-Modified-Since"];
    }
    [self requestDataTask];
}

- (void)resumeRequestStart{
    //直接请求源端数据
    self.request = [NSMutableURLRequest requestWithURL:self.requestUrl
                                           cachePolicy:(NSURLRequestReloadIgnoringCacheData)
                                       timeoutInterval:10.0];
    if (self.requestOffset > 0) {
        NSString *value = [NSString stringWithFormat:@"bytes=%ld-%ld", (long)self.requestOffset,(long)self.fileLength];
        [self.request addValue:value forHTTPHeaderField:@"Range"];
    }
    [self requestDataTask];
}

- (void)requestDataTask{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:self.operationQueue];
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
    if (_cancel) {
        return;
    }
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    self.isNewAudio = NO;
    
    NSInteger statusCode = httpResponse.statusCode;
    if (statusCode == 200) {
        NSString *contentLength = httpResponse.allHeaderFields[@"Content-Length"];
        self.fileLength = (long)[contentLength integerValue] > 0 ? (long)[contentLength integerValue] : (long)[response expectedContentLength];
        
        DFPlayerRequestModel *model = [DFPlayerRequestModel new];
        model.last_modified = httpResponse.allHeaderFields[@"Last-Modified"];
        model.ETag          = httpResponse.allHeaderFields[@"Etag"];
        
        [DFPlayerArchiverManager df_archiveValue:model forKey:self.requestUrl.absoluteString];
        
        //如果没归档成功 如果本地有缓存则还是播放网络文件
    }else if(statusCode == 206){//带有Range请求头的返回
        
    }else{
        _cancel = YES;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestManagerDidReceiveResponseWithStatusCode:)]) {
        [self.delegate requestManagerDidReceiveResponseWithStatusCode:statusCode];
    }
    
}

//服务器返回数据 可能会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (_cancel){
        return;
    }
    self.cacheLength += data.length;
    [DFPlayerFileManager df_writeDataToAudioFileTempPathWithData:data];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestManagerDidReceiveData)]) {
        [self.delegate requestManagerDidReceiveData];
    }
}

//请求完成会调用该方法，请求失败则error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (_cancel) {
        return;
    }
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestManagerDidCompleteWithError:)]) {
            [self.delegate requestManagerDidCompleteWithError:error.code];
        }
    }else {
        self.isNewAudio = YES;
        //可以缓存则保存文件
        BOOL success = [DFPlayerFileManager df_moveAudioFileFromTempPathToCachePath:self.requestUrl];
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestManagerIsCached:)]) {
            [self.delegate requestManagerIsCached:success];
        }
    }
}


@end
