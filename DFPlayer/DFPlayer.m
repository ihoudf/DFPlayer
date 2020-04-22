//
//  DFPlayer.m
//  DFPlayer
//
//  Created by ihoudf on 2017/7/18.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import "DFPlayer.h"
#import "DFPlayerFileManager.h"
#import "DFPlayerResourceLoader.h"
#import "DFPlayerTool.h"
#import <MediaPlayer/MediaPlayer.h>

/**Asset KEY*/
NSString * const DFPlayableKey                  = @"playable";
/**PlayerItem KEY*/
NSString * const DFStatusKey                    = @"status";
NSString * const DFLoadedTimeRangesKey          = @"loadedTimeRanges";
NSString * const DFPlaybackBufferEmptyKey       = @"playbackBufferEmpty";
NSString * const DFPlaybackLikelyToKeepUpKey    = @"playbackLikelyToKeepUp";

@interface DFPlayer()<DFPlayerResourceLoaderDelegate>
{
    BOOL _isOtherPlaying; // 其他应用是否正在播放
    BOOL _isBackground; // 是否进入后台
    BOOL _isCached; // 当前音频是否缓存
    BOOL _isSeek; // 正在seek
    BOOL _isSeekWaiting; // seek 等待
    BOOL _isNaturalToEndTime; // 是否是自然结束
    dispatch_group_t _netGroupQueue; // 组队列-网络
    dispatch_group_t _dataGroupQueue; // 组队列-数据
    NSInteger _currentAudioId; // 当前正在播放的音频Id
    NSInteger _randomIndex; // 随机数组元素index
    NSInteger _playIndex1; // 播放顺序标识
    NSInteger _playIndex2; // 播放顺序标识
    CGFloat _seekValue; // seek value
    NSMutableDictionary *_remoteInfoDictionary; // 控制中心信息
}
/** player */
@property (nonatomic, strong) AVPlayer          *player;
/** playerItem */
@property (nonatomic, strong) AVPlayerItem      *playerItem;
/** 播放进度监测 */
@property (nonatomic, strong) id                timeObserver;
/** 随机数组 */
@property (nonatomic, strong) NSMutableArray    *randomIndexArray;
/** 资源下载器 */
@property (nonatomic, strong) DFPlayerResourceLoader *resourceLoader;
/** model数据数组 */
@property (nonatomic, strong) NSMutableArray<DFPlayerModel *> *playerModelArray;

@property (nonatomic, copy) void(^seekCompletionBlock)(void);

@property (nonatomic, readwrite, strong) DFPlayerModel *currentAudioModel;
@property (nonatomic, readwrite, strong) DFPlayerInfoModel *currentAudioInfoModel;
@property (nonatomic, readwrite, assign) DFPlayerState state;
@property (nonatomic, readwrite, assign) CGFloat bufferProgress;
@property (nonatomic, readwrite, assign) CGFloat progress;
@property (nonatomic, readwrite, assign) CGFloat currentTime;
@property (nonatomic, readwrite, assign) CGFloat totalTime;

@end

@implementation DFPlayer

#pragma mark - 初始化
+ (DFPlayer *)sharedPlayer {
    static DFPlayer *player = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        player = [[[self class] alloc] init];
    });
    return player;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 初始化播放器
- (void)df_initPlayerWithUserId:(NSString *)userId{
    [DFPlayerFileManager df_saveUserId:userId];
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    _isOtherPlaying = [AVAudioSession sharedInstance].otherAudioPlaying;
    
    self.playMode = DFPlayerModeOnlyOnce;
    self.state = DFPlayerStateStopped;
    self.isObserveProgress          = YES;
    self.isObserveBufferProgress    = YES;
    self.isNeedCache                = YES;
    self.isObserveFileModifiedTime  = NO;
    self.isObserveWWAN              = NO;
    _isCached       = NO;
    _isBackground   = NO;
    _randomIndex    = -1;
    _playIndex2     = 0;
    
    _netGroupQueue  = dispatch_group_create();
    _dataGroupQueue = dispatch_group_create();
    
    [self addNetObserver];
    [self addPlayerObserver];
    [self addRemoteControlHandler];
}

