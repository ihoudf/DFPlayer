//
//  DFPlayerLyricsTableview.h
//  DFPlayer
//
//  Created by ihoudf on 2017/8/16.
//  Copyright © 2017年 ihoudf. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DFPlayerLyricsTableview;

@protocol DFPlayerLyricsTableviewDelegate <NSObject>

@optional
- (void)df_lyricsTableview:(DFPlayerLyricsTableview *)lyricsTableview
           onPlayingLyrics:(NSString *)onPlayingLyrics;

@end

@interface DFPlayerLyricsTableview : UITableView

@property (nonatomic, weak) id<DFPlayerLyricsTableviewDelegate> lyricsDelegate;

@property (nonatomic, assign) BOOL stopUpdate;

@property (nonatomic, assign) CGFloat cellRowHeight;

@property (nonatomic, strong) UIColor *cellBackgroundColor;

@property (nonatomic, strong) UIColor *currentLineLrcForegroundTextColor;

@property (nonatomic, strong) UIColor *currentLineLrcBackgroundTextColor;

@property (nonatomic, strong) UIColor *otherLineLrcBackgroundTextColor;

@property (nonatomic, strong) UIFont *currentLineLrcFont;

@property (nonatomic, strong) UIFont *otherLineLrcFont;

@property (nonatomic, strong) UIView *lrcTableViewSuperview;

@end
