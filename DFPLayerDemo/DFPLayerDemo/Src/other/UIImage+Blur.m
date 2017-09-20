//
//  UIImage+Blur.m
//  DFPlayer
//
//  Created by Faroe on 2017/9/19.
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


- (UIImage *)blurImageUseCoreImageWithBlurLevel:(CGFloat)blurLevel{
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [[CIImage alloc] initWithImage:self];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:blurLevel] forKey:@"inputRadius"];
    CIImage *result=[filter outputImage];
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
    UIImage *image1 = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image1;
}


@end