- (void)addNetObserver{
    static dispatch_once_t token1;
    dispatch_once(&token1, ^{
        dispatch_group_enter(self->_netGroupQueue);
    });
    dispatch_group_async(_netGroupQueue, DFPlayerDefaultGlobalQueue, ^{
        [DFPlayerTool startMonitoringNetworkStatus:^(DFPlayerNetworkStatus networkStatus) {
            static dispatch_once_t token2;
            dispatch_once(&token2, ^{
                dispatch_group_leave(self->_netGroupQueue);
            });
        }];
    });
}

- (void)addPlayerObserver{
    //将要进入后台
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(df_playerWillResignActive)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    //已经进入前台
    [notificationCenter addObserver:self
                           selector:@selector(df_playerDidEnterForeground)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    //监测耳机
    [notificationCenter addObserver:self
                           selector:@selector(df_playerAudioRouteChange:)
                               name:AVAudioSessionRouteChangeNotification
                             object:nil];
    //监听播放器被打断（别的软件播放音乐，来电话）
    [notificationCenter addObserver:self
                           selector:@selector(df_playerAudioBeInterrupted:)
                               name:AVAudioSessionInterruptionNotification
                             object:[AVAudioSession sharedInstance]];
    //监测其他app是否占据AudioSession
    [notificationCenter addObserver:self
                           selector:@selector(df_playerSecondaryAudioHint:)
                               name:AVAudioSessionSilenceSecondaryAudioHintNotification
                             object:nil];
}

- (void)df_playerWillResignActive{
    _isBackground = YES;
}

- (void)df_playerDidEnterForeground{
    _isBackground = NO;
}

- (void)df_playerAudioRouteChange:(NSNotification *)notification{
    NSInteger routeChangeReason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable://耳机插入
            if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isHeadphone:)]) {
                [self.delegate df_player:self isHeadphone:YES];
            }
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable://耳机拔出，停止播放操作
            if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isHeadphone:)]) {
                [self.delegate df_player:self isHeadphone:NO];
            }else{
                [self df_pause];
            }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            //
            break;
        default:
            break;
    }
}

- (void)df_playerAudioBeInterrupted:(NSNotification *)notification{
    NSDictionary *dic = notification.userInfo;
    if ([dic[AVAudioSessionInterruptionTypeKey] integerValue] == 1) {//打断开始
        if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isInterrupted:)]) {
            [self.delegate df_player:self isInterrupted:YES];
        }else{
            [self df_pause];
        }
    }else {//打断结束
        if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isInterrupted:)]) {
            [self.delegate df_player:self isInterrupted:NO];
        }else{
            if ([notification.userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue] == 1) {
                [self df_play];
            }
        }
    }
}

- (void)df_playerSecondaryAudioHint:(NSNotification *)notification{
    //    NSInteger type = [notification.userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] integerValue];
}

-(void)df_playerDidPlayToEndTime:(NSNotification *)notification{
    if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerDidPlayToEndTime:)]) {
        [self.delegate df_playerDidPlayToEndTime:self];
    }else{
        _isNaturalToEndTime = YES;
        [self df_next];
    }
}

/**远程线控*/
- (void)addRemoteControlHandler{
    if (@available (iOS 7.1, *)) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
        [self addRemoteCommand:center.playCommand selector:@selector(df_play)];
        [self addRemoteCommand:center.pauseCommand selector:@selector(df_pause)];
        [self addRemoteCommand:center.previousTrackCommand selector:@selector(df_last)];
        [self addRemoteCommand:center.nextTrackCommand selector:@selector(df_next)];
        [center.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            if ([DFPlayer sharedPlayer].state == DFPlayerStatePlaying) {
                [[DFPlayer sharedPlayer] df_pause];
            }else{
                [[DFPlayer sharedPlayer] df_play];
            }
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        
        if (@available (iOS 9.1,*)) {
            [center.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
                MPChangePlaybackPositionCommandEvent *positionEvent = (MPChangePlaybackPositionCommandEvent *)event;
                if (self.totalTime > 0) {
                    [self df_seekToTime:positionEvent.positionTime / self.totalTime completionBlock:nil];
                }
                return MPRemoteCommandHandlerStatusSuccess;
            }];
        }
    }
}

