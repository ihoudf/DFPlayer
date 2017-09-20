//
//  DFPlayerResourceLoader.m
//  DFPlayer
//
//  Created by HDF on 2017/7/30.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayerResourceLoader.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "DFPlayerFileManager.h"

@interface DFPlayerResourceLoader ()
@property (nonatomic, strong) NSMutableArray<AVAssetResourceLoadingRequest *> *requestList;
@property (nonatomic, strong) DFPlayerRequestManager *requestManager;
@end



@implementation DFPlayerResourceLoader

- (instancetype)init {
    if (self = [super init]) {
        self.requestList = [NSMutableArray array];
    }
    return self;
}

- (void)stopLoading{
    self.requestManager.cancel = YES;
}

#pragma mark - SURequestTaskDelegate
- (void)requestManagerDidReceiveResponseWithStatusCode:(NSInteger)statusCode{
    if (self.checkStatusBlock) {
        self.checkStatusBlock(statusCode);
    }
}
- (void)requestManagerDidReceiveData {
    [self processRequestList];
}

- (void)requestManagerDidCompleteWithError:(NSString *)errorDescription isCached:(BOOL)isCached{
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(loader:isCached:)]) {
        [self.delegate loader:self isCached:isCached];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(loader:didGetError:)]) {
        [self.delegate loader:self didGetError:errorDescription];
    }
}



#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
//    self.currentUrlAbsoluteString = loadingRequest.request.URL.absoluteString;
    
//    NSLog(@"WaitingLoadingRequest < requestedOffset = %lld, currentOffset = %lld, requestedLength = %ld >", loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    [self addLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
//    NSLog(@"CancelLoadingRequest  < requestedOffset = %lld, currentOffset = %lld, requestedLength = %ld >", loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    
    [self.requestList removeObject:loadingRequest];
}

#pragma mark - 处理LoadingRequest
- (void)addLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.requestList addObject:loadingRequest];
//    NSLog(@"--loadRequest:%@",loadingRequest);

    @synchronized(self) {
        if (self.requestManager) {
            if (loadingRequest.dataRequest.requestedOffset >= self.requestManager.requestOffset &&
                loadingRequest.dataRequest.requestedOffset <= self.requestManager.requestOffset + self.requestManager.cacheLength) {
                //数据已经缓存，则直接完
                [self processRequestList];
            }else {
                //数据还没缓存，则等待数据下载；如果是Seek操作，则重新请求
                if (self.seekRequired) {
                    //Seek操作，则重新请求
                    [self newTaskWithLoadingRequest:loadingRequest cache:NO];
                }
            }
        }else {
            [self newTaskWithLoadingRequest:loadingRequest cache:YES];
        }
    }
}

- (void)newTaskWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest cache:(BOOL)cache {
    NSUInteger fileLength = 0;
    if (self.requestManager) {
        fileLength = self.requestManager.fileLength;
        self.requestManager.cancel = YES;
    }
    self.requestManager = [[DFPlayerRequestManager alloc] initWithUrl:loadingRequest.request.URL];
    self.requestManager.requestOffset = (long)loadingRequest.dataRequest.requestedOffset;
    self.requestManager.isCanCache = cache;
    if (fileLength > 0) {
        self.requestManager.fileLength = fileLength;
    }
    self.requestManager.delegate = self;
    
    self.requestManager.isHaveCache = self.isHaveCache;
    self.requestManager.isObserveLastModified = self.isObserveLastModified;
    
    [self.requestManager requestStart];
    self.seekRequired = NO;
}


- (void)processRequestList {
    NSMutableArray * finishRequestList = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest * loadingRequest in self.requestList) {
        if ([self finishLoadingWithLoadingRequest:loadingRequest]) {
            [finishRequestList addObject:loadingRequest];
        }
    }
    [self.requestList removeObjectsInArray:finishRequestList];
}

- (BOOL)finishLoadingWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    //填充信息
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(MimeType), NULL);
    loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    loadingRequest.contentInformationRequest.contentLength = self.requestManager.fileLength;
    
    //读文件，填充数据
    NSUInteger cacheLength = self.requestManager.cacheLength;
    NSUInteger requestedOffset = (long)loadingRequest.dataRequest.requestedOffset;
    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestedOffset = (long)loadingRequest.dataRequest.currentOffset;
    }
    NSUInteger canReadLength = cacheLength - (requestedOffset - self.requestManager.requestOffset);
    NSUInteger respondLength = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
    
    //    NSLog(@"cacheLength %ld, requestedOffset %lld, currentOffset %lld, canReadLength %ld, requestedLength %ld", cacheLength, loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset,canReadLength, loadingRequest.dataRequest.requestedLength);
    
    [loadingRequest.dataRequest respondWithData:[DFPlayerFileManager df_readTempFileDataWithOffset:requestedOffset - self.requestManager.requestOffset length:respondLength]];
    
    //如果完全响应了所需要的数据，则完成
    NSUInteger nowendOffset = requestedOffset + canReadLength;
    NSUInteger reqEndOffset = (long)loadingRequest.dataRequest.requestedOffset + (long)loadingRequest.dataRequest.requestedLength;
    if (nowendOffset >= reqEndOffset) {
        [loadingRequest finishLoading];
        return YES;
    }
    return NO;
}


@end


