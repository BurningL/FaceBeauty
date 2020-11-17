//
//  FaceBeautyThinFaceFilter.h
//  FaceBeauty
//
//  Created by liuhongyang on 2020/11/17.
//  Copyright © 2020 Burning. All rights reserved.
//

#import <GPUImage/GPUImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface FaceBeautyThinFaceFilter : GPUImageFilter

@property(nonatomic, assign) CGFloat thinFaceDelta;
@property(nonatomic, assign) CGFloat bigEyeDelta;

@end

NS_ASSUME_NONNULL_END
