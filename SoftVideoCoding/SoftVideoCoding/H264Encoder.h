//
//  H264Encoder.h
//  SoftVideoCoding
//
//  Created by mac on 2018/12/14.
//  Copyright © 2018年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface H264Encoder : NSObject

-(instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSize:(CGSize)size NS_DESIGNATED_INITIALIZER;
- (void)encodeFrame:(CMSampleBufferRef)sampleBuf;
- (void)stopEncoding;

@end

NS_ASSUME_NONNULL_END
