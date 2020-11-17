//
//  FaceBeautyRecorder.m
//  FaceBeauty
//
//  Created by liuhongyang on 2020/11/17.
//  Copyright © 2020 Burning. All rights reserved.
//

#import "FaceBeautyRecorder.h"
//gpu
#import <GPUImage/GPUImage.h>
#import "FaceBeautyThinFaceFilter.h"

#import "FaceBeautyFaceDetector.h"

@interface FaceBeautyRecorder ()<GPUImageVideoCameraDelegate>

@property (nonatomic,strong) GPUImageView *gpuView;
@property (nonatomic,strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic,strong) FaceBeautyThinFaceFilter *thinFaceFilter;

@end
@implementation FaceBeautyRecorder

#pragma mark - Public

- (void)setupPreview:(UIView *)preview
{
    self.gpuView = [[GPUImageView alloc] initWithFrame:preview.bounds];
    [self.gpuView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    [self.gpuView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [preview insertSubview:self.gpuView atIndex:0];
    
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.frameRate = 25;
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    [self.videoCamera addAudioInputsAndOutputs];
    self.videoCamera.delegate = self;
    
    self.thinFaceFilter = [[FaceBeautyThinFaceFilter alloc] init];
    
    [self.videoCamera addTarget:self.thinFaceFilter];
    [self.thinFaceFilter addTarget:self.gpuView];

}

#warning GPUImage中有在子线程中刷新UI，所以会卡顿几秒钟，可自行优化
- (void)startCaptureSession{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.videoCamera startCameraCapture];
    });
}

- (void)stopCaptureSession{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.videoCamera stopCameraCapture];
    });
}

- (void)setShowLankmarks:(BOOL)showLankmarks
{
    _showLankmarks = showLankmarks;
    if (!showLankmarks) {
        while (self.gpuView.subviews.count) {
            [self.gpuView.subviews.lastObject removeFromSuperview];
        }
    }
}

- (void)setThinFacePercent:(CGFloat)thinFacePercent
{
    _thinFacePercent = thinFacePercent;
    CGFloat min = 0.00;
    CGFloat max = 0.05;
    self.thinFaceFilter.thinFaceDelta =  (max - min) * thinFacePercent + min;
}

- (void)setBigEyesPercent:(CGFloat)bigEyesPercent
{
    _bigEyesPercent = bigEyesPercent;
    CGFloat min = 0.00;
    CGFloat max = 0.15;
    self.thinFaceFilter.bigEyeDelta =  (max - min) * bigEyesPercent + min;
}

#pragma mark - Prvite



#pragma mark - GPUImageVideoCameraDelegate

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CMSampleBufferRef imageCopy;
    CMSampleBufferCreateCopy(CFAllocatorGetDefault(), sampleBuffer, &imageCopy);
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer((__bridge CMSampleBufferRef)(CFBridgingRelease(imageCopy)));
    
    [[FaceBeautyFaceDetector shareInstance] getLandmarksFromPixelBuffer:pixelBuffer orientation:kCGImagePropertyOrientationLeftMirrored complete:^(NSArray * _Nonnull landmarks) {
        
#warning 此方法较耗性能，仅做辅助测试用，建议使用opengl绘制
        if (self.showLankmarks) {
            dispatch_async(dispatch_get_main_queue(), ^{
                while (self.gpuView.subviews.count) {
                    [self.gpuView.subviews.lastObject removeFromSuperview];
                }
                for (int i=0; i< landmarks.count; i++) {
                    UIView *pointview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, 3)];
                    pointview.backgroundColor = [UIColor yellowColor];
                    NSValue *value = landmarks[i];
                    CGPoint point = [value CGPointValue];
                    pointview.center = CGPointMake(point.x * self.gpuView.frame.size.width, point.y * self.gpuView.frame.size.height);
                    [self.gpuView addSubview:pointview];
                    
                    UILabel *indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 24, 12)];
                    indexLabel.font = [UIFont systemFontOfSize:8.0];
                    indexLabel.textColor = [UIColor orangeColor];
                    indexLabel.center = CGPointMake(point.x * self.gpuView.frame.size.width, point.y * self.gpuView.frame.size.height + 5);
                    indexLabel.text = [NSString stringWithFormat:@"%d",i];
                    [self.gpuView addSubview:indexLabel];
                }
            });
        }
    }];
}


@end
