# <img src="https://github.com/ihoudf/DFPlayer/blob/master/DFPlayerLogo/dfplayer_logo388x83.png?raw=true" width="260">
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/build-passing-green.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/pod-1.0.1-yellow.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer/blob/master/LICENSE" target="blank"><img src="https://img.shields.io/badge/license-MIT-brightgreen.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/platform-iOS-blue.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/support-iOS%207%2B-yellowgreen.svg"></a>
<a href="https://ihoudf.github.io/" target="blank"><img src="https://img.shields.io/badge/homepage-ihoudf-brightgreen.svg"></a>

##### A simple and flexible iOS audio playback module. Based on AVPlayer, support local and remote audio playback, with caching, remote control, locking and control center information display, single sequential and random playback and other basic audio player functions, using a few code can realize the function of player.（简单又灵活的iOS音频播放组件。基于AVPlayer，支持本地和远程音频播放，具有缓存、耳机线控、锁频和控制中心信息展示、单曲顺序和随机播放等基本的音频播放器功能，DFPlayer封装了播放按钮、进度条等UI控件，一行代码布局即可实现相应功能。）

- ##### 观看两分钟视频介绍:[http://www.iqiyi.com/w_19ruzcqjqh.html](http://www.iqiyi.com/w_19ruzcqjqh.html)
- ##### 截图展示：

<img width="282" src="https://github.com/ihoudf/DFPlayer/blob/master/DFPLayerImage1.png?raw=true">&nbsp;<img width="282" src="https://github.com/ihoudf/DFPlayer/blob/master/DFPlayerImage2.png?raw=true">&nbsp;<img width="282" src="https://github.com/ihoudf/DFPlayer/blob/master/DFPlayerImage3.png?raw=true">

#
### 安装（最低支持 iOS 7.0）
###### CocoaPods
```
    1.在 Podfile 中添加:  pod 'DFPlayer', '~> 1.0.1'
    2.执行 pod install 或 pod update
    3.import "DFPlayer.h"
```

###### 手动安装
```
    1.下载 DFPlayer 文件夹内的所有内容
    2.将 DFPlayer文件夹添加(拖放)到你的工程
    3.import "DFPlayer.h"
```
> DFPLayer使用AFNetworkReachabilityManager进行网络监测，如正在使用AFNetWorking，删除DFPlayer中的相关文件。


### 使用
DFPlayer的使用十分简单。
##### 详细文档：[DFPlayer详细文档](https://ihoudf.github.io/2017/09/29/DFPlayer%E6%8E%A5%E5%85%A5%E8%AF%B4%E6%98%8E/#df-doc)
##### 简要说明：
1.初始化DFPlayer，设置数据源（必须）
```
    [[DFPlayerManager shareInstance] initPlayerWithUserId:nil];//初始化
    [DFPlayerManager shareInstance].dataSource  = self;//设置数据源
    [[DFPlayerManager shareInstance] df_reloadData];//刷新数据源
```
2.实现数据源，将音频数据传给DFPlayer（必须）
```
    //（必须）
    - (NSArray<DFPlayerModel *> *)df_playerModelArray{
        //在这里将音频数据传给DFPlayer
    }

    //（可选）
    - (DFPlayerInfoModel *)df_playerAudioInfoModel:(DFPlayerManager *)playerManager{
        //DFPlayer收到某个音频的播放请求时，会调用这个方法请求该音频的音频名、歌手、专辑名、歌词、配图等信息。
    }
```
3.开始播放(必须)
```
    [[DFPlayerManager shareInstance] df_playerPlayWithAudioId:audioId];
```
4.选择DFPLayer中提供的UI控件，布局到页面（可选）
> DFPlayer封装了歌词tableview（提供逐句和逐字两种模式的歌词同步）、缓冲条、进度条、播放模式按钮（单曲、顺序、随机）、播放暂停按钮、下一首按钮、上一首按钮、当前时间Label、总时间Label。
>> 你只需要<br>
（1）同名更换DFPlayer.bundle中的图片<br>
（2）调用DFPlayerControlManager.h中暴露出来的方法，布局到自己的页面，即可实现相应的功能，无需其他代码。
```
    //使用示例：
    DFPlayerControlManager *manager = [DFPlayerControlManager shareInstance];
    //播放暂停按钮
    [manager df_playPauseBtnWithFrame:frame2 superView:superView block:nil];
    //下一首按钮
    [manager df_nextAudioBtnWithFrame:frame3 superView:superView block:nil];
    //上一首按钮
    [manager df_lastAudioBtnWithFrame:frame4 superView:superView block:nil];
    ...等，详细查看‘详细文档’。
```

### 许可证
使用 MIT 许可证，详情见<a href="https://github.com/ihoudf/DFPlayer/blob/master/LICENSE">LICENSE</a> 文件。

#
### Installation（required iOS 7.0+）
###### CocoaPods
```
    1.Podfile: pod 'DFPlayer', '~> 1.0.1'
    2.Run pod install or pod update.
    3.import "DFPlayer.h"
```
###### Manually
```
    1.Download all the files in the DFPlayer subdirectory.
    2.Add the DFPlayer group to your Xcode project.
    3.import "DFPlayer.h"
```
> DFPLayer use AFNetworkReachabilityManager to monitor network status,if you are using AFNetWorking,delete releative file in DFPlayer group.

### Use
The use of DFPlayer is so easy.
##### Detailed documentation：[DFPlayer documents](https://ihoudf.github.io/2017/09/29/DFPlayer%E6%8E%A5%E5%85%A5%E8%AF%B4%E6%98%8E/#df-doc)
##### Use Statement：
1. Init DFPlayer,and set dataSource（required）
```
    [[DFPlayerManager shareInstance] initPlayerWithUserId:nil];
    [DFPlayerManager shareInstance].dataSource  = self;
    [[DFPlayerManager shareInstance] df_reloadData];
```
2.Implement the dataSource method,send data to DFPlayer（required）
```
    //required
    - (NSArray<DFPlayerModel *> *)df_playerModelArray{
        //send data to DFPlayer
    }

    //optional
    - (DFPlayerInfoModel *)df_playerAudioInfoModel:(DFPlayerManager *)playerManager{
        //When prepare to play,DFPlayer get audio message like audio name by this method.
    }
```
3.Start playing(required)
```
    [[DFPlayerManager shareInstance] df_playerPlayWithAudioId:audioId];
```
4.Select the method DFPlayer provide，layout your UI（optional）

> DFPlayer provide lyrics tableview,buffering bar,progress bar,type button（single circle、order circle、shuffle circle）、play pause button、next audio button、last audio button、current time Label、total time label.
>> you can
<br>（1）Exchange the image in DFPlayer.bundle with the same name.
<br>（2）Using the method exposed in DFPlayerControlManager.h, layout to your own page, you can achieve the corresponding function, without other code.

```
    //example：
    DFPlayerControlManager *manager = [DFPlayerControlManager shareInstance];

    //play pause button
    [manager df_playPauseBtnWithFrame:frame2 superView:superView block:nil];

    //next audio button
    [manager df_nextAudioBtnWithFrame:frame3 superView:superView block:nil];
    
    //last audio button
    [manager df_lastAudioBtnWithFrame:frame4 superView:superView block:nil];
    ...
```


### License
provided under the MIT license. See <a href="https://github.com/ihoudf/DFPlayer/blob/master/LICENSE">LICENSE</a>  file for details.

# THANKS!

<font color="#42C485">qq交流群，bug提交群：479873475</font>
<br>
<font color="#42C485">合作qq：188816190</font>
<br>
<br>
<br>

