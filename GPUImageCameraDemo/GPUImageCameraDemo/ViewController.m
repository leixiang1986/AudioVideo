//
//  ViewController.m
//  GPUImageCameraDemo
//
//  Created by mac on 2018/12/14.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage.h>

@interface ViewController ()
@property (nonatomic, strong) GPUImageStillCamera *camera;
@property (nonatomic, strong) GPUImageBrightnessFilter *filter;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self createCamera];
    
}

- (void)createCamera {
    //创建相机
    GPUImageStillCamera *camera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:(AVCaptureDevicePositionFront)];
    camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _camera = camera;
    
    //添加滤镜
    GPUImageBrightnessFilter *filter = [[GPUImageBrightnessFilter alloc] init];
    [camera addTarget:filter];
    filter.brightness = 0.1;
    _filter = filter;
    
    //创建UIImageView
    GPUImageView *imageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:imageView atIndex:0];
    [filter addTarget:imageView];
    
}

- (IBAction)start:(id)sender {
    if (_camera == nil) {
        return;
    }
    [_camera startCameraCapture];
}

- (IBAction)stop:(id)sender {
    if (_camera == nil) {
        return;
    }
    [_camera stopCameraCapture];
}

- (IBAction)takePhoto:(id)sender {
    if (_camera == nil) {
        return;
    }
    [_camera capturePhotoAsImageProcessedUpToFilter:_filter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        void *context = NULL;
        UIImageWriteToSavedPhotosAlbum(processedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), context);
    }];
}

- (IBAction)reverse:(id)sender {
    if (_camera == nil) {
        return;
    }
    [_camera rotateCamera];
}

- (void)image:(UIImage *)image
    didFinishSavingWithError:(NSError *)error
                 contextInfo:(void *)contextInfo{
    NSLog(@"保存成功");
}

@end
