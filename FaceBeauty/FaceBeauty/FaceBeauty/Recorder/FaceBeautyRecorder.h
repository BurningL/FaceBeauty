//
//  FaceBeautyRecorder.h
//  FaceBeauty
//
//  Created by liuhongyang on 2020/11/17.
//  Copyright © 2020 Burning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FaceBeautyRecorder : NSObject

@property (nonatomic,assign) BOOL showLankmarks;
@property (nonatomic,assign) CGFloat thinFacePercent;
@property (nonatomic,assign) CGFloat bigEyesPercent;

- (void)setupPreview:(UIView *)preview;
- (void)startCaptureSession;
- (void)stopCaptureSession;

@end

NS_ASSUME_NONNULL_END
