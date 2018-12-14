//
//  ViewController.m
//  GPUImageDemo
//
//  Created by mac on 2018/12/13.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _imageView.contentMode = UIViewContentModeScaleToFill;
    _imageView.image = [UIImage imageNamed:@"test"];
    
}

- (void)processPictureWithFilter:(GPUImageFilter *)filter {
    if (filter == nil) {
        return;
    }
    
    UIImage *image = [UIImage imageNamed:@"test"];
    //gpu图片
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
    //设置滤镜

    
    //添加滤镜
    [picture addTarget:filter];
    
    //使用滤镜处理下一次显示
    [filter useNextFrameForImageCapture];
    [picture processImage];
    
    _imageView.image = filter.imageFromCurrentFramebuffer;
    
}
- (IBAction)sketchFilter:(id)sender {
    GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
    [self processPictureWithFilter:filter];
}
- (IBAction)blurFilter:(id)sender {
    GPUImageGaussianBlurFilter *blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    blurFilter.blurRadiusInPixels = 2;
    blurFilter.texelSpacingMultiplier = 5;
    [self processPictureWithFilter:blurFilter];
}

- (IBAction)fudiaoFilter:(id)sender {
    GPUImageEmbossFilter *filter = [[GPUImageEmbossFilter alloc] init];
    [self processPictureWithFilter:filter];
}

- (IBAction)invertFilter:(id)sender {
    GPUImageColorInvertFilter *filter = [[GPUImageColorInvertFilter alloc] init];
    [self processPictureWithFilter:filter];
}

- (IBAction)grayFilter:(id)sender {
    GPUImageGrayscaleFilter *filter = [[GPUImageGrayscaleFilter alloc] init];
    [self processPictureWithFilter:filter];
}



@end
