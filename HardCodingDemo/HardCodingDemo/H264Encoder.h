//
//  H264Encoder.h
//  HardCodingDemo
//
//  Created by mac on 2018/12/15.
//  Copyright © 2018年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface H264Encoder : NSObject
- (instancetype)initWithWidth:(int)width height:(int )height;
- (void)encodeFrame:(CMSampleBufferRef)buf;
- (void)stopEncoding;
@end

NS_ASSUME_NONNULL_END
