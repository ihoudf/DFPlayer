//
//  DFPlayerManager.m
//  DFPlayer
//
//  Created by HDF on 2017/7/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayerManager.h"
#import "DFPLayerMacro.h"
#import "DFPlayerFileManager.h"
#import "DFPlayerResourceLoader.h"
#import "DFPlayerTool.h"

/**类型KEY*/
NSString * const DFPlayerTypeKey                = @"DFPlayerType";
/**Asset KEY*/
NSString * const DFPlayableKey                  = @"playable";
/**PlayerItem KEY*/
NSString * const DFStatusKey                    = @"status";
NSString * const DFLoadedTimeRangesKey          = @"loadedTimeRanges";
NSString * const DFPlaybackBufferEmptyKey       = @"playbackBufferEmpty";
NSString * const DFPlaybackLikelyToKeepUpKey    = @"playbackLikelyToKeepUp";
/**AVPlayer KEY*/
NSString * const DFRateKey                      = @"rate";

@interface DFPlayerManager()<DFPlayerResourceLoaderDelegate>
/**其他应用是否正在播放*/
@property (nonatomic, assign) BOOL              isOthetPlaying;
/**是否正在播放*/
@property (nonatomic, assign) BOOL              isPlaying;
/**是否进入后台*/
@property (nonatomic, assign) BOOL              isBackground;
/**组队列*/
@property (nonatomic, strong) dispatch_group_t  groupQueue;
/**player*/
@property (nonatomic, strong) AVPlayer          *player;
/**playerItem*/
@property (nonatomic, strong) AVPlayerItem      *playerItem;
/**播放进度*/
@property (nonatomic, strong) id                timeObserver;
/**当前正在播放的音频Id*/
@property (nonatomic, assign) NSInteger         currentAudioTag;
/**随机数组*/
@property (nonatomic, strong) NSMutableArray    *randomIndexArray;
/**随机数组元素index*/
@property (nonatomic, assign) NSInteger         randomIndex;
/**播放进度是否被拖拽了*/
@property (nonatomic, assign) BOOL              isDraged;
/**当前音频是否缓存*/
@property (nonatomic, assign) BOOL              isCached;
/**是否有某个音频播放过*/
@property (nonatomic, assign) BOOL              isAnAudioPlayed;
/**是否是第一次初始化播放器*/
@property (nonatomic, assign) BOOL              isInitPlayerMark1;
@property (nonatomic, assign) BOOL              isInitPlayerMark2;
/**资源下载器*/
@property (nonatomic, strong) DFPlayerResourceLoader            *resourceLoader;
/**model数据数组*/
@property (nonatomic, strong) NSMutableArray<DFPlayerModel *>   *playerModelArray;

@end

@implementation DFPlayerManager

#pragma mark - BEGIN
+ (DFPlayerManager *)shareInstance {
    static DFPlayerManager *instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 初始化播放器
- (void)initPlayerWithUserId:(NSString *)userId{
    self.isOthetPlaying = [AVAudioSession sharedInstance].otherAudioPlaying;
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    
    NSInteger user_playerType = [[NSUserDefaults standardUserDefaults] integerForKey:DFPlayerTypeKey];
    if (user_playerType) {
        self.type = user_playerType;
    }else{
        self.type = DFPlayerTypeOnlyOnce;
    }
    
    self.isObserveProgress          = YES;
    self.isObserveBufferProgress    = YES;
    self.isLockInfo                 = YES;
    self.isNeedCache                = YES;
    self.isRemoteControl            = YES;
    self.isObserveWWAN              = NO;
    self.isHeadPhoneAutoPlay        = YES;
    self.isObserveLastModified      = YES;
    self.isObservePreviousAudioModel= NO;
    self.isBackground               = NO;
    self.randomIndex                = -1;
    self.isAnAudioPlayed            = NO;
    self.isCached                   = NO;
    
    self.isInitPlayerMark1 = YES;
    self.isInitPlayerMark2 = YES;
    //添加观察者
    [self addPlayerObserver];
    
    //记录用户
    [self initPlayerCachePathWithUserId:userId];
}

#pragma mark - 监测网络 监听播放结束 耳机插拔 播放器被打断
- (void)addPlayerObserver{
    
    self.groupQueue = dispatch_group_create();
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_group_enter(self.groupQueue);
    });
    dispatch_group_async(self.groupQueue, globalQueue, ^{
        [DFPlayerTool checkNetworkReachable:^(NSInteger networkStatus) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                dispatch_group_leave(self.groupQueue);
            });
            switch (networkStatus) {
                case -1:
                    self.networkStatus = DFPlayerNetworkStatusUnknown;break;
                case 0:
                    self.networkStatus = DFPlayerNetworkStatusNotReachable;break;
                case 1:
                    self.networkStatus = DFPlayerNetworkStatusReachableViaWWAN;break;
                case 2:
                    self.networkStatus = DFPlayerNetworkStatusReachableViaWiFi;break;
                default:
                    break;
            }
        }];
    });
  
    //将要进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_playerWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    //已经进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_playerDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    //已经进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_playerDidEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    //程序将被终止
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_playerWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    //监测耳机
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_playerAudioRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    //监听播放器被打断（别的软件播放音乐，来电话）
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_playerAudioBeInterrupted:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    //监测其他app是否占据AudioSession
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_playerSecondaryAudioHint:) name:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil];
}