- (void)addRemoteCommand:(MPRemoteCommand *)command selector:(SEL)selector{
    [command addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if ([self respondsToSelector:selector]) {
            IMP imp = [self methodForSelector:selector];
            void (*func)(id, SEL) = (void *)imp;
            func(self, selector);
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

#pragma mark - 数据源

- (void)df_reloadData{
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(df_audioDataForPlayer:)]) {
        if (!self.playerModelArray) {
            self.playerModelArray = [NSMutableArray array];
        }
        if (self.playerModelArray.count != 0) {
            [self.playerModelArray removeAllObjects];
        }
        dispatch_group_enter(_dataGroupQueue);
        dispatch_group_async(_dataGroupQueue, DFPlayerHighGlobalQueue, ^{
            dispatch_async(DFPlayerHighGlobalQueue, ^{
                
                [self.playerModelArray addObjectsFromArray:[self.dataSource df_audioDataForPlayer:self]];
                
                //更新随机数组
                [self updateRandomIndexArray];
                
                //更新currentAudioId
                if (self.currentAudioModel.audioUrl) {
                    [self.playerModelArray enumerateObjectsWithOptions:(NSEnumerationConcurrent) usingBlock:^(DFPlayerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj.audioUrl.absoluteString isEqualToString:self.currentAudioModel.audioUrl.absoluteString]) {
                            self.currentAudioModel.audioId = idx;
                            self->_currentAudioId = idx;
                            *stop = YES;
                        }
                    }];
                }
                dispatch_group_leave(self->_dataGroupQueue);
            });
        });
    }
}

#pragma mark - 播放 IMPORTANT

- (void)df_playWithAudioId:(NSUInteger)audioId{
    dispatch_group_notify(_dataGroupQueue, DFPlayerHighGlobalQueue, ^{
        if (self.playerModelArray.count > audioId) {
            self.currentAudioModel = self.playerModelArray[audioId];
            self->_currentAudioId = audioId;
            [self audioPrePlay];
        }
    });
}

- (void)audioPrePlay{
    [self reset];

    if (![DFPlayerTool isNSURL:self.currentAudioModel.audioUrl]) {
        return;
    }

    if (self.dataSource && [self.dataSource respondsToSelector:@selector(df_audioInfoForPlayer:)]) {
        self.currentAudioInfoModel = [self.dataSource df_audioInfoForPlayer:self];
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerAudioAddToPlayQueue:)]) {
        [self.delegate df_playerAudioAddToPlayQueue:self];
    }

    if ([DFPlayerTool isLocalAudio:self.currentAudioModel.audioUrl]) {
//        NSLog(@"-- DFPlayer：本地音频，Id：%ld",(unsigned long)self.currentAudioModel.audioId);
        _isCached = YES;
        [self loadPlayerItemWithURL:self.currentAudioModel.audioUrl];
    }else{
        NSString *cachePath = [DFPlayerFileManager df_cachePath:self.currentAudioModel.audioUrl];
        _isCached = cachePath ? YES : NO;
//        NSLog(@"-- DFPlayer：网络音频，Id：%ld 缓存：%@",(unsigned long)self.currentAudioModel.audioId, cachePath ? @"有" : @"无");
        dispatch_group_notify(_netGroupQueue, DFPlayerDefaultGlobalQueue, ^{
            if ([DFPlayerTool networkStatus] == DFPlayerNetworkStatusUnknown ||
                [DFPlayerTool networkStatus] == DFPlayerNetworkStatusNotReachable){
                if (cachePath){//有缓存，播放缓存
                    [self loadPlayerItemWithURL:[NSURL fileURLWithPath:cachePath]];
                }else{//无缓存，提示联网
                    [self df_getStatusCode:DFPlayerStatusNoNetwork];
                }
            }else{
                if (!self.isNeedCache){//不需要缓存
                    // WWAN网络警告
                    if (self.isObserveWWAN && [DFPlayerTool networkStatus] == DFPlayerNetworkStatusReachableViaWWAN) {
                        [self df_getStatusCode:DFPlayerStatusViaWWAN];
                        return;
                    }
                    [self loadPlayerItemWithURL:self.currentAudioModel.audioUrl];
                }else{//需要缓存
                    if (cachePath && !self.isObserveFileModifiedTime) {
                        //有缓存且不监听改变时间，直接播放缓存
                        [self loadPlayerItemWithURL:[NSURL fileURLWithPath:cachePath]];
                    }else{//无缓存 或 需要兼听
                        // WWAN网络警告
                        if (self.isObserveWWAN && [DFPlayerTool networkStatus] == DFPlayerNetworkStatusReachableViaWWAN) {
                            [self df_getStatusCode:DFPlayerStatusViaWWAN];
                            return;
                        }
                        [self loadAudioWithCachePath:cachePath];
                    }
                }
            }
        });
    }
}

