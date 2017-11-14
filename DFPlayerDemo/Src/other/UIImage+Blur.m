//
//  UIImage+Blur.m
//  DFPlayer
//
//  Created by HDF on 2017/9/19.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import "UIImage+Blur.h"

@implementation UIImage (Blur)
-(UIImage *)getSubImage:(CGRect)rect{
    if (rect.origin.x+rect.size.width > self.size.width || rect.origin.y+rect.size.height > self.size.height) {
        return self;
    }
    CGImageRef subImageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    UIGraphicsBeginImageContext(smallBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    UIImage *smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    return smallImage;
}
@end