- (void)df_playerWillResignActive{
     DFLog(@"--将要进入后台");
    self.isBackground = YES;
}
- (void)df_playerDidEnterBackground{
     DFLog(@"--已经进入后台，当前播放模式:%ld",(long)self.category);
    if (self.category != DFPlayerAudioSessionCategoryPlayback) {
        [self recordCurrentAudioInfoModel];
    }
}

- (void)df_playerDidEnterForeground{
    DFLog(@"--将要进入前台");
    self.isBackground = NO;
}

- (void)df_playerWillTerminate{
    DFLog(@"--播放类型:%ld",(long)self.category);
    if (self.category == DFPlayerAudioSessionCategoryPlayback) {
        [self recordCurrentAudioInfoModel];
    }
}

- (void)recordCurrentAudioInfoModel{
    //记录信息
    if (self.currentAudioModel && self.isAnAudioPlayed) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        if (self.currentAudioModel.audioId) {
            [dic setObject:[NSNumber numberWithUnsignedInteger:self.currentAudioModel.audioId]
                    forKey:DFPlayerCurrentAudioInfoModelAudioId];
        }
        if (self.currentAudioModel.audioUrl && [self.currentAudioModel.audioUrl isKindOfClass:[NSURL class]]) {
            [dic setObject:[self.currentAudioModel.audioUrl absoluteString]
                    forKey:DFPlayerCurrentAudioInfoModelAudioUrl];
        }
        if (self.currentAudioModel.audioName) {
            [dic setObject:self.currentAudioModel.audioName
                    forKey:DFPlayerCurrentAudioInfoModelAudioName];
        }
        if (self.currentAudioModel.audioAlbum) {
            [dic setObject:self.currentAudioModel.audioAlbum
                    forKey:DFPlayerCurrentAudioInfoModelAudioAlbum];
        }
        if (self.currentAudioModel.audioImage) {
            [dic setObject:self.currentAudioModel.audioImage
                    forKey:DFPlayerCurrentAudioInfoModelAudioImage];
        }
        if (self.currentAudioModel.audioSinger) {
            [dic setObject:self.currentAudioModel.audioSinger
                    forKey:DFPlayerCurrentAudioInfoModelAudioSinger];
        }
        if (self.currentAudioModel.audioLyric) {
            [dic setObject:self.currentAudioModel.audioLyric
                    forKey:DFPlayerCurrentAudioInfoModelAudioLyric];
        }
        if (self.isCached) {
            [dic setObject:[NSNumber numberWithBool:self.isCached]
                    forKey:DFPlayerCurrentAudioInfoModelIsCached];
        }
        if (self.currentTime) {
            [dic setObject:[NSNumber numberWithFloat:self.currentTime]
                    forKey:DFPlayerCurrentAudioInfoModelCurrentTime];
        }
        if (self.totalTime) {
            [dic setObject:[NSNumber numberWithFloat:self.totalTime]
                    forKey:DFPlayerCurrentAudioInfoModelTotalTime];
        }
        if (self.progress) {
            [dic setObject:[NSNumber numberWithFloat:self.progress]
                    forKey:DFPlayerCurrentAudioInfoModelProgress];
        }
        [DFPlayerArchiverManager df_archiveInfoModelDictionary:dic];
        DFLog(@"--播放信息保存完成");
    }
}

- (void)df_playerAudioRouteChange:(NSNotification *)notification {
    NSInteger routeChangeReason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable://耳机插入
            if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isHeadphone:)]) {
                [self.delegate df_player:self isHeadphone:YES];
            }else{
                if (self.isHeadPhoneAutoPlay) {
                    if (self.currentAudioModel) {
                        [self df_audioPlay];
                    }
                }
            }
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable://耳机拔出，停止播放操作
            if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isHeadphone:)]) {
                [self.delegate df_player:self isHeadphone:NO];
            }else{
                [self df_audioPause];
                self.state = DFPlayerStatePause;
            }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            //
            break;
        default:
            break;
    }
}