- (void)loadAudioWithCachePath:(NSString *)cachePath{
    self.resourceLoader = [[DFPlayerResourceLoader alloc] init];
    self.resourceLoader.delegate = self;
    self.resourceLoader.isCached = _isCached;
    self.resourceLoader.isObserveFileModifiedTime = self.isObserveFileModifiedTime;
    
    NSURL *customUrl = [DFPlayerTool customURL:self.currentAudioModel.audioUrl];
    if (!customUrl) {
        return;
    }
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:customUrl options:nil];
    [asset.resourceLoader setDelegate:self.resourceLoader queue:dispatch_get_main_queue()];
    [asset loadValuesAsynchronouslyForKeys:@[DFPlayableKey] completionHandler:^{
        dispatch_async( dispatch_get_main_queue(),^{
            if (!asset.playable) {
                self.state = DFPlayerStateFailed;
                [self.resourceLoader stopDownload];
                [asset cancelLoading];
            }
        });
    }];
    DFPlayerWeakSelf
    self.resourceLoader.checkStatusBlock = ^(NSInteger statusCode){
        DFPlayerStrongSelf
        if (statusCode == 200) {
            [sSelf loadPlayerItemWithAsset:asset];
        }else if (statusCode == 304) { // 服务器文件未变化
            [sSelf loadPlayerItemWithURL:[NSURL fileURLWithPath:cachePath]];
        }else if (statusCode == 206){
            
        }
    };
}

- (void)loadPlayerItemWithURL:(NSURL *)URL{
    self.playerItem = [[AVPlayerItem alloc] initWithURL:URL];
    [self loadPlayer];
}

- (void)loadPlayerItemWithAsset:(AVURLAsset *)asset{
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self loadPlayer];
}

