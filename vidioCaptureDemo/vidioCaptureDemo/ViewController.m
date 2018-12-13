//
//  ViewController.m
//  vidioCaptureDemo
//
//  Created by mac on 2018/12/13.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, weak) AVCaptureDeviceInput *videoInput;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    

}

- (IBAction)startCapture:(id)sender {
    self.session = [[AVCaptureSession alloc] init];
    
//    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
//
//    }];
//    if (status != AVAuthorizationStatusAuthorized) {
//        NSLog(@"没有取得授权");
//    }
    //创建设备
    AVCaptureDevice *device  = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //创建输入,添加输入
    NSError *error = nil;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (![_session canAddInput:deviceInput]) {
        NSLog(@"无法加入输入源");
        return;
    }
    [_session addInput:deviceInput];
    _videoInput = deviceInput;
    
    //添加输出
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0   )];
    if ([_session canAddOutput:output]) {
        [_session addOutput:output];
    }
    
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
}

- (IBAction)reverseLens:(id)sender {
    if (_videoInput == nil) {
        return;
    }
    
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

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"捕捉到帧数据");
}


@end
