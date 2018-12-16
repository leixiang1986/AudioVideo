//
//  ViewController.m
//  SoftVideoDecoding
//
//  Created by mac on 2018/12/14.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLView20.h"
#import "H264Decoder.h"

@interface ViewController ()
@property (nonatomic, strong) OpenGLView20 *glView;
@property (nonatomic, strong) H264Decoder *decoder;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.glView = [[OpenGLView20 alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:self.glView atIndex:0];
    _decoder = [[H264Decoder alloc] initWithFile:@"story.mp4" width:480 height:640];
}

- (IBAction)start:(id)sender {
    __weak typeof(self) weakSelf = self;
    [_decoder decodeWithComplete:^(char * _Nonnull buf, CGSize frameSize) {
        [weakSelf.glView displayYUV420pData:buf width:(int)frameSize.width height:(int)frameSize.height];
        free(buf);
    }];
}

@end