- (void)df_playerAudioBeInterrupted:(NSNotification *)notification {
    NSDictionary *dic = notification.userInfo;
    NSInteger type = [dic[AVAudioSessionInterruptionTypeKey] integerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {//打断开始
         DFLog(@"--打断开始");
        [self df_audioPause];
        //打断时也要记录信息
        [self recordCurrentAudioInfoModel];
        if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:beInterruptedBySystemBegin:)]) {
            [self.delegate df_player:self beInterruptedBySystemBegin:dic];
        }
    }else {
         DFLog(@"--打断结束");
        if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:beInterruptedBySystemEnd:)]) {
            [self.delegate df_player:self beInterruptedBySystemEnd:dic];
        }else{
            AVAudioSessionInterruptionOptions options = [notification.userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
            if (options == AVAudioSessionInterruptionOptionShouldResume) {
                [self df_audioPlay];
            }
        }
    }
}

- (void)df_playerSecondaryAudioHint:(NSNotification *)notification{
    NSInteger type = [notification.userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] integerValue];
    if (type == AVAudioSessionSilenceSecondaryAudioHintTypeBegin) {
        DFLog(@"--被其他音频占据");
    }else{
        DFLog(@"--占据结束");
    }
}

-(void)df_playerDidPlayToEndTime:(NSNotification *)notification{
    [self df_audioNext];
    if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerDidPlayToEndTime:)]) {
        [self.delegate df_playerDidPlayToEndTime:self];
    }
}

#pragma mark - DFPlayer Data
/**刷新数据源数据*/
- (void)df_reloadData{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(df_playerModelArray)]) {
        if (!self.playerModelArray) {
            self.playerModelArray = [NSMutableArray array];
        }
        if (self.playerModelArray.count != 0) {
            [self.playerModelArray removeAllObjects];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.playerModelArray addObjectsFromArray:[self.dataSource df_playerModelArray]];
        });
    }else{
        [self playfailureWithErrorMessage:@"没有音频资源"];return;
    }
}
/**选择audioId对应的音频开始播放*/
- (void)df_playerDidSelectWithAudioId:(NSUInteger)audioId{
    if (self.playerModelArray.count > audioId) {
        self.currentAudioModel = self.playerModelArray[audioId];
        NSLog(@"--点击了音频Id:%ld   url：%@",(unsigned long)self.currentAudioModel.audioId,self.currentAudioModel.audioUrl);
        self.currentAudioTag = audioId;
        [self audioPrePlay];
    }else{
        [self playfailureWithErrorMessage:@"数组越界"];
    }
}

#pragma mark - DFPlayerResourceLoaderDelegate
/**下载出错*/
- (void)loader:(DFPlayerResourceLoader *)loader didGetError:(NSString *)errorDescription{
    [self playfailureWithErrorMessage:errorDescription];
}
/**是否完成缓存*/
- (void)loader:(DFPlayerResourceLoader *)loader isCached:(BOOL)isCached{
    if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isCached:)]) {
        self.isCached = isCached;
        [self.delegate df_player:self isCached:isCached];
    }
}


