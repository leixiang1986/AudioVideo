//
//  ViewController.m
//  HardCodingDemo
//
//  Created by mac on 2018/12/15.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ViewController.h"
#import "VideoCapture.h"

@interface ViewController ()
@property (nonatomic,strong) VideoCapture *videoCapture;
@end

@implementation ViewController

- (VideoCapture *)videoCapture {
    if (!_videoCapture) {
        _videoCapture = [[VideoCapture alloc] init];
    }
    
    return _videoCapture;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)start:(id)sender {
    [self.videoCapture startCapturing:self.view];
    
}
- (IBAction)end:(id)sender {
    [self.videoCapture stopCapturing];
}

@end
