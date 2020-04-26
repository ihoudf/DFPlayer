> ## 只需关注三个类即可：
>>#### [1、DFPlayer：播放能力管理器](#first)
>>#### [2、DFPlayerUIManager：播放控件管理器](#second)
>>#### [3、DFPlayerModel：数据model类](#third)
>为了显示清晰，以下只列举了方法，具体参数要求下载工程查看

<br>

## <a id="first">一、DFPlayer</a>

#### 两个数据源方法
```
// 数据源1：音频数组
- (NSArray<DFPlayerModel *> *)df_audioDataForPlayer:(DFPlayer *)player;

// 数据源2：音频信息
- (DFPlayerInfoModel *)df_audioInfoForPlayer:(DFPlayer *)player;
```


#### 8个代理
```
// 代理1：音频已经加入播放队列
- (void)df_playerAudioAddToPlayQueue:(DFPlayer *)player;

// 代理2：准备播放
- (void)df_playerReadyToPlay:(DFPlayer *)player;

// 代理3：缓冲进度代理
- (void)df_player:(DFPlayer *)player bufferProgress:(CGFloat)bufferProgress totalTime:(CGFloat)totalTime;

// 代理4：播放进度代理
- (void)df_player:(DFPlayer *)player progress:(CGFloat)progress currentTime:(CGFloat)currentTime totalTime:(CGFloat)totalTime;

// 代理5：播放结束代理
- (void)df_playerDidPlayToEndTime:(DFPlayer *)player;

// 代理6：播放状态码代理
- (void)df_player:(DFPlayer *)player didGetStatusCode:(DFPlayerStatusCode)statusCode;

// 代理7：播放器被系统打断代理
- (void)df_player:(DFPlayer *)player isInterrupted:(BOOL)isInterrupted;

// 代理8：监听耳机插入拔出代理
- (void)df_player:(DFPlayer *)player isHeadphone:(BOOL)isHeadphone;
```
#### 初始化和操作
```
@property (nonatomic, weak) id<DFPlayerDataSource> dataSource;

@property (nonatomic, weak) id<DFPlayerDelegate> delegate;

// 播放器类型，默认AVAudioSessionCategoryPlayback
@property (nonatomic, assign) AVAudioSessionCategory category;

// 播放模式，默认DFPlayerModeOnlyOnce
@property (nonatomic, assign) DFPlayerMode playMode;

// 是否监听播放进度，默认YES
@property (nonatomic, assign) BOOL isObserveProgress;

// 是否监听缓冲进度，默认YES
@property (nonatomic, assign) BOOL isObserveBufferProgress;

// 是否需要缓存，默认YES
@property (nonatomic, assign) BOOL isNeedCache;

// 是否监测WWAN无线广域网（2g/3g/4g）,默认NO。
@property (nonatomic, assign) BOOL isObserveWWAN;

// 是否监听服务器文件修改时间，默认NO
@property (nonatomic, assign) BOOL isObserveFileModifiedTime;

// 单例
+ (DFPlayer *)sharedPlayer;

// 初始化播放器
- (void)df_initPlayerWithUserId:(NSString *)userId;

// 刷新数据源数据
- (void)df_reloadData;

// 选择audioId对应的音频开始播放
- (void)df_playWithAudioId:(NSUInteger)audioId;

// 播放
- (void)df_play;

// 暂停
- (void)df_pause;

// 下一首
- (void)df_next;

// 上一首
- (void)df_last;

// 音频跳转
- (void)df_seekToTime:(CGFloat)value completionBlock:(void(^)(void))completionBlock;

// 倍速播放
- (void)df_setRate:(CGFloat)rate;

// 释放播放器，还原其他播放器
- (void)df_deallocPlayer;
```

#### 状态类

```
// 播放器状态
@property (nonatomic, readonly, assign) DFPlayerState state;

// 当前正在播放的音频model
@property (nonatomic, readonly, strong) DFPlayerModel *currentAudioModel;

// 当前正在播放的音频信息model
@property (nonatomic, readonly, strong) DFPlayerInfoModel *currentAudioInfoModel;

// 当前音频缓冲进度
@property (nonatomic, readonly, assign) CGFloat bufferProgress;

// 当前音频播放进度
@property (nonatomic, readonly, assign) CGFloat progress;

// 当前音频当前时间
@property (nonatomic, readonly, assign) CGFloat currentTime;

// 当前音频总时长
@property (nonatomic, readonly, assign) CGFloat totalTime;
```

#### 缓存相关