#pragma mark - DFPLayer -资源准备 IMPORTANT
/**预播放*/
- (void)audioPrePlay{
    //音频将要加入播放队列
    if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerAudioWillAddToPlayQueue:)]) {
        [self.delegate df_playerAudioWillAddToPlayQueue:self];
    }
    //重置进度和时间
    if (!self.isInitPlayerMark1 || !self.isObservePreviousAudioModel) {
        self.progress       = .0f;
        self.bufferProgress = .0f;
        self.currentTime    = .0f;
        self.totalTime      = .0f;
    }
    self.isInitPlayerMark1 = NO;
    //暂停播放
    if (self.isPlaying) {
        [self df_audioPause];
    }
    //移除进度观察者
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    //音频地址安全性判断
    NSURL *currentAudioUrl;
    if([self.currentAudioModel.audioUrl isKindOfClass:[NSURL class]]){
        currentAudioUrl = self.currentAudioModel.audioUrl;
    }else{
        [self playfailureWithErrorMessage:DFPlayerWarning_TypeError];return;
    }
    
    //播放本地音频
    if ([currentAudioUrl.scheme isEqualToString:@"file"])
    {
        DFLog(@"--播放本地音频");
        [self loadPlayerWithItemUrl:currentAudioUrl];
        self.isCached = YES;
    }
    //播放网络音频
    else{
        dispatch_group_notify(self.groupQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *cacheFilePath = [DFPlayerFileManager df_isExistAudioFileWithURL:currentAudioUrl];
            DFLog(@"--是否有缓存：%@",cacheFilePath);
            self.isCached = cacheFilePath?YES:NO;
            
            //如果监听WWAN，网络状态是WWAN，并且本地无缓存，三种情况同时存在时发起代理
            if (self.isObserveWWAN && self.networkStatus == DFPlayerNetworkStatusReachableViaWWAN && !cacheFilePath)
            {
                if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerNetworkDidChangeToWWAN:)])
                {
                    [self.delegate df_playerNetworkDidChangeToWWAN:self];
                }else{
                    DFLog(@"--未实现df_playerNetworkDidChangeToWWAN代理方法，或将isObserveWWAN置为NO");
                }
            }
            else
            {
                [self loadPlayerItemWithUrl:currentAudioUrl andCacheFilePath:cacheFilePath];
            }
        });
    }
}
/**加载playerItem*/
- (void)loadPlayerItemWithUrl:(NSURL *)currentAudioUrl andCacheFilePath:(NSString *)cacheFilePath{
    
    if (self.networkStatus == DFPlayerNetworkStatusUnknown ||
        self.networkStatus == DFPlayerNetworkStatusNotReachable)//无网络
    {
        if (cacheFilePath)//无网络 有缓存
        {
            DFLog(@"--当前无网络，有缓存，即将播放缓存文件");
            [self loadPlayerWithItemUrl:[NSURL fileURLWithPath:cacheFilePath]];
        }
        else//无网络 无缓存
        {
            [self playfailureWithErrorMessage:DFPlayerWarning_UnavailableNewwork];//提示联网
        }
    }
    else//有网络
    {
        if (!self.isNeedCache)//不需要缓存
        {
            [self loadPlayerWithItemUrl:currentAudioUrl];
        }
        else
        {
            if (self.resourceLoader) {
                [self.resourceLoader stopLoading];
            }
            self.resourceLoader = [[DFPlayerResourceLoader alloc] init];
            self.resourceLoader.delegate = self;
            NSURL *customUrl = [DFPlayerTool customUrlWithUrl:currentAudioUrl];
            if (!customUrl) {
                [self playfailureWithErrorMessage:DFPlayerWarning_UnavailableLinks];return;
            }
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:customUrl options:nil];
            [asset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
            
            BOOL isCached = NO;
            if (cacheFilePath) {
                isCached = YES;
            }
            self.resourceLoader.isHaveCache = isCached;
            self.resourceLoader.isObserveLastModified = self.isObserveLastModified;
            
            kWeakSelf;
            self.resourceLoader.checkStatusBlock = ^(NSInteger statusCode){
                if (statusCode == 200) {
                    DFLog(@"--播放网络文件");
                    weakSelf.bufferProgress = 0;
                    [weakSelf loadPlayerWithAsset:asset];
                }else if (statusCode == 304) {
                    DFLog(@"--服务器音频资源未更新，播放本地");
                    [weakSelf loadPlayerWithItemUrl:[NSURL fileURLWithPath:cacheFilePath]];
                }else{
                    [weakSelf playfailureWithErrorMessage:DFPlayerWarning_UnavailableData];
                }
            };

            NSArray *requestedKeys = [NSArray arrayWithObjects:DFPlayableKey, nil];
            [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
                dispatch_async( dispatch_get_main_queue(),^{
                    if (!asset.playable) {
                        [self.resourceLoader stopLoading];
                        self.state = DFPlayerStateFailed;
                        [asset cancelLoading];
                    }
                });
            }];
        }
    }
}

- (void)loadPlayerWithAsset:(AVURLAsset *)asset{
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self loadPlayer];
}

- (void)loadPlayerWithItemUrl:(NSURL *)url{
    self.playerItem = [[AVPlayerItem alloc] initWithURL:url];
    [self loadPlayer];
}

