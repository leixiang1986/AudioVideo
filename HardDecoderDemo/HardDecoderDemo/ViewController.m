//
//  ViewController.m
//  HardDecoderDemo
//
//  Created by mac on 2018/12/16.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ViewController.h"
#import <VideoToolbox/VideoToolbox.h>
#import "AAPLEAGLLayer.h"

@interface ViewController ()
{
    long packetSize;
    uint8_t *packetBuffer;
    
    long maxReadLength;
    long leftLength;
    uint8_t *dataPointer;
    
    uint8_t *mSPS;
    long mSPSSize;
    uint8_t *mPPS;
    long mPPSSize;
}

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, weak) CADisplayLink *displayLink;
@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, assign) VTDecompressionSessionRef session;
@property (nonatomic, assign) CMFormatDescriptionRef format;
@property (nonatomic, weak) AAPLEAGLLayer *previewLayer;
@end

const char startCode[] = "\x00\x00\x00\x01";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"123.h264" ofType:nil];
    self.inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    
    //定时器
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame)];
    [displayLink setFrameInterval:2];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [displayLink setPaused:YES];
    self.displayLink = displayLink;
    
    self.queue = dispatch_get_global_queue(0, 0);
    
    AAPLEAGLLayer *layer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];
    [self.view.layer addSublayer:layer];
    self.previewLayer = layer;
}

- (void)updateFrame {
    
    //读取一个NALU的数据
    [self readPacket];
    
    if (packetSize == 0 || packetBuffer == NULL) {
        [self.displayLink setPaused:YES];
        [self.displayLink invalidate];
        [self.inputStream close];
        return;
    }
    
    //根据数据的类型进行不同的处理
    //sps/pps/i帧/其他帧
    uint32_t nalSize = (uint32_t)(packetSize - 4);
    uint32_t *pNalSize = (uint32_t *)packetBuffer;
    *pNalSize = CFSwapInt32HostToBig(nalSize);
    
    int nalType = packetBuffer[4] & 0x1F;
    CVImageBufferRef imageBuffer = NULL;
    switch (nalType) {
        case 0x07:
            mSPSSize = packetSize - 4;
            mSPS = calloc(1, mSPSSize);
            memcpy(mSPS, packetBuffer + 4, mSPSSize);
            break;
        case 0x08:
            mPPSSize = packetSize - 4;
            mPPS = calloc(1, mPPSSize);
            memcpy(mPPS, packetBuffer + 4, mPPSSize);
            break;
        case 0x05:
            [self initDecompressionsession];
            imageBuffer = [self decodeFrame];
        default:
            imageBuffer = [self decodeFrame];
            break;
    }
    
    if (imageBuffer != NULL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.previewLayer.pixelBuffer = imageBuffer;
            CFRelease(imageBuffer);
        });
    }
}

- (void)initDecompressionsession {
    //1,创建CMVideoFormatDescriptionRef
    const uint8_t *parameterSetPointers[2] = {mSPS,mPPS};
    const size_t parameterSetSizes[2] = {mSPSSize,mPPSSize};
    CMVideoFormatDescriptionCreateFromH264ParameterSets(NULL, 2, parameterSetPointers, parameterSetSizes, 4, &_format);
    
    //解码之后的回调函数
    NSDictionary *attr = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
    VTDecompressionOutputCallbackRecord callbackRecord;
    callbackRecord.decompressionOutputCallback = decompressionCallback;
    
    // 3.创建VTDecompressionSession
    VTDecompressionSessionCreate(NULL, self.format, NULL, (__bridge CFDictionaryRef _Nullable)(attr), &callbackRecord, &_session);
}

- (CVPixelBufferRef)decodeFrame {
    CMBlockBufferRef blockBuffer = NULL;
    CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                       (void*)packetBuffer,
                                       packetSize,
                                       kCFAllocatorNull,
                                       NULL,
                                       0,
                                       packetSize,
                                       0,
                                       &blockBuffer);
    //创建准备的对象
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {0};
    CMSampleBufferCreateReady(NULL, blockBuffer, self.format, 0, 0, NULL, 0, sampleSizeArray, &sampleBuffer);
    
    //开始解码
    CVPixelBufferRef outputPixelBuffer = NULL;
    VTDecompressionSessionDecodeFrame(_session, sampleBuffer, 0, &outputPixelBuffer, NULL);
    
    CFRelease(sampleBuffer);
    CFRelease(blockBuffer);
    
    return outputPixelBuffer;
}


- (void)readPacket {
    //将之前保存的数据清空
    if (packetSize != 0) {
        packetSize = 0;
    }
    if (packetBuffer != NULL) {
        free(packetBuffer);
        packetBuffer = NULL;
    }
    //开始从文件中读取一定长度的数据
    if (leftLength < maxReadLength && self.inputStream.hasBytesAvailable) {
        leftLength += [self.inputStream read:dataPointer + leftLength
                                   maxLength:maxReadLength - leftLength];
    }
    
    //从dataPointerz内存中取出一个NALU的长度
    //并且放入到packetSize/packetBuffer - 1
    if (memcmp(dataPointer, startCode, 4) == 0) {
        if (leftLength > 4) {
            uint8_t *pStart = dataPointer + 4;
            uint8_t *pEnd = dataPointer + leftLength;
            while (pStart != pEnd) { //这里使用一种简略的方式来获取这一帧的长度：通过查找下一个0x00000001来确定
                if (memcmp(pStart - 3, startCode, 4) == 0) {
                    packetSize = pStart - 3 - dataPointer;
                    packetBuffer = calloc(1, packetSize);
                    memcpy(packetBuffer, dataPointer, packetSize);
                    memmove(dataPointer, dataPointer + packetSize, leftLength - packetSize);
                    leftLength -= packetSize;
                    break;
                } else {
                    ++pStart;
                }
            }
        }
    }
}

void decompressionCallback(void * CM_NULLABLE decompressionOutputRefCon,
                           void * CM_NULLABLE sourceFrameRefCon,
                           OSStatus status,
                           VTDecodeInfoFlags infoFlags,
                           CM_NULLABLE CVImageBufferRef imageBuffer,
                           CMTime presentationTimeStamp,
                           CMTime presentationDuration ) {
    CVPixelBufferRef *pointer = (CVPixelBufferRef *)sourceFrameRefCon;
    *pointer = CVBufferRetain(imageBuffer);
}
- (IBAction)play:(id)sender {
    // 1.对定义的长度进行赋值
    maxReadLength = 720 * 1280;
    leftLength = 0;
    dataPointer = malloc(maxReadLength);
    
    // 2.打开文件
    [self.inputStream open];
    
    // 3.开始读取
    [self.displayLink setPaused:NO];
}

@end
