# <img src="https://github.com/ihoudf/DFPlayer/blob/master/dfplayer_logo388x83.png?raw=true" width="260">
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/build-passing-green.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer/blob/master/LICENSE" target="blank"><img src="https://img.shields.io/badge/license-MIT-brightgreen.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/platform-iOS-blue.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer"><img src="https://img.shields.io/badge/support-iOS%207%2B-yellowgreen.svg"></a>
<a href="https://github.com/ihoudf/DFPlayer" target="blank"><img src="https://img.shields.io/badge/lauguage-Objective--C-orange.svg"></a>


# DFPlayer2.0.3版本来啦！使用更简单、代码更清晰

#### 简单灵活的iOS音频播放组件。基于AVPlayer，支持本地和远程音频播放，具有缓存、耳机线控、锁屏和控制中心信息展示、单曲顺序随机播放、倍速播放、歌词同步等音频播放器功能，DFPlayer封装了缓冲条、进度条、播放暂停按钮、下一首按钮、上一首按钮、播放模式按钮、歌词同步的tableview等UI控件，一行代码布局即可实现相应功能。


- ##### DFPlayer：关于iOS音频播放，传音频数据给我就好了🙃
- ##### 截图展示：
<a href=""><img width="275" src="https://github.com/ihoudf/DFPlayer/blob/master/DFPlayerImage1.png?raw=true"></a>
<a href=""><img width="275" src="https://github.com/ihoudf/DFPlayer/blob/master/DFPlayerImage2.png?raw=true"></a>
<a href=""><img width="275" src="https://github.com/ihoudf/DFPlayer/blob/master/DFPlayerImage3.png?raw=true"></a>

<br>

## -- 支持
- 本地和远程音频播放
- 边下边播
- 分账户缓存（根据不同用户建立不同缓存地址）、清除缓存
- 耳机线控
- 锁屏和控制中心音频信息展示及控制
- 单曲顺序随机播放
- 歌词同步（提供逐句和逐字两种模式的基于Lrc的歌词同步）
- 倍速播放
- 流量监测（使用流量播放时提示）
- 断点续传

<br>

## -- 版本
  
  本次更新：
  <br>1、减小包体积，将图片资源移入外部传入
  <br>2、优化代码
  <br><a href="https://github.com/ihoudf/DFPlayer/blob/master/Document.md" target="blank">查看历史版本点击这里</a>

  <br>

## -- 安装（最低支持 iOS 7.1）
###### 手动安装
```
    1、下载并将DFPlayer文件夹拖进工程
    2、import "DFPlayer.h"
```
###### CocoaPods
```
    1、在Podfile中添加: pod 'DFPlayer'
    2、执行pod install 或 pod update
    3、import "DFPlayer.h"
    Ps:pod拉取代码的同学，首先核查DFPlayer.h中注明的版本号，没有或不是2.0.3都不是最新的。
```

<br>

## -- 使用
DFPlayer的使用十分简单。
##### 一、详细文档：<a href="https://github.com/ihoudf/DFPlayer/blob/master/Document.md" target="blank">查看所有API点击这里</a>

##### 二、简要说明：
1、初始化DFPlayer，并设置数据源（必须）
```
    [[DFPlayer sharedPlayer] df_initPlayerWithUserId:nil];//初始化
    [DFPlayer sharedPlayer].dataSource = self;//设置数据源
    [[DFPlayer sharedPlayer] df_reloadData];//刷新数据源
```
2、实现数据源，传数据给DFPlayer（必须）
```
    //（必须）
    - (NSArray<DFPlayerModel *> *)df_audioDataForPlayer:(DFPlayer *)player{
        //在这里将音频数据传给DFPlayer
    }
```
3、传入audioId准备播放(必须)
```
    [[DFPlayer sharedPlayer] df_playWithAudioId:audioId];
```
4、选择DFPLayer中提供的UI控件，布局到页面（可选）
> DFPlayer封装了歌词tableview、缓冲条、进度条、播放暂停按钮、下一首按钮、上一首按钮、播放模式按钮（单曲、顺序、随机）、当前时间Label、总时间Label。
>> 只需调用DFPlayerUIManager.h中暴露的方法布局到页面，即可实现相应功能，无需其他代码。

示例：
```
    DFPlayerUIManager *mgr = [DFPlayerUIManager sharedManager];

    //播放暂停按钮
    [mgr df_playPauseBtnWithFrame:playRect playImage:playImage pauseImage:pauseImage superView:_bgView block:nil];

    //下一首按钮
    [mgr df_nextBtnWithFrame:nextRext image:nextImage superView:_bgView block:nil];

    //上一首按钮
    [mgr df_lastBtnWithFrame:lastRect image:lastImage superView:_bgView block:nil];

    ...等，详查"详细文档"。
```

<br>

## -- 许可证
使用 MIT 许可证，详见<a href="https://github.com/ihoudf/DFPlayer/blob/master/LICENSE">LICENSE</a> 文件。
<br>

<br>

## THANKS!
关于DFPlayer的业务需求改进、bug反馈在<a href="https://github.com/ihoudf/DFPlayer/issues" target="blank">这里</a>提交。
<br>
<font color="#42C485">工作合作qq：188816190</font>
<br>
<br>