- (void)loadPlayer{
    if (self.player) {
        [self.player removeObserver:self forKeyPath:DFRateKey];
    }
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    [self.player addObserver:self forKeyPath:DFRateKey options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    
    //监听播放进度
    if (self.isObserveProgress) {
        [self addPlayProgressTimeObserver];
    }
    //设置锁屏信息
    if (self.isLockInfo) {
        [self addInformationOfLockScreen];
    }
    
    if (!self.isInitPlayerMark2 || !self.isObservePreviousAudioModel || !self.previousAudioModel.audioUrl) {
        [self df_audioPlay];
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == self.player) {
        if ([keyPath isEqualToString:DFRateKey]) {
            if (self.player.rate == 0.f) {
                self.state = DFPlayerStatePause;
                self.isPlaying = NO;
                DFLog(@"--暂停");
            }else {
                self.state = DFPlayerStatePlaying;
                self.isPlaying = YES;
                DFLog(@"--播放");
            }
        }
    }else if (object == self.player.currentItem) {
        if ([keyPath isEqualToString:DFStatusKey]) {
            AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            switch (status) {
                case AVPlayerItemStatusUnknown: //未知错误
                    self.state = DFPlayerStateFailed;
                    [self playfailureWithErrorMessage:DFPlayerWarning_UnknownError];
                    break;
                case AVPlayerItemStatusReadyToPlay://准备播放
                    DFLog(@"--准备播放");
                    [self df_seekTotimeOfInfoModelWhenInitDFPlayer];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerDidReadyToPlay:)]) {
                        [self.delegate df_playerDidReadyToPlay:self];
                    }
                    break;
                case AVPlayerItemStatusFailed://准备失败.
                    [self playfailureWithErrorMessage:DFPlayerWarning_PlayError];
                    self.state = DFPlayerStateFailed;
                    DFLog(@"--播放失败");
                    break;
                default:
                    break;
            }
        } else if ([keyPath isEqualToString:DFLoadedTimeRangesKey]) {
            self.totalTime = CMTimeGetSeconds(self.playerItem.duration);
            if (self.isObserveBufferProgress) {//缓冲进度
                [self addBufferProgressObserver];
            }
        } else if ([keyPath isEqualToString:DFPlaybackBufferEmptyKey]) {
            if (self.playerItem.playbackBufferEmpty) {//当缓冲是空的时候
                self.state = DFPlayerStateBuffering;
            }
        } else if ([keyPath isEqualToString:DFPlaybackLikelyToKeepUpKey]) {
            DFLog(@"--缓冲达到可播放");
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 缓冲进度 播放进度 歌曲锁屏信息 音频跳转
/**缓冲进度*/
- (void)addBufferProgressObserver{
    CMTimeRange timeRange   = [self.playerItem.loadedTimeRanges.firstObject CMTimeRangeValue];
    CGFloat startSeconds    = CMTimeGetSeconds(timeRange.start);
    CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
    self.bufferProgress     = (startSeconds + durationSeconds) / self.totalTime;
    if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:bufferProgress:totalTime:)]) {
        [self.delegate df_player:self
                  bufferProgress:self.bufferProgress
                       totalTime:self.totalTime];
    }
}

/**播放进度*/
- (void)addPlayProgressTimeObserver{
    kWeakSelf;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time){
        AVPlayerItem *currentItem = weakSelf.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0){
            CGFloat currentT = (CGFloat)CMTimeGetSeconds([currentItem currentTime]);
            if (!weakSelf.isDraged) {
                weakSelf.currentTime = currentT;
            }
            weakSelf.progress = CMTimeGetSeconds([currentItem currentTime]) / weakSelf.totalTime;
            
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(df_player:progress:currentTime:totalTime:)]) {
                [weakSelf.delegate df_player:weakSelf
                                    progress:weakSelf.progress
                                 currentTime:currentT
                                   totalTime:weakSelf.totalTime];
            }
            if (weakSelf.isBackground) {
                [weakSelf updatePlayingCenterInfo];
            }
        }
    }];
}

/**锁屏、后台模式信息*/
- (void)addInformationOfLockScreen{
    MPNowPlayingInfoCenter *playInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if (self.currentAudioModel.audioName) {
        dic[MPMediaItemPropertyTitle] = self.currentAudioModel.audioName;
    }
    if (self.currentAudioModel.audioAlbum) {
        dic[MPMediaItemPropertyAlbumTitle] = self.currentAudioModel.audioAlbum;
    }
    if (self.currentAudioModel.audioSinger) {
        dic[MPMediaItemPropertyArtist] = self.currentAudioModel.audioSinger;
    }
    dic[MPNowPlayingInfoPropertyPlaybackRate] = [NSNumber numberWithFloat:1.0];
    if ([self.currentAudioModel.audioImage isKindOfClass:[UIImage class]] && self.currentAudioModel.audioImage) {
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:self.currentAudioModel.audioImage];
        dic[MPMediaItemPropertyArtwork] = artwork;
    }
    playInfoCenter.nowPlayingInfo = dic;
}

- (void)updatePlayingCenterInfo{
    NSDictionary *info=[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:info];
    dic[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:CMTimeGetSeconds(self.playerItem.currentTime)];
    dic[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithDouble:CMTimeGetSeconds(self.playerItem.duration)];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dic];
}

- (void)df_seekTotimeOfInfoModelWhenInitDFPlayer{
    if (self.isInitPlayerMark2) {
        self.isInitPlayerMark2 = NO;
        [self.player seekToTime:CMTimeMake(floorf(self.totalTime * self.progress), 1)
                toleranceBefore:CMTimeMake(1,1)
                 toleranceAfter:CMTimeMake(1,1)
              completionHandler:^(BOOL finished) {
                  if (finished) {}
        }];
    }
}

