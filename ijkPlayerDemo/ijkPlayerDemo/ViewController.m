//
//  ViewController.m
//  ijkPlayerDemo
//
//  Created by mac on 2018/12/18.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>

@interface ViewController ()
@property (nonatomic, strong) IJKFFMoviePlayerController *vc;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    IJKFFOptions *option = [IJKFFOptions optionsByDefault];
    IJKFFMoviePlayerController *vc = [[IJKFFMoviePlayerController alloc] initWithContentURLString:@"rtmp://192.168.1.10:1935/rtmplive/demo" withOptions:option];
    vc.view.frame = self.view.bounds;
    [self.view addSubview:vc.view];
    _vc = vc;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_vc prepareToPlay];
}


@end
