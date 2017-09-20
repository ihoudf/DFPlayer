//
//  UIImage+Blur.h
//  DFPlayer
//
//  Created by Faroe on 2017/9/19.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Blur)
-(UIImage*)getSubImage:(CGRect)rect;
- (UIImage *)blurImageUseCoreImageWithBlurLevel:(CGFloat)blurLevel;
@end
