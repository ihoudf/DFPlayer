//
//  DFPlayer.m
//  DFPlayer
//
//  Created by HDF on 2017/7/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayer.h"
#import "DFPlayerFileManager.h"
#import "DFPlayerResourceLoader.h"
#import "DFPlayerTool.h"
#import "DFPlayerRemoteApplication.h"
/**类型KEY*/
NSString * const DFPlayerTypeKey                = @"DFPlayerType";
/**Asset KEY*/
NSString * const DFPlayableKey                  = @"playable";
/**PlayerItem KEY*/
NSString * const DFStatusKey                    = @"status";
NSString * const DFLoadedTimeRangesKey          = @"loadedTimeRanges";
NSString * const DFPlaybackBufferEmptyKey       = @"playbackBufferEmpty";
NSString * const DFPlaybackLikelyToKeepUpKey    = @"playbackLikelyToKeepUp";

//网络状态
typedef NS_ENUM(NSInteger, DFPlayerNetworkStatus) {
    DFPlayerNetworkStatusUnknown          = -1, //未知
    DFPlayerNetworkStatusNotReachable     = 0,  //无网络链接
    DFPlayerNetworkStatusReachableViaWWAN = 1,  //2G/3G/4G
    DFPlayerNetworkStatusReachableViaWiFi = 2   //WIFI
};

@interface DFPlayer()<DFPlayerResourceLoaderDelegate>
/**网络状态*/
@property (nonatomic, assign) DFPlayerNetworkStatus   networkStatus;
/**其他应用是否正在播放*/
@property (nonatomic, assign) BOOL              isOthetPlaying;
/**是否正在播放*/
@property (nonatomic, assign) BOOL              isPlaying;
/**是否进入后台*/
@property (nonatomic, assign) BOOL              isBackground;
/**组队列-网络*/
@property (nonatomic, strong) dispatch_group_t  netGroupQueue;
/**组队列-数据*/
@property (nonatomic, strong) dispatch_group_t  dataGroupQueue;
/**HIGH全局并发队列*/
@property (nonatomic, strong) dispatch_queue_t  HighGlobalQueue;
/**DEFAULT全局并发队列*/
@property (nonatomic, strong) dispatch_queue_t  defaultGlobalQueue;
/**player*/
@property (nonatomic, strong) AVPlayer          *player;
/**playerItem*/
@property (nonatomic, strong) AVPlayerItem      *playerItem;
/**播放进度监测*/
@property (nonatomic, strong) id                timeObserver;
/**当前正在播放的音频Id*/
@property (nonatomic, assign) NSInteger         currentAudioTag;
/**随机数组*/
@property (nonatomic, strong) NSMutableArray    *randomIndexArray;
/**随机数组元素index*/
@property (nonatomic, assign) NSInteger         randomIndex;
/**播放顺序标识*/
@property (nonatomic, assign) NSInteger         playIndex1;
/**播放顺序标识*/
@property (nonatomic, assign) NSInteger         playIndex2;
/**播放进度是否被拖拽了*/
@property (nonatomic, assign) BOOL              isDraged;
/**当前音频是否缓存*/
@property (nonatomic, assign) BOOL              isCached;
/**seek 等待*/
@property (nonatomic, assign) BOOL              isSeekWaiting;
/**seek value*/
@property (nonatomic, assign) CGFloat           seekValue;
/**是否有某个音频播放过*/
@property (nonatomic, assign) BOOL              isAnAudioPlayed;
/**是否是自然结束*/
@property (nonatomic, assign) BOOL              isNaturalToEndTime;
/**音频信息model*/
@property (nonatomic, strong) DFPlayerInfoModel                 *currentAudioInfoModel;
/**历史model*/
@property (nonatomic, strong) DFPlayerPreviousAudioModel        *previousAudioModel;
/**资源下载器*/
@property (nonatomic, strong) DFPlayerResourceLoader            *resourceLoader;
/**model数据数组*/
@property (nonatomic, strong) NSMutableArray<DFPlayerModel *>   *playerModelArray;


