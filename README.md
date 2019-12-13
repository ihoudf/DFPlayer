# <img src="https://github.com/ihoudf/DFPlayer/blob/master/dfplayer_logo388x83.png?raw=true" width="260">
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/build-passing-green.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/pod-1.0.5-yellow.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer/blob/master/LICENSE" target="blank"><img src="https://img.shields.io/badge/license-MIT-brightgreen.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/platform-iOS-blue.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/support-iOS%207%2B-yellowgreen.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer" target="blank"><img src="https://img.shields.io/badge/lauguage-Objective--C-orange.svg"></a>
<a href="https://ihoudf.github.io/" target="blank"><img src="https://img.shields.io/badge/homepage-ihoudf-brightgreen.svg"></a>


##### A simple and flexible iOS audio playback module. Based on AVPlayer, support local and remote audio playback, with caching, remote control, locking and control center information display, single sequential and random playback,airplay,Lyrics sync,and other basic audio player functions, using a few code can realize the function of player.（简单灵活的iOS音频播放组件。基于AVPlayer，支持本地和远程音频播放，具有缓存、耳机线控、锁屏和控制中心信息展示、单曲顺序随机播放、歌词同步、倍速播放等基本的音频播放器功能，DFPlayer封装了缓冲条、进度条、播放暂停按钮、下一首按钮、上一首按钮、播放模式按钮、歌词同步的tableview等UI控件，一行代码布局即可实现相应功能。）


- ##### DFPlayer：关于iOS音频播放，传音频数据给我就好了🙃
- ##### 观看两分钟视频展示：<a href="http://www.iqiyi.com/w_19ruzcqjqh.html" target="blank">http://www.iqiyi.com/w_19ruzcqjqh.html</a>
- ##### 截图展示：
<img width="282" src="https://github.com/ihoudf/DFPlayer/blob/master/DFPlayerImage1.webp?raw=true">
<img width="282" src="https://github.com/ihoudf/DFPlayer/blob/master/DFPlayerImage2.webp?raw=true">
<img width="282" src="https://github.com/ihoudf/DFPlayer/blob/master/DFPlayerImage3.webp?raw=true">

#
## -- 支持
    1、支持本地和远程音频播放
    2、分账户缓存（根据不同用户建立不同缓存地址）、清除缓存
    3、耳机线控
    4、锁屏和控制中心信息展示及控制
    5、单曲顺序随机播放
    6、歌词同步（提供逐句和逐字两种模式的基于Lrc的歌词同步）
    7、倍速播放
    8、流量监测（使用流量播放时提示）
    9、断点续传

<br>

## -- 安装（最低支持 iOS 7.1）
###### 手动安装
```
    1.下载，并将DFPlayer文件夹拖放到工程
    2.import "DFPlayer.h"
```
###### CocoaPods
```
    1.在 Podfile 中添加:  pod 'DFPlayer'
    2.执行 pod install 或 pod update
    3.import "DFPlayer.h"
```
<br>

## -- 使用
DFPlayer的使用十分简单。
##### 详细文档：<a href="https://ihoudf.github.io/2017/10/26/DFPlayer%E6%8E%A5%E5%85%A5%E8%AF%B4%E6%98%8E/#df-doc" target="blank">查看所有API点击这里</a>

##### 简要说明：
1.初始化DFPlayer，设置数据源（必须）
```
    [[DFPlayer shareInstance] df_initPlayerWithUserId:nil];//初始化
    [DFPlayer shareInstance].dataSource = self;//设置数据源
    [[DFPlayer shareInstance] df_reloadData];//刷新数据源
```
2.实现数据源，将音频数据传给DFPlayer（必须）
```
    //（必须）
    - (NSArray<DFPlayerModel *> *)df_audioDataForPlayer:(DFPlayer *)player{
        //在这里将音频数据传给DFPlayer
    }

    //（可选）
    - (DFPlayerInfoModel *)df_audioInfoForPlayer:(DFPlayer *)player{
        //DFPlayer收到某个音频的播放请求时，会调用这个方法请求该音频的音频名、歌手、专辑名、歌词、配图等信息。
    }
```
3.选择AudioId对应的音频加入播放队列准备播放(必须)
```
    [[DFPlayer shareInstance] df_playWithAudioId:audioId];
```
4.选择DFPLayer中提供的UI控件，布局到页面（可选）
> DFPlayer封装了歌词tableview、缓冲条、进度条、播放暂停按钮、下一首按钮、上一首按钮、播放模式按钮（单曲、顺序、随机）、当前时间Label、总时间Label。
>> 你只需要<br>
（1）同名更换DFPlayer.bundle中的图片<br>
（2）调用DFPlayerControlManager.h中暴露出来的方法，布局到自己的页面，即可实现相应的功能，无需其他代码。
```
    //使用示例：
    DFPlayerControlManager *mgr = [DFPlayerControlManager shareInstance];
    //播放暂停按钮
    [mgr df_playPauseBtnWithFrame:frame1 superView:superView block:nil];
    //下一首按钮
    [mgr df_nextAudioBtnWithFrame:frame2 superView:superView block:nil];
    //上一首按钮
    [mgr df_lastAudioBtnWithFrame:frame3 superView:superView block:nil];
    ...等，详细查看‘详细文档’。
```

<br>

## -- 许可证
使用 MIT 许可证，详见<a href="https://github.com/ihoudf/DFPlayer/blob/master/LICENSE">LICENSE</a> 文件。

## THANKS!
如果您对DFPlayer有业务需求改进或发现bug，欢迎在<a href="https://github.com/ihoudf/DFPlayer/issues" target="blank">这里</a>提交。
<br>
<font color="#42C485">合作qq：188816190</font>
<br>
<br>

