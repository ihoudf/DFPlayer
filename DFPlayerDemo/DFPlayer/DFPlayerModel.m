//
//  DFPlayerModel.m
//  DFPlayer
//
//  Created by HDF on 2017/7/18.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "DFPlayerModel.h"
#import "DFPlayerFileManager.h"

@implementation DFPlayerModel


@end

NSString *const DFPlayerCurrentAudioInfoModelAudioId        = @"DFPlayerCurrentAudioInfoModelAudioId";
NSString *const DFPlayerCurrentAudioInfoModelAudioUrl       = @"DFPlayerCurrentAudioInfoModelAudioUrl";
NSString *const DFPlayerCurrentAudioInfoModelAudioLyric     = @"DFPlayerCurrentAudioInfoModelAudioLyric";
NSString *const DFPlayerCurrentAudioInfoModelAudioName      = @"DFPlayerCurrentAudioInfoModelAudioName";
NSString *const DFPlayerCurrentAudioInfoModelAudioAlbum     = @"DFPlayerCurrentAudioInfoModelAudioAlbum";
NSString *const DFPlayerCurrentAudioInfoModelAudioSinger    = @"DFPlayerCurrentAudioInfoModelAudioSinger";
NSString *const DFPlayerCurrentAudioInfoModelAudioImage     = @"DFPlayerCurrentAudioInfoModelAudioImage";
NSString *const DFPlayerCurrentAudioInfoModelIsCached       = @"DFPlayerCurrentAudioInfoModelIsCached";
NSString *const DFPlayerCurrentAudioInfoModelCurrentTime    = @"DFPlayerCurrentAudioInfoModelCurrentTime";
NSString *const DFPlayerCurrentAudioInfoModelTotalTime      = @"DFPlayerCurrentAudioInfoModelTotalTime";
NSString *const DFPlayerCurrentAudioInfoModelProgress       = @"DFPlayerCurrentAudioInfoModelProgress";

@implementation DFPlayerPreviousAudioModel

- (NSDictionary *)infoDic{
    return [DFPlayerArchiverManager df_unarchiveInfoModelDictionary];
}
- (NSUInteger)audioId{
    return [[[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelAudioId] unsignedIntegerValue];
}
- (NSURL *)audioUrl{
    return [NSURL URLWithString:[[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelAudioUrl]];
}
- (NSString *)audioLyric{
    return [[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelAudioLyric];
}
- (NSString *)audioName{
    return [[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelAudioName];
}
- (NSString *)audioAlbum{
    return [[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelAudioAlbum];
}
- (NSString *)audioSinger{
    return [[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelAudioSinger];
}
- (UIImage *)audioImage{
    return [[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelAudioImage];
}
- (BOOL)isCached{
    return [[[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelIsCached] boolValue];
}
- (CGFloat)currentTime{
    return [[[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelCurrentTime] floatValue];
}
- (CGFloat)totalTime{
    return [[[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelTotalTime] floatValue];
}
- (CGFloat)progress{
    return [[[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelProgress] floatValue];
}

@end