@end

@implementation DFPlayer

#pragma mark - INIT
+ (DFPlayer *)shareInstance {
    static DFPlayer *instance = nil;
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
- (void)df_initPlayerWithUserId:(NSString *)userId{
    //记录用户
    [self initPlayerCachePathWithUserId:userId];
    //添加观察者
    [self addPlayerObserver];

    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];

    self.isOthetPlaying = [AVAudioSession sharedInstance].otherAudioPlaying;
    
    NSInteger user_playerType = [[NSUserDefaults standardUserDefaults] integerForKey:DFPlayerTypeKey];
    self.type = user_playerType?user_playerType:DFPlayerTypeSingleCycle;
    self.state = DFPlayerStateStopped;
    self.isObserveProgress          = YES;
    self.isObserveBufferProgress    = YES;
    self.isNeedCache                = YES;
    self.isRemoteControl            = YES;
    self.isObserveFileModifiedTime  = NO;
    self.isObservePreviousAudioModel= NO;
    self.isHeadPhoneAutoPlay        = NO;
    self.isAnAudioPlayed            = NO;
    self.isObserveWWAN              = NO;
    self.isBackground               = NO;
    self.isCached                   = NO;
    self.isManualToPlay             = YES;
    self.randomIndex                = -1;
    self.playIndex2                 = 0;
}

#pragma mark - 监测网络 监听播放结束 耳机插拔 播放器被打断
- (void)addPlayerObserver{
    self.defaultGlobalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.HighGlobalQueue    = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    self.netGroupQueue      = dispatch_group_create();
    self.dataGroupQueue     = dispatch_group_create();
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_group_enter(self.netGroupQueue);
    });
    dispatch_group_async(self.netGroupQueue, self.defaultGlobalQueue, ^{
        [DFPlayerTool checkNetworkReachable:^(NSInteger networkStatus) {
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
            static dispatch_once_t onceTokens;
            dispatch_once(&onceTokens, ^{
                dispatch_group_leave(self.netGroupQueue);
            });
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
    //通知播放
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPrePlayToLoadPreviousAudio) name:@"DFPlayerLoadPreviousAudioModelNotification" object:nil];
}

- (void)df_playerDidEnterForeground{
    NSLog(@"-- DFPlayer： 将要进入前台");
    self.isBackground = NO;
}
- (void)df_playerWillResignActive{
    NSLog(@"-- DFPlayer： 将要进入后台");
    self.isBackground = YES;
}

- (void)df_playerDidEnterBackground{
    NSLog(@"-- DFPlayer： 已经进入后台，当前播放模式:%ld",(long)self.category);
    if (self.category != DFPlayerAudioSessionCategoryPlayback) {
        [self recordCurrentAudioInfoModel];
    }
}
- (void)df_playerWillTerminate{
    NSLog(@"-- DFPlayer： 程序将要终止，当前播放模式:%ld",(long)self.category);
    [self df_dellecPlayer];
    if (self.category == DFPlayerAudioSessionCategoryPlayback) {
        [self recordCurrentAudioInfoModel];
    }
}
- (void)recordCurrentAudioInfoModel{
    //记录信息
    if (self.isObservePreviousAudioModel && self.currentAudioModel && self.isAnAudioPlayed) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        if (self.currentAudioModel.audioId) {
            [dic setObject:[NSNumber numberWithUnsignedInteger:self.currentAudioModel.audioId]
                    forKey:DFPlayerCurrentAudioInfoModelAudioId];
        }
        if (self.currentAudioModel.audioUrl && [self.currentAudioModel.audioUrl isKindOfClass:[NSURL class]]) {
            [dic setObject:[self.currentAudioModel.audioUrl absoluteString]
                    forKey:DFPlayerCurrentAudioInfoModelAudioUrl];
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
        NSLog(@"-- DFPlayer： 播放信息保存完成");
    }
}

- (void)df_playerAudioRouteChange:(NSNotification *)notification {
    NSInteger routeChangeReason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable://耳机插入
            if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isHeadphone:)]) {
                [self.delegate df_player:self isHeadphone:YES];
            }else{
                if (self.isHeadPhoneAutoPlay && self.currentAudioModel) {
                    [self df_audioPlay];
                }
            }
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable://耳机拔出，停止播放操作
            if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isHeadphone:)]) {
                [self.delegate df_player:self isHeadphone:NO];
            }else{
                [self df_audioPause];
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
    if ([dic[AVAudioSessionInterruptionTypeKey] integerValue] == 1) {//打断开始
        NSLog(@"-- DFPlayer： 音频被打断开始");
        [self recordCurrentAudioInfoModel];//打断时也要记录信息
        if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isInterruptedBegin:)]) {
            [self.delegate df_player:self isInterruptedBegin:YES];
        }else{
            [self df_audioPause];
        }
    }else {//打断结束
        NSLog(@"-- DFPlayer： 音频被打断结束");
        if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:isInterruptedBegin:)]) {
            [self.delegate df_player:self isInterruptedBegin:NO];
        }else{
            if ([notification.userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue] == 1) {
                NSLog(@"-- DFPlayer： -能够恢复播放");
                [self df_audioPlay];
            }
        }
    }
}

