//
//  H264Encoder.m
//  SoftVideoCoding
//
//  Created by mac on 2018/12/14.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "H264Encoder.h"
//#import <FFmpeg/avformat.h>
//#import <FFmpeg/avcodec.h>
#import "avformat.h"
#import "avcodec.h"

@interface H264Encoder ()
{
    AVFormatContext *pFormatCxt;
    AVStream *pStream;
    AVCodecContext *pCodecCtx;
    AVCodec *pCodec;
    AVFrame *pFrame;
    
    int frame_width;
    int frame_height;
    int frame_size;
    AVPacket packet;
}
@end

@implementation H264Encoder
- (instancetype)initWithSize:(CGSize)size {
    self = [super init];
    if (self) {
        av_register_all();
        
        pFormatCxt = avformat_alloc_context();
        
        NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"123.h264"];
        
        //创建输出流
        AVOutputFormat *outputFormat = av_guess_format(NULL, [filePath UTF8String], NULL);
        pFormatCxt->oformat = outputFormat;
        
        if (avio_open(&pFormatCxt->pb, [filePath UTF8String], AVIO_FLAG_READ_WRITE) < 0) {
            NSLog(@"打开输出流失败");
            return nil;
        }
        
        //创建stream
        pStream = avformat_new_stream(pFormatCxt, 0);
        
        pStream->time_base.num = 90000;
        pStream->time_base.den = 1;
        
        if (pStream == NULL) {
            NSLog(@"创建输出流失败");
            return nil;
        }
        
        //从stream中获取AVCodecContext
        pCodecCtx = pStream->codec;
        pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
        pCodecCtx->codec_id = AV_CODEC_ID_H264;
        pCodecCtx->pix_fmt = PIX_FMT_YUV420P;
        
        pCodecCtx->width = size.width;
        pCodecCtx->height = size.height;
        
        pCodecCtx->time_base.num = 24;
        pCodecCtx->time_base.den = 1;
        
        pCodecCtx->bit_rate = 1500000;
        
        pCodecCtx->gop_size = 30;
        
        pCodecCtx->max_b_frames = 5;
        
        pCodecCtx->qmax = 51;
        pCodecCtx->qmin = 10;
        
        //查找编码器
        pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
        
        if (pCodec == NULL) {
            NSLog(@"查找编码器失败");
            return nil;
        }
        
        //打开编码器
        AVDictionary *parma = 0;
        if (pCodecCtx->codec_id == AV_CODEC_ID_H264) {
            av_dict_set(&parma, "preset", "slow", 0);
            av_dict_set(&parma, "tune", "zerolatency", 0);
        }
        
        if (avcodec_open2(pCodecCtx, pCodec, &parma) < 0) {
            NSLog(@"打开编码器失败");
            return nil;
        }
        
        //创建AVFrame->AVPacket
        pFrame = av_frame_alloc();
        
        uint8_t buffer;
        avpicture_fill((AVPicture *)pFrame, &buffer, PIX_FMT_YUV420P, (int)size.width, (int)size.height);
        
        //记录宽高
        frame_width = size.width;
        frame_height = size.height;
        frame_size = size.width * size.height;
        
    }
    return self;
}

- (void)encodeFrame:(CMSampleBufferRef)sampleBuf {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuf);
    //锁定CVImageBufferRef对应的内存地址
    if (CVPixelBufferLockBaseAddress(imageBuffer, 0) != kCVReturnSuccess) {
        return;
    }
    //获取Y分量
    UInt8 *bufferPtrY = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
    //UV分量
    UInt8 *bufferPtrUV = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,1);
    //获取图像真实的宽高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    //获取Y分量，每行的数据量
    size_t yBPR = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    size_t uvBPR = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
    //4:1:1
    //iOS视频采集的NV12的数据，要转化为网络传输的I420
    UInt8 *yuv420_data = (UInt8 *)calloc(1, width * height * 3 / 2);
    UInt8 *pU = yuv420_data + width * height;
    UInt8 *pV = pU + (width * height)/4;
    for (int i = 0; i < height; i++) {
        memcpy(yuv420_data+i*width, bufferPtrY + i * yBPR, width);
    }
    
    for (int j = 0; j < height / 2; j++) {
        for (int i = 0; i <  width / 2; i++) {
            *(pU++) = bufferPtrUV[i<<1];
            *(pV++) = bufferPtrUV[(i<<1)+1];
        }
        bufferPtrY += uvBPR;
    }
    
    //将获取到的I420传递给AVFrame
    pFrame->data[0] = yuv420_data;
    pFrame->data[1] = yuv420_data + width * height;
    pFrame->data[2] = yuv420_data + width * height * 5 / 4;
    
    //设置宽高
    pFrame->width = frame_width;
    pFrame->height = frame_height;
    
    //设置格式
    pFrame->format = PIX_FMT_YUV420P;
    
    //将AVFrame编码成AVPacket
    int got_picure = 0;
    if (avcodec_encode_video2(pCodecCtx, &packet, pFrame, &got_picure) < 0) {
        NSLog(@"编码一帧数据失败");
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        return;
    }
    
    if (got_picure) {
        packet.stream_index = pStream->index;
        av_write_frame(pFormatCxt, &packet);
        av_free_packet(&packet);
    }
    
    free(yuv420_data);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

- (void)stopEncoding {
    av_write_trailer(pFormatCxt);
    avcodec_close(pCodecCtx);
    avpicture_free((AVPicture *)pFrame);
    free(pFormatCxt);
}

@end