```
// audioUrl对应的音频在本地的缓存地址
- (NSString *)df_cachePath:(NSURL *)audioUrl;

// DFPlayer的缓存大小
- (CGFloat)df_cacheSize:(BOOL)currentUser;

// 清除音频缓存
- (BOOL)df_clearAudioCache:(NSURL *)audioUrl;

// 清除用户缓存
- (BOOL)df_clearUserCache:(BOOL)currentUser;
```


## <a id="second">二、DFPlayerUIManager</a>
```
// 单利
+ (DFPlayerUIManager *)sharedManager;

// 停止所有进度类控件的刷新
- (void)df_stopUpdate;

// 恢复所有进度类控件的刷新
- (void)df_resumeUpdate;

// 播放暂停按钮
- (UIButton *)df_playPauseBtnWithFrame:(CGRect)frame
                             playImage:(UIImage *)playImage
                            pauseImage:(UIImage *)pauseImage
                             superView:(UIView *)superView
                                 block:(nullable void (^)(void))block;

// 上一首按钮
- (UIButton *)df_lastBtnWithFrame:(CGRect)frame
                            image:(UIImage *)image
                        superView:(UIView *)superView
                            block:(nullable void (^)(void))block;

// 下一首按钮
- (UIButton *)df_nextBtnWithFrame:(CGRect)frame
                            image:(UIImage *)image
                        superView:(UIView *)superView
                            block:(nullable void (^)(void))block;

// 播放模式按钮
- (UIButton *)df_typeBtnWithFrame:(CGRect)frame
                      singleImage:(UIImage *)singleImage
                      circleImage:(UIImage *)circleImage
                     shuffleImage:(UIImage *)shuffleImage
                        superView:(UIView *)superView
                            block:(nullable void (^)(void))block;

// 缓冲条
- (UIProgressView *)df_bufferViewWithFrame:(CGRect)frame
                            trackTintColor:(UIColor *)trackTintColor
                         progressTintColor:(UIColor *)progressTintColor
                                 superView:(UIView *)superView;

// 播放进度条
- (UISlider *)df_sliderWithFrame:(CGRect)frame
           minimumTrackTintColor:(UIColor *)minimumTrackTintColor
           maximumTrackTintColor:(UIColor *)maximumTrackTintColor
                     trackHeight:(CGFloat)trackHeight
                      thumbImage:(UIImage *)thumbImage
                       superView:(UIView *)superView;

// 音频当前时间label
- (UILabel *)df_currentTimeLabelWithFrame:(CGRect)frame
                                textColor:(UIColor *)textColor
                            textAlignment:(NSTextAlignment)textAlignment
                                     font:(UIFont *)font
                                superView:(UIView *)superView;

// 音频总时长label
- (UILabel *)df_totalTimeLabelWithFrame:(CGRect)frame
                              textColor:(UIColor *)textColor
                          textAlignment:(NSTextAlignment)textAlignment
                                   font:(UIFont *)font
                              superView:(UIView *)superView;

// 歌词tableview
- (UITableView *)df_lyricTableViewWithFrame:(CGRect)frame
                              cellRowHeight:(CGFloat)cellRowHeight
                        cellBackgroundColor:(UIColor *)cellBackgroundColor
          currentLineLrcForegroundTextColor:(nullable UIColor *)currentLineLrcForegroundTextColor
          currentLineLrcBackgroundTextColor:(UIColor *)currentLineLrcBackgroundTextColor
            otherLineLrcBackgroundTextColor:(UIColor *)otherLineLrcBackgroundTextColor
                         currentLineLrcFont:(UIFont *)currentLineLrcFont
                           otherLineLrcFont:(UIFont *)otherLineLrcFont
                                  superView:(UIView *)superView
                                      block:(nullable void (^)(NSString * onPlayingLyrics))block;
```


## <a id="third">三、DFPlayerModel</a>

##### DFPlayerModel（必传）
```
@property (nonatomic, assign) NSUInteger audioId; // 音频Id

@property (nonatomic, strong) NSURL *audioUrl; // 音频地址
```

##### DFPlayerInfoModel(非必传)
```
@property (nonatomic, nullable, copy) NSString *audioLyrics; // 歌词

@property (nonatomic, nullable, copy) NSString *audioName; // 音频名

@property (nonatomic, nullable, copy) NSString *audioAlbum; // 专辑名

@property (nonatomic, nullable, copy) NSString *audioSinger; // 歌手名

@property (nonatomic, nullable, copy) UIImage *audioImage; // 音频配图
```


