//
//  NSObject+Extentions.m
//  DFPlayerDemo
//
//  Created by ihoudf on 2019/1/30.
//  Copyright © 2019年 HDF. All rights reserved.
//

#import "NSObject+Extentions.h"

@implementation NSObject (Extentions)

- (NSURL *)getAvailableURL:(NSString *)URLString{
    //如果链接中存在中文或某些特殊字符，需要通过以下代码转译。如果确认没有，可直接构造NSURL
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)URLString, (CFStringRef)@"!NULL,'()*+,-./:;=?@_~%#[]", NULL, kCFStringEncodingUTF8));
    //    NSString *encodedString = [yourUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSURL URLWithString:encodedString];
}

- (NSMutableArray<YourModel *> *)getYourModelArray{
    return [self getArray:@"AudioData"];
}

- (NSArray<YourModel *> *)getYourModelAddArray{
    return [NSMutableArray arrayWithArray:[self getArray:@"AudioDataAdd"]];
}

- (NSMutableArray<YourModel *> *)getArray:(NSString *)fileName{
    NSMutableArray *array = [NSMutableArray array];
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];
    NSArray *arr = [[NSArray alloc] initWithContentsOfFile:path];
    for (int i = 0; i < arr.count; i++) {
        NSDictionary *dic = arr[i];
        YourModel *model = [[YourModel alloc] init];
        model.yourUrl = [dic valueForKey:@"audioUrl"];
        model.yourName = [dic valueForKey:@"audioName"];
        model.yourSinger = [dic valueForKey:@"audioSinger"];
        model.yourAlbum = [dic valueForKey:@"audioAlbum"];
        model.yourImage = [dic valueForKey:@"audioImage"];
        model.yourLyric = [dic valueForKey:@"audioLyric"];
        [array addObject:model];
    }
    return array;
}

- (UIImage *)getBackgroundImage:(UIImage *)image{
    if (image) {
        CGFloat imgW = image.size.height*SCREEN_WIDTH/SCREEN_HEIGHT;
        CGRect imgRect = CGRectMake((image.size.width-imgW) / 2, 0, imgW, image.size.height);
        image = [image getSubImage:imgRect];
    }
    return image;
}

- (UIImageView *)bgView:(UIView *)superView{
    UIImageView *view = [[UIImageView alloc] initWithFrame:superView.bounds];
    view.backgroundColor = [UIColor whiteColor];
    view.image = [UIImage imageNamed:@"default_bg.jpg"];
    view.userInteractionEnabled = YES;
    [superView addSubview:view];
    if (@available(iOS 8.0,*)) {
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        effectView.frame = view.frame;
        [view addSubview:effectView];
    }
    return view;
}


@end



@implementation UIImage (Extentions)

- (UIImage *)getSubImage:(CGRect)rect{
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


@implementation UIViewController (Extensions)

- (void)showAlert:(NSString *)title{
    if (@available(iOS 8.0,*)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showAlert:(NSString *)title okBlock:(void(^)(void))okBlock{
    if (@available(iOS 8.0,*)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:@"" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:NULL];
        
        UIAlertAction *certainAction = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            if (okBlock) {
                okBlock();
            }
        }];
        [alert addAction:cancelAction];
        [alert addAction:certainAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showRateAlertSheetBlock:(void(^)(CGFloat rate))block{
    if (@available(iOS 8.0,*)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择倍速" message:@"" preferredStyle:(UIAlertControllerStyleActionSheet)];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:NULL];
        
        NSArray *array = @[@"0.5",@"0.67",@"0.80",@"1.0",@"1.25",@"1.50",@"2.0"];
        for (int i = 0; i < array.count; i++) {
            UIAlertAction *act = [UIAlertAction actionWithTitle:array[i] style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                if (block) {
                    block([array[i] floatValue]);
                }
            }];
            [alert addAction:act];
        }
        [alert addAction:cancelAction];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

@end
