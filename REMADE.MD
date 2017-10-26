# <img src="https://github.com/ihoudf/DFPlayer/blob/master/image/dfplayer_logo750x120.png?raw=true" width="375">
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/build-passing-green.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/pod-1.0.0-yellow.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer/blob/master/LICENSE" target="blank"><img src="https://img.shields.io/badge/license-MIT-brightgreen.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/platform-iOS-blue.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/support-iOS%207%2B-yellowgreen.svg"></a>
<a href="https://ihoudf.github.io/" target="blank"><img src="https://img.shields.io/badge/homepage-ihoudf-brightgreen.svg"></a>

##### Build iOS audio player like building blocks. Based on AVPlayer, support local and remote audio playback, with caching, remote control, locking and control center information display, single sequential and random playback and other basic audio player functions, using a few code can realize the function of player.（像搭积木一样搭建iOS音频播放器。基于AVPlayer，支持本地和远程音频播放，具有缓存、耳机线控、锁频和控制中心信息展示、单曲顺序和随机播放等基本的音频播放器功能，让您用极少的代码就可实现播放器功能。）· If possible, please give me a star in github.✧(≖ ◡ ≖✿)
##
<!-- <img width="375" src="https://github.com/ihoudf/DFLabelSizeFit/blob/master/IMG_4877.JPG?raw=true"> -->
##### DFPlayer——简单又灵活的iOS音频组件
(1) 基于AVPlayer，支持本地和远程音频播放，具有缓存、耳机线控、锁频和控制中心信息展示、单曲顺序和随机播放等基本的音频播放器功能
<br>(2) 提供支持歌词同步的tableview、播放暂停按钮、缓冲条、进度条、播放类型按钮（单曲、顺序、随机）、下一首按钮、上一首按钮等控件，直接调用方法布局到你的页面，即可实现相应功能，无需其他代码。歌词tableview基于lrc歌词实现。支持逐字、逐句两种形式的歌词同步。
<br>(3) DFPlayer能够记录上次杀死app时正在播放的音频和播放进度等信息，并能在下次启动app时，定位到相应位置（可选功能）
<br>(4) DFPlayer支持一人一个账户体系，缓存地址不混用。提供了清理缓存的接口。
使用AFNetworkReachabilityManager监测网络状态，处理各种网络状态下的播放情况。（使用AFNetWorking组件的小伙伴可直接删除DFPlayer中的AFNetworkReachabilityManager相关文件。）



### 安装
##### · 最低支持 iOS 7.0
###### CocoaPods
```
    1.在 Podfile 中添加 pod 'DFPlayer'。
    2.执行 pod install 或 pod update。
    3.导入 "DFPlayer.h"。
```

###### 手动安装
```
    1.下载 DFPlayer 文件夹内的所有内容。
    2.将 DFPlayer文件夹添加(拖放)到你的工程。
    3.import "DFPlayer.h"
```


### 使用
DFPlayer的使用十分简单。
##### 详细文档：
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
```
    //DFPlayer封装了歌词tableview、缓冲条、进度条、播放类型按钮（单曲、顺序、随机）、播放暂停按钮、下一首按钮、上一首按钮、当前时间Label、总时间Label。
    您只需要
    (1)同名更换DFPlayer.bundle中的图片
    (2)调用DFPlayerControlManager.h中暴露出来的方法，布局到自己的页面，即可实现相应的功能，无需其他代码。

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

### Installation
##### · required iOS 7.0+
###### CocoaPods
```
    1.Add pod 'DFPlayer' to your Podfile.
    2.Run pod install or pod update.
    3.import "DFPlayer.h"
```
###### Manually
```
    1.Download all the files in the DFPlayer subdirectory.
    2.Add the DFPlayer group to your Xcode project.
    3.import "DFPlayer.h
```

### Use
The use of DFPlayer is so easy.
##### Detailed documentation：
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
        //When prepare to play,DFPlayer get the message of audio name,singer,album,lyrics and image by this method.
    }
```
3.Start playing(required)
```
    [[DFPlayerManager shareInstance] df_playerPlayWithAudioId:audioId];
```
4.Select the method DFPlayer provide，layout your UI（optional）
```
    //DFPlayer provide lyrics tableview,buffering bar,progress bar,type button（single circle、order circle、shuffle circle）、play pause button、next audio button、last audio button、current time Label、total time label.
    you can
    (1)exchange the image in DFPlayer.bundle with the same name.
    (2)Using the method exposed in DFPlayerControlManager.h, layout to your own page, you can achieve the corresponding function, without other code.

    //example：
    DFPlayerControlManager *manager = [DFPlayerControlManager shareInstance];
    //play pause button
    [manager df_playPauseBtnWithFrame:frame2 superView:superView block:nil];
    //next audio button
    [manager df_nextAudioBtnWithFrame:frame3 superView:superView block:nil];
    //last audio button
    [manager df_lastAudioBtnWithFrame:frame4 superView:superView block:nil];
```


### License
provided under the MIT license. See <a href="https://github.com/ihoudf/DFPlayer/blob/master/LICENSE">LICENSE</a>  file for details.

<br>
# THANKS!
<br>
<font color="#42C485">qq交流群，bug提交群：479873475</font>
<br>
<font color="#42C485">合作qq：188816190</font>
<br>
<br>
<br>

