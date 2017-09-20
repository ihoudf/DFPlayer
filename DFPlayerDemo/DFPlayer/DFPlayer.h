//
//  DFPlayer.h
//  DFPlayer
//
//  Created by HDF on 2017/7/18.
//  Copyright © 2017年 HDF. All rights reserved.
//


#import "DFPlayerManager.h"
#import "DFPlayerControlManager.h"
#import "DFPlayerModel.h"
/*
 
 DFPLayer，像搭积木一样的搭建iOS音频播放器。基于AVPlayer，
 
 1.支持本地音频和在线音频播放
 2.支持一人一个账户体系。缓存列表不混用。
 2.缓存功能。提供缓存列表，清理缓存接口。
 3.支持单曲单次播放、单曲循环播放、循环播放、随机播放
 4.锁屏模式、后台模式信息展示。
 5.airplay播放。
 6.耳机线控。
 7.可以为您记录上次杀死app时播放的音频信息。下次启动app继续播放
 8.可以比较服务器音频资源更新时间。不必频繁更换文件名，以更新资源。
  3.使用AFNetworkReachabilityManager监测网络
 
 */


/**
 实现播放只需要3步
 
 
 */