- (void)loadPlayer{
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    if (@available(iOS 10.0,*)) {
        self.player.automaticallyWaitsToMinimizeStalling = NO;
    }
    [self df_play];
    [self addProgressObserver];
    [self addPlayingCenterInfo];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == self.player.currentItem) {
        if ([keyPath isEqualToString:DFStatusKey]) {
            AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            switch (status) {
                case AVPlayerItemStatusUnknown:
                    self.state = DFPlayerStateFailed;
                    [self df_getStatusCode:DFPlayerStatusUnknown];
                    break;
                case AVPlayerItemStatusReadyToPlay:
                    if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerReadyToPlay:)]) {
                        [self.delegate df_playerReadyToPlay:self];
                    }
                    break;
                case AVPlayerItemStatusFailed:
                    self.state = DFPlayerStateFailed;
                    [self df_getStatusCode:DFPlayerStatusFailed];
                    break;
                default:
                    break;
            }
        }else if ([keyPath isEqualToString:DFLoadedTimeRangesKey]) {
            [self addBufferProgressObserver];
        }else if ([keyPath isEqualToString:DFPlaybackBufferEmptyKey]) {
            if (self.playerItem.playbackBufferEmpty) {
                self.state = DFPlayerStateBuffering;
            }
        }else if ([keyPath isEqualToString:DFPlaybackLikelyToKeepUpKey]) {
            
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - DFPlayerResourceLoaderDelegate
/**下载出错*/
- (void)loader:(DFPlayerResourceLoader *)loader requestError:(NSInteger)errorCode{
    if (errorCode == NSURLErrorTimedOut) {
        [self df_getStatusCode:DFPlayerStatusTimeOut];
    }else if ([DFPlayerTool networkStatus] == DFPlayerNetworkStatusNotReachable ||
              [DFPlayerTool networkStatus] == DFPlayerNetworkStatusUnknown) {
        [self df_getStatusCode:DFPlayerStatusNoNetwork];
    }
}

/**是否完成缓存*/
- (void)loader:(DFPlayerResourceLoader *)loader isCached:(BOOL)isCached{
    _isCached = isCached;
    NSUInteger status = isCached ? DFPlayerStatusCacheSucc : DFPlayerStatusCacheFail;
    [self df_getStatusCode:status];
}


#pragma mark - 缓冲进度 播放进度 歌曲锁屏信息 音频跳转

- (void)addBufferProgressObserver{
    self.totalTime = CMTimeGetSeconds(self.playerItem.duration);
    if (!self.isObserveBufferProgress) {
        return;
    }
    CMTimeRange timeRange   = [self.playerItem.loadedTimeRanges.firstObject CMTimeRangeValue];
    CGFloat startSeconds    = CMTimeGetSeconds(timeRange.start);
    CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
    if (self.totalTime != 0) {//避免出现inf
        self.bufferProgress = (startSeconds + durationSeconds) / self.totalTime;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:bufferProgress:)]) {
        [self.delegate df_player:self bufferProgress:self.bufferProgress];
    }

    if (_isSeekWaiting) {
        if (self.bufferProgress > _seekValue) {
            _isSeekWaiting = NO;
            [self didSeekToTime:_seekValue completionBlock:^{
                if (self.seekCompletionBlock) {
                    self.seekCompletionBlock();
                }
            }];
        }
    }
}

- (void)addProgressObserver{
    if (!self.isObserveProgress) {
        return;
    }

    DFPlayerWeakSelf
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0, 1.0) queue:nil usingBlock:^(CMTime time){
        DFPlayerStrongSelf
        if (sSelf->_isSeek) {
            return;
        }
        AVPlayerItem *currentItem = sSelf.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0){
            CGFloat currentT = (CGFloat)CMTimeGetSeconds(time);
            sSelf.currentTime = currentT;
            if (sSelf.totalTime != 0) {//避免出现inf
                sSelf.progress = CMTimeGetSeconds([currentItem currentTime]) / sSelf.totalTime;
            }
            if (sSelf.delegate && [sSelf.delegate respondsToSelector:@selector(df_player:progress:currentTime:)]) {
                [sSelf.delegate df_player:sSelf progress:sSelf.progress currentTime:currentT];
            }

            [sSelf updatePlayingCenterInfo];
        }
    }];
}

- (void)addPlayingCenterInfo{
    _remoteInfoDictionary = [NSMutableDictionary dictionary];
    
    if (self.currentAudioInfoModel.audioName) {
        _remoteInfoDictionary[MPMediaItemPropertyTitle] = self.currentAudioInfoModel.audioName;
    }
    if (self.currentAudioInfoModel.audioAlbum) {
        _remoteInfoDictionary[MPMediaItemPropertyAlbumTitle] = self.currentAudioInfoModel.audioAlbum;
    }
    if (self.currentAudioInfoModel.audioSinger) {
        _remoteInfoDictionary[MPMediaItemPropertyArtist] = self.currentAudioInfoModel.audioSinger;
    }
    if ([self.currentAudioInfoModel.audioImage isKindOfClass:[UIImage class]] && self.currentAudioInfoModel.audioImage) {
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:self.currentAudioInfoModel.audioImage];
        _remoteInfoDictionary[MPMediaItemPropertyArtwork] = artwork;
    }
    _remoteInfoDictionary[MPNowPlayingInfoPropertyPlaybackRate] = [NSNumber numberWithFloat:1.0];
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = _remoteInfoDictionary;
}

