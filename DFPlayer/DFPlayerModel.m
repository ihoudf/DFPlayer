//
//  DFPlayerModel.m
//  DFPlayer
//
//  Created by ihoudf on 2017/7/18.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import "DFPlayerModel.h"
#import "DFPlayerFileManager.h"

@implementation DFPlayerModel

@end

@implementation DFPlayerInfoModel

@end

@implementation DFPlayerPreviousAudioModel

- (NSDictionary *)infoDic{
    return [DFPlayerArchiverManager df_unarchiveInfoModelDictionary];
}

- (NSString *)audioUrlAbsoluteString{   
    return [[self infoDic] objectForKey:DFPlayerCurrentAudioInfoModelAudioUrl];
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