/**音频跳转*/
- (void)df_seekToTimeWithValue:(CGFloat)value{
    self.isDraged = YES;
    self.resourceLoader.seekRequired = YES;

    if (self.state == DFPlayerStatePlaying || self.state == DFPlayerStatePause) {
        // 先暂停
        [self df_audioPause];
        // 跳转
        NSInteger seconds = floorf(self.totalTime * value);
        [self.player seekToTime:CMTimeMake(seconds, 1)
                toleranceBefore:CMTimeMake(1,1)
                 toleranceAfter:CMTimeMake(1,1)
              completionHandler:^(BOOL finished) {
            if (finished) {
                [self df_audioPlay];
                self.isDraged = NO;
            }
        }];
    }
}


#pragma mark - 播放 暂停 下一首 上一首
/**播放*/
-(void)df_audioPlay{
    self.isAnAudioPlayed = YES;
    if (!self.isPlaying) {
        self.isPlaying = YES;
        self.state = DFPlayerStatePlaying;
    }
    [self.player play];
}

/**暂停*/
-(void)df_audioPause{
    if (self.isPlaying) {
        self.isPlaying = NO;
        self.state = DFPlayerStatePause;
    }
    [self.player pause];
}

// 下一首
- (void)df_audioNext{
    switch (self.type) {
        case DFPlayerTypeOnlyOnce:
            break;
        case DFPlayerTypeSingleCycle:{
            [self audioPrePlay];
        }
            break;
        case DFPlayerTypeOrderCycle:{
            self.currentAudioTag++;
            if (self.currentAudioTag < 0 || self.currentAudioTag >= self.playerModelArray.count) {
                self.currentAudioTag = 0;
            }
            self.currentAudioModel = self.playerModelArray[self.currentAudioTag];
            [self audioPrePlay];
        }
            break;
        case DFPlayerTypeShuffleCycle:
        {
            self.randomIndex++;
            if (self.randomIndex >= self.randomIndexArray.count) {
                self.randomIndex = 0;
            }
            NSInteger tag = [self.randomIndexArray[self.randomIndex] integerValue];
            self.currentAudioModel = self.playerModelArray[tag];
            [self audioPrePlay];
        }
            break;
        default:
            break;
    }
}

// 上一首
- (void)df_audioLast{
    switch (self.type) {
        case DFPlayerTypeOnlyOnce:
            break;
        case DFPlayerTypeSingleCycle:
            [self audioPrePlay];
            break;
        case DFPlayerTypeOrderCycle:
            self.currentAudioTag--;
            if (self.currentAudioTag < 0) {
                self.currentAudioTag = self.playerModelArray.count-1;
            }
            self.currentAudioModel = self.playerModelArray[self.currentAudioTag];
            [self audioPrePlay];
            break;
        case DFPlayerTypeShuffleCycle:
        {
            self.randomIndex--;
            if (self.randomIndex < 0) {
                self.randomIndex = self.randomIndexArray.count-1;
            }
            NSInteger tag = [self.randomIndexArray[self.randomIndex] integerValue];
            self.currentAudioModel = self.playerModelArray[tag];
            [self audioPrePlay];
        }
            break;
        default:
            break;
    }
}

//释放播放器
- (void)df_dellecPlayer{
    [self df_audioPause];
    //解除激活,并还原其他应用播放器声音
    if (self.resourceLoader) {
        [self.resourceLoader stopLoading];
    }
    if (self.isOthetPlaying) {
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    }else{
        [[AVAudioSession sharedInstance]setActive:NO error:nil];
    }
    if (self.player) {
        self.player = nil;
    }
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
}

#pragma mark - 随机播放数组
- (NSMutableArray *)randomIndexArray{
    if (!_randomIndexArray) {
        _randomIndexArray = [NSMutableArray arrayWithArray:[self getRandomPlayerModelIndexArray]];
    }
    return _randomIndexArray;
}
-(NSMutableArray*)getRandomPlayerModelIndexArray{
    NSInteger startIndex = 0;
    NSInteger length = self.playerModelArray.count;
    NSInteger endIndex = startIndex+length;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:length];
    NSMutableArray *arr1 = [NSMutableArray arrayWithCapacity:length];
    for (NSInteger i = startIndex; i < endIndex; i++) {
        [arr1 addObject:[NSString stringWithFormat:@"%ld",(long)i]];
    }
    for (NSInteger i = startIndex; i < endIndex; i++) {
        int index = arc4random()%arr1.count;
        int radom = [arr1[index] intValue];
        NSNumber *num = [NSNumber numberWithInt:radom];
        [arr addObject:num];
        [arr1 removeObjectAtIndex:index];
    }
    return arr;
}