- (void)df_playerSecondaryAudioHint:(NSNotification *)notification{
    NSInteger type = [notification.userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] integerValue];
    if (type == 1) {//开始被其他音频占据
        NSLog(@"-- DFPlayer： 其他音频占据开始");
    }else{//占据结束
        NSLog(@"-- DFPlayer： 其他音频占据结束");
    }
}

-(void)df_playerDidPlayToEndTime:(NSNotification *)notification{
    self.isNaturalToEndTime = YES;
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
        dispatch_group_enter(self.dataGroupQueue);
        dispatch_group_async(self.dataGroupQueue, self.HighGlobalQueue, ^{
            dispatch_async(self.HighGlobalQueue, ^{
                [self.playerModelArray addObjectsFromArray:[self.dataSource df_playerModelArray]];

                //更新数据时更新audioId
                if (self.currentAudioModel.audioUrl) {
                    [self.playerModelArray enumerateObjectsWithOptions:(NSEnumerationConcurrent) usingBlock:^(DFPlayerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj.audioUrl.absoluteString isEqualToString:self.currentAudioModel.audioUrl.absoluteString]) {
                            self.currentAudioModel.audioId = idx;
                            self.currentAudioTag = idx;
                            *stop = YES;
                        }
                    }];
                    //更新随机数组
                    [self updateRandomIndexArray];
                }
                //用previousAudioModel配置播放器数据
                [self setupPlayerWithPreviousAudioModelWhenInitDFPlayer];
                //通知完成
                dispatch_group_leave(self.dataGroupQueue);
            });
        });
    }else{
        [self playfailureWithErrorMessage:@"请实现df_playerModelArray数据源方法"];return;
    }
}

/**初始化播放器时，用previousAudioModel配置播放器数据*/
- (void)setupPlayerWithPreviousAudioModelWhenInitDFPlayer{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (self.isObservePreviousAudioModel && self.previousAudioModel.audioUrl) {
            [self.playerModelArray enumerateObjectsWithOptions:(NSEnumerationConcurrent) usingBlock:^(DFPlayerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                //如果数据源中有previousAudioModel中的url
                if ([self.previousAudioModel.audioUrl.absoluteString isEqualToString:obj.audioUrl.absoluteString]) {
                    NSLog(@"-- DFPlayer： 当前数据源中存在此数据");
                    dispatch_async(self.defaultGlobalQueue, ^{
                        self.currentAudioModel          = [[DFPlayerModel alloc] init];
                        self.currentAudioModel.audioUrl = self.previousAudioModel.audioUrl;
                        self.currentAudioModel.audioId  = idx;
                        self.currentAudioTag            = idx;
                        self.progress                   = self.previousAudioModel.progress;
                        self.currentTime                = self.previousAudioModel.currentTime;
                        self.totalTime                  = self.previousAudioModel.totalTime;
                        //请求音频信息
                        if (self.dataSource && [self.dataSource respondsToSelector:@selector(df_playerAudioInfoModel:)]) {
                            self.currentAudioInfoModel = [self.dataSource df_playerAudioInfoModel:self];
                        }
                        //音频将要加入播放队列
                        if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerAudioWillAddToPlayQueue:)]) {
                            [self.delegate df_playerAudioWillAddToPlayQueue:self];
                        }
                    });
                    *stop = YES;
                }
            }];
        }
    });
}

