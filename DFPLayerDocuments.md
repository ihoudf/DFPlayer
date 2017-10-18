## DFPlayer详细文档
你可能需要用到以下三个类：<br>
<br>
<a href="#DFPlayerManager">DFPlayerManager.h</a>
<br>
<a href="#DFPlayerModel">DFPlayerModel.h</a>
<br>
<a href="#DFPlayerControlManager">DFPlayerControlManager.h</a>


<div id="DFPlayerManager"></div>
#### DFPlayerManager(DFPlayer音频播放管理器)
```
    //播放器类别
    typedef NS_ENUM(NSInteger,DFPlayerAudioSessionCategory){
        DFPlayerAudioSessionCategoryAmbient,        //用于播放。随静音键和屏幕关闭而静音。不终止其它应用播放声音
        DFPlayerAudioSessionCategorySoloAmbient,    //用于播放。随静音键和屏幕关闭而静音。终止其它应用播放声音
        DFPlayerAudioSessionCategoryPlayback,       //用于播放。不随静音键和屏幕关闭而静音。终止其它应用播放声音
        DFPlayerAudioSessionCategoryPlayAndRecord,  //用于播放和录音。不随着静音键和屏幕关闭而静音。终止其他应用播放声音
        DFPlayerAudioSessionCategoryMultiRoute      //用于播放和录音。不随着静音键和屏幕关闭而静音。可多设备输出
    };

    //播放器状态
    typedef NS_ENUM(NSInteger, DFPlayerState) {
        DFPlayerStateFailed,     // 播放失败
        DFPlayerStateBuffering,  // 缓冲中
        DFPlayerStatePlaying,    // 播放中
        DFPlayerStatePause,      // 暂停播放
        DFPlayerStateStopped     // 停止播放
    };

    //播放类型
    typedef NS_ENUM(NSInteger, DFPlayerType){
        DFPlayerTypeOnlyOnce,       //单曲只播放一次
        DFPlayerTypeSingleCycle,    //单曲循环
        DFPlayerTypeOrderCycle,     //顺序循环
        DFPlayerTypeShuffleCycle    //随机循环
    };

    //网络状态
    typedef NS_ENUM(NSInteger, DFPlayerNetworkStatus) {
        DFPlayerNetworkStatusUnknown          = -1, //未知
        DFPlayerNetworkStatusNotReachable     = 0,  //无网络链接
        DFPlayerNetworkStatusReachableViaWWAN = 1,  //2G/3G/4G
        DFPlayerNetworkStatusReachableViaWiFi = 2   //WIFI
    };


    @protocol DFPlayerDataSource <NSObject>
    @required
    /**
     数据源1：音频model数组
     */
    - (NSArray<DFPlayerModel *> *)df_playerModelArray;

    @optional
    /**
     数据源2：音频信息model
     当DFPlayer收到播放请求时，会调用此方法请求当前音频的信息
     根据playerManager.currentAudioModel.audioId获取音频在数组中的位置,返回对应的音频信息model
     
     @param playerManager DFPlayer音频播放管理器
     */
    - (DFPlayerInfoModel *)df_playerAudioInfoModel:(DFPlayerManager *)playerManager;

    @end

    @protocol DFPlayerDelegate <NSObject>
    @optional

    /**
     代理1：音频将要加入播放队列

     @param playerManager DFPlayer音频播放管理器
     */
    - (void)df_playerAudioWillAddToPlayQueue:(DFPlayerManager *)playerManager;

    /**
     代理2：WWAN网络状态代理（isObserveWWAN（默认NO）为YES，网络状态为WWAN，且当前播放音频无缓存时发起）
     
     @param playerManager DFPlayer音频播放管理器
     */
    - (void)df_playerNetworkDidChangeToWWAN:(DFPlayerManager *)playerManager;

    /**
     代理3：准备开始播放代理
     
     @param playerManager DFPlayer音频播放管理器
     */
    - (void)df_playerDidReadyToPlay:(DFPlayerManager *)playerManager;

    /**
     代理4：缓冲进度代理  (属性isObserveBufferProgress(默认YES)为YES时有效）
     
     @param playerManager DFPlayer音频播放管理器
     @param bufferProgress 缓冲进度
     @param totalTime 音频总时长
     */
    - (void)df_player:(DFPlayerManager *)playerManager
       bufferProgress:(CGFloat)bufferProgress
            totalTime:(CGFloat)totalTime;

    /**
     代理5：播放进度代理 （属性isObserveProgress(默认YES)为YES时有效）
     
     @param playerManager DFPlayer音频播放管理器
     @param progress 播放进度
     @param currentTime 当前播放到的时间
     @param totalTime 音频总时长
     */
    - (void)df_player:(DFPlayerManager *)playerManager
             progress:(CGFloat)progress
          currentTime:(CGFloat)currentTime
            totalTime:(CGFloat)totalTime;

    /**
     代理6：当前音频缓存结果代理
     
     @param playerManager FPlayer音频播放管理器
     @param isCached 是否缓存成功
     */
    - (void)df_player:(DFPlayerManager *)playerManager isCached:(BOOL)isCached;

    /**
     代理7：播放结束代理
     
     @param playerManager FPlayer音频播放管理器
     */
    - (void)df_playerDidPlayToEndTime:(DFPlayerManager *)playerManager;

    /**
     代理8：播放失败代理

     @param playerManager DFPlayer音频播放管理器
     @param errorMessage 错误信息
     */
    - (void)df_player:(DFPlayerManager *)playerManager didFailWithErrorMessage:(NSString *)errorMessage;

    /**
     代理9：播放器被系统打断代理
     （DFPlayer默认被系统打断暂停播放，打断结束检测能够播放则恢复播放，如果实现此代理，打断逻辑由您处理）

     @param playerManager DFPlayer音频播放管理器
     @param isInterruptedBegin YES:被系统打断开始  NO:被系统打断结束
     */
    - (void)df_player:(DFPlayerManager *)playerManager isInterruptedBegin:(BOOL)isInterruptedBegin;

    /**
     代理10：监听耳机插入拔出代理

     @param playerManager DFPlayer音频播放管理器
     @param isHeadphone YES:插入 NO:拔出
     */
    - (void)df_player:(DFPlayerManager *)playerManager isHeadphone:(BOOL)isHeadphone;

    @end

    /**
     DFPlayer音频播放管理器
     */
    @interface DFPlayerManager : NSObject

    @property (nonatomic, weak) id<DFPlayerDelegate>    delegate;
    @property (nonatomic, weak) id<DFPlayerDataSource>  dataSource;

    #pragma mark - 设置类
    /**播放器类型，默认DFPlayerAudioSessionCategorySoloAmbient*/
    @property (nonatomic, assign) DFPlayerAudioSessionCategory category;
    /**
     播放类型，首次默认DFPlayerTypeSingleCycle。设置播放类型后，DFPlayer将为您记录用户的选择。
     如需每次启动都设置固定某一个播放类型，请在初始化播放器后，调用[DFPlayerManager shareInstance].type = XX;重置播放类型。
     */
    @property (nonatomic, assign) DFPlayerType type;
    /**是否监听播放进度，默认YES*/
    @property (nonatomic, assign) BOOL isObserveProgress;
    /**是否监听缓冲进度，默认YES*/
    @property (nonatomic, assign) BOOL isObserveBufferProgress;
    /**是否需要缓存，默认YES*/
    @property (nonatomic, assign) BOOL isNeedCache;
    /**是否需要耳机线控功能，默认YES*/
    @property (nonatomic, assign) BOOL isRemoteControl;
    /**是否监测上次关闭app时的音频信息，默认NO*/
    @property (nonatomic, assign) BOOL isObservePreviousAudioModel;
    /**
     在单曲循环模式下，点击下一首(上一首)按钮(或使用线控播放下一首、上一首)是重新开始播放当前音频还是播放下一首（上一首）
     移动版QQ音乐是播放下一首（上一首），PC版QQ音乐是重新开始播放当前音频
     DFPlayer默认YES，即采用移动版QQ音乐设置。设置为NO时，重新开始播放当前音频
     */
    @property (nonatomic, assign) BOOL isManualToPlay;
    /**
     当currentAudioModel存在时，是否插入耳机音频自动恢复播放，默认NO
     当您没有实现代理10的情况下，DFPlaye默认拨出耳机音频自动停止，插入耳机音频不会自动恢复。
     你可通过此属性控制插入耳机时音频是否可自动恢复
     当您实现代理10时，耳机插入拔出时的播放暂停逻辑由您处理。
     */
    @property (nonatomic, assign) BOOL isHeadPhoneAutoPlay;
    /**
     是否监测WWAN无线广域网（2g/3g/4g）,默认NO。
     播放本地音频（工程目录和沙盒文件）不监测。
     播放网络音频时，DFPlayer为您实现wifi下自动播放，无网络有缓存播放缓存，无网络无缓存返回无网络错误码。
     基于播放器具有循环播放的功能，开启该属性，无线广域网（WWAN）网络状态通过代理2返回，可在此代理方法下弹窗提示用户，
     并根据用户选择，若选择继续播放，将此属性置为NO，同时通过代理方法返回的playerManager对象获得currentAudioModel的audioId，
     执行df_playerPlayWithAudioId:方法继续播放，详见demo。
     */
    @property (nonatomic, assign) BOOL isObserveWWAN;
    /**
     是否监听服务器文件修改时间，默认YES。
     在播放网络音频且需要DFPlayer的缓存功能的情况下，开启该属性，不必频繁更换服务端文件名来更新客户端播放内容。
     比如，你的服务器上有audioname.mp3资源，若更改音频内容而需重新上传音频时，您不必更改文件名以保证客户端获取最新资源，本属性为YES即可完成。
     第一次请求某资源时，DFPlayer缓存文件的同时会记录文件在服务器端的修改时间。
     以后播放该资源时，DFPlayer会判断服务端文件是否修改过，修改过则加载新资源，没有修改过则播放缓存文件。
     关闭此属性，有缓存时将直接播放缓存，不做更新校验，在弱网环境下播放响应速度更快。
     无网络连接时，有缓存直接播放缓存文件。
     */
    @property (nonatomic, assign) BOOL isObserveLastModified;

    #pragma mark - 状态类
    /**网络状态*/
    @property (nonatomic, readonly, assign) DFPlayerNetworkStatus   networkStatus;
    /**播放器状态*/
    @property (nonatomic, readonly, assign) DFPlayerState           state;
    /**当前正在播放的音频model*/
    @property (nonatomic, readonly, strong) DFPlayerModel           *currentAudioModel;
    /**当前正在播放的音频信息model*/
    @property (nonatomic, readonly, strong) DFPlayerInfoModel       *currentAudioInfoModel;
    /**当前音频缓冲进度*/
    @property (nonatomic, readonly, assign) CGFloat                 bufferProgress;
    /**当前音频播放进度*/
    @property (nonatomic, readonly, assign) CGFloat                 progress;
    /**当前音频当前时间*/
    @property (nonatomic, readonly, assign) CGFloat                 currentTime;
    /**当前音频总时长*/
    @property (nonatomic, readonly, assign) CGFloat                 totalTime;
    /**上次关闭app时播放的音频信息。(属性isObservePreviousAudioModel（默认NO）为YES时有效)*/
    @property (nonatomic, readonly, strong) DFPlayerPreviousAudioModel *previousAudioModel;

    #pragma mark - 初始化和操作
    /**单例方法*/
    + (DFPlayerManager *)shareInstance;

    /**
     初始化播放器
     
     @param userId 用户唯一Id。
     isNeedCache（默认YES）为YES时，若同一设备登录不同账号：
     1.userId存在时，DFPlayer将为每位用户建立不同的缓存文件目录。例如，user_001,user_002...
     2.userId为nil或@""时，统一使用DFPlayerCache文件夹下的user_public文件夹作为缓存目录。
     isNeedCache为NO时,userId设置无效，此时不会在沙盒创建缓存目录
     */
    - (void)initPlayerWithUserId:(NSString *)userId;

    /**刷新数据源数据*/
    - (void)df_reloadData;

    /**选择audioId对应的音频开始播放*/
    - (void)df_playerPlayWithAudioId:(NSUInteger)audioId;

    /**播放*/
    - (void)df_audioPlay;

    /**暂停*/
    - (void)df_audioPause;

    /**下一首*/
    - (void)df_audioNext;

    /**上一首*/
    - (void)df_audioLast;

    /**音频跳转，value：时间百分比*/
    - (void)df_seekToTimeWithValue:(CGFloat)value;

    /**释放播放器，还原其他播放器*/ 
    - (void)df_dellecPlayer;

    /**实现远程线控功能，需替换main.m中UIApplicationMain函数的第三个参数。*/
    - (NSString *)remoteControlClass;

    #pragma mark - 缓存相关
    /**
     url对应音频是否已经在本地缓存
     
     @param url 网络音频url
     @return 有缓存返回缓存地址，无缓存返回nil
     */
    - (NSString *)df_playerCheckIsCachedWithUrl:(NSURL *)url;

    /**
     计算DFPlayer的缓存大小

     @param isCurrentUser YES:计算当前用户缓存大小  NO:计算所有用户缓存大小
     @return 大小
     */
    + (CGFloat)df_playerCountCacheSizeForCurrentUser:(BOOL)isCurrentUser;

    /**
     清除DFPlayer产生的缓存

     @param isClearCurrentUser YES:清除当前用户缓存  NO:清除所有用户缓存
     @param block 是否清除成功 错误信息
     */
    + (void)df_playerClearCacheForCurrentUser:(BOOL)isClearCurrentUser
                                        block:(void(^)(BOOL isSuccess, NSError *error))block;

    /**计算系统磁盘空间 剩余可用空间*/
    + (void)df_countSystemSizeBlock:(void(^)(CGFloat totalSize,CGFloat freeSize,BOOL isSuccess))block;

    @end

```
<br>
<div id="DFPlayerModel"></div>
#### DFPlayerModel(DFPlayer数据model类)
```
    /**
        数据model类（必传属性） - IMPORTANT
     */
    @interface DFPlayerModel : NSObject
    /**音频Id。仅标识当前音频在数组中的位置。详见demo。
     
     说明：鉴于音频播放器有顺序播放、随机播放等功能，DFPLayer需要一次性知道全部数据。
     而在删除、增加音频后需要调用[[DFPlayerManager shareInstance] df_reloadData];刷新数据。
     DFPlayer内部实现里做了线程优化，合理范围内的大数据量也毫无压力。
     */
    @property (nonatomic, assign) NSUInteger audioId;

    /**音频地址*/
    @property (nonatomic, nonnull, strong) NSURL *audioUrl;

    @end


    /**
        音频信息model类（非必传属性）
     */
    @interface DFPlayerInfoModel : NSObject

    /**歌词*/
    @property (nonatomic, nullable, copy) NSString *audioLyric;

    /*当您正确传入以下属性时，DFPlayer将自动为您设置锁屏模式和控制中心的播放信息展示*/
    /**音频名*/
    @property (nonatomic, nullable, copy) NSString *audioName;

    /**专辑名*/
    @property (nonatomic, nullable, copy) NSString *audioAlbum;

    /**歌手名*/
    @property (nonatomic, nullable, copy) NSString *audioSinger;

    /**音频配图*/
    @property (nonatomic, nullable, copy) UIImage *audioImage;

    @end
```

