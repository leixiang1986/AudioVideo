//
//  H264Decoder.h
//  SoftVideoDecoding
//
//  Created by mac on 2018/12/14.
//  Copyright © 2018年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface H264Decoder : NSObject
- (instancetype)initWithFile:(NSString *)fileName width:(int)width height:(int)height;
- (void)decodeWithComplete:(void(^)(char *buf, CGSize frameSize))complete;
@end

NS_ASSUME_NONNULL_END
