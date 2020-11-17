//
//  ViewController.m
//  FaceBeauty
//
//  Created by liuhongyang on 2020/11/17.
//  Copyright © 2020 Burning. All rights reserved.
//

#import "ViewController.h"
#import "FaceBeautyRecorder.h"

@interface ViewController ()

@property (nonatomic,strong) FaceBeautyRecorder *recorder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.bounds = [UIScreen mainScreen].bounds;
    self.recorder = [[FaceBeautyRecorder alloc] init];
    [self.recorder setupPreview:self.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.recorder startCaptureSession];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.recorder stopCaptureSession];
}

- (IBAction)thinFaceSlider:(id)sender {
    self.recorder.thinFacePercent = ((UISlider *)sender).value;
}
- (IBAction)bigEyeSlider:(id)sender {
    self.recorder.bigEyesPercent = ((UISlider *)sender).value;
}
- (IBAction)showSwitch:(id)sender {
    self.recorder.showLankmarks = ((UISwitch *)sender).isOn;
}

@end
