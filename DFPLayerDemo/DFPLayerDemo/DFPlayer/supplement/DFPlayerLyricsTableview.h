//
//  DFPlayerLyricsTableview.h
//  DFPlayer
//
//  Created by HDF on 2017/8/16.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface DFPlayerLyricsTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *backgroundLrcLabel;
@property (nonatomic, strong) UILabel *ForegroundLrcLabel;
@property (nonatomic, strong) CALayer *lrcMasklayer;

@end


@interface DFPlayerLyricsTableview : UITableView

@property (nonatomic, strong) UIColor *cellBackgroundColor;
@property (nonatomic, strong) UIColor *currentLineLrcForegroundTextColor;
@property (nonatomic, strong) UIColor *currentLineLrcBackgroundTextColor;
@property (nonatomic, strong) UIColor *otherLineLrcBackgroundTextColor;
@property (nonatomic, strong) UIFont *currentLineLrcFont;
@property (nonatomic, strong) UIFont *otherLineLrcFont;
@property (nonatomic, assign) CGRect lrcLabelFrame;

@end
