//
//  H264Encoder.m
//  HardCodingDemo
//
//  Created by mac on 2018/12/15.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "H264Encoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface H264Encoder ()
{
    int frameIndex;
}
@property (nonatomic, assign) VTCompressionSessionRef sesstion;
@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

@implementation H264Encoder
- (instancetype)initWithWidth:(int)width height:(int )height {
    if (self = [super init]) {
        NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"123.h264"];
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        
        frameIndex = 0;
        
        // 1.创建VTCompressionSessionRef对象
        // 参数一: CoreFoundation创建对象的方式, NULL -> Default
        // 参数二: 编码的视频的宽度
        // 参数三: 编码的视频的高度
        // 参数四: 编码的标准 H.264/H/265
        // 参数五~参数七 : NULL
        // 参数八: 编码成功一帧数据后的回调函数
        // 参数九: 回调函数中的第一个参数
        VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, compressCallback, (__bridge void *)self, &_sesstion);
        //2.设置属性
        VTSessionSetProperty(_sesstion, kVTCompressionPropertyKey_RealTime, (__bridge CFTypeRef _Nonnull)(@YES));
        //设置帧率
        VTSessionSetProperty(_sesstion, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef _Nonnull)(@30));
        //设置码率
        VTSessionSetProperty(_sesstion, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef _Nonnull)(@1500000));
        NSArray *limits = @[@(1500000/8),@1];
        VTSessionSetProperty(_sesstion, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFTypeRef _Nonnull)(limits));
        //设置GOP大小
        VTSessionSetProperty(_sesstion, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef _Nonnull)(@20));
        //准备开始编码
        VTCompressionSessionPrepareToEncodeFrames(_sesstion);
    }
    
    return self;
}

- (void)encodeFrame:(CMSampleBufferRef)buf {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(buf);
    frameIndex++;
    CMTime pts = CMTimeMake(frameIndex, 30); //展示时间戳
    VTCompressionSessionEncodeFrame(_sesstion, imageBuffer, pts, kCMTimeInvalid, NULL, NULL, NULL);
}

- (void)stopEncoding {
    VTCompressionSessionInvalidate(_sesstion);
    CFRelease(_sesstion);
}

#pragma mark - private
void compressCallback(void * CM_NULLABLE outputCallbackRefCon,
                      void * CM_NULLABLE sourceFrameRefCon,
                      OSStatus status,
                      VTEncodeInfoFlags infoFlags,
                      CM_NULLABLE CMSampleBufferRef sampleBuffer) {
    
    if (sampleBuffer == NULL) {
        NSLog(@"sampleBuffer 为NULL");
        return;
    } else {
        NSLog(@"Debug SampleBuffer 不为NULL");
    }
    
    //获取当前的对象
    H264Encoder *encoder = (__bridge H264Encoder *)outputCallbackRefCon;
    //判断是否是关键帧
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFDictionaryRef dict = CFArrayGetValueAtIndex(attachments, 0);
    BOOL isKeyFrame = !CFDictionaryContainsKey(dict, kCMSampleAttachmentKey_NotSync);
    if (isKeyFrame) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        //从format中获取SPS信息--序列参数集
        const uint8_t *spsPointer;
        size_t spsSize, spsCount;
        int NALUHeaderLength;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &spsPointer, &spsSize, &spsCount, &NALUHeaderLength);
        NSLog(@"1获取sps时获取的NALUHeaderLength:%d",NALUHeaderLength);
        
        //从format中获取PPS信息--图像参数集
        const uint8_t *ppsPointer;
        size_t ppsSize, ppsCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &ppsPointer, &ppsSize, &ppsCount, &NALUHeaderLength);
        NSLog(@"2获取pps时获取的NALUHeaderLength:%d",NALUHeaderLength);
        
        NSLog(@"spsSize:%ld ppsSize:%ld \n spsCount:%ld  ppsCount:%ld",spsSize,ppsSize,spsCount,ppsCount);
        //将sps/pps写入NAL单元中
        NSData *spsData = [NSData dataWithBytes:spsPointer length:spsSize];
        NSData *ppsData = [NSData dataWithBytes:ppsPointer length:ppsSize];
        [encoder writeData:spsData];
        [encoder writeData:ppsData];
    }
    
    //将编码后的帧数据写入文件中
    //获取CMBlockVufferRef
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    //获取内存地址和长度
    size_t totalLength;
    char *dataPointer;
    CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totalLength, &dataPointer);
    
    static const int h264HeaderLength = 4;
    size_t offsetLength = 0;
    
    while (h264HeaderLength < totalLength - offsetLength) {
        //4.5读取slice的长度
        uint32_t naluLength;
        memcpy(&naluLength, dataPointer+offsetLength, h264HeaderLength);
        
        //h264大端字节序
        naluLength = CFSwapInt32BigToHost(naluLength);
        
        //根据读取字节，并且转成NSData
        NSData *data = [NSData dataWithBytes:dataPointer + offsetLength + h264HeaderLength length:naluLength];
        
        [encoder writeData:data];
        
        offsetLength += naluLength + h264HeaderLength;
    }
    
    
    
    
}

- (void)writeData:(NSData *)data {
    if (data.length == 0) {
        return;
    }
    const char bytes[] = "\x00\x00\x00\x01";
    int headerLength = sizeof(bytes) - 1; //字符串最后一个是\0
    NSData *headerData = [NSData dataWithBytes:bytes length:headerLength];
    //NALU体
    [self.fileHandle writeData:headerData];
    [self.fileHandle writeData:data];
    
}


@end