- (void)updatePlayingCenterInfo{
    if (!_isBackground) {return;}
    _remoteInfoDictionary[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithDouble:CMTimeGetSeconds(self.playerItem.currentTime)];
    _remoteInfoDictionary[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithDouble:CMTimeGetSeconds(self.playerItem.duration)];
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = _remoteInfoDictionary;
}

- (void)df_seekToTime:(CGFloat)value completionBlock:(void (^)(void))completionBlock{
    _isSeek = YES;
    // 先暂停
    if (self.state == DFPlayerStatePlaying) {
        [self df_pause];
    }
    if (self.bufferProgress < value) {
        _isSeekWaiting = YES;
        _seekValue = value;
        if (completionBlock) {
            self.seekCompletionBlock = completionBlock;
        }
    }else{
        _isSeekWaiting = NO;
        [self didSeekToTime:value completionBlock:completionBlock];
    }
}

- (void)didSeekToTime:(CGFloat)value completionBlock:(void (^)(void))completionBlock{
    [self.player seekToTime:CMTimeMake(floorf(self.totalTime * value), 1)
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero
          completionHandler:^(BOOL finished) {
        if (finished) {
            [self df_play];
            self->_isSeek = NO;
            if (completionBlock) {
                completionBlock();
            }
        }
    }];
}

/**倍速播放*/
- (void)df_setRate:(CGFloat)rate{
    for (AVPlayerItemTrack *track in self.playerItem.tracks){
        if ([track.assetTrack.mediaType isEqual:AVMediaTypeAudio]){
            track.enabled = YES;
        }
    }
    self.player.rate = rate;
}

/**释放播放器*/
- (void)df_deallocPlayer{
    
    [self reset];
    
    self.state = DFPlayerStateStopped;
    
    [DFPlayerTool stopMonitoringNetwork];
    
    if (@available(iOS 7.1, *)) {
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
        MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
        [[center playCommand] removeTarget:self];
        [[center pauseCommand] removeTarget:self];
        [[center nextTrackCommand] removeTarget:self];
        [[center previousTrackCommand] removeTarget:self];
        [[center togglePlayPauseCommand] removeTarget:self];
        if(@available(iOS 9.1, *)) {
            [center.changePlaybackPositionCommand removeTarget:self];
        }
    }
    
    if (_isOtherPlaying) {
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    }else{
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
    }
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    
    if (self.randomIndexArray) {
        self.randomIndexArray = nil;
    }
    
    if (self.playerModelArray) {
        self.playerModelArray = nil;
    }
    
    if (self.playerItem) {
        self.playerItem = nil;
    }
    
    if (self.player) {
        self.player = nil;
    }
}

- (void)reset{
    if (self.state == DFPlayerStatePlaying) {
        [self df_pause];
    }
    
    //停止下载
    if (self.resourceLoader) {
        [self.resourceLoader stopDownload];
    }
    
    //移除进度观察者
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    
    //重置
    self.progress = .0f;
    self.bufferProgress = .0f;
    self.currentTime = .0f;
    self.totalTime = .0f;
    _isSeekWaiting = NO;
}

#pragma mark - 播放 暂停 下一首 上一首
/**播放*/
-(void)df_play{
    self.state = DFPlayerStatePlaying;
    [self.player play];
}

/**暂停*/
-(void)df_pause{
    self.state = DFPlayerStatePause;
    [self.player pause];
}

/**下一首*/
- (void)df_next{
    switch (self.playMode) {
        case DFPlayerModeOnlyOnce:
            if (_isNaturalToEndTime) {
                _isNaturalToEndTime = NO;
                [self df_pause];
            }else{
                [self next];
            }
            break;
        case DFPlayerModeSingleCycle:
            if (_isNaturalToEndTime) {
                _isNaturalToEndTime = NO;
                [self audioPrePlay];
            }else{
                [self next];
            }
            break;
        case DFPlayerModeOrderCycle:
            [self next];
            break;
        case DFPlayerModeShuffleCycle:{
            _playIndex2++;
            _currentAudioId = [self randomAudioId];
            self.currentAudioModel = self.playerModelArray[_currentAudioId];
            [self audioPrePlay];
            break;
        }
        default:
            break;
    }
}