/**选择audioId对应的音频开始播放*/
- (void)df_playerPlayWithAudioId:(NSUInteger)audioId{
    dispatch_group_notify(self.dataGroupQueue, self.HighGlobalQueue, ^{
        if (self.playerModelArray.count > audioId) {
            self.currentAudioModel = self.playerModelArray[audioId];
            NSLog(@"-- DFPlayer： 点击了音频Id:%ld   url：%@",(unsigned long)self.currentAudioModel.audioId,self.currentAudioModel.audioUrl);
            self.currentAudioTag = audioId;
            [self audioPrePlay];
        }else{
            [self playfailureWithErrorMessage:[NSString stringWithFormat:@"数组越界%ld==c:%lu",(long)audioId,(unsigned long)self.playerModelArray.count]];
        }
    });
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
- (void)audioPrePlayToLoadPreviousAudio{
    //如果监测、历史model音频url存在、当前播放的是历史储存的音频
    if (self.isObservePreviousAudioModel && self.previousAudioModel.audioUrl && !self.isAnAudioPlayed) {
        [self audioPrePlayToLoadAudio];
    }
}
/**预播放*/
- (void)audioPrePlay{
    [self audioPrePlayToResetAudio];
    [self audioPrePlayToLoadAudio];
}
/**重置音频信息*/
- (void)audioPrePlayToResetAudio{
    //重置进度和时间
    self.progress       = .0f;
    self.bufferProgress = .0f;
    self.currentTime    = .0f;
    self.totalTime      = .0f;
    self.isSeekWaiting  = NO;
    
    //暂停播放
    if (self.isPlaying) {
        [self df_audioPause];
    }
    //移除进度观察者
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    //请求音频信息
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(df_playerAudioInfoModel:)]) {
        self.currentAudioInfoModel = [self.dataSource df_playerAudioInfoModel:self];
    }
    //音频将要加入播放队列
    if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerAudioWillAddToPlayQueue:)]) {
        [self.delegate df_playerAudioWillAddToPlayQueue:self];
    }
}
/**加载音频*/
- (void)audioPrePlayToLoadAudio{
    self.isAnAudioPlayed = YES;
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
        NSLog(@"-- DFPlayer： 播放本地音频");
        [self loadPlayerWithItemUrl:currentAudioUrl];
        self.isCached = YES;
    }
    //播放网络音频
    else{
        dispatch_group_notify(self.netGroupQueue, self.defaultGlobalQueue, ^{
            NSString *cacheFilePath = [DFPlayerFileManager df_isExistAudioFileWithURL:currentAudioUrl];
            NSLog(@"-- DFPlayer： 是否有缓存：%@",cacheFilePath);
            self.isCached = cacheFilePath?YES:NO;
            
            //如果监听WWAN，本地无缓存，网络状态是WWAN，三种情况同时存在时发起代理8
            if (self.isObserveWWAN && !cacheFilePath &&
                self.networkStatus == DFPlayerNetworkStatusReachableViaWWAN)
            {
                if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerNetworkDidChangeToWWAN:)])
                {
                    [self.delegate df_playerNetworkDidChangeToWWAN:self];
                }else{
                    NSLog(@"-- DFPlayer： 未实现df_playerNetworkDidChangeToWWAN代理方法，或将isObserveWWAN置为NO");
                }
            }
            else
            {
                //加载音频
                [self loadPlayerItemWithUrl:currentAudioUrl
                           andCacheFilePath:cacheFilePath];
            }
        });
    }
}

