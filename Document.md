> 只需关注三个类即可：
>>[1、DFPlayer：播放能力管理器](#first)<br>
[2、DFPlayerControlManager：播放控件管理器](#second)<br>
[3、DFPlayerModel：数据model类](#third)

### <a id="first">一、DFPlayer</a>

#### 两个数据源方法
```
/**
 数据源1：音频数组
 
 @param player DFPlayer
 */

- (NSArray<DFPlayerModel *> *)df_audioDataForPlayer:(DFPlayer *)player;

/**
 数据源2：音频信息
 调用df_playWithAudioId时，DFPlayer会调用此方法请求当前音频的信息
 根据player.currentAudioModel.audioId获取音频在数组中的位置,传入对应的音频信息model
 
 @param player DFPlayer
 */
- (DFPlayerInfoModel *)df_audioInfoForPlayer:(DFPlayer *)player;
```


#### 8个代理
```
/**
 代理1：音频已经加入播放队列
 
 @param player DFPlayer
 */
- (void)df_playerAudioAddToPlayQueue:(DFPlayer *)player;

/**
 代理2：准备播放
 
 @param player DFPlayer
 */
- (void)df_playerReadyToPlay:(DFPlayer *)player;

/**
 代理3：缓冲进度代理  (属性isObserveBufferProgress(默认YES)为YES时有效）
 
 @param player DFPlayer
 @param bufferProgress 缓冲进度
 @param totalTime 音频总时长
 */
- (void)df_player:(DFPlayer *)player bufferProgress:(CGFloat)bufferProgress totalTime:(CGFloat)totalTime;

/**
 代理4：播放进度代理 （属性isObserveProgress(默认YES)为YES时有效）
 
 @param player DFPlayer
 @param progress 播放进度
 @param currentTime 当前播放到的时间
 @param totalTime 音频总时长
 */
- (void)df_player:(DFPlayer *)player progress:(CGFloat)progress currentTime:(CGFloat)currentTime totalTime:(CGFloat)totalTime;

/**
 代理5：播放结束代理
 （默认播放结束后调用df_next，如果实现此代理，播放结束逻辑由您处理）
 
 @param player FPlayer
 */
- (void)df_playerDidPlayToEndTime:(DFPlayer *)player;

/**
 代理6：播放状态码代理
 
 @param player DFPlayer
 @param statusCode 状态码(统一在主线程返回)
 */
- (void)df_player:(DFPlayer *)player didGetStatusCode:(DFPlayerStatusCode)statusCode;

/**
 代理7：播放器被系统打断代理
 （默认被系统打断暂停播放，打断结束检测能够播放则恢复播放，如果实现此代理，打断逻辑由您处理）
 
 @param player DFPlayer
 @param isInterrupted YES:被系统打断开始  NO:被系统打断结束
 */
- (void)df_player:(DFPlayer *)player isInterrupted:(BOOL)isInterrupted;

/**
 代理8：监听耳机插入拔出代理
 
 @param player DFPlayer
 @param isHeadphone YES:插入 NO:拔出
 */
- (void)df_player:(DFPlayer *)player isHeadphone:(BOOL)isHeadphone;

```
#### 初始化和操作
```

@property (nonatomic, weak) id<DFPlayerDataSource> dataSource;

@property (nonatomic, weak) id<DFPlayerDelegate> delegate;

/**
 播放器类型，默认AVAudioSessionCategoryPlayback
 Tips:AVAudioSessionCategoryPlayback，需在工程里设置targets->capabilities->选择backgrounds modes->勾选audio,airplay,and picture in picture
 */
@property (nonatomic, assign) AVAudioSessionCategory category;

/**
 播放模式，默认DFPlayerModeOnlyOnce。
 */
@property (nonatomic, assign) DFPlayerMode playMode;

/**
 是否监听播放进度，默认YES
 */
@property (nonatomic, assign) BOOL isObserveProgress;

/**
 是否监听缓冲进度，默认YES
 */
@property (nonatomic, assign) BOOL isObserveBufferProgress;

/**
 是否需要缓存，默认YES
 */
@property (nonatomic, assign) BOOL isNeedCache;

/**
 是否监测WWAN无线广域网（2g/3g/4g）,默认NO。
 播放本地音频（工程目录和沙盒文件）不监测。
 播放网络音频时，DFPlayer为您实现无网络有缓存播放缓存，无网络无缓存返回无网络错误码，wifi下自动播放。开启该属性，当网络为WWAN时，通过代理6返回状态码DFPlayerStatusViaWWAN。
 */
@property (nonatomic, assign) BOOL isObserveWWAN;

/**
 是否监听服务器文件修改时间，默认NO。
 第一次请求某资源时，DFPlayer缓存文件的同时会记录文件在服务器端的修改时间。
 开启该属性，以后播放该资源时，DFPlayer会判断服务端文件是否修改过，修改过则加载新资源，没有修改过则播放缓存文件。
 关闭此属性，有缓存时将直接播放缓存，不做更新校验，在弱网环境下播放响应速度更快。
 无网络连接时，有缓存直接播放缓存文件。
 */
@property (nonatomic, assign) BOOL isObserveFileModifiedTime;

/**
 单例
 */
+ (DFPlayer *)sharedPlayer;

/**
 初始化播放器
 
 @param userId 用户Id。
 isNeedCache（默认YES）为YES时，若同一设备登录不同账号：
 1.userId不为空时，DFPlayer将为每位用户建立不同的缓存文件目录。例如，user_001,user_002...
 2.userId为nil或@""时，统一使用DFPlayerCache文件夹下的user_public作为缓存目录。
 isNeedCache为NO时,userId设置无效，此时不会在沙盒创建缓存目录。
 */
- (void)df_initPlayerWithUserId:(NSString *)userId;

/**
 刷新数据源数据
 */
- (void)df_reloadData;

/**
 选择audioId对应的音频开始播放。
 说明：DFPlayer通过数据源方法提前获取数据，通过df_playWithAudioId选择对应音频播放。
 而在删除、增加音频后需要调用[[DFPlayer shareInstance] df_reloadData];刷新数据。
 */
- (void)df_playWithAudioId:(NSUInteger)audioId;

/**
 播放
 */
- (void)df_play;

/**
 暂停
 */
- (void)df_pause;

/**
 下一首
 */
- (void)df_next;

/**
 上一首
 */
- (void)df_last;

/**
 音频跳转
 
 @param value 时间百分比
 @param completionBlock seek结束
 */
- (void)df_seekToTime:(CGFloat)value completionBlock:(void(^)(void))completionBlock;

/**
 倍速播放（iOS10之后系统支持的倍速常数有0.50, 0.67, 0.80, 1.0, 1.25, 1.50和2.0）
 @param rate 倍速
 */
- (void)df_setRate:(CGFloat)rate;

/**
 释放播放器，还原其他播放器
 */
- (void)df_deallocPlayer;

```

#### 状态类

```
/**
 播放器状态
 */
@property (nonatomic, readonly, assign) DFPlayerState state;

/**
 当前正在播放的音频model
 */
@property (nonatomic, readonly, strong) DFPlayerModel *currentAudioModel;

/**
 当前正在播放的音频信息model
 */
@property (nonatomic, readonly, strong) DFPlayerInfoModel *currentAudioInfoModel;

/**
 当前音频缓冲进度
 */
@property (nonatomic, readonly, assign) CGFloat bufferProgress;

/**
 当前音频播放进度
 */
@property (nonatomic, readonly, assign) CGFloat progress;

/**
 当前音频当前时间
 */
@property (nonatomic, readonly, assign) CGFloat currentTime;

/**
 当前音频总时长
 */
@property (nonatomic, readonly, assign) CGFloat totalTime;

```

#### 缓存相关

```
/**
 audioUrl对应的音频在本地的缓存地址
 
 @param audioUrl 网络音频url
 @return 无缓存时返回nil
 */
- (NSString *)df_cachePath:(NSURL *)audioUrl;

/**
 DFPlayer的缓存大小
 
 @param currentUser YES:当前用户  NO:所有用户
 @return 缓存大小
 */
- (CGFloat)df_cacheSize:(BOOL)currentUser;

/**
 清除音频缓存
 
 @param audioUrl 网络音频url
 @return 是否清除成功（无缓存时返回YES）
 */
- (BOOL)df_clearAudioCache:(NSURL *)audioUrl;

/**
 清除用户缓存
 
 @param currentUser YES:清除当前用户缓存  NO:清除所有用户缓存
 @return 是否清除成功（无缓存时返回YES）
 */
- (BOOL)df_clearUserCache:(BOOL)currentUser;
```


### <a id="second">二、DFPlayerControlManager</a>
```

+ (DFPlayerControlManager *)sharedManager;

/**
 停止所有进度类控件的刷新
 */
- (void)df_stopUpdate;

/**
 恢复所有进度类控件的刷新
 */
- (void)df_resumeUpdate;

/**
 播放暂停按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 播放暂停按钮
 */
- (UIButton *)df_playPauseBtnWithFrame:(CGRect)frame
                             superView:(UIView *)superView
                                 block:(nullable void (^)(void))block;

/**
 上一首按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 上一首按钮
 */
- (UIButton *)df_lastAudioBtnWithFrame:(CGRect)frame
                             superView:(UIView *)superView
                                 block:(nullable void (^)(void))block;

/**
 下一首按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 下一首按钮
 */
- (UIButton *)df_nextAudioBtnWithFrame:(CGRect)frame
                             superView:(UIView *)superView
                                 block:(nullable void (^)(void))block;

/**
 播放模式按钮(DFPlayerMode不是DFPlayerModeOnlyOnce时有效。）
 
 @param frame 按钮frame
 @param superView 按钮父视图
 @param block 按钮action 若无其他操作需求，传nil即可
 @return 播放模式设置按钮
 */
- (UIButton *)df_typeControlBtnWithFrame:(CGRect)frame
                               superView:(UIView *)superView
                                   block:(nullable void (^)(void))block;

/**
 缓冲进度条
 
 @param frame frame
 @param trackTintColor 未缓冲部分进度条颜色
 @param progressTintColor 已缓冲部分进度条颜色
 @param superView 进度条父视图
 @return 进度条
 */
- (UIProgressView *)df_bufferProgressViewWithFrame:(CGRect)frame
                                    trackTintColor:(UIColor *)trackTintColor
                                 progressTintColor:(UIColor *)progressTintColor
                                         superView:(UIView *)superView;

/**
 播放进度条
 
 @param frame frame
 @param minimumTrackTintColor 滑块左边滑动条的颜色
 @param maximumTrackTintColor 滑块右边滑动条的颜色
 @param trackHeight 滑动条的高度(长度采用frame的width)
 @param thumbSize 滑块的大小
 @param superView 进度条父视图
 @return 进度条
 */
- (UISlider *)df_sliderWithFrame:(CGRect)frame
           minimumTrackTintColor:(UIColor *)minimumTrackTintColor
           maximumTrackTintColor:(UIColor *)maximumTrackTintColor
                     trackHeight:(CGFloat)trackHeight
                       thumbSize:(CGSize)thumbSize
                       superView:(UIView *)superView;

/**
 音频当前时间label
 
 @param frame frame
 @param superView label父视图
 @return label
 */
- (UILabel *)df_currentTimeLabelWithFrame:(CGRect)frame
                                superView:(UIView *)superView;

/**
 音频总时长label
 
 @param frame frame
 @param superView label父视图
 @return label
 */
- (UILabel *)df_totalTimeLabelWithFrame:(CGRect)frame
                              superView:(UIView *)superView;

/**
 lyricTableview
 ①采用lrc标准格式编写，即"[00:00.00]歌词" 或 "[00:00]歌词" 或 "[00:00:00]歌词"
 ②根据lrc歌词软件开发标准，凡具有“[*:*]”形式的都应认为是标签（注意：其中的冒号并非全角字符“：”）。凡是标签都不应显示。
 ③支持单句歌词多个时间的格式，如“[00:10.00][00:50.00][00:70.00]歌词”
 ④lrc歌词文件单行只有时间标签，没有歌词内容的，将被认作为上一个相邻时间内歌词的结束时间,并不做空行显示处理。比如
 [00:11.11]歌词
 [00:22.22] （22秒22毫米，该时间下无歌词显示，将被认作为上一个相邻时间歌词的演唱结束时间。此处的相邻不是位置的相邻，而是时间大小的相邻）
 ⑤如果歌词中需要空行，DFPlayer默认时间标签后的“####”是空行标志，如“[00:11.11]####”，DFPlayer将在解析到歌词为####时做空行显示
 详情查看demo中”许嵩(Vae)-有何不可.lrc“文件
 ⑥DFPlayer认为每个时间标签都是一个单元格。只不过时间标签后无歌词时，DFPlayer将该单元格隐藏。
 ⑦DFPlayer不对单句歌词做换行处理，所以单行歌词长度尽量不要超过tableview的宽度，当超出时，DFPlayer用末尾省略号处理。
 
 @param frame  tableview frame
 @param cellRowHeight  tableview 单行rowHeight
 @param cellBackgroundColor cell背景色
 @param currentLineLrcForegroundTextColor 当前行歌词文字前景色（此属性不为nil时，采用卡拉OK模式显示）
 @param currentLineLrcBackgroundTextColor 当前行歌词文字背景色
 @param otherLineLrcBackgroundTextColor 其他行歌词文字颜色
 @param currentLineLrcFont 当前行歌词字体
 @param otherLineLrcFont 其他行歌词字体
 @param superView 父视图
 @return 歌词tableView
 */

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


### <a id="third">三、DFPlayerModel</a>

##### DFPlayerModel（必传）
```
@property (nonatomic, assign) NSUInteger audioId; // 音频Id（从0开始，仅标识当前音频在数组中的位置）

@property (nonatomic, strong) NSURL *audioUrl; // 音频地址
```

##### DFPlayerInfoModel(非必传)
```

@property (nonatomic, nullable, copy) NSString *audioLyrics; // 歌词

/* 正确传入以下属性时，DFPlayer将自动设置锁屏模式和控制中心的播放信息展示 */

@property (nonatomic, nullable, copy) NSString *audioName; // 音频名

@property (nonatomic, nullable, copy) NSString *audioAlbum; // 专辑名

@property (nonatomic, nullable, copy) NSString *audioSinger; // 歌手名

@property (nonatomic, nullable, copy) UIImage *audioImage; // 音频配图
```