/**上一首*/
- (void)df_last{
    if (self.playMode == DFPlayerModeShuffleCycle) {
        if (_playIndex2 == 1) {
            _playIndex2 = 0;
            self.currentAudioModel = self.playerModelArray[_playIndex1];
        }else{
            _currentAudioId = [self randomAudioId];
            self.currentAudioModel = self.playerModelArray[_currentAudioId];
        }
        [self audioPrePlay];
    }else{
        _currentAudioId--;
        if (_currentAudioId < 0) {
            _currentAudioId = self.playerModelArray.count - 1;
        }
        self.currentAudioModel = self.playerModelArray[_currentAudioId];
        [self audioPrePlay];
    }
}

- (void)next{
    _currentAudioId++;
    if (_currentAudioId < 0 || _currentAudioId >= self.playerModelArray.count) {
        _currentAudioId = 0;
    }
    _playIndex1 = _currentAudioId;
    _playIndex2 = 0;
    self.currentAudioModel = self.playerModelArray[_currentAudioId];
    [self audioPrePlay];
}


#pragma mark - 随机播放相关

- (void)updateRandomIndexArray{
    NSInteger startIndex = 0;
    NSInteger length = self.playerModelArray.count;
    NSInteger endIndex = startIndex+length;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:length];
    NSMutableArray *arr1 = [NSMutableArray arrayWithCapacity:length];
    for (NSInteger i = startIndex; i < endIndex; i++) {
        @autoreleasepool {
            NSString *str = [NSString stringWithFormat:@"%ld",(long)i];
            [arr1 addObject:str];
        }
    }
    for (NSInteger i = startIndex; i < endIndex; i++) {
        @autoreleasepool {
            int index = arc4random()%arr1.count;
            int radom = [arr1[index] intValue];
            NSNumber *num = [NSNumber numberWithInt:radom];
            [arr addObject:num];
            [arr1 removeObjectAtIndex:index];
        }
    }
    _randomIndexArray = [NSMutableArray arrayWithArray:arr];
}

- (NSInteger)randomAudioId{
    _randomIndex++;
    if (_randomIndex >= self.randomIndexArray.count) {
        _randomIndex = 0;
    }
    if (_randomIndex < 0) {
        _randomIndex = self.randomIndexArray.count - 1;
    }
    NSInteger index = [self.randomIndexArray[_randomIndex] integerValue];
    //去重
    if (index == _currentAudioId) {
        index = [self randomAudioId];
    }
    return index;
}

#pragma mark - setter

- (void)setCategory:(AVAudioSessionCategory)category{
    [[AVAudioSession sharedInstance] setCategory:category error:nil];
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem{
    if (_playerItem == playerItem) {
        return;
    }
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

#pragma mark - 缓存相关
- (NSString *)df_cachePath:(NSURL *)audioUrl{
    if ([DFPlayerTool isLocalAudio:audioUrl] || ![DFPlayerTool isNSURL:audioUrl] || !audioUrl) {
        return nil;
    }
    return [DFPlayerFileManager df_cachePath:audioUrl];
}

- (CGFloat)df_cacheSize:(BOOL)currentUser{
    return [DFPlayerFileManager df_cacheSize:currentUser];
}

- (BOOL)df_clearAudioCache:(NSURL *)audioUrl{
    return [DFPlayerFileManager df_clearAudioCache:audioUrl];
}

- (BOOL)df_clearUserCache:(BOOL)currentUser{
    return [DFPlayerFileManager df_clearUserCache:currentUser];
}


#pragma mark - 统一状态代理
- (void)df_getStatusCode:(NSUInteger)statusCode{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:didGetStatusCode:)]) {
            [self.delegate df_player:self didGetStatusCode:statusCode];
        }
    });
}

@end



