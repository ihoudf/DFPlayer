//
//  DFPlayerRemoteApplication.m
//  DFPlayer
//
//  Created by HDF on 2017/8/10.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayerRemoteApplication.h"
#import "DFPlayer.h"

@implementation DFPlayerRemoteApplication

- (BOOL)canBecomeFirstResponder{
    return YES;
}

-(void)remoteControlReceivedWithEvent:(UIEvent *)event{    
    if (event.type == UIEventTypeRemoteControl) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                [[DFPlayer shareInstance] df_audioPlay];

                //播放：100
                break;
            case UIEventSubtypeRemoteControlPause:
                [[DFPlayer shareInstance] df_audioPause];

                //暂停：101
                break;
            case UIEventSubtypeRemoteControlStop:
                //停止：102
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
            {
                //播放暂停切换键：103
                if ([DFPlayer shareInstance].state == DFPlayerStatePlaying) {
                    [[DFPlayer shareInstance] df_audioPause];
                }else{
                    [[DFPlayer shareInstance] df_audioPlay];
                }
            }
                break;
            case UIEventSubtypeRemoteControlNextTrack:
            {
                //双击暂停键（下一曲）：104
                [[DFPlayer shareInstance] df_audioNext];
            }
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
            {
                //三击暂停键（上一曲）：105
                [[DFPlayer shareInstance] df_audioLast];
            }
                break;
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                //三击不松开（快退开始）：106
                break;
            case UIEventSubtypeRemoteControlEndSeekingBackward:
                //三击到了快退的位置松开（快退停止）：107
                break;
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                //两击不要松开（快进开始）：108
                break;
            case UIEventSubtypeRemoteControlEndSeekingForward:
                //两击到了快进的位置松开（快进停止）：109
                break;
            default:
                break;
        }
    }
}

@end