#pragma mark - setter
- (void)setPlayerItem:(AVPlayerItem *)playerItem{
    if (_playerItem == playerItem) {return;}
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [_playerItem removeObserver:self forKeyPath:DFStatusKey];
        [_playerItem removeObserver:self forKeyPath:DFLoadedTimeRangesKey];
        [_playerItem removeObserver:self forKeyPath:DFPlaybackBufferEmptyKey];
        [_playerItem removeObserver:self forKeyPath:DFPlaybackLikelyToKeepUpKey];
    }
    _playerItem = playerItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(df_playerDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [playerItem addObserver:self forKeyPath:DFStatusKey options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:DFLoadedTimeRangesKey options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:DFPlaybackBufferEmptyKey options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:DFPlaybackLikelyToKeepUpKey options:NSKeyValueObservingOptionNew context:nil];
    }
}
- (void)setCategory:(DFPlayerAudioSessionCategory)category{
    DFLog(@"--设置了播放器类型:%ld",(long)category);
    _category = category;
    switch (category) {
        case DFPlayerAudioSessionCategoryAmbient:
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
            break;
        case DFPlayerAudioSessionCategorySoloAmbient:
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
            break;
        case DFPlayerAudioSessionCategoryPlayback:
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            break;
        case DFPlayerAudioSessionCategoryRecord:
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
            break;
        case DFPlayerAudioSessionCategoryPlayAndRecord:
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
            break;
        case DFPlayerAudioSessionCategoryMultiRoute:
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
            break;
        default:
            break;
    }
}

- (void)setIsObserveProgress:(BOOL)isObserveProgress{
    DFLog(@"--设置了是否监听播放进度:%d",isObserveProgress);
    _isObserveProgress = isObserveProgress;
}

- (void)setIsObserveBufferProgress:(BOOL)isObserveBufferProgress{
    DFLog(@"--设置了是否监听缓冲进度:%d",isObserveBufferProgress);
    _isObserveBufferProgress = isObserveBufferProgress;
}