- (void)loadPlayerItemWithUrl:(NSURL *)currentAudioUrl
             andCacheFilePath:(NSString *)cacheFilePath
{
    if (self.networkStatus == DFPlayerNetworkStatusUnknown ||
        self.networkStatus == DFPlayerNetworkStatusNotReachable)//无网络
    {
        if (cacheFilePath)//无网络 有缓存
        {
            NSLog(@"-- DFPlayer： 当前无网络，有缓存，即将播放缓存文件");
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
        else//需要缓存
        {
            if (cacheFilePath && !self.isObserveFileModifiedTime) {//有缓存且不监听改变时间 直接播放缓存
                [self loadPlayerWithItemUrl:[NSURL fileURLWithPath:cacheFilePath]];
            }else{//无缓存 或 需要兼听
                [self loadNetAudioWithUrl:currentAudioUrl
                         andCacheFilePath:cacheFilePath];
            }
        }
    }
}

- (void)loadNetAudioWithUrl:(NSURL *)currentAudioUrl andCacheFilePath:(NSString *)cacheFilePath{
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
    
    self.resourceLoader.isHaveCache = cacheFilePath?YES:NO;
    self.resourceLoader.isObserveFileModifiedTime = self.isObserveFileModifiedTime;
    
    kWeakSelf;
    self.resourceLoader.checkStatusBlock = ^(NSInteger statusCode){
        if (statusCode == 200) {
            weakSelf.bufferProgress = 0;
            [weakSelf loadPlayerWithAsset:asset];
        }else if (statusCode == 304) {
            NSLog(@"-- DFPlayer： 服务器音频资源未更新，播放本地");
            [weakSelf loadPlayerWithItemUrl:[NSURL fileURLWithPath:cacheFilePath]];
        }else if(statusCode == 206){
            
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

/**加载 AVPlayerItem*/
- (void)loadPlayerWithAsset:(AVURLAsset *)asset{
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self loadPlayer];
}
- (void)loadPlayerWithItemUrl:(NSURL *)url{
    self.playerItem = [[AVPlayerItem alloc] initWithURL:url];
    [self loadPlayer];
}
/**加载 AVPlayer*/
- (void)loadPlayer{
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    //监听播放进度
    if (self.isObserveProgress) {[self addPlayProgressTimeObserver];}
    //设置锁屏和控制中心音频信息
    [self addInformationOfLockScreen];
    
    [self df_audioPlay];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == self.player.currentItem) {
        if ([keyPath isEqualToString:DFStatusKey]) {
            AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            switch (status) {
                case AVPlayerItemStatusUnknown: //未知错误
                    self.state = DFPlayerStateFailed;
                    [self playfailureWithErrorMessage:DFPlayerWarning_UnknownError];
                    break;
                case AVPlayerItemStatusReadyToPlay://准备播放
                    NSLog(@"-- DFPlayer： 准备播放");
                    [self seekTotimeOfPreviousAudioModelWhenInitDFPlayer];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(df_playerDidReadyToPlay:)]) {
                        [self.delegate df_playerDidReadyToPlay:self];
                    }
                    break;
                case AVPlayerItemStatusFailed://准备失败.
                    self.state = DFPlayerStateFailed;
                    [self playfailureWithErrorMessage:DFPlayerWarning_PlayError];
                    NSLog(@"-- DFPlayer： 播放失败");
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
            NSLog(@"-- DFPlayer： 缓冲达到可播放");
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 缓冲进度 播放进度 歌曲锁屏信息 音频跳转 远程线控
/**缓冲进度*/
- (void)addBufferProgressObserver{
    CMTimeRange timeRange   = [self.playerItem.loadedTimeRanges.firstObject CMTimeRangeValue];
    CGFloat startSeconds    = CMTimeGetSeconds(timeRange.start);
    CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
    if (self.totalTime != 0) {//避免出现inf
        self.bufferProgress = (startSeconds + durationSeconds) / self.totalTime;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:bufferProgress:totalTime:)]) {
        [self.delegate df_player:self
                  bufferProgress:self.bufferProgress
                       totalTime:self.totalTime];
    }
    
    if (self.isSeekWaiting) {
        if (self.bufferProgress > self.seekValue) {
            self.isSeekWaiting = NO;
            [self didSeekToTimeWithValue:self.seekValue];
        }
    }
}

/**播放进度*/
- (void)addPlayProgressTimeObserver{
    kWeakSelf;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time){
        AVPlayerItem *currentItem = weakSelf.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0){
            CGFloat currentT = (CGFloat)CMTimeGetSeconds(time);
            if (!weakSelf.isDraged) {
                weakSelf.currentTime = currentT;
            }
            if (weakSelf.totalTime != 0) {//避免出现inf
                weakSelf.progress = CMTimeGetSeconds([currentItem currentTime]) / weakSelf.totalTime;
            }
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
    if (!self.currentAudioInfoModel.audioName &&
        !self.currentAudioInfoModel.audioAlbum &&
        !self.currentAudioInfoModel.audioSinger &&
        !self.currentAudioInfoModel.audioImage) {
        return;
    }
    MPNowPlayingInfoCenter *playInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    if (self.currentAudioInfoModel.audioName) {
        dic[MPMediaItemPropertyTitle] = self.currentAudioInfoModel.audioName;
    }
    if (self.currentAudioInfoModel.audioAlbum) {
        dic[MPMediaItemPropertyAlbumTitle] = self.currentAudioInfoModel.audioAlbum;
    }
    if (self.currentAudioInfoModel.audioSinger) {
        dic[MPMediaItemPropertyArtist] = self.currentAudioInfoModel.audioSinger;
    }
    dic[MPNowPlayingInfoPropertyPlaybackRate] = [NSNumber numberWithFloat:1.0];
    if ([self.currentAudioInfoModel.audioImage isKindOfClass:[UIImage class]] && self.currentAudioInfoModel.audioImage) {
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:self.currentAudioInfoModel.audioImage];
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

- (void)seekTotimeOfPreviousAudioModelWhenInitDFPlayer{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (self.isObservePreviousAudioModel) {
            [self.player seekToTime:CMTimeMake(floorf(self.totalTime * self.progress), 1)
                    toleranceBefore:(CMTimeMake(1, 1))
                     toleranceAfter:(CMTimeMake(1, 1))
                  completionHandler:^(BOOL finished) {
                      if (finished) {
                          [self df_audioPlay];
                          self.isDraged = NO;
                      }
            }];
        }
    });
}

/**音频跳转*/
- (void)df_seekToTimeWithValue:(CGFloat)value{
    self.isDraged = YES;
    // 先暂停
    [self df_audioPause];
    if (self.bufferProgress < value) {
        self.isSeekWaiting = YES;
        self.seekValue = value;
    }else{
        self.isSeekWaiting = NO;
        [self didSeekToTimeWithValue:value];
    }
}

- (void)didSeekToTimeWithValue:(CGFloat)value{
    if (self.state == DFPlayerStatePlaying || self.state == DFPlayerStatePause) {
        // 跳转
        [self.player seekToTime:CMTimeMake(floorf(self.totalTime * value), 1)
                toleranceBefore:CMTimeMake(1,1)
                 toleranceAfter:CMTimeMake(1,1)
              completionHandler:^(BOOL finished) {
                  if (finished) {
                      [self df_audioPlay];
                      self.isDraged = NO;
                  }
              }];
    }else if (self.state == DFPlayerStateStopped){
        [self audioPrePlayToLoadPreviousAudio];
        self.progress = value;
    }
}

/**远程线控*/
- (NSString *)remoteControlClass{
    return NSStringFromClass([DFPlayerRemoteApplication class]);
}

#pragma mark - 播放 暂停 下一首 上一首
/**播放*/
-(void)df_audioPlay{
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

/**下一首*/
- (void)df_audioNext{
    switch (self.type) {
        case DFPlayerTypeOnlyOnce:
            self.state = DFPlayerStateStopped;
            break;
        case DFPlayerTypeSingleCycle:
            /**解释：单曲循环模式下，如果是自动播放结束，则单曲循环。
             如果手动控制播放下一首或上一首，则根据isManualToPlay的设置判断播放下一首还是重新播放*/
            if (self.isNaturalToEndTime) {
                self.isNaturalToEndTime = NO;
                [self audioPrePlay];
            }else{
                if (self.isManualToPlay) {
                    [self audioNextOrderCycle];
                }else{
                    [self audioPrePlay];
                }
            }
            break;
        case DFPlayerTypeOrderCycle:
            [self audioNextOrderCycle];
            break;
        case DFPlayerTypeShuffleCycle:{
            self.playIndex2++;
            NSInteger tag = [self audioNextShuffleCycleIndex];
            //去重 避免随机到当前正在播放的音频
            if (tag == self.currentAudioTag) {
                tag = [self audioNextShuffleCycleIndex];
            }
            self.currentAudioTag = tag;
            self.currentAudioModel = self.playerModelArray[self.currentAudioTag];
            [self audioPrePlay];
            break;
        }
        default:
            break;
    }
}

/**上一首*/
- (void)df_audioLast{
    switch (self.type) {
        case DFPlayerTypeOnlyOnce:
            self.state = DFPlayerStateStopped;
            break;
        case DFPlayerTypeSingleCycle:
            if (self.isManualToPlay) {
                [self audioLastOrderCycle];
            }else{
                [self audioPrePlay];
            }
            break;
        case DFPlayerTypeOrderCycle:
            [self audioLastOrderCycle];
            break;
        case DFPlayerTypeShuffleCycle:{
            if (self.playIndex2 == 1) {
                self.playIndex2 = 0;
                self.currentAudioModel = self.playerModelArray[self.playIndex1];
            }else{
                NSInteger tag = [self audioLastShuffleCycleIndex];
                //去重 避免随机到当前正在播放的音频
                if (tag == self.currentAudioTag) {
                    tag = [self audioLastShuffleCycleIndex];
                }
                self.currentAudioTag = tag;
                self.currentAudioModel = self.playerModelArray[self.currentAudioTag];
            }
            [self audioPrePlay];
            break;
        }
        default:
            break;
    }
}

- (void)audioNextOrderCycle{
    self.currentAudioTag++;
    if (self.currentAudioTag < 0 || self.currentAudioTag >= self.playerModelArray.count) {
        self.currentAudioTag = 0;
    }
    self.playIndex1 = self.currentAudioTag;
    self.playIndex2 = 0;
    self.currentAudioModel = self.playerModelArray[self.currentAudioTag];
    [self audioPrePlay];
}
- (void)audioLastOrderCycle{
    self.currentAudioTag--;
    if (self.currentAudioTag < 0) {
        self.currentAudioTag = self.playerModelArray.count-1;
    }
    self.currentAudioModel = self.playerModelArray[self.currentAudioTag];
    [self audioPrePlay];
}

/**释放播放器*/
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

/**更新随机播放数组*/
- (void)updateRandomIndexArray{
    if (self.randomIndexArray.count != 0) {
        [self.randomIndexArray removeAllObjects];
        self.randomIndexArray = [NSMutableArray arrayWithArray:[self getRandomPlayerModelIndexArray]];
    }
}

//下一首随机index
- (NSInteger)audioNextShuffleCycleIndex{
    self.randomIndex++;
    if (self.randomIndex >= self.randomIndexArray.count) {
        self.randomIndex = 0;
    }
    NSInteger tag = [self.randomIndexArray[self.randomIndex] integerValue];
    return tag;
}
//上一首随机index
- (NSInteger)audioLastShuffleCycleIndex{
    self.randomIndex--;
    if (self.randomIndex < 0) {
        self.randomIndex = self.randomIndexArray.count-1;
    }
    NSInteger tag = [self.randomIndexArray[self.randomIndex] integerValue];
    return tag;
}

-(NSMutableArray*)getRandomPlayerModelIndexArray{
    NSInteger startIndex = 0;
    NSInteger length = self.playerModelArray.count;
    NSInteger endIndex = startIndex+length;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:length];
    NSMutableArray *arr1 = [NSMutableArray arrayWithCapacity:length];
    @autoreleasepool{
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
    }
    
    NSLog(@"-- DFPlayer： index:%@",arr);
    
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
    NSLog(@"-- DFPlayer： 设置了播放器类型:%ld",(long)category);
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
//        case DFPlayerAudioSessionCategoryRecord:
//            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
//            break;
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
- (void)setType:(DFPlayerType)type{
    NSLog(@"-- DFPlayer： 设置了播放类型:%ld",(long)type);
    _type = type;
    [[NSUserDefaults standardUserDefaults] setInteger:type forKey:DFPlayerTypeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)setState:(DFPlayerState)state{
    NSLog(@"-- DFPlayer： 播放器状态:%ld",(long)state);
    _state = state;
}
- (void)setNetworkStatus:(DFPlayerNetworkStatus)networkStatus{
    NSLog(@"-- DFPlayer： 网络状态：%ld",(long)networkStatus);
    _networkStatus = networkStatus;
}
- (void)setIsRemoteControl:(BOOL)isRemoteControl{
    _isRemoteControl = isRemoteControl;
    if (_isRemoteControl) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }else{
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    }
}

- (void)setIsObservePreviousAudioModel:(BOOL)isObservePreviousAudioModel{
    _isObservePreviousAudioModel = isObservePreviousAudioModel;
    if (_isObservePreviousAudioModel) {
        self.previousAudioModel = [[DFPlayerPreviousAudioModel alloc] init];
    }
}
- (void)setCurrentAudioModel:(DFPlayerModel *)currentAudioModel{_currentAudioModel = currentAudioModel;}

- (void)setProgress:(CGFloat)progress{_progress = progress;}

- (void)setBufferProgress:(CGFloat)bufferProgress{_bufferProgress = bufferProgress;}

- (void)setCurrentTime:(NSInteger)currentTime{_currentTime = currentTime;}

- (void)setTotalTime:(CGFloat)totalTime{_totalTime = totalTime;}

#pragma mark - 缓存相关
- (void)initPlayerCachePathWithUserId:(NSString *)userId{
    [DFPlayerFileManager df_playerCreateCachePathWithId:userId];
}

/**检查当前链接是否缓存*/
+ (NSString *)df_playerCheckIsCachedWithAudioUrl:(NSURL *)url{
    if (![url isKindOfClass:[NSURL class]]) {return nil;}
    if ([url.scheme isEqualToString:@"file"]) {return nil;}
    if (url) {
        NSString *cacheFilePath = [DFPlayerFileManager df_isExistAudioFileWithURL:url];
        if (cacheFilePath) {return cacheFilePath;}
    }
    return nil;
}

/**清除url对应的本地缓存*/
+ (void)df_playerClearCacheWithAudioUrl:(NSURL *)url block:(void(^)(BOOL isSuccess, NSError *error))block{
    [DFPlayerFileManager df_playerClearCacheWithUrl:url block:^(BOOL isSuccess, NSError *error) {
        if (block) {
            block(isSuccess,error);
        }
    }];
}
/**计算DFPlayer缓存大小*/
+ (CGFloat)df_playerCountCacheSizeForCurrentUser:(BOOL)isCurrentUser{
    return [DFPlayerFileManager df_countCacheSizeForCurrentUser:isCurrentUser];
}

/**清除缓存 */
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
        NSLog(@"-- DFPlayer： errorMessage:%@",errorMessage);
        if (self.delegate && [self.delegate respondsToSelector:@selector(df_player:didFailWithErrorMessage:)]) {
            [self.delegate df_player:self didFailWithErrorMessage:errorMessage];
        }
    }
}

@end



