//
//  ViewController.m
//  vidioCaptureDemo
//
//  Created by mac on 2018/12/13.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong) AVCaptureSession *session;  //previewLayer中引用
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, weak) AVCaptureDeviceInput *videoInput;
@property (nonatomic, weak) AVCaptureMovieFileOutput *fileOutput;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    

}

- (IBAction)startCapture:(id)sender {
    self.session = [[AVCaptureSession alloc] init];
        //创建设备
    AVCaptureDevice *device  = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //创建输入,添加输入
    NSError *error = nil;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (![_session canAddInput:deviceInput] || error != nil) {
        NSLog(@"无法加入输入源");
        return;
    }
    [_session addInput:deviceInput];
    _videoInput = deviceInput;
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (![_session canAddInput:audioInput] || error != nil) {
        NSLog(@"添加音频输入失败");
        return;
    }
    [_session addInput:audioInput];
    
    //添加输出
    AVCaptureMovieFileOutput *fileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if (![_session canAddOutput:fileOutput]) {
        NSLog(@"不能添加文件输出");
        return ;
    }
    [_session addOutput:fileOutput];
    self.fileOutput = fileOutput;
    AVCaptureConnection *connection = [fileOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    
    //视频输出
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0   )];
    if (![_session canAddOutput:output]) {
        NSLog(@"不能添加视频输出");
        return;
    }
    [_session addOutput:output];
    
    //音频输出
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    if (![_session canAddOutput:audioOutput]) {
        NSLog(@"不能添加音频输出");
        return;
    }
    [_session addOutput:audioOutput];
    
    //添加预览图层
    [self.previewLayer removeFromSuperlayer];
    AVCaptureVideoPreviewLayer *prelayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    if (prelayer == nil) {
        NSLog(@"初始化prelayer 失败");
        return;
    }
    prelayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:prelayer atIndex:0];
    self.previewLayer = prelayer;
    
    [_session startRunning];
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"abc.mp4"];
    NSURL *url = [NSURL fileURLWithPath:path];
    [fileOutput startRecordingToOutputFileURL:url recordingDelegate:self];
    
    
    
}

- (IBAction)reverseLens:(id)sender {
    if (_videoInput == nil) {
        return;
    }
    
    CATransition *animation = [[CATransition alloc] init];
    animation.type = @"oglFlip";
    animation.subtype = @"fromLeft";
    animation.duration = 0.5;
    [self.view.layer addAnimation:animation forKey:nil];
    
    //获取之前的镜头
    AVCaptureDevicePosition position = _videoInput.device.position;
    BOOL isFront = (position == AVCaptureDevicePositionFront);
    position = isFront ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    
    //获取新的device
    AVCaptureDevice *device = [self cameraWithPostion:position];
    
    //获取新的输入
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
   
    //移除旧的input，添加新的input
    [_session beginConfiguration];
    [_session removeInput:_videoInput];
    if ([_session canAddInput:input]) {
        [_session addInput:input];
    }
    [_session commitConfiguration];
    
    _videoInput = input;
}


- (IBAction)stopCapture:(id)sender {
    [_fileOutput stopRecording];
    [_session stopRunning];
    [_previewLayer removeFromSuperlayer];
    _session = nil;
    _previewLayer = nil;
}
#pragma mark private

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (AVCaptureDevice *)cameraWithPostion:(AVCaptureDevicePosition)position{
    //返回和视频录制相关的默认设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    //遍历这些设备返回跟postion相关的设备
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}
#else
- (AVCaptureDevice *)cameraWithPostion:(AVCaptureDevicePosition)position{
    AVCaptureDeviceDiscoverySession *devicesIOS10 = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    
    NSArray *devicesIOS  = devicesIOS10.devices;
    for (AVCaptureDevice *device in devicesIOS) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}
#endif

#pragma mark - delegate
//音视频的代理方法
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    if ([output connectionWithMediaType:AVMediaTypeVideo] == connection) {
        NSLog(@"视频帧数据");
    } else {
        NSLog(@"音频数据");
    }
}

//写入文件的代理方法
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    NSLog(@"开始了写入%@",[fileURL absoluteString]);
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    NSLog(@"完成了写入%@:%@",error,[outputFileURL absoluteString]);
}

@end
