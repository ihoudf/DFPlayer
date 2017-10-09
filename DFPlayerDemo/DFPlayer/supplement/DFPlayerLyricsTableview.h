//
//  DFPlayerLyricsTableview.h
//  DFPlayer
//
//  Created by HDF on 2017/8/16.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <UIKit/UIKit.h>
static NSString *DFPLayerNotificationDragStatus = @"DFPlayerNotificationDragStatus";

@interface DFPlayerLyricsTableview : UITableView

@property (nonatomic, assign) CGFloat cellRowHeight;
@property (nonatomic, strong) UIColor *cellBackgroundColor;
@property (nonatomic, strong) UIColor *currentLineLrcForegroundTextColor;
@property (nonatomic, strong) UIColor *currentLineLrcBackgroundTextColor;
@property (nonatomic, strong) UIColor *otherLineLrcBackgroundTextColor;
@property (nonatomic, strong) UIFont *currentLineLrcFont;
@property (nonatomic, strong) UIFont *otherLineLrcFont;
@property (nonatomic, copy) void(^block)(NSIndexPath *indexPath);
@property (nonatomic, strong) NSString *DFPlayerLyricTableviewStopUpdateNotification;
@property (nonatomic, strong) NSString *DFPlayerLyricTableviewResumeUpdateNotification;

@end