<br>
<div id="DFPlayerControlManager"></div>
#### DFPlayerControlManager(DFPlayer控制管理器)
```
    /**
        DFPlayer控制管理器
    */
    @interface DFPlayerControlManager : NSObject

    /**单利方法*/
    + (DFPlayerControlManager *_Nullable)shareInstance;

    /**
     AirPlayView

     @param frame AirPlayView frame
     @param backgroundColor 背景颜色
     @param superView AirPlayView父视图
     @return AirPlayView
     */
    - (UIView *_Nullable)df_airPlayViewWithFrame:(CGRect)frame
                                 backgroundColor:(UIColor *_Nullable)backgroundColor
                                       superView:(UIView *_Nonnull)superView;

    /**
     播放暂停按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)
     
     @param frame 按钮frame
     @param superView 按钮父视图
     @param block 按钮action 若无其他操作需求，传nil即可
     @return 播放暂停按钮
     */
    - (UIButton *_Nullable)df_playPauseBtnWithFrame:(CGRect)frame
                                          superView:(UIView *_Nonnull)superView
                                              block:(void(^_Nullable)(void))block;

    /**
     上一首按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)

     @param frame 按钮frame
     @param superView 按钮父视图
     @param block 按钮action 若无其他操作需求，传nil即可
     @return 上一首按钮
     */
    - (UIButton *_Nullable)df_lastAudioBtnWithFrame:(CGRect)frame
                                          superView:(UIView *_Nonnull)superView
                                              block:(void(^_Nullable)(void))block;

    /**
     下一首按钮(背景图片在DFPlayer.bundle中同名替换相应的图片即可)
     
     @param frame 按钮frame
     @param superView 按钮父视图
     @param block 按钮action 若无其他操作需求，传nil即可
     @return 下一首按钮
     */
    - (UIButton *_Nullable)df_nextAudioBtnWithFrame:(CGRect)frame
                                          superView:(UIView *_Nonnull)superView
                                              block:(void(^_Nullable)(void))block;

    /**
     播放类型设置按钮(单曲循环，顺序循环，随机循环)
     
     @param frame 按钮frame
     @param superView 按钮父视图
     @param block 按钮action 若无其他操作需求，传nil即可
     @return 播放类型设置按钮
     
     * 注意：当设置了DFPlayer的播放类型以后，DFPlayer将为您记录用户的选择，并在下次启动app时选择用户设置的播放类型。
     如需每次启动都设置固定某一个播放类型，请在初始化播放器后，调用[DFPlayerManager shareInstance].type = XX;重置播放类型。
     */
    - (UIButton *_Nullable)df_typeControlBtnWithFrame:(CGRect)frame
                                            superView:(UIView *_Nonnull)superView
                                                block:(void(^_Nullable)(void))block;


    /**
     缓冲进度条

     @param frame frame
     @param trackTintColor 未缓冲部分进度条颜色
     @param progressTintColor 已缓冲部分进度条颜色
     @param superView 进度条父视图
     @return 进度条
     */
    - (UIProgressView *_Nullable)df_bufferProgressViewWithFrame:(CGRect)frame
                                        trackTintColor:(UIColor *_Nonnull)trackTintColor
                                     progressTintColor:(UIColor *_Nonnull)progressTintColor
                                             superView:(UIView *_Nonnull)superView;

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
    - (UISlider *_Nullable)df_sliderWithFrame:(CGRect)frame
                       minimumTrackTintColor:(UIColor *_Nonnull)minimumTrackTintColor
                       maximumTrackTintColor:(UIColor *_Nonnull)maximumTrackTintColor
                                 trackHeight:(CGFloat)trackHeight
                                   thumbSize:(CGSize)thumbSize
                                   superView:(UIView *_Nonnull)superView;

    /**
     音频当前时间label

     @param frame frame
     @param superView label父视图
     @return label
     */
    - (UILabel *_Nullable)df_currentTimeLabelWithFrame:(CGRect)frame
                                    superView:(UIView *_Nonnull)superView;

    /**
     音频总时长label

     @param frame frame
     @param superView label父视图
     @return label
     */
    - (UILabel *_Nullable)df_totalTimeLabelWithFrame:(CGRect)frame
                                  superView:(UIView *_Nonnull)superView;

    /**
     lyricTableview
     ①采用lrc标准格式编写，即"[00:00.00]歌词" 或 "[00:00]歌词" 或 "[00:00:00]歌词"
     ②根据lrc歌词软件开发标准，凡具有“[*:*]”形式的都应认为是标签（注意：其中的冒号并非全角字符“：”）。凡是标签都不应显示。
     ③支持单句歌词多个时间的格式，如“[00:10.00][00:50.00][00:70.00]歌词”
     ④lrc歌词文件单行只有时间标签，没有歌词内容的，将被认作为上一个相邻时间内歌词的结束时间,并不做空行显示处理。比如
     [00:11.11]歌词
     [00:22.22] （22秒22毫米，该时间下无歌词显示，将被认作为上一个相邻时间歌词的演唱结束时间，此处的相邻不是位置的相邻，而是时间大小的相邻）
     ⑤如果歌词中需要空行，DFPlayer默认时间标签后的“####”是空行标志，如“[00:11.11]####”，DFPlayer将在解析到歌词为####时做空行显示
     详情查看demo中”许嵩(Vae)-有何不可.lrc“文件
     ⑥DFPlayer认为每个时间标签都是一个单元格。只不过时间标签后无歌词时，DFPlayer将该单元格隐藏。
     ⑦DFPlayer不对单句歌词做换行处理，所以单行歌词长度尽量不要超过tableview的宽度，当超出时，DFPlayer用省略号处理。
     
     @param frame tableview frame
     @param cellRowHeight tableview 单行rowHeight
     @param cellBackgroundColor cell背景色
     @param currentLineLrcForegroundTextColor 当前行歌词文字前景色（此属性不为空时，采用卡拉OK模式显示）
     @param currentLineLrcBackgroundTextColor 当前行歌词文字背景色
     @param otherLineLrcBackgroundTextColor 其他行歌词文字颜色
     @param currentLineLrcFont 当前行歌词字体
     @param otherLineLrcFont 其他行歌词字体
     @param superView 父视图
     @param block 点击某个歌词cell。indexpath：该行cell的indexpath
     @return 歌词tableView
     */
    - (UITableView *_Nullable)df_lyricTableViewWithFrame:(CGRect)frame
                                           cellRowHeight:(CGFloat)cellRowHeight
                                     cellBackgroundColor:(UIColor *_Nullable)cellBackgroundColor
                       currentLineLrcForegroundTextColor:(UIColor *_Nullable)currentLineLrcForegroundTextColor
                       currentLineLrcBackgroundTextColor:(UIColor *_Nonnull)currentLineLrcBackgroundTextColor
                         otherLineLrcBackgroundTextColor:(UIColor *_Nonnull)otherLineLrcBackgroundTextColor
                                      currentLineLrcFont:(UIFont *_Nonnull)currentLineLrcFont
                                        otherLineLrcFont:(UIFont *_Nonnull)otherLineLrcFont
                                               superView:(UIView *_Nonnull)superView
                                                   block:(void(^_Nullable)(NSIndexPath * _Nullable indexpath))block;

    /**DFPlayer不管理lyricTableview中歌词更新的暂停和恢复。当检测到*/
    /**适当的时候，发起此通知，停止更新lyricTableview中歌词的刷新*/
    FOUNDATION_EXPORT NSString * _Nullable const DFPlayerLyricTableviewStopUpdateNotification;
    /**适当的时候，发起此通知，恢复更新lyricTableview中歌词的刷新*/
    FOUNDATION_EXPORT NSString * _Nullable const DFPlayerLyricTableviewResumeUpdateNotification;
```
