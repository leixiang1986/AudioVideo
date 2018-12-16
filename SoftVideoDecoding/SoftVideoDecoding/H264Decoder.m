//
//  H264Decoder.m
//  SoftVideoDecoding
//
//  Created by mac on 2018/12/14.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "H264Decoder.h"
#import "avformat.h"
#import "avcodec.h"

@interface H264Decoder()
{
    AVFormatContext *pFormatCtx;
    AVStream *pStream;
    AVCodecContext *pCodecCtx;
    AVCodec *pCodec;
    AVFrame *pFrame;
    AVPacket packet;
    int video_index;
    
}
@end

@implementation H264Decoder
- (instancetype)initWithFile:(NSString *)fileName width:(int)width height:(int)height {
    self = [super init];
    if (self) {
        av_register_all();
        NSString *filepath = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
        if (avformat_open_input(&pFormatCtx, [filepath UTF8String], NULL, NULL) < 0) {
            NSLog(@"打开输入流失败");
            return nil;
        }
        
        if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
            NSLog(@"查找流失败");
            return nil;
        }
        
        video_index = -1;
        for (int i = 0; i < pFormatCtx->nb_streams; i++) {
            if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
                video_index++;
                NSLog(@"是视频数据===========");
                break;
            } else {
                NSLog(@"不是视频数据---------");
            }
        }
        
        pStream = pFormatCtx->streams[video_index];
        pCodecCtx = pStream->codec;
        pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
        if (pCodec == NULL) {
            NSLog(@"查找解码器失败");
            return nil;
        }
        
        //打开解码器
        if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
            NSLog(@"打开解码器失败");
            return nil;
        }
        
        pFrame = av_frame_alloc();
    }
    return self;
}

- (void)decodeWithComplete:(void(^)(char *buf, CGSize frameSize))complete {
    while (av_read_frame(pFormatCtx, &packet) >= 0) {
        if (packet.stream_index != video_index) {
            NSLog(@"不是视频数据");
            continue;
        }
        
        int got_picture = -1;
        if (avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, &packet) < 0) { //没有解码成功，继续下一帧的解码
            continue;
        }
        
        if (got_picture) {
            //申请内存
            char *buf = (char *)calloc(1, pFrame->width * pFrame->height * 3 / 2);
            AVPicture *picture = (AVPicture *)pFrame;
            int w, h, i;
            char *y, *u, *v;
            w = pFrame->width;
            h = pFrame->height;
            y = buf;
            u = y+ w * h;
            v = u + w * h / 4;
            for (i=0; i<h; i++) {
                memcpy(y + w * i, picture->data[0] + picture->linesize[0] * i, w);
            }
            for (i=0; i<h/2; i++) {
                memcpy(u + w/2 * i, picture->data[1] + picture->linesize[1] * i, w / 2);
            }
            for (i = 0; i < h /2; i++) {
                memcpy(v + w / 2 * i, picture->data[2] + picture->linesize[2] * i, w / 2);
            }
            
            if (buf == NULL) {
                continue;
            }
            
            if (complete) {
                complete(buf,CGSizeMake(w, h));
            }
        }
    }
}
@end