- (void)setType:(DFPlayerType)type{
    DFLog(@"--设置了播放类型:%ld",(long)type);
    _type = type;
    [[NSUserDefaults standardUserDefaults] setInteger:type forKey:DFPlayerTypeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIsLockInfo:(BOOL)isLockInfo{
    DFLog(@"--设置了是否展示锁屏信息：%d",isLockInfo);
    _isLockInfo = isLockInfo;
}

- (void)setIsObserveWWAN:(BOOL)isObserveWWAN{
    DFLog(@"--设置了是否监测WWAN：%d",isObserveWWAN);
    _isObserveWWAN = isObserveWWAN;
}
- (void)setIsRemoteControl:(BOOL)isRemoteControl{
     DFLog(@"--设置了是否耳机线控:%d",isRemoteControl);
    _isRemoteControl = isRemoteControl;
    if (_isRemoteControl) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }else{
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    }
}

- (void)setIsHeadPhoneAutoPlay:(BOOL)isHeadPhoneAutoPlay{
    DFLog(@"--设置了是否插入耳机后音频自动恢复：%d",isHeadPhoneAutoPlay);
    _isHeadPhoneAutoPlay = isHeadPhoneAutoPlay;
}

- (void)setIsEnableLog:(BOOL)isEnableLog{
    NSLog(@"--设置了是否需要打印日志:%d",isEnableLog);
    _isEnableLog = isEnableLog;
    [DFPlayerTool setLogEnabled:isEnableLog];
}

- (void)setIsObserveLastModified:(BOOL)isObserveLastModified{
    DFLog(@"--设置了是否观察修改时间：%d",isObserveLastModified);
    _isObserveLastModified = isObserveLastModified;
}
- (void)setIsObservePreviousAudioModel:(BOOL)isObservePreviousAudioModel{
    DFLog(@"--设置了是否监测音频model信息：%d",isObservePreviousAudioModel);
    _isObservePreviousAudioModel = isObservePreviousAudioModel;
    
    if (isObservePreviousAudioModel && self.previousAudioModel.audioUrl) {
        //如果记录上次播放信息，配置上次播放信息
            self.currentAudioModel              = [[DFPlayerModel alloc] init];
            self.currentAudioModel.audioUrl     = self.previousAudioModel.audioUrl;
            self.currentAudioModel.audioId      = self.previousAudioModel.audioId;
            self.currentAudioModel.audioLyric   = self.previousAudioModel.audioLyric;
            self.currentAudioModel.audioName    = self.previousAudioModel.audioName;
            self.currentAudioModel.audioAlbum   = self.previousAudioModel.audioAlbum;
            self.currentAudioModel.audioImage   = self.previousAudioModel.audioImage;
            self.currentAudioModel.audioSinger  = self.previousAudioModel.audioSinger;
            self.isCached                       = self.previousAudioModel.isCached;
            self.progress                       = self.previousAudioModel.progress;
            self.currentTime                    = self.previousAudioModel.currentTime;
            self.totalTime                      = self.previousAudioModel.totalTime;
            [self audioPrePlay];
    }
}
//以下为状态setter
- (void)setCurrentAudioModel:(DFPlayerModel *)currentAudioModel{_currentAudioModel = currentAudioModel;}

- (void)setProgress:(CGFloat)progress{_progress = progress;}

- (void)setBufferProgress:(CGFloat)bufferProgress{_bufferProgress = bufferProgress;}

- (void)setCurrentTime:(NSInteger)currentTime{_currentTime = currentTime;}

- (void)setTotalTime:(CGFloat)totalTime{_totalTime = totalTime;}

- (void)setState:(DFPlayerState)state {
    DFLog(@"--播放器状态:%ld",(long)state);
    _state = state;
}
- (void)setNetworkStatus:(DFPlayerNetworkStatus)networkStatus{
    DFLog(@"--网络状态：%ld",(long)networkStatus);
    _networkStatus = networkStatus;
}
- (DFPlayerPreviousAudioModel *)currentAudioInfoModel{
    return [[DFPlayerPreviousAudioModel alloc] init];
}

#pragma mark - 缓存相关
- (void)initPlayerCachePathWithUserId:(NSString *)userId{
    [DFPlayerFileManager df_playerCreateCachePathWithId:userId];
}

- (NSMutableArray<DFPlayerModel *> *)df_getCacheListFromCurrentDataSource{
    NSMutableArray *cacheArr = [NSMutableArray array];
    [self df_reloadData];
    for (int i = 0; i < self.playerModelArray.count; i++) {
        DFPlayerModel *model = self.playerModelArray[i];
        NSString *urlStr = [NSString string];
        if([model.audioUrl isKindOfClass:[NSURL class]]){
            urlStr = (NSString *)[model.audioUrl absoluteString];
        }else{
            urlStr = @"";
        }
        if ([urlStr rangeOfString:@"//"].location != NSNotFound) {
            NSString *path = [[urlStr componentsSeparatedByString:@"//"] lastObject];
            NSString *wholePath = [[DFPlayerFileManager df_playerUserCachePath] stringByAppendingPathComponent:path];
            if ([[NSFileManager defaultManager] fileExistsAtPath:wholePath]) {
                [cacheArr addObject:model];
            }
        }else{
        }
    }
    return cacheArr;
}


/**
 检查当前链接是否缓存

 @param url url
 @return 缓存文件路径
 */
- (NSString *)df_playerCheckIsCachedWithUrl:(NSURL *)url{
    if (![url isKindOfClass:[NSURL class]]) {return nil;}
    if ([url.scheme isEqualToString:@"file"]) {return nil;}
    if (url) {
        NSString *cacheFilePath = [DFPlayerFileManager df_isExistAudioFileWithURL:url];
        if (cacheFilePath) {return cacheFilePath;}
    }
    return nil;
}

/**
 计算DFPlayer缓存大小
 
 @param isCurrentUser YES 计算当前用户文件夹大小  NO所有用户
 @return 大小
 */
+ (CGFloat)df_playerCountCacheSizeForCurrentUser:(BOOL)isCurrentUser{
    return [DFPlayerFileManager df_countCacheSizeForCurrentUser:isCurrentUser];
}

/**
 清除缓存
 
 @param isClearCurrentUser YES 清除当前用户缓存  NO清除DFPlayer所有用户缓存
 @param block 是否清除成功 错误信息
 */
+ (void)df_playerClearCacheForCurrentUser:(BOOL)isClearCurrentUser
                                    block:(void(^)(BOOL isSuccess, NSError *error))block{
    [DFPlayerFileManager df_clearCacheForCurrentUser:isClearCurrentUser block:^(BOOL isSuccess, NSError *error) {
        if (block) {
            block(isSuccess,error);
        }
    }];
}
/**计算系统磁盘空间 剩余可用空间*/
+ (void)df_countSystemSizeBlock:(void(^)(CGFloat totalSize,CGFloat freeSize,BOOL isSuccess))block{
    [DFPlayerFileManager df_countSystemSizeBlock:^(CGFloat totalSize, CGFloat freeSize, BOOL isSuccess) {
        if (block) {
            block(totalSize,freeSize,isSuccess);
        }
    }];
}

#pragma mark - 统一错误代理
- (void)playfailureWithErrorMessage:(NSString *)errorMessage{
    if (errorMessage) {
        DFLog(@"--errorMessage:%@",errorMessage);
        if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:didFailWithErrorMessage:)]) {
            [self.delegate df_player:self didFailWithErrorMessage:errorMessage];
        }
    }
}

@end



