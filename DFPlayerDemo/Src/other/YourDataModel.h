//
//  YourDataModel.h
//  DFPlayer
//
//  Created by HDF on 2017/8/4.
//  Copyright © 2017年 HDF. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YourDataModel : NSObject

/**音频地址*/
@property (nonatomic, copy) NSString    *yourUrl;

/**音频名*/
@property (nonatomic, copy) NSString    *yourName;

/**歌手名*/
@property (nonatomic, copy) NSString    *yourSinger;

/**专辑名*/
@property (nonatomic, copy) NSString    *yourAlbum;

/**专辑名*/
@property (nonatomic, copy) NSString    *yourImage;

/**歌词*/
@property (nonatomic, copy) NSString    *yourLyric;

//and so on

@end
